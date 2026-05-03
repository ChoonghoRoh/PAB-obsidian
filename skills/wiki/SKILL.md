---
name: wiki
description: 자연어 입력으로부터 옵시디언 규격 wiki 노트를 자동 생성한다 — 원본 immutable 보존(SOURCE) + LLM 요약본 두 파일 동시 생성.
argument-hint: "<내용 또는 URL...> [--type=TYPE] [--dry] [--help]"
user-invocable: true
allowed-tools: "Read, Write, Bash, WebFetch"
---

# /pab:wiki — 원본 + 요약 두 파일 동시 생성 (Karpathy 3계층)

## §0 --help 처리

`$ARGUMENTS`에 `--help` 포함 시 본 작업 미실행, 표준 헬프 출력 후 종료:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 /pab:wiki  — Karpathy 3계층 wiki 노트 생성
   1회 호출 → 원본(SOURCE) + 요약본 두 파일 동시 생성

📥 사용법
   /pab:wiki <내용 또는 URL...> [--type=TYPE] [--dry]

📋 옵션
   --type=TYPE   요약본 TYPE 강제 지정 (RESEARCH_NOTE/CONCEPT/LESSON/PROJECT/DAILY/REFERENCE)
   --dry         미저장, frontmatter+본문 미리보기만
   --help        본 도움말 출력 후 종료

📚 예시
   /pab:wiki https://gist.github.com/karpathy/... 내용 정리해줘
   /pab:wiki 위에서 논의한 RAG 패턴 정리
   /pab:wiki                   # 직전 대화 컨텍스트 활용
   /pab:wiki <input> --type=LESSON --dry

📖 상세: skills/wiki/SKILL.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## §1 입력 파싱

`$ARGUMENTS`를 다음 규칙으로 분류:
1. `--help` 토큰 → §0 처리
2. `--key=value` / `--flag` → 옵션 (override)
3. 그 외 모든 토큰 → 자연어 입력 (URL 포함 가능)
4. 자연어 입력이 비어있으면 → 직전 대화 컨텍스트 활용

## §2 옵시디언 규격

### 2.1 TYPE 판별 휴리스틱 (7 TYPE)

| TYPE | 채택 신호 |
|---|---|
| **SOURCE** | 외부 자료의 *원문 텍스트 자체* — 변경 금지, 요약본의 immutable 짝 (자동 결정) |
| RESEARCH_NOTE | 외부 자료(글/논문/gist/URL) 본문 정리, 출처 인용, 논점 보존 |
| CONCEPT | 추상 개념 정의·비교, 패턴 분류, "X란 무엇인가" |
| LESSON | 실수·교훈·회고, "이렇게 했더니 X 이슈", 운영 경험 |
| PROJECT | 진행 중 프로젝트 기록, 마일스톤, 의사결정 |
| DAILY | 일일 작업 로그, 회의록 |
| REFERENCE | 규약·체크리스트·치트시트, 변경 빈도 낮은 참고서 |

**판별 규칙**:
- SOURCE는 LLM이 자동 결정 (사용자 선택 불가). URL 입력 시 원본 페치 → SOURCE 파일 생성은 항상 수반.
- 요약본 TYPE은 `--type=` override 또는 §2.1 휴리스틱 적용.
- 외부 URL/글 정리 → RESEARCH_NOTE 우선.
- 예시: `/pab:wiki https://gist.github.com/karpathy/... 정리해줘` → 요약=RESEARCH_NOTE, 원본=SOURCE.

### 2.2 6 DOMAIN 매핑

| DOMAIN | 대상 |
|---|---|
| AI | LLM/ML, 에이전트, RAG, fine-tuning |
| HARNESS | Claude Code, IDE, CLI 도구 |
| ENGINEERING | 알고리즘, 아키텍처, 디버깅, 성능 |
| PRODUCT | 로드맵, PRD, UX, 스프린트 |
| KNOWLEDGE_MGMT | 노트 시스템, 학습 방법론, Zettelkasten/PARA |
| MISC | 분류 불명 (가능한 회피) |

**우선순위**: 본질 > 도구. 원본·요약본 모두 동일 DOMAIN 사용.

### 2.3 frontmatter 11필드

상세: `wiki/30_Constraints/frontmatter-spec.md`

