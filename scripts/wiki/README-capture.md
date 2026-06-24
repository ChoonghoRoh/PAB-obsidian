# PAB Wiki Capture — Telegram → Obsidian 파이프라인

상위 노트: [[10_Notes/2026-06-23_pab_wiki_pc_remote_worker_guide]]

## 개요

**capture/store 분리** 아키텍처:

- **캡처** (`telegram_ingest_listener.sh`): 텔레그램에서 메시지를 수신한다. `/wiki <url>` 명령이면 합성을 워커에 위임하고, 일반 메시지/URL이면 `99_Inbox/YYYY-MM-DD.md`에 원문만 append한다. 네트워크만 필요.
- **합성** (`pab_wiki_worker.sh`): `claude -p "/pab:wiki <url>"` 을 headless로 실행해 SOURCE + 요약본 두 노트를 vault(`PAB-LLMDATA/`)에 기록한다. Claude CLI 인증 필요.

```
모바일 텔레그램
     │ /wiki <url>          일반 텍스트/URL
     ▼                           ▼
telegram_ingest_listener.sh ─────┤
     │ /wiki 경로                │ 99_Inbox append
     ▼                           ▼
pab_wiki_worker.sh          PAB-LLMDATA/99_Inbox/YYYY-MM-DD.md
     │
     ▼
claude -p "/pab:wiki <url>"
     │
     ▼
PAB-LLMDATA/wiki/10_Notes/  (요약본)
PAB-LLMDATA/wiki/15_Sources/ (SOURCE 원본)
```

---

## 전제 조건

| 항목 | 요건 |
|---|---|
| Claude CLI | `claude --version` ≥ v2.1.51 |
| `.env` | 프로젝트 루트에 `WIKI_TELEGRAM_BOT_TOKEN`(리스너 전용 봇 — @BotFather로 별도 생성. 알림용 `TELEGRAM_BOT_TOKEN`과 공유 시 토큰당 폴러 1개 제한으로 409 충돌), `TELEGRAM_CHAT_ID` 정의 |
| Claude 인증 (로컬/Mac) | `claude /login` 완료 후 credential 캐시 유지 |
| Claude 인증 (서버/3800X) | `claude setup-token` 또는 `ANTHROPIC_API_KEY` 환경변수 설정 |
| `jq` | JSON 파싱용. 없으면 raw 출력 모드로 폴백(기능 저하 없음) |
| `WIKI_VAULT_ROOT` | 미설정 시 `<프로젝트루트>/PAB-LLMDATA`로 자동 설정 |

`.env` 예시:

```dotenv
# 알림용 봇(report_to_telegram.sh) — getUpdates 폴링 안 함
TELEGRAM_BOT_TOKEN=123456789:AAAA...
# 리스너 전용 봇(@BotFather로 별도 생성) — 알림용과 공유하면 409 충돌
WIKI_TELEGRAM_BOT_TOKEN=987654321:BBBB...
TELEGRAM_CHAT_ID=987654321
# 선택사항 — 서버에서 vault 위치가 다를 경우
# 주의: mirror 경로(/home/oceanui/pab-vault-mirror/...)를 지정하면 R-1 위반.
#       반드시 vault 정본(클론 경로/PAB-LLMDATA)을 사용할 것.
WIKI_VAULT_ROOT=/home/oceanui/WORKS/PAB-obsidian/PAB-LLMDATA
```

---

## 워커 단독 실행 / 테스트

```bash
# 실제 실행 (노트 생성)
scripts/wiki/pab_wiki_worker.sh "https://example.com/some-article"

# --dry 테스트 (파일 미생성, 파싱만 검증)
scripts/wiki/pab_wiki_worker.sh "https://example.com/some-article" --dry

# 로그 확인
ls -lt scripts/wiki/logs/
tail -f scripts/wiki/logs/pab-wiki-YYYYMMDD-HHMMSS.log
```

> **headless 주의**: `claude -p "/pab:wiki <url>"` 를 직접 실행할 때는 반드시
> `--plugin-dir <PROJECT_ROOT>` 를 포함해야 한다. 이 옵션이 없으면
> headless 모드에서 로컬 skills/plugins를 자동 발견하지 않아
> `Unknown command: /pab:wiki` 오류가 발생한다.
>
> ```bash
> # 올바른 직접 호출 예시
> claude -p "/pab:wiki https://example.com/article" \
>   --plugin-dir /Users/map-rch/WORKS/PAB-obsidian \
>   --output-format json
> ```

---

## 리스너 실행

### 포그라운드 (개발/디버깅)

```bash
scripts/wiki/telegram_ingest_listener.sh
```

SIGINT(Ctrl+C)로 cleanly 종료. offset이 `.telegram_offset`에 자동 저장된다.

### --once 모드 (테스트 / 단발 cron)

현재 대기 중인 배치만 처리하고 즉시 종료한다.

```bash
scripts/wiki/telegram_ingest_listener.sh --once
```

### 상시 가동 — Mac (launchd plist)

