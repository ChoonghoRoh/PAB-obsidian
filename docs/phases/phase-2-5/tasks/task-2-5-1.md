---
task: "2-5-1"
title: "헬스 모니터링 + Telegram 알림"
domain: "[INFRA]"
gap: "G-1 (🔴)"
assignee: backend-dev
status: pending
depends_on: []
integration_ref: docs/interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md
blocked_on: "UK_PAB_VAULT_PUSH_URL 발급 (Observer 측) — 미설정 시 Push 생략 동작으로 선배포 가능"
---

# Task 2-5-1: 헬스 모니터링 + Telegram 알림

## 목표
CouchDB·bridge 상태를 주기 점검하고 이상 시에만 Telegram으로 알린다. 2026-08-21 3일 장애 미인지의 직접 원인(G-1) 해소.

## 설계 변경 (2026-08-25, 사용자 지시)

**1차 알림 경로를 Observer/UK로 일원화한다.** 정상 시 무소음을 Telegram 침묵으로 구현하는 게 아니라, **Observer heartbeat의 존재 자체**를 정상 신호로 삼는다. heartbeat가 끊기면 UK가 알린다 — 수집기 자체가 죽는 경우까지 덮인다.

**정본**: [OB2 §7.1](../../interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md) — 수집기 규격·판정 4종·중복 조정 의견

- 파일: `pab-vault-sync-collect.sh` → `/home/oceanui/observer/scripts/`, cron 5분
- Push: `GET {UK_PAB_VAULT_PUSH_URL}?status={up|down}&msg={요약}&ping={정상항목수}`
- 판정 4종: `couch-net`(N-1 위양성) / `couch-up`(Tailnet IP 경유) / `mirror-fresh`(N-3) / `git-gap`(N-2)
- 기존 수집기 중복 감시 금지 — `pab-livesync-bridge`는 `container-health-collect.sh`가 이미 감시 중

## 작업
- 헬스체크 스크립트 작성 — 점검 항목:
  - CouchDB `/_up` (HTTP 200)
  - `pab-couchdb` 컨테이너 running + **네트워크 엔드포인트 존재** (§1.3 위양성 방지: `Networks: {}` 상태 검출)
  - `pab-livesync-bridge` 컨테이너 상태
  - 마지막 git 커밋 경과 시간 > 24h (DP-2-5-2 잔여 위험 커버)
- 알림 정책 — **연속 N회 실패 시에만** 발송 + **복구 시 1회** 발송 (PR-2 플래핑 방지)
- `scripts/pmAuto/report_to_telegram.sh` 재사용. `_` 단독 토큰 하이픈 치환·escape (PR-4)
- **3800X crontab 등록** (DP-2-5-1)
- **맥북발 주 1회 역방향 확인** 보조 장치 — 서버 자체 다운 시 침묵 감지

## 산출물
- 헬스체크 스크립트 + crontab 엔트리 (서버)
- 맥북 역방향 확인 스크립트 + cron 엔트리

## 검증 (G2_infra / G3_smoke)
- G2_infra: cron 등록 확인, 정상 상태에서 **알림 미발송**(무소음) 확인
- G3_smoke(tester): 컨테이너 강제 정지 → 알림 수신 → 복구 → 복구 알림 수신 E2E

## 비고
- 정상일 때 조용해야 한다 — 매 실행 발송은 알림 피로를 유발해 실제 장애를 묻는다
- HR-5 적용 대상 (신규 bash 스크립트, E-2 예외 아님)
