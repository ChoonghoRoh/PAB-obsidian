# CLAUDE.md — PAB SSOT 운영 지침

## 언어

- 모든 응답은 **한국어**로 할 것
- 코드 주석도 한국어로 작성

## 프로젝트 설정 단일 소스: PROJECT.md

프로젝트별 설정(이름·성격·플랫폼·언어·빌드 명령·코드 영역·규칙/페르소나 오버라이드)은 **루트 `PROJECT.md` 하나에서 관리**한다.

- **작업 착수 전** `PROJECT.md`를 읽어 §1 개요, §3 작업 폴더, §4 규칙 오버라이드를 파악한다.
- frontmatter 변경 시 `/project-config sync` (새 세션 시작 시 SessionStart 훅이 자동 동기화).
- 팀원 스폰 시: 각 역할 `ROLES/*.md` §1(Charter)에 **PROJECT.md §6 페르소나 오버라이드**를 덧붙여 주입하고, verifier·dev에게 **§4 규칙 오버라이드**를 함께 전달한다.
- 이 파일(CLAUDE.md)에는 프로젝트별 내용을 두지 않는다 — 전부 PROJECT.md로.

## SSOT (Lazy Load)

진입점: `docs/SSOT/entrypoint.md`. SSOT 버전은 entrypoint 머리 `**SSOT 버전**:` 값이 정본이다.

- **단순 질문·대화**: SSOT 로드 불필요. 바로 응답.
- **실제 작업 지시** (코드 작성/수정, 문서·산출물 생성, Phase 진행, 팀 운영): 작업 착수 전 `/ssot-reload` 실행 후 진행.
- **사용자 주도 개발 요청**: `/plan`은 마스터 플랜 작성 전 프롬프트 품질을 다듬는 선택 절차다.
- 모든 운영 규칙(HR, CHAIN, FRESH, LOCK, ENTRY 등)은 SSOT에 정의. 이 파일에서 중복 기술하지 않는다.
  - 규칙 조회: `/rules-lookup <규칙ID>` 또는 `docs/SSOT/CORE/rules-index.md`

## 역할

메인 세션은 **Team Lead**로 동작한다 (`docs/SSOT/ROLES/team-lead.md`).

- HR-1: Team Lead는 코드를 직접 수정하지 않는다 — backend-dev / frontend-dev에게 위임 (hook이 가드. 가드 범위는 Edit·Write와 팀 활성 판정까지 — Bash·NotebookEdit 쓰기는 밖).
- 팀원 스폰 시 로딩 세트: `docs/SSOT/entrypoint.md` §역할별 스폰 컨텍스트 주입(base 세트, HANDOFF-1 전달 시점·HANDOFF-2 전달물). 팀원이 base 밖 SSOT가 필요하면 `[SSOT 요청]`으로 Team Lead에게 요청한다(HANDOFF-3).
- 커밋·스테이징은 Team Lead 몫이다(REPORT-5) — 팀원 위임은 지시로 명시한 경우만 예외.
- `[DS]`(디자인) Task는 designer가 구현한다(`entrypoint.md` §3.8 도메인 태그).

## 디렉토리 규약

| 경로 | 용도 | 편집 규칙 |
|------|------|-----------|
| `PROJECT.md` | 프로젝트 단일 설정 문서 | frontmatter 변경 후 `/project-config sync` |
| `docs/SSOT/` | SSOT 본체 (규칙·역할·템플릿) | LOCK-1: Phase 실행 중 수정 금지 (hook이 가드). 업그레이드: 번들 `INSTALL.md` §7 |
| `docs/phases/` | Phase 산출물 (status/plan/todo/tasks) | CHAIN-6/CHAIN-10 규칙 준수 (`/phase-init`으로 생성) |
| `docs/history/` | 일자별 work-log (`{YYMMDD}-work-log.md`, 상세본 `output/`) | `scripts/log-prompt.sh` 또는 `/worklog`로 기록 |
| `docs/reports/` | 분석·보고서 (Phase 밖). Phase 활성 시엔 `docs/phases/phase-X-Y/reports/` | `/report`로 저장 — 임의 위치 저장 금지 |
| `docs/handoff/` | 세션 인계 문서 (`{YYMMDD-HHMM}-handoff.md`) | `/context-handoff prepare`/`resume` |
| `.claude/skills/` | 스킬 단일 소스 (`/menu`로 카탈로그) | — |
| `.claude/hooks/` | 훅 스크립트 + `hooks.env` (PROJECT.md에서 자동 생성 — 직접 수정 금지) | — |
| `scripts/` | 공용 스크립트 (log-prompt.sh, sync-project-config.sh, statusline.sh, pmAuto/) | — |
| `scripts/zombiecheck/` | LIFECYCLE-5 좀비 감지 헬퍼(`zombie_check.sh` + `zombie_check_selftest.sh`) + LIFECYCLE-6 체크 스케줄러(`zombie_watch.sh` + `zombie_watch_selftest.sh` + `zombie_watch_selftest_regression.sh`) + 헬퍼/폴링 분리 모듈(`zombie_watch_lib.sh` + `zombie_watch_poll.sh`, source 전용) | 코드 영역 여부는 `PROJECT.md` `code_dirs`가 정한다(코드 영역이면 HR-1 가드 대상) |
| `docs/guide/index.html` | HTML 사용 가이드 (SSOT·스킬·훅·인포창 — 사용자에게 안내 시 참조) | — |

## 주석 정책

- **COMMENT-1 (베이스)** — 하네스(SSOT·훅·스킬·스크립트) · scratchpad 임시 도구에 새로 쓰거나 고치는 주석은 최소로. 참조·과거 이력·과정·이슈 서술·개수·버전·코드 반복·주석 내 코드 예시·구분선 금지. 규격 표지(`Name : 한글명 · YYMMDD`)의 작성일 · 수정일 칸은 이력이 아니다. 적용은 작성자가 아니라 파일 위치로 가린다. 정본 `docs/SSOT/WORKFLOW/handoff/common.md §5`.
- **제품 코드 구역** — `PROJECT.md` §3 제품 코드 구역의 코드·마크업 주석은 누가 쓰든 `docs/comment-policy/comment-policy.md`(형식 `Name : 한글명 · YYMMDD [· point-N]` + 닫는 표지 · 붙이는 자리 · 읽을 때 L1~L3 · 포인터 운영) + 하네스 `scripts/comment/comment-lint.py`(scan·lint·points·map·show)를 따른다. `PROJECT.md §4`에 주석 규칙이 있으면 우선. 규격 위반(NOTE-1~6)의 등급은 VP §G2 판정 기준 「등급 산출」 표.
- `docs/comment-policy/CLAUDE-BLOCK.md` — 프로젝트 CLAUDE.md에 주석 정책 블록을 넣는 스니펫.

## 프롬프트 기록

SessionStart hook이 오늘자 work-log를 자동 초기화한다. 응답 완료 후:

```bash
./scripts/log-prompt.sh log "프롬프트 원문" "결과 요약(파일명용)" "상세 기록 내용"
```

## 프로젝트별 커스터마이징 (이식 시)

1. `PROJECT.md` 편집 (또는 `/project-config init` 대화형 생성) — 이름·성격·언어·빌드·코드 영역·임계값 전부 이 문서에서
2. `/project-config sync` 로 hooks.env 반영 (새 세션 시작 시 자동)
3. Telegram 알림(NOTIFY-1): `PAB_TELEGRAM_BOT_TOKEN` / `PAB_TELEGRAM_CHAT_ID` 환경변수 설정 (문서에 기입 금지)
