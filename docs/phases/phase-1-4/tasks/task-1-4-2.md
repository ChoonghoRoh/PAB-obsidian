---
task_id: "1-4-2"
title: "wiki new — 11필드 frontmatter 자동 + 템플릿 적용"
domain: WIKI-CLI
owner: backend-dev
priority: P0
estimate_min: 30
status: pending
depends_on: ["1-4-1"]
blocks: ["1-4-6"]
---

# Task 1-4-2 — `wiki new <type> <slug>` 구현

## 목적

새 노트 생성 워크플로우를 자동화한다: TYPE 템플릿 적용 + 11필드 frontmatter 자동 채움 + naming-convention 준수 + `obsidian create` 호출.

## 산출물

- `scripts/wiki/lib/frontmatter.py` 본격 구현 (build_default_frontmatter, render_note, write_note)
- `scripts/wiki/wiki.py` 의 `cmd_new` 함수 채움 (T-1에서 stub 작성됨)

## 11필드 default 매핑

| 필드 | default 규칙 | 비고 |
|---|---|---|
| `title` | `slug.replace("-"," ").replace("_"," ").title()` | 사용자가 frontmatter 편집으로 수정 가능 |
| `description` | `""` (빈 문자열) | jsonschema에서 빈 문자열 허용 확인 필요 |
| `created` | `datetime.now().strftime("%Y-%m-%d %H:%M")` | naming-convention의 날짜와 일관 |
| `updated` | `created`와 동일 | |
| `type` | `f"[[{TYPE}]]"` | TYPE은 인자 그대로 |
| `index` | `"[[ROOT]]"` | DOMAIN은 사용자가 본문 작성 시 직접 수정 |
| `topics` | `[]` | |
| `tags` | TYPE에 따라 1~2개 default<br>`RESEARCH_NOTE → ["research-note"]`<br>`CONCEPT → ["concept"]`<br>`LESSON → ["lesson"]`<br>`PROJECT → ["project"]`<br>`DAILY → ["daily"]`<br>`REFERENCE → ["reference"]` | schema v1.1 tag pattern (`^[a-z0-9-]+(/[a-z0-9-]+)*$`) 준수 |
| `keywords` | `[]` | |
| `sources` | `[]` | |
| `aliases` | `[]` | |

## 파일명 + 디렉토리

- 디렉토리:
  - `RESEARCH_NOTE`/`CONCEPT`/`LESSON`/`REFERENCE` → `wiki/10_Notes/`
  - `PROJECT` → `wiki/10_Notes/` (동일, slug에서 프로젝트 명시)
  - `DAILY` → `wiki/99_Inbox/` (또는 `wiki/10_Notes/` — 본 task에서는 `99_Inbox` 채택)
- 파일명: `YYYY-MM-DD_<slug>.md` (slug는 인자 그대로)
- 충돌 처리: 동일 파일 존재 시 exit 1 + 에러 메시지 (덮어쓰기 금지)

## 템플릿 머지 절차

1. `wiki/40_Templates/<TYPE>.md` 읽기
2. python-frontmatter로 frontmatter / 본문 분리
3. 본문에 placeholder(`{{title}}` 등) 있으면 build_default_frontmatter 결과로 치환 (현재 Phase 1-2 템플릿은 placeholder 미사용 — 단순 복사로 충분)
4. 새 frontmatter(default 채움) + 템플릿 본문을 합쳐 새 파일 작성

## obsidian create 호출

```python
import subprocess
result = subprocess.run(
    ["obsidian", "create", str(out_path)],
    capture_output=True, text=True, timeout=10,
)
```

- 성공 (returncode 0): stdout 메시지 출력
- 실패: stderr 보고 + 직접 파일 작성 결과는 유지 (이미 작성됨). exit 0 (파일은 정상 생성됨)
- timeout / FileNotFoundError: 경고만 출력, 파일은 유지

## --dry-run

작성될 경로 + frontmatter YAML을 stdout에 출력. 실제 파일·obsidian 호출 없음.

## smoke test

```bash
# dry-run으로 11필드 모두 채워지는지 확인
python3 scripts/wiki/wiki.py new RESEARCH_NOTE smoke-test --dry-run

# 실제 생성
python3 scripts/wiki/wiki.py new RESEARCH_NOTE smoke-test
ls -la wiki/10_Notes/$(date +%F)_smoke-test.md

# 11필드 검증
python3 -c "
import frontmatter, sys
post = frontmatter.load('wiki/10_Notes/$(date +%F)_smoke-test.md')
required = ['title','description','created','updated','type','index','topics','tags','keywords','sources','aliases']
missing = [k for k in required if k not in post.metadata]
sys.exit(0 if not missing else 1)
"

# 정리
rm wiki/10_Notes/$(date +%F)_smoke-test.md
```

## 완료 기준

- [ ] `lib/frontmatter.py` build_default_frontmatter / render_note / write_note 구현
- [ ] `wiki.py cmd_new` 분기 정상 동작 (dry-run + 실제 생성 모두)
- [ ] smoke test (RESEARCH_NOTE) 11필드 모두 채워짐
- [ ] 6 TYPE 모두 dry-run으로 검증 완료
- [ ] 동일 파일 충돌 시 exit 1
- [ ] obsidian CLI 호출 결과 (성공·실패 모두) 보고
- [ ] `lib/frontmatter.py` 200줄 이하 (R-4)
- [ ] smoke test 산출물 정리 완료

## 보고

`reports/report-backend-dev.md` §T-2:
- 6 TYPE dry-run 출력 발췌 (각 TYPE별 frontmatter)
- 실제 생성 + 검증 + 정리 로그
- obsidian CLI 호출 결과 (성공·실패·timeout 사례)

## 위험

- **L-2**: `obsidian create`가 GUI 의존이라 비대화형 환경에서 실패 가능 → 폴백으로 직접 파일 작성. 본 task는 폴백 우선 + obsidian 호출은 best-effort
- jsonschema가 빈 문자열(`description: ""`) 거부 시 → schema v1.1 확인 후 default를 placeholder 문구(`"<TODO>"`) 또는 frontmatter 누락(=None) 중 결정. backend-dev가 1차 검증 후 결정
