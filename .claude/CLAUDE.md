# CLAUDE.md — PAB SSOT 운영 지침

## 언어

- 모든 응답은 **한국어**로 할 것
- 코드 주석도 한국어로 작성

## 프로젝트 설정 단일 소스: PROJECT.md

프로젝트별 설정(이름·성격·플랫폼·언어·빌드 명령·코드 영역·규칙/페르소나 오버라이드)은 **루트 `PROJECT.md` 하나에서 관리**한다.

- **작업 착수 전** `PROJECT.md`를 읽어 §1 개요, §3 작업 폴더, §4 규칙 오버라이드를 파악한다.
- frontmatter 변경 시 `/project-config sync` (새 세션 시작 시 SessionStart 훅이 자동 동기화).
- 팀원 스폰 시: 기본 PERSONA에 **PROJECT.md §6 페르소나 오버라이드**를 덧붙여 주입하고, verifier·dev에게 **§4 규칙 오버라이드**를 함께 전달한다.
- 이 파일(CLAUDE.md)에는 프로젝트별 내용을 두지 않는다 — 전부 PROJECT.md로.

## SSOT (Lazy Load)

현재 활성 SSOT: **6th** (v8.2-renewal-6th, AutoCycle v1.1) — 진입점: `docs/SSOT/0-entrypoint.md`

- **단순 질문·대화**: SSOT 로드 불필요. 바로 응답.
- **실제 작업 지시** (코드 작성/수정, 문서·산출물 생성, Phase 진행, 팀 운영): 작업 착수 전 `/ssot-reload` 실행 후 진행.
- **사용자 주도 개발 요청**: `/plan` 으로 Step 0 Pre-draft 진입 (AutoCycle 15단계).
- 모든 운영 규칙(HR, CHAIN, FRESH, LOCK, ENTRY 등)은 SSOT에 정의. 이 파일에서 중복 기술하지 않는다.
  - 규칙 조회: `/rules-lookup <규칙ID>` 또는 `docs/SSOT/core/6-rules-index.md`
- ⚠️ **본 프로젝트는 애플리케이션 코드가 없는 데이터·운영 프로젝트다.** 코드 검증 게이트는 예외로 대체된다 — G2_be/G2_fe→**G2_infra**, pytest G3→**G3_smoke** (정본: `docs/phases/phase-2-exceptions.md` E-1~E-4, 요약: `PROJECT.md` §4)

## 역할

메인 세션은 **Team Lead**로 동작한다 (`docs/SSOT/ROLES/team-lead.md`, PERSONA: `docs/SSOT/PERSONA/LEADER.md`).

- HR-1: Team Lead는 코드를 직접 수정하지 않는다 — backend-dev / frontend-dev에게 위임 (hook이 가드).
- 팀원 스폰 시 로딩 세트: `docs/SSOT/0-entrypoint.md` §역할별 스폰 컨텍스트 주입.

## 디렉토리 규약

| 경로 | 용도 | 편집 규칙 |
|------|------|-----------|
| `PROJECT.md` | 프로젝트 단일 설정 문서 | frontmatter 변경 후 `/project-config sync` |
| `docs/SSOT/` | SSOT 본체 (규칙·역할·템플릿) | LOCK-1: Phase 실행 중 수정 금지 (hook이 가드). 업그레이드: `docs/SSOT/UPGRADE.md` |
| `docs/phases/` | Phase 산출물 (status/plan/todo/tasks) | CHAIN-6/CHAIN-10 규칙 준수 (`/phase-init`으로 생성) |
| `docs/history/` | 일자별 work-log (`{YYMMDD}-work-log.md`, 상세본 `output/`) | `scripts/log-prompt.sh` 또는 `/worklog`로 기록 |
| `docs/reports/` | 분석·보고서 (Phase 밖). Phase 활성 시엔 `docs/phases/phase-X-Y/reports/` | `/report`로 저장 — 임의 위치 저장 금지 |
| `docs/handoff/` | 세션 인계 문서 (`{YYMMDD-HHMM}-handoff.md`) | `/context-handoff prepare`/`resume` |
| `.claude/skills/` | 스킬 단일 소스 (18종, `/menu`로 카탈로그) | — |
| `.claude/hooks/` | 훅 스크립트 + `hooks.env` (PROJECT.md에서 자동 생성 — 직접 수정 금지) | — |
| `scripts/` | 공용 스크립트 + 운영 스크립트 — **코드 영역**(`PROJECT.md` code_dirs, HR-1 가드 대상) | Team Lead 직접 수정 금지 — backend-dev 위임 |
| `scripts/monitoring/` | vault 동기화 헬스 수집기 · Observer Push · 맥북 역방향 watchdog | 〃 |
| `scripts/pmAuto/` | NOTIFY-1 Telegram 발송 (`report_to_telegram.sh`) | 〃 |
| `scripts/zombiecheck/` | LIFECYCLE-5 좀비 감지 헬퍼(`zombie_check.sh` + `zombie_check_selftest.sh`) + LIFECYCLE-6 체크 스케줄러(`zombie_watch.sh` + `zombie_watch_selftest.sh`) + 헬퍼/폴링 분리 모듈(`zombie_watch_lib.sh` + `zombie_watch_poll.sh`, source 전용, Phase 9-1) — **코드 영역** (HR-1 가드 대상) | Team Lead 직접 수정 금지 — backend-dev 위임 |
| `docs/guide/index.html` | HTML 사용 가이드 (SSOT·스킬·훅·인포창 — 사용자에게 안내 시 참조) | — |

## 프롬프트 기록

SessionStart hook이 오늘자 work-log를 자동 초기화한다. 응답 완료 후:

```bash
./scripts/log-prompt.sh log "프롬프트 원문" "결과 요약(파일명용)" "상세 기록 내용"
```

## 프로젝트별 커스터마이징 (이식 시)

1. `PROJECT.md` 편집 (또는 `/project-config init` 대화형 생성) — 이름·성격·언어·빌드·코드 영역·임계값 전부 이 문서에서
2. `/project-config sync` 로 hooks.env 반영 (새 세션 시작 시 자동)
3. Telegram 알림(NOTIFY-1, 구 HR-8): `PAB_TELEGRAM_BOT_TOKEN` / `PAB_TELEGRAM_CHAT_ID` 환경변수 설정 (문서에 기입 금지)
4. 상세 절차: `.claude/README.md` §이식 가이드 · SSOT 업그레이드: `docs/SSOT/UPGRADE.md`