| # | 필드 | 등급 | 자동 결정 방식 |
|---|---|---|---|
| 1 | `title` | **Critical** | 본문 핵심 + 저자/소스명 (한글 가능) |
| 2 | `description` | High | 1~2줄 요약 |
| 3 | `created` | **Critical** | `YYYY-MM-DD HH:MM` 현재 시각 (ISO T/Z 형식 금지) |
| 4 | `updated` | High | 첫 작성 시 `created`와 동일 |
| 5 | `type` | **Critical** | `"[[<TYPE>]]"` 형식 (평문 금지) |
| 6 | `index` | High | `"[[<DOMAIN>]]"` (원본·요약본 동일) |
| 7 | `topics` | High | `["[[<TOPIC1>]]", ...]` — 없으면 `[]` |
| 8 | `tags` | High | 첫 항목=TYPE 슬러그 (소문자·하이픈만) |
| 9 | `keywords` | Low | 자유 키워드 5~10개 |
| 10 | `sources` | Low | 요약본: `["[[15_Sources/<slug>_source]]", "<URL>"]` / 원본: `["<URL>"]` |
| 11 | `aliases` | High | 한글·약어·동의어 1~3개 |

**TYPE별 tags 첫 항목**:
| TYPE | tags[0] | 저장 폴더 |
|---|---|---|
| RESEARCH_NOTE | `research-note` | `wiki/10_Notes/` |
| CONCEPT | `concept` | `wiki/10_Notes/` |
| LESSON | `lesson` | `wiki/10_Notes/` |
| PROJECT | `project` | `wiki/10_Notes/` |
| DAILY | `daily` | `wiki/10_Notes/` |
| REFERENCE | `reference` | `wiki/10_Notes/` |
| SOURCE | `source` | `wiki/15_Sources/` |

### 2.4 파일명 규칙

상세: `wiki/30_Constraints/naming-convention.md`

| 파일 | 패턴 | 예시 |
|---|---|---|
| 요약본 | `wiki/10_Notes/YYYY-MM-DD_<slug>.md` | `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` |
| 원본 | `wiki/15_Sources/YYYY-MM-DD_<slug>_source.md` | `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` |

- slug: `^[a-z0-9_]{1,50}$` (소문자·숫자·언더스코어, 하이픈 금지)
- 정규식: `^\d{4}-\d{2}-\d{2}_[a-z0-9_]{1,50}\.md$`

## §3 처리 절차 (12 step)

### Step 1 — 입력 파싱 + WebFetch
- URL 패턴 추출 (`https?://...`)
- URL 있으면 `WebFetch`로 원문 텍스트 *전체* 페치 (요약 아님, 그대로 보존)
- URL 없으면 자연어 또는 직전 대화 활용

### Step 2 — TYPE 자동 판별 (요약본)
- §2.1 휴리스틱 적용
- `--type=` override 있으면 그 값 사용
- SOURCE는 자동 — 요약본 TYPE 결정 후 원본은 항상 SOURCE

### Step 3 — DOMAIN 자동 매핑
- §2.2 매핑표. 원본·요약본 동일 DOMAIN.

### Step 4 — TOPIC 후보 추출
- 본문에서 핵심 명사/개념 → UPPER_SNAKE_CASE
- `wiki/00_MOC/TOPICS/*.md` 기존 매칭 (Read)
- 매칭 없으면 신규 TOPIC 1개 마중물 (N=3 도달 시 `wiki moc-build` 자동 승격)
- 모호하면 `topics: []`

### Step 5 — 메타데이터 생성
- slug 1개 공유 (`<slug>`): 요약=`<slug>`, 원본=`<slug>_source`
- title/aliases/tags/keywords/sources/description 자동 결정
- slug 정규식 검증: `^[a-z0-9_]{1,50}$`

### Step 6 — 본문 생성 (요약본 — TOC 링크 포함)
- H1 = title, H2 = 핵심 섹션 5~10개
- **각 H2 섹션 헤더 직후** 원본 anchor 링크 자동 삽입:
  ```markdown
  ## <섹션 제목>
  [원본 §<원본 대응 섹션> →](YYYY-MM-DD_<slug>_source.md#<anchor>)

  (LLM 요약 본문 ...)
  ```
- 대응 섹션 매핑: LLM이 요약 섹션 ↔ 원본 섹션 자동 매칭 (1:1 또는 1:N)
- 원본 anchor 정규화:
  ```
  anchor = header.strip().lower()
  anchor = re.sub(r'\s+', '-', anchor)          # 공백 → 하이픈
  anchor = re.sub(r'[^a-z0-9가-힣\-]', '', anchor)  # 영숫자·한글·하이픈만
  ```
- 핵심 개념·도구·인물명 `[[Term]]` wikilink 자동 삽입

