---
task_id: "1-5-2"
title: "skills/wiki/SKILL.md v2 — SOURCE TYPE + Step 8a 원본 저장 + TOC 링크"
domain: WIKI-SKILL
owner: backend-dev
priority: P0
estimate_min: 60
status: rework_required
depends_on: ["1-5-5"]
blocks: ["1-5-3", "1-5-6"]
intent_ref: docs/phases/phase-1-5/phase-1-5-intent.md
---

# Task 1-5-2 (REWORK v2) — `skills/wiki/SKILL.md` v2 작성

> **본질 (잃지 말 것)**:
> 1. 원본 immutable 보존 (`wiki/15_Sources/`)
> 2. LLM 요약본 (`wiki/10_Notes/`)
> 3. TOC 양방향 링크
> 4. 두 산출물 동시 생성
> 5. Karpathy 3계층 아키텍처 충족

## 목적

v1 SKILL.md에서 누락된 **원본 보존 + TOC 링크**를 정정한다. `/pab:wiki <자연어>` 1회 호출이 *항상* 두 파일을 동시 생성하도록 §3 처리 절차를 보강하고, §2 옵시디언 규격에 SOURCE TYPE을 추가한다.

## 입력
- 기존: `skills/wiki/SKILL.md` v1 (207줄, T-1/T-2 v1 산출물)
- 의존: T-5 완료 후 (SOURCE TYPE schema/template/MOC 가용 상태)
- 정의 갱신본:
  - `wiki/30_Constraints/frontmatter-spec.md` (T-5 갱신: SOURCE TYPE 추가)
  - `wiki/30_Constraints/naming-convention.md` (T-5 갱신: 15_ Sources 추가)
  - `wiki/40_Templates/SOURCE.md` (T-5 신규)

## 산출물
- `skills/wiki/SKILL.md` v2 (380줄 이하 권장, R-3 400줄 강제)

## v2 변경 사항 — v1 대비 *추가/보강*

### §2 옵시디언 규격 보강

**§2.1 TYPE**: 6 → 7 (또는 8) — `SOURCE` 추가 행:

| TYPE | 채택 신호 |
|---|---|
| **SOURCE** | 외부 자료의 *원문 텍스트 자체* — 변경 금지, 요약본의 immutable 짝 |
| RESEARCH_NOTE | 외부 자료를 정독·요약·논점 보존 (SOURCE 짝으로 자동 생성됨) |
| ... (기존 TYPE 그대로) |

**§2.2 DOMAIN**: 변경 없음 (6 DOMAIN)

**§2.3 frontmatter — TYPE별 차이 표**: SOURCE row 추가

| TYPE | `type` 값 | `tags` 첫 항목 | `index` 기본 | 특이사항 |
|---|---|---|---|---|
| SOURCE | `"[[SOURCE]]"` | `source` | (요약본의 index와 동일) | `sources` = 외부 URL 1개, 본문 = 원문 텍스트, 변경 금지 |

**§2.4 폴더 prefix 표**: `15_ Sources` 행 추가 (T-5 결과와 동기)

### §3 처리 절차 — 핵심 변경 (12 step으로 확장)

기존 Step 8 → **Step 8a + Step 8b** 분할 + Step 6에 TOC 링크 자동 삽입.

