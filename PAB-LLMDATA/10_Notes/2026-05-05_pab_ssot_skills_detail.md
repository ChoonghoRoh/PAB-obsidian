---
title: "PAB SSOT — 11 skill 상세 (입출력·내부 절차·예시)"
description: "각 PAB skill의 입력 옵션·실행 절차·산출물·연계 skill·SSOT 규칙 매핑 상세. 카탈로그는 별도 노트 참조"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[PAB_SSOT]]", "[[SKILLS]]", "[[CLAUDE_CODE]]"]
tags: [research-note, pab-ssot-nexus, skills, claude-code, harness, detail]
keywords: ["argument-hint", "user-invocable", "agent: main/general-purpose/Explore", "context: inherit/fork", "allowed-tools", "공통 --help", "상호배타 검증", "PAB 공통 절차"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/skills/{11 skills}/SKILL.md"
aliases: ["skill 입출력", "skill 내부 절차"]
---

# PAB SSOT — 11 skill 상세

## 공통 frontmatter 필드

모든 PAB skill은 공통 frontmatter 형식을 따름:

```yaml
---
name: <skill-name>             # /pab:{name}으로 호출
description: <한 줄 설명>
argument-hint: "<인수 형식>"   # 자동완성 힌트
user-invocable: true           # 사용자 직접 호출 가능
context: inherit | fork        # 부모 컨텍스트 상속 vs 분리
agent: main | general-purpose | Explore  # 실행 agent 타입
allowed-tools: "Read, Write, Bash, ..."  # 허용 도구 화이트리스트
---
```

| 필드 | 설명 |
|---|---|
| `name` | 호출 이름. `/pab:{name}` |
| `argument-hint` | 자동완성 시 사용자에게 표시될 인수 형식 |
| `user-invocable: true` | 사용자가 슬래시 명령으로 직접 호출 가능 (false면 다른 skill 내부 호출 전용) |
| `context: inherit` | 부모 세션 context 상속 (Team Lead 컨텍스트 그대로) |
| `context: fork` | 새 컨텍스트 분리 (별도 세션) |
| `agent: main` | Team Lead(메인 세션)에서 직접 실행 |
| `agent: general-purpose` | sonnet 계열 sub-agent로 위임 |
| `agent: Explore` | opus 계열 read-only sub-agent로 위임 |
| `allowed-tools` | 화이트리스트 (도구 권한 제한) |

## 공통 절차 (모든 skill)

### Step 0 — `--help` 처리 (PAB 공통)
`$ARGUMENTS`에 `--help` 포함 시 본 작업 미실행, 표준 헬프 (description + argument-hint + 옵션 표 + 예시) 출력 후 즉시 종료.

### Step 1 — 입력 파싱
1. `$ARGUMENTS`를 공백 단위 토큰화 (`"..."` / `'...'` 안의 공백 보존)
2. `--`로 시작하는 토큰을 옵션으로 분리
3. 나머지를 위치 인수로 수집
4. 알 수 없는 옵션은 경고 출력 (실행 계속)
5. **상호배타 옵션이 동시 지정되면 즉시 오류 종료**
6. **`--help` 우선 처리**: `options.help === true`이면 §0 출력 후 종료

### Step 2~ — skill별 고유 절차

## 1. `/pab:menu`

**입력**: 없음 (`--help`만)
**agent**: main / **context**: inherit
**allowed-tools**: 없음 (정적 출력)

**절차**: 11 skill 카탈로그 마크다운 출력. 신규 사용자 발견성용.

## 2. `/pab:context-handoff <prepare|resume>`

**입력**:

| 위치 | 값 | 필수 | 설명 |
|---|---|:--:|---|
| 1 | `prepare` ‖ `resume` | ✅ | 모드 |
| 2 | handoff-path | — | resume 전용. 미지정 시 가장 최근 자동 선택 |

| 옵션 | 기본 | 설명 |
|---|---|---|
| `--phase=ID` | (자동) | prepare 시 명시 (미지정 시 git/디렉토리에서 추론) |
| `--summary=TEXT` | (자동) | 핸드오프 1줄 요약 |
| `--no-clear-hint` | false | prepare 후 `/clear` 안내 메시지 생략 |

**상호배타**:
- prepare 모드에서 handoff-path 위치 인수 지정 → 무시 (경고)
- resume 모드에서 `--phase` → 무시 (.md에서 추출)

**agent**: main / **context**: inherit
**allowed-tools**: Read, Glob, Bash, Write, Skill

**산출**:
- prepare: `docs/handoff/YYYY-MM-DD-phase-{N}-{M}.md` (현재 작업 상태 직렬화)
- resume: 핸드오프 .md를 읽고 SSOT 리로드 + status 확인 + 팀 재구성

**자동화 규칙**: HR-3 (컨텍스트 복구 시 SSOT 리로드 필수) + CHAIN-13 (직전 3 Phase 자동 로딩).

**연계**: resume 모드는 `/pab:ssot-reload`를 Skill 도구로 호출.

## 3. `/pab:ssot-reload`

**입력**: 없음 (`--help`만)
**agent**: Explore (opus 계열) / **context**: fork
**allowed-tools**: Read, Glob

**절차**: FRESH-1 절차 자동 실행
1. SSOT 0→1→2→3 순서 로드 (`docs/SSOT/docs/0-entrypoint.md` → `1-project.md` → `2-architecture.md` → `3-workflow.md`)
2. `ssot_version` 확인
3. 현재 Phase status.md 읽기 (`docs/phases/phase-X-Y/phase-X-Y-status.md`)
4. 프로젝트 상태 요약 출력

**연계**: `pab:context-handoff resume` 모드가 본 skill을 자동 호출.

## 4. `/pab:phase-init <phase_id>`

**입력**:
| 위치 | 값 | 필수 | 설명 |
|---|---|:--:|---|
| 1 | `phase_id` | ✅ | 형식 `{N}-{M}` 예: `4-6` |

| 옵션 | 기본 | 설명 |
|---|---|---|
| `--dry` | false | 파일 생성 없이 계획만 출력 (검증) |
| `--force` | false | 동일 phase_id 디렉토리 존재 시 강행 (덮어쓰기 주의) |
| `--no-tasks` | false | `tasks/` 디렉토리 생성 생략 |

**상호배타**: `--dry` ↔ `--force` 동시 지정 시 즉시 오류.

**agent**: general-purpose / **context**: fork
**allowed-tools**: Read, Glob, Bash, Write, Edit

**산출 (CHAIN-6 4종)**:
```
docs/phases/phase-{N}-{M}/
├── phase-{N}-{M}-status.md     # YAML 상태 (current_state: IDLE)
├── phase-{N}-{M}-plan.md       # 계획서 (placeholder)
├── phase-{N}-{M}-todo-list.md  # 체크리스트 (placeholder)
└── tasks/                      # Task 명세 디렉토리 (--no-tasks 시 생략)
```

**자동화 규칙**: CHAIN-6 / CHAIN-10 / HR-2 / HR-4.

## 5. `/pab:plan` — Step 0 Pre-draft

**입력**: 없음 (`--help`만)
**agent**: main / **context**: inherit
**allowed-tools**: Read, Glob, Grep, Bash, Write, Edit, EnterPlanMode, ExitPlanMode, Agent

**진입 조건**:
- 사용자 주도 마스터 플랜 진입 직전 (`initiator: user`)
- AI handoff(`initiator: ai-handoff`) 시 자동 제외

**절차** (Plan Mode 유사):
1. EnterPlanMode 진입
2. 사용자 원본 프롬프트 정리
3. 토픽 분류 (사용자/개발자 관점 양쪽)
4. 수집 자료 (필요 시 BE/FE/tester 온디맨드 호출 — Agent 도구)
5. Pre-test (실행 가능성 사전 검증)
6. **PROMPT-QUALITY 5항목 판정**:
   - 완전성 — 사용자 + 개발자 관점 양쪽 도출 가능
   - 명료성 — 모호 용어 0건 (또는 "TBD" 명시)
   - 실행 가능성 — 기술적 Show-stopper 없음
   - 범위 적정성 — 단일 Phase 적정 / 분할 필요
   - 트리아지 — 즉시 진행 / 재질문 / 분할 / 취소
7. 마스터 플랜 진입 준비
8. ExitPlanMode → `docs/phases/pre/phase-{N}-pre-draft.md` 작성 + 사용자 승인 대기

**Fast-path**: 5항목 자명 PASS 시 템플릿 작성 생략 (master-plan에 `prompt_quality: fast-path` 표기).

**자동화 규칙**: PROMPT-QUALITY (HIGH) — `6-rules-index §1.20`.

**Team Lead 단독 운영**: 코드 조사·리뷰 필요 시에만 BE/FE/tester 온디맨드 호출.

## 6. `/pab:notify-telegram`

**입력**:

| 옵션 | 필수 | 설명 |
|---|:--:|---|
| `--phase=ID` | ✅ | Phase ID (예: `3-1`, `24-2-1`) |
| `--status=STATUS` | ✅ | `done` / `blocked` / `master-done` 등 |
| `--summary=TEXT` | — | 한 줄 요약 (미지정 시 자동 생성 시도) |
| `--report-path=PATH` | — | 보고서 경로 (메시지에 포함) |
| `--type=TYPE` | — | `phase` (기본) / `master-summary` / `alert` |

**상호배타**: `--type=master-summary` + `--phase` 가 sub-phase 형식이면 경고.

**agent**: main / **context**: inherit
**allowed-tools**: Bash, Read

**절차**:
1. 옵션 파싱 + 검증
2. status에 따라 메시지 형식 결정 (NOTIFY-2 강제)
3. `scripts/pmAuto/report_to_telegram.sh "{프로젝트명}" "{메시지}"` 호출
4. `.env`의 BOT_TOKEN과 CHAT_ID로 전송
5. 결과 확인 + 사용자 보고

**메시지 형식 (NOTIFY-2)**:
```
[PAB-SSOT-Nexus] ✅ Phase X-Y 완료: {요약}
📊 결과: {핵심 수치}
📁 보고서: {경로}
```

**자동화 규칙**: HR-8 NOTIFY-1~3.

## 7. `/pab:worktree <subcommand>`

**입력**:

| 위치 | 값 | 설명 |
|---|---|---|
| 1 | subcommand | `setup` / `cleanup` / `audit` / `compare` |
| 2~ | branch 또는 옵션 | subcommand별 |

| 옵션 | 적용 | 설명 |
|---|---|---|
| `--gh-pr` | setup | GitHub PR draft 자동 생성 (gh CLI 필요) |
| `--remote=URL` | setup | 다른 GitHub 레포 clone 후 worktree |
| `--criteria=KEYS` | compare | 비교 기준 (기본: lines,test-pass) |
| `--branch-prefix=PREFIX` | compare | branch 명명 prefix (기본: `compare-`) |
| `--dry` | 모든 subcommand | 명령만 출력 |

**agent**: general-purpose / **context**: fork
**allowed-tools**: Bash, Read, Glob

### setup
```bash
git worktree add ../{레포명}-wt-phase-{X}-{Y}-{branch} {branch}
cd ../{레포명}-wt-phase-{X}-{Y}-{branch}
# 의존성 설치 (npm ci / pip install -r requirements.txt)
```

WT-2 경로 규약: `../{레포명}-wt-phase-{X}-{Y}-{track}` 패턴만 허용.

### cleanup
```bash
# 안전 검사: uncommitted changes 확인 → 있으면 중단
git worktree remove ../{레포명}-wt-phase-{X}-{Y}-{branch}
git worktree prune
```

### audit
모든 worktree 상태 진단 + 정리 후보(stale, orphan) 권고.

### compare
A/B 분기 워크플로우 자동화. 옵션별 worktree 생성 → 평가 → ab-comparison-template.md 작성.

**자동화 규칙**: WT-1~5 (병렬 BUILDING 격리).

## 8. `/pab:refactor-scan [path]`

**입력**:

| 위치 | 값 | 기본 | 설명 |
|---|---|---|---|
| 1 | path | (전체) | 스캔 대상 디렉토리 |

| 옵션 | 기본 | 설명 |
|---|---|---|
| `--threshold=N` | 500 | WATCH 임계값 변경 (예: `--threshold=300`) |
| `--json` | false | JSON 출력 (기본은 마크다운) |

**agent**: Explore / **context**: fork
**allowed-tools**: Read, Glob, Grep, Bash

**절차**:
1. 대상 경로 코드 파일 스캔 (.py, .js, .ts, .tsx, .jsx 등)
2. 줄수 측정 (`wc -l`)
3. 분류:
   - **WATCH** (500+): 레지스트리 등록만 (REFACTOR-1)
   - **WARN** (700+): Lv1/Lv2 분류 (REFACTOR-2)
   - **CRITICAL** (1000+): 즉시 리팩토링 권고
4. 출력 (마크다운 표 또는 JSON)
5. (선택) `docs/refactoring/refactoring-registry.md` 갱신 권고

**자동화 규칙**: HR-5 / REFACTOR-1~3.

## 9. `/pab:worklog [init|log|check]`

**입력**:

| 위치 | 값 | 설명 |
|---|---|---|
| 1 | `init` | 오늘자 worklog 파일 초기화 (idempotent) |
| 1 | `log` | 작업 한 건 추가 (`--prompt` + `--result` 필수) |
| 1 | `check` | 오늘자 worklog 상태 출력 |
| (생략) | — | `check`로 동작 |

| 옵션 | 적용 | 설명 |
|---|---|---|
| `--prompt=TEXT` | log | 사용자 프롬프트 요약 (필수) |
| `--result=TEXT` | log | 작업 결과 요약 (필수) |

**상호배타**: `init`/`check` 모드에서 `--prompt`/`--result` 지정 → 무시 (경고).

**agent**: main / **context**: inherit
**allowed-tools**: Read, Write, Edit, Bash, Glob

**산출**: `docs/worklog/YYYY-MM-DD.md` 또는 프로젝트별 정의 경로.

**asanSmartcity hook 공존**: SessionStart hook이 자동 init하는 worklog와 idempotent 동작으로 충돌 없음.

## 10. `/pab:report`

**입력**:

| 옵션 | 기본 | 설명 |
|---|---|---|
| `--path=PATH` | (자동) | 저장 경로/파일명 |
| `--format=FMT` | `md` | 출력 포맷 (`md` 외 미구현) |
| `--append` | false | 기존 파일에 이어 붙이기 |
| `--section=NAME` | — | 특정 섹션만 추출/저장 |
| `--no-meta` | false | 보고서 상단 메타 헤더 생략 |

**상호배타**:
- `--append` + `--no-meta` → 함께 사용 가능
- `--format` ≠ `md` → "미구현" 메시지 후 종료

**allowed-tools**: Read, Write, Edit, Bash

**절차**:
1. 직전 대화에서 보고서 성격 출력 추출
2. 메타 헤더 자동 추가 (`--no-meta` 시 생략) — 작성일·제목
3. `--section` 지정 시 해당 섹션만 추출
4. `--append` 시 기존 파일 끝에 추가, 아니면 새 파일 생성
5. 저장 경로 표시

## 11. `/pab:wiki <내용 또는 URL...>`

**입력**:

| 옵션 | 설명 |
|---|---|
| (자연어) | 본문 또는 URL (위치 인수) |
| `--type=TYPE` | 요약본 TYPE 강제 (RESEARCH_NOTE/CONCEPT/LESSON/PROJECT/DAILY/REFERENCE) |
| `--dry` | 미저장, frontmatter+본문 미리보기만 |

**allowed-tools**: Read, Write, Bash, WebFetch

**절차** (12 step):
1. 입력 파싱 + URL 패턴 추출 → WebFetch로 원문 페치
2. TYPE 자동 판별 (요약본) — 7 TYPE 휴리스틱
3. DOMAIN 자동 매핑 — 6 DOMAIN
4. TOPIC 후보 추출 — UPPER_SNAKE_CASE, 기존 매칭
5. 메타데이터 생성 — slug 1개 공유 (`<slug>` / `<slug>_source`)
6. 본문 생성 (요약본) — H1=title, H2 5~10개, **각 H2에 원본 anchor 링크 자동 삽입**
7. frontmatter 11필드 (양 파일 각각)
8. **vault root 결정**: `$WIKI_VAULT_ROOT` 우선, 미설정 시 `./wiki/`
8a. 원본 저장 (SOURCE, immutable) — `${VAULT_ROOT}/15_Sources/YYYY-MM-DD_<slug>_source.md`
8b. 요약본 저장 — `${VAULT_ROOT}/10_Notes/YYYY-MM-DD_<slug>.md`
9. 검증 — `python3 scripts/wiki/wiki.py link-check` (vault-wide, schema_violations만 critical)
10. 사용자 응답 메시지

**Karpathy 3계층**: SOURCE(원본) + 요약본 + (미래) MOC. 원본 immutable 보존.

**파일명 규칙**:
- 요약본: `wiki/10_Notes/YYYY-MM-DD_<slug>.md`
- 원본: `wiki/15_Sources/YYYY-MM-DD_<slug>_source.md`
- slug 정규식: `^[a-z0-9_]{1,50}$` (하이픈 금지)

상세는 본 vault `skills/wiki/SKILL.md` (226줄).

## 다음 노트

- [[2026-05-05_pab_ssot_skills_catalog|skill 카탈로그]] — 11 skill 일람
- [[2026-05-05_pab_ssot_workflow|워크플로우]] — 자동화 대상 규칙
- [[2026-05-05_pab_ssot_portability|이식 가이드]] — skill plugin.json 등록·이식 절차
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/skills/{11 skill}/SKILL.md`
- `/PAB-SSOT-Nexus/.claude-plugin/plugin.json` (있다면) — PAB plugin 등록
- `/PAB-SSOT-Nexus/scripts/pmAuto/report_to_telegram.sh` — notify-telegram 구현체