### Step 7 — frontmatter 11필드 (양 파일 각각)
- **요약본** `sources`: `["[[15_Sources/YYYY-MM-DD_<slug>_source]]", "<외부 URL>"]`
- **원본** `sources`: `["<외부 URL>"]` (외부 URL만, 요약본 링크는 backlink로 형성)
- 양 파일 `index`, `topics`, `created`, `updated` 동일

### Step 8 vault root 결정 (Step 8a/8b 공통)
양 파일은 **반드시 같은 vault 안**에 저장 (TOC wikilink가 vault 내부 해소되어야 함). vault root는 다음 우선순위:
1. 환경변수 `$WIKI_VAULT_ROOT` 설정되어 있으면 그 값 (공통 vault 모드 — Karpathy 본래 의도)
2. 미설정 시 호출 프로젝트의 `./wiki/` (자기완결 모드 — PAB-obsidian dogfooding 등 예외 케이스)

### Step 8a — 원본 저장 (SOURCE, immutable)
- 경로: `${VAULT_ROOT}/15_Sources/YYYY-MM-DD_<slug>_source.md`
- 내용: WebFetch로 받은 원문 텍스트 그대로 (개인 vault 보관)
- frontmatter 첫 줄 직후에 `> ⚠️ 변경 금지 — 원본 immutable 보존` 표시
- 동일 파일 존재 시 사용자에게 확인 (덮어쓰기 금지 — immutable 원칙)
- `--dry` 시 stdout만 출력

### Step 8b — 요약본 저장
- 경로: `${VAULT_ROOT}/10_Notes/YYYY-MM-DD_<slug>.md`
- 내용: Step 6 본문 + Step 7 frontmatter
- 동일 파일 존재 시 사용자에게 확인
- `--dry` 시 stdout만 출력

### Step 9 — 검증 (양 파일 모두)
```bash
# vault root 자동 감지 — $WIKI_VAULT_ROOT 우선, 미설정 시 ./wiki
python3 scripts/wiki/wiki.py link-check  # vault-wide
```
- `violations=0` → Critical/High PASS ✅
- `broken=N` → 미래 노트 unresolved (WARN, 사용자에게 분리 보고, 정상)
- `schema_violations`만 critical로 취급
- TOC 링크 검증: 요약본의 `[원본 §... →]` anchor가 원본 실제 헤더와 일치 확인

### Step 10 — 사용자 응답 메시지
```
✅ 노트 생성 완료 (두 파일 동시 생성)

📄 요약본: wiki/10_Notes/YYYY-MM-DD_<slug>.md (NK)
📄 원본:   wiki/15_Sources/YYYY-MM-DD_<slug>_source.md (NK, immutable)
🏷️  TYPE: <TYPE>  |  DOMAIN: <DOMAIN>  |  TOPIC: <TOPIC1>, ...
🔗 wikilink N개 + TOC 링크 M개 자동 삽입
⚠️  원본은 변경 금지 — Karpathy immutable sources 계층

⚠️  (TOPIC 신규 마중물 시) TOPIC `<TOPIC>`은 처음 등장 — 노트 3개 도달 시
    `make wiki-moc-build`로 MOC 자동 승격됩니다.
```

## §4 이전 가이드 (요약 — 상세는 PORTABILITY.md)

**복사 대상 (4개)**:
1. `.claude-plugin/plugin.json`
2. `skills/wiki/SKILL.md` (본 파일) + `skills/wiki/PORTABILITY.md`
3. `wiki/30_Constraints/{frontmatter-spec,naming-convention}.md`
4. `wiki/40_Templates/SOURCE.md` + `wiki/40_Templates/_schema.json`

**이전 시 vault 구조 동기화**:
- 폴더 신설: `${VAULT_ROOT}/15_Sources/`, `${VAULT_ROOT}/10_Notes/`
- TYPE MOC: `${VAULT_ROOT}/00_MOC/TYPES/SOURCE.md`

**vault 운영 모드 선택 (권장: 공통 vault)**:
- **공통 vault** (Karpathy 본래 의도, 권장): `export WIKI_VAULT_ROOT="$HOME/Obsidian/<vault>"` → 모든 프로젝트의 노트가 한 vault에 누적
- **자기완결 모드**: 환경변수 미설정 → 호출 프로젝트의 `./wiki/` 사용 (프로젝트 dogfooding 등 예외 케이스)
- `scripts/wiki/wiki.py` → 대상 프로젝트 경로 (없으면 LLM 직접 검증)