```
Step 1 — 입력 파싱 + WebFetch (URL 있을 시) — 원문 텍스트 *전체 보존*
Step 2 — TYPE 자동 판별 (요약본의 TYPE 결정. SOURCE는 짝으로 자동)
Step 3 — DOMAIN 자동 매핑
Step 4 — TOPIC 후보 추출
Step 5 — 메타데이터 생성 (slug 1개로 양 파일 공유: <slug> + <slug>_source)
Step 6 — 본문 생성 (옵시디언 친화)
   → 각 H2 섹션 헤더 *직후* 다음 줄에 원본 anchor 링크 자동 삽입:
     `[원본 §<섹션명> →](2026-05-02_<slug>_source.md#<anchor>)`
   → anchor 정규화: 소문자화, 공백→하이픈, 한글 그대로 (옵시디언 anchor 규약)
Step 7 — frontmatter 11필드 채움 (요약본 + 원본 각각)
   요약본 sources: ["[[15_Sources/2026-05-02_<slug>_source]]", "<URL>"]
   원본 sources:   ["<URL>"] (외부 URL만)
Step 8a — *원본* 저장 (NEW)
   경로: wiki/15_Sources/2026-05-02_<slug>_source.md
   내용: WebFetch로 받은 원문 텍스트 (그대로, 사용자 개인 vault 보관)
   frontmatter type: "[[SOURCE]]"
   주의: 동일 파일 존재 시 사용자에게 확인 (덮어쓰기 금지 — immutable 원칙)
Step 8b — *요약본* 저장
   경로: wiki/10_Notes/2026-05-02_<slug>.md
   내용: Step 6 본문 + Step 7 frontmatter
Step 9 — 검증 (양 파일 모두)
   - python3 scripts/wiki/wiki.py link-check (frontmatter strict)
   - violations=0 → Critical PASS
   - broken=N (의도된 unresolved 미래 노트) → WARN, 사용자에게 분리 보고
   - schema_violations만 critical로 취급
   - TOC 링크 검증: 요약본의 각 [원본 §... →] 링크가 실제 원본 헤더 anchor와 일치 (정규화 후 비교)
Step 10 — 사용자 응답 메시지
   원본/요약본 두 경로 모두 표시
   wikilink 개수 + 신규 TOPIC + TOC 링크 개수
```

### §3 Step 6 — TOC 링크 자동 삽입 명세

요약본의 각 H2 섹션은 다음 형식을 따른다:

```markdown
## <섹션 제목>
[원본 §<원본의 대응 섹션> →](2026-05-02_<slug>_source.md#<anchor>)

(LLM 요약 본문 ...)
```

**대응 섹션 매핑**: LLM이 요약본의 각 H2 섹션이 원본의 어느 섹션에서 파생됐는지 자동 결정. 1:N (요약 한 섹션이 원본 여러 섹션 통합) 또는 1:1 가능. 없으면 링크 생략 (가장 가까운 섹션 명시 권장).

**anchor 정규화 함수** (의사코드):
```
def to_anchor(header: str) -> str:
    s = header.strip().lower()
    s = re.sub(r'\s+', '-', s)        # 공백 → 하이픈
    s = re.sub(r'[^a-z0-9가-힣\-]', '', s)  # 영숫자·한글·하이픈만 유지
    return s
```

### §4 nexus 이전 가이드 — 복사 대상 갱신

**복사 대상 (4개)**:
1. `.claude-plugin/plugin.json`
2. `skills/wiki/SKILL.md` (v2)
3. `wiki/30_Constraints/{frontmatter-spec,naming-convention}.md`
4. `wiki/40_Templates/SOURCE.md` + `wiki/40_Templates/_schema.json`

**이전 시 vault 구조 동기화**:
- 폴더 신설: `wiki/15_Sources/`
- TYPE MOC: `wiki/00_MOC/TYPES/SOURCE.md`

## 실행 절차

1. T-5 완료 확인 (SOURCE 템플릿/스키마/MOC + 갱신본 frontmatter-spec/naming-convention)
2. v1 SKILL.md를 v2로 보강 (Edit 또는 Write):
   - §2.1 TYPE 표에 SOURCE row 추가
   - §2.3 TYPE별 frontmatter 표에 SOURCE row 추가
   - §2.4 폴더 prefix 표에 15_ Sources row 추가
   - §3 Step 6 — TOC 링크 자동 삽입 절차 추가
   - §3 Step 7 — 양 파일 각각 frontmatter 명세 추가
   - §3 Step 8 → Step 8a + 8b 분할
   - §3 Step 9 — 양 파일 검증 + violations/broken 분리 + TOC 링크 일치 검증
   - §3 Step 10 — 응답 메시지 양 파일 모두 표시
   - §0 헬프 출력의 사용법 갱신 (필요 시)
   - §4 nexus 이전 가이드 갱신
3. 줄 수 검증 (R-3): `wc -l skills/wiki/SKILL.md` ≤ 400
4. frontmatter YAML parse 검증

## 완료 기준

- [ ] §2.1 TYPE 표에 SOURCE row 추가됨
- [ ] §2.3 TYPE별 frontmatter 표에 SOURCE row 추가됨
- [ ] §2.4 폴더 prefix 표에 15_ Sources row 추가됨
- [ ] §3 Step 6에 TOC 링크 자동 삽입 명세 + anchor 정규화 함수 포함
- [ ] §3 Step 7에 양 파일 frontmatter 차이 명시
- [ ] §3 Step 8a (원본 저장) + Step 8b (요약본 저장) 분리 명시
- [ ] §3 Step 9에 violations/broken 분리 처리 명시
- [ ] §3 Step 10 응답 메시지에 두 파일 경로 + TOC 링크 개수 표시
- [ ] §4 nexus 이전 가이드 4개 복사 대상 + vault 구조 동기화 명시
- [ ] 파일 분량 ≤ 400줄
- [ ] frontmatter YAML parse PASS

## 보고

`docs/phases/phase-1-5/reports/report-backend-dev-v2.md` §T-2 섹션:
- v1 → v2 변경 항목 목록 (체크리스트 형식)
- §3 Step 6 anchor 정규화 함수 (그대로)
- §3 Step 8a vs 8b 차이 표
- v2 줄 수 + frontmatter dump

## 위험

- **L-1**: TOC anchor 정규화 — 한글 헤더 처리 시 옵시디언 실제 동작과 차이 가능. 검증 시 한글 anchor 명시 테스트
- **L-2**: 원문이 매우 길어 R-3 위반 — SKILL.md 본체에는 영향 없음 (원문은 별도 파일). 단 SKILL.md 자체가 길어지면 §2 정의를 외부 참조로 우회
- **L-3**: 동일 slug 충돌 — 같은 날짜 같은 slug로 두 번째 호출 시 덮어쓰기 위험 → Step 8a/8b에 사용자 확인 절차 명시
