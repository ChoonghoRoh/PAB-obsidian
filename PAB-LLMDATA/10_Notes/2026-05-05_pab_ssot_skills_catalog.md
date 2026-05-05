---
title: "PAB SSOT — 11 skill 카탈로그 (skills/)"
description: "PAB plugin 활성 11 skill 일람 — 워크플로우 자동화(notify-telegram·phase-init·ssot-reload·plan·context-handoff·worktree) + 작업 보조(refactor-scan·worklog·report·menu) + 콘텐츠(wiki). HR/CHAIN/NOTIFY/WT 규칙 자동화 매핑"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[PAB_SSOT]]", "[[SKILLS]]", "[[CLAUDE_CODE]]"]
tags: [research-note, pab-ssot-nexus, skills, claude-code, harness, automation]
keywords: ["context-handoff", "menu", "notify-telegram", "phase-init", "plan", "refactor-scan", "report", "ssot-reload", "wiki", "worklog", "worktree", "PAB plugin", "/pab namespace", "user-invocable"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/skills/"
aliases: ["PAB skill 카탈로그", "/pab namespace", "SSOT 자동화 skill"]
---

# PAB SSOT — 11 skill 카탈로그

> PAB plugin의 활성 skill 11종. 모두 `/pab:{skill-name}` 형식으로 user-invocable. 일부는 다른 skill에서 Skill 도구로 호출 (예: `/pab:context-handoff resume` → `/pab:ssot-reload` 자동 트리거).

## 분류

| 분류 | skill 수 | 목적 |
|---|:--:|---|
| **워크플로우 자동화** | 6 | HR/CHAIN/NOTIFY/WT 규칙 강제 자동화 |
| **작업 보조** | 4 | 분석·기록·요약·발견성 |
| **콘텐츠** | 1 | wiki 노트 생성 (PAB-obsidian 정본) |

## 11 skill 일람

| # | skill | 라인 | agent | 분류 | 핵심 자동화 규칙 |
|:--:|---|---:|---|---|---|
| 1 | **`/pab:menu`** | 148 | main | 보조 | — (발견성) |
| 2 | **`/pab:context-handoff`** | 192 | main | 자동화 | HR-3, CHAIN-13 (세션 인계) |
| 3 | **`/pab:ssot-reload`** | 123 | Explore | 자동화 | FRESH-1 (SSOT 0→1→2→3 로드) |
| 4 | **`/pab:phase-init`** | 188 | general-purpose | 자동화 | CHAIN-6, CHAIN-10, HR-2 (Phase 산출물 4종 자동 생성) |
| 5 | **`/pab:plan`** | 185 | main | 자동화 | PROMPT-QUALITY (Step 0 Pre-draft) |
| 6 | **`/pab:notify-telegram`** | 131 | main | 자동화 | HR-8 NOTIFY-1 (DONE 알림 의무) |
| 7 | **`/pab:worktree`** | 328 | general-purpose | 자동화 | WT-1~5 (병렬 BUILDING 격리) |
| 8 | **`/pab:refactor-scan`** | 161 | Explore | 보조 | HR-5 / REFACTOR-1 (500/700/1000 줄 스캔) |
| 9 | **`/pab:worklog`** | 138 | main | 보조 | 작업 기록 (asanSmartcity hook 공존) |
| 10 | **`/pab:report`** | 106 | — | 보조 | 보고서 .md 저장 |
| 11 | **`/pab:wiki`** | 226 | — | 콘텐츠 | wiki 노트 생성 (PAB-obsidian) |

## 1. `/pab:menu`

**설명**: PAB plugin 활성 skill 11종의 카탈로그를 출력. `/pab:m` 두 글자 자동완성으로 호출 가능.

**용도**: 신규 사용자 발견성 확보 — 본 노트와 같은 일람을 CLI에서 바로 표시.

**호출**: `/pab:menu` 또는 `/pab:m`

## 2. `/pab:context-handoff <prepare|resume>`

**설명**: 컨텍스트 한계 도달 시 현재 세션을 새 세션으로 무손실 인계 (prepare/resume 모드).

**자동화 규칙**: HR-3 (컨텍스트 복구 시 SSOT 리로드 필수) + CHAIN-13 (직전 3 Phase 자동 로딩).

**호출 예**:
```
/pab:context-handoff prepare --phase=4-5 --summary="menu 스킬 신설 완료"
/pab:context-handoff resume                          # 가장 최근 핸드오프 자동 선택
/pab:context-handoff resume docs/handoff/2026-04-15-phase-3-1.md
```

**연계**: resume 모드는 `/pab:ssot-reload`를 자동 트리거 (FRESH-1 절차 재사용).

## 3. `/pab:ssot-reload`

**설명**: FRESH-1 절차 자동 실행. SSOT 0→1→2→3 순서 로드 + 버전 확인.

**자동화 규칙**: FRESH-1 (세션 시작 시 SSOT 리로드).

**호출**: `/pab:ssot-reload`

**연계**: `/pab:context-handoff resume`이 본 skill을 Skill 도구로 호출 (사용자 명시 호출 없이 자동 트리거).

## 4. `/pab:phase-init <phase_id>`

**설명**: Phase 디렉토리 + 산출물 4종 (status/plan/todo-list/tasks/) 자동 생성.

**자동화 규칙**:
- **CHAIN-6** (산출물 의무) — status/plan/todo-list/tasks 4종 필수
- **CHAIN-10** (파일 경로 규칙) — phase-{N}-{M}/ 하위 구조
- **HR-2** (Phase 산출물 생략 금지)
- **HR-4** (Phase 문서 경로 규칙)

**호출 예**:
```
/pab:phase-init 4-6
/pab:phase-init 4-6 --dry           # 계획만 출력 (검증)
/pab:phase-init 4-6 --force         # 동일 phase_id 존재 시 강행
/pab:phase-init 4-6 --no-tasks      # tasks/ 디렉토리 생략
```

## 5. `/pab:plan` — Step 0 Pre-draft (사용자 주도 한정)

**설명**: 사용자 주도 마스터 플랜 진입 전 프롬프트 품질 토픽 논의 + 자료 수집. Plan Mode 유사. **Team Lead 단독 운영**, 코드 조사·리뷰 필요 시에만 BE/FE/tester 온디맨드 호출. AI handoff 시 자동 제외.

**자동화 규칙**: **PROMPT-QUALITY** (HIGH) — `6-rules-index §1.20` 5항목 판정 (완전성·명료성·실행 가능성·범위 적정성·트리아지).

**호출**: `/pab:plan`

**산출**: `docs/phases/pre/phase-{N}-pre-draft.md` (HR-4 / CHAIN-10 — `pre/` 평탄 폴더, 8 섹션 양식 [[2026-05-05_pab_ssot_templates|템플릿 노트 §12]]).

## 6. `/pab:notify-telegram`

**설명**: Phase 완료/이슈 알림을 Telegram으로 전송. **HR-8 NOTIFY-1 의무 자동화**.

**자동화 규칙**:
- **NOTIFY-1** (DONE 시 발송 필수, 생략 시 DONE 전이 무효)
- **NOTIFY-2** (메시지 형식 강제)
- **NOTIFY-3** (Master Plan 종합 알림)

**호출 예**:
```
/pab:notify-telegram --phase=4-5 --status=done --summary="pab-menu-helper 완료"
/pab:notify-telegram --phase=4 --status=master-done --type=master-summary
/pab:notify-telegram --phase=3-2 --status=blocked --summary="Ollama 연결 실패"
```

**옵션**: `--type=phase` (기본) / `--type=master-summary` / `--type=alert`. `--report-path=PATH` 보고서 경로.

**구현**: `scripts/pmAuto/report_to_telegram.sh` 호출, `.env`의 토큰/채널 사용.

## 7. `/pab:worktree`

**설명**: Git worktree 신설/정리/감사 (병렬 BUILDING 격리). **PAB 종속성 0** — 어떤 git 레포에서도 동작.

**자동화 규칙**: **WT-1~5** (병렬 BUILDING 트랙 ≥ 2 시 worktree 격리 필수).

**서브커맨드 4종**:

| subcommand | 용도 |
|---|---|
| `setup <branch>` | worktree를 저장소 옆 형제 디렉토리에 생성 |
| `cleanup <branch>` | 안전 검사 후 worktree 제거 + `git worktree prune` |
| `audit` | 모든 worktree 상태 진단 + 정리 후보 권고 |
| `compare <opt-A> <opt-B> ...` | 옵션별 worktree 생성 후 비교 워크플로우 |

**호출 예**:
```
/pab:worktree setup feature-x
/pab:worktree setup feature-x --gh-pr             # GitHub PR draft 자동 생성 (gh CLI 필요)
/pab:worktree setup feature-x --remote=https://github.com/user/repo
/pab:worktree cleanup feature-x
/pab:worktree audit
/pab:worktree compare A B C --criteria=lines,test-pass,readability
/pab:worktree compare A B --dry                   # 명령만 출력
```

**경로 규약 (WT-2)**: `../{레포명}-wt-phase-{X}-{Y}-{track}` (저장소 외부, gitignore 누락 위험 방지).

## 8. `/pab:refactor-scan`

**설명**: 500/700/1000줄 초과 파일 탐지. HR-5 Level 분류.

**자동화 규칙**:
- **HR-5** (리팩토링 규정)
- **REFACTOR-1** (Phase 완료 시 등록만)
- **REFACTOR-2** (Master Plan 시 편성)

**호출 예**:
```
/pab:refactor-scan                          # 전체 스캔, 500줄 기준
/pab:refactor-scan backend/                 # 특정 디렉토리만
/pab:refactor-scan --threshold=300          # 더 엄격하게 (300줄)
/pab:refactor-scan --json                   # JSON 출력 (기본은 마크다운)
```

**Level 분류**:
- **Lv1** (700+ 독립 분리 가능) → 다음 Master Plan 선행 sub-phase
- **Lv2** (700+ 양방향 밀접) → `phase-X-refactoring` 별도 Phase

## 9. `/pab:worklog [init|log|check]`

**설명**: 명령형 호출로 worklog에 작업 기록 추가. asanSmartcity hook 자동 init과 공존.

**용도**: LLM이 명시적으로 작업을 기록할 때. SessionStart hook이 적용되지 않는 환경(SSOT-Nexus 등)에서는 본 skill이 init도 담당.

**호출 예**:
```
/pab:worklog init                                 # 오늘자 worklog 파일 초기화 (idempotent)
/pab:worklog log --prompt="Phase 3-1 구현" --result="task-3-1-1 완료"
/pab:worklog check                                # 오늘자 worklog 상태 출력
/pab:worklog                                      # check로 동작 (위치 인수 생략)
```

## 10. `/pab:report`

**설명**: 직전 대화에서 생성된 분석/보고서 출력을 `.md` 파일로 저장.

**호출 예**:
```
/pab:report --path=docs/analysis/comparison.md
/pab:report --path=docs/r.md --section="비교 분석"           # 특정 섹션만 추출
/pab:report --path=docs/r.md --append                       # 기존 파일에 이어쓰기
/pab:report --path=docs/r.md --no-meta                      # 메타 헤더 생략
/pab:report --path=docs/r.md --format=md                    # 기본
```

> `--format` 다른 값(pptx/docx/html)은 미구현 — 향후 추가 예정.

## 11. `/pab:wiki <내용 또는 URL...>`

**설명**: 자연어 입력으로부터 옵시디언 규격 wiki 노트 자동 생성 — **원본 immutable 보존(SOURCE) + LLM 요약본 두 파일 동시 생성** (Karpathy 3계층).

> 본 skill은 **PAB-obsidian 프로젝트 정본**(현재 본 wiki vault). SSOT-Nexus의 `skills/wiki/`도 동일 skill의 다른 인스턴스 또는 origin.

**호출 예**:
```
/pab:wiki https://gist.github.com/karpathy/... 내용 정리해줘
/pab:wiki 위에서 논의한 RAG 패턴 정리
/pab:wiki                       # 직전 대화 컨텍스트 활용
/pab:wiki <input> --type=LESSON --dry         # 미저장 미리보기
```

상세는 [[2026-05-05_pab_ssot_skills_detail|skill 상세 노트]] 또는 본 vault의 `skills/wiki/SKILL.md` (226줄).

## 공통 — `--help` 처리

모든 skill은 `--help` 토큰 발견 시 본 작업 미실행 + 표준 헬프 (description / argument-hint / 옵션 표 / 예시) 출력 후 즉시 종료.

```
/pab:notify-telegram --help
/pab:worktree --help
/pab:phase-init --help
```

## 다음 노트

- [[2026-05-05_pab_ssot_skills_detail|skill 상세]] — 각 skill 입출력·내부 절차·실행 예시
- [[2026-05-05_pab_ssot_workflow|워크플로우]] — 자동화 대상 규칙 (HR/CHAIN/NOTIFY/WT)
- [[2026-05-05_pab_ssot_rules_chain|규칙·CHAIN]] — 96개 규칙 인덱스
- [[2026-05-05_pab_ssot_portability|이식 가이드]] — skill 이식 + plugin.json 등록
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/skills/` (11 skill 디렉토리)
- 각 skill의 `SKILL.md` 파일 — 본 노트의 1차 출처
- `.claude-plugin/plugin.json` — PAB plugin 등록 매니페스트
