# .claude — PAB SSOT 포터블 설정 번들

Claude Code 기반 **AutoCycle v1.1 / SSOT 6th (v8.2)** 운영 설정. 이 폴더와 `PROJECT.md`, `docs/SSOT/`, `scripts/`를 함께 복사하면 다른 프로젝트에서 동일한 체계로 운영할 수 있다.

## 0. 설정 단일 소스: PROJECT.md

프로젝트별 설정(이름·성격·플랫폼·언어·빌드·코드 영역·규칙/페르소나 오버라이드)은 **루트 `PROJECT.md` 한 문서**에서 관리한다.

```
PROJECT.md (단일 소스)
  ├─ frontmatter ──/project-config sync──▶ .claude/hooks/hooks.env ──▶ 훅 9종
  └─ 프로즈 §1~§9 ───────────────────────▶ Team Lead·팀원 스폰 시 로드
```

- frontmatter 수정 후 `/project-config sync` — 새 세션 시작 시 SessionStart 훅이 변경을 감지해 자동 동기화한다.
- `hooks.env`는 자동 생성 파생물이므로 직접 수정하지 않는다.

## 1. 구성

```
.claude/
├── CLAUDE.md            # 페르소나·SSOT 진입점 지시 (시작 시 로드)
├── settings.json        # 권한 + hooks 배선 (프로젝트 공유)
├── settings.local.json  # 개인 로컬 권한 (git 제외 대상)
├── hooks/               # 훅 스크립트 9종 + hooks.env (자동 생성)
│   ├── hooks.env                  # PROJECT.md frontmatter에서 자동 생성 (직접 수정 금지)
│   ├── ssot-freshness-check.sh    # SessionStart — PROJECT.md 자동 동기화 + SSOT·Phase 요약
│   ├── hr1-guard.sh               # PreToolUse — 팀 운영 중 Team Lead 코드 수정 차단
│   ├── lock1-guard.sh             # PreToolUse — Phase 실행 중 SSOT 수정 차단
│   ├── line-count-monitor.sh      # PostToolUse — HR-5 줄수 경고
│   ├── state-transition-guard.sh  # PostToolUse — status.md 상태 전이 검증
│   ├── on-task-completed.sh       # TaskCompleted — CDN/HR-5 품질 검사
│   ├── team-sentinel.sh           # SubagentStart/Stop — 팀 활성 센티넬
│   ├── stop-worklog-reminder.sh   # Stop — work-log 기록 리마인더
│   └── post-compact-reminder.sh   # PostCompact — FRESH-7 복구 안내
└── skills/              # 스킬 단일 소스 18종 (/menu로 카탈로그 조회)
```

**외부 의존 (함께 복사)**:

| 경로 | 용도 |
|------|------|
| `PROJECT.md` | 프로젝트 단일 설정 문서 (/project-config로 관리) |
| `docs/SSOT/` | SSOT 본체 (진입점 `0-entrypoint.md`, 업그레이드는 `UPGRADE.md`) |
| `scripts/sync-project-config.sh` | PROJECT.md → hooks.env 동기화 |
| `scripts/log-prompt.sh` | work-log 기록 CLI (SessionStart/Stop hook + /worklog 스킬이 사용) |
| `scripts/pmAuto/report_to_telegram.sh` | HR-8 Telegram 알림 (/notify-telegram 스킬이 사용) |

## 2. 이식 가이드 (다른 프로젝트에 설치)

> 🔴 **정본은 번들 루트 `INSTALL.md`다**(본 배포본에는 포함되지 않는다 — 설치 전에 읽는 문서이므로 미배포는 결함이 아니다). 아래는 배포본 측 최소 요약이다.

```bash
# 번들(git 클론 또는 zip 해제본)을 별도 고정 위치(예: ~/pab-ssot-bundle/)에 두고 실행한다.

# 신규 설치:
bash ~/pab-ssot-bundle/install.sh /path/to/target-project

# 기존 이식 프로젝트의 SSOT/스킬/훅 업그레이드 (프로젝트 설정 보존):
bash ~/pab-ssot-bundle/install.sh /path/to/target-project --upgrade
```

번들 위치를 고정해 두면 여러 프로젝트 설치·`--upgrade` 재배포에 같은 명령을 반복 사용할 수 있다. 대상이 번들 자신이면 에러(소스≠대상 필수).

### 설치 후 체크리스트

1. **PROJECT.md 편집** — 대상 프로젝트에서 `/project-config init`(대화형) 또는 직접 편집: 이름·성격·언어·빌드 명령·코드 영역(`code_dirs`)·HR-5 임계값 전부 이 문서에서
2. **동기화** — `/project-config sync` (새 세션 시작 시 자동)
3. **Telegram (선택)** — `export PAB_TELEGRAM_BOT_TOKEN=... PAB_TELEGRAM_CHAT_ID=...` (문서에 기입 금지)
4. **기존 .claude가 있는 대상** — 충돌 파일은 `*.pab-new`로 저장됨 → diff 후 수동 병합
5. **동작 확인** — 새 세션 시작 → SessionStart hook의 "Project: ..." 줄 확인 → `/menu` → `/project-config check` → `/ssot-reload`

### SSOT 업그레이드

번들의 SSOT가 개정되면 `--upgrade`로 배포한다. 프레임워크 파일만 덮어쓰고 `PROJECT.md`, `hooks.env`, 커스터마이징된 `1-project.md`/`2-architecture.md`/`PERSONA/`는 보존된다. 상세: [docs/SSOT/UPGRADE.md](../docs/SSOT/UPGRADE.md)

## 3. 페르소나 설정 위치 (참고)

`settings.json`에는 페르소나(시스템 프롬프트) 필드가 없다. 페르소나·커스텀 지시는 **CLAUDE.md**로만 등록한다.

| 목적 | 파일 |
|------|------|
| 페르소나·운영 지시 | `.claude/CLAUDE.md` |
| 권한·훅·환경변수 | `.claude/settings.json` (공유) / `settings.local.json` (개인) |

- 공식 문서: [Claude Code settings](https://code.claude.com/docs/en/settings) — "To add custom instructions, use CLAUDE.md files"
- 스키마: https://json.schemastore.org/claude-code-settings.json