`~/Library/LaunchAgents/com.pab.wiki-listener.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.pab.wiki-listener</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>/Users/map-rch/WORKS/PAB-obsidian/scripts/wiki/telegram_ingest_listener.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/Users/map-rch/WORKS/PAB-obsidian/scripts/wiki/logs/listener-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/map-rch/WORKS/PAB-obsidian/scripts/wiki/logs/listener-stderr.log</string>
</dict>
</plist>
```

```bash
# 등록 및 시작
launchctl load ~/Library/LaunchAgents/com.pab.wiki-listener.plist

# 중지
launchctl unload ~/Library/LaunchAgents/com.pab.wiki-listener.plist
```

### 상시 가동 — 3800X (systemd user service)

`~/.config/systemd/user/pab-wiki-listener.service`:

```ini
[Unit]
Description=PAB Wiki Telegram Ingest Listener
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash /home/oceanui/WORKS/PAB-obsidian/scripts/wiki/telegram_ingest_listener.sh
Restart=on-failure
RestartSec=10
StandardOutput=append:/home/oceanui/WORKS/PAB-obsidian/scripts/wiki/logs/listener-stdout.log
StandardError=append:/home/oceanui/WORKS/PAB-obsidian/scripts/wiki/logs/listener-stderr.log

[Install]
WantedBy=default.target
```

```bash
# 등록 및 시작
systemctl --user daemon-reload
systemctl --user enable --now pab-wiki-listener

# 상태 확인
systemctl --user status pab-wiki-listener

# 로그
journalctl --user -u pab-wiki-listener -f
```

---

## 보안 메모

**chat_id 인가**
리스너는 수신 메시지의 `chat.id`를 `.env`의 `TELEGRAM_CHAT_ID`와 비교한다. 불일치 시 무시(다른 사용자/봇 차단). 인가된 chat_id에서만 명령이 처리된다.

**URL 검증**
워커와 리스너 양쪽에서 `^https?://[^[:space:]]+$` 정규식을 적용한다. 미일치 URL은 즉시 거부(exit 2)하고 텔레그램에 에러를 회신한다. `eval` 완전 금지 — `claude` 인자는 bash 배열로만 구성한다.

**`--bare` 금지**
`claude -p` 호출 시 `--bare` 플래그를 사용하면 skills/plugins 디렉토리를 스킵하기 때문에 `/pab:wiki` 스킬이 로드되지 않는다. 워커는 이 플래그를 사용하지 않는다. 향후 스크립트 수정 시에도 이 플래그를 추가하지 말 것.

**secret 비로깅**
`TELEGRAM_BOT_TOKEN`은 URL 경로에만 포함되며 curl `-s` 플래그로 verbose 출력이 억제된다. 로그 파일에 토큰이 기록되지 않는다. `.env`는 `.gitignore`에 포함되어 있어야 한다.

**99_Inbox append 안전성**
사용자 입력 텍스트는 `printf '%s'`로 파일에 쓴다. 셸 변수 확장이나 eval 없이 리터럴 문자열로 처리된다.

---

## 3800X 배포 절차

포터블 빌드이므로 파일 복사 후 Claude 인증만 추가하면 된다.

```bash
# 1. 코드 동기화 (Mac → 3800X)
rsync -avz --exclude '.env' \
  /Users/map-rch/WORKS/PAB-obsidian/scripts/wiki/ \
  oceanui@3800X:/home/oceanui/WORKS/PAB-obsidian/scripts/wiki/

# 2. 서버에서 .env 설정 (토큰은 직접 입력)
#    WIKI_VAULT_ROOT를 서버 vault 경로로 지정
ssh oceanui@3800X
cat >> ~/WORKS/PAB-obsidian/.env <<'EOF'
TELEGRAM_BOT_TOKEN=<your-token>
TELEGRAM_CHAT_ID=<your-chat-id>
WIKI_VAULT_ROOT=/home/oceanui/WORKS/PAB-obsidian/PAB-LLMDATA
EOF

# 3. 서버에서 Claude CLI 인증
claude setup-token          # API key 방식
# 또는
export ANTHROPIC_API_KEY=<key>  # .env에 추가 후 영속화

# 4. 실행권한 확인
chmod +x ~/WORKS/PAB-obsidian/scripts/wiki/pab_wiki_worker.sh
chmod +x ~/WORKS/PAB-obsidian/scripts/wiki/telegram_ingest_listener.sh

# 5. --once로 동작 검증
~/WORKS/PAB-obsidian/scripts/wiki/telegram_ingest_listener.sh --once

# 6. systemd 서비스로 상시 가동 (위의 unit 파일 참조)
```

> **R-1 준수**: 워커는 `WIKI_VAULT_ROOT`(`PAB-LLMDATA/`)에만 쓴다. LiveSync 미러(`/home/oceanui/pab-vault-mirror/`)에 직접 쓰지 않는다. 미러로의 복제는 CouchDB LiveSync가 담당한다.
