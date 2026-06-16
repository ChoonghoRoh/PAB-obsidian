---
task: "2-1-4"
title: "레노버 연동 + 양방향 동기화 검증"
domain: "[INFRA]"
assignee: 사용자 (GUI) + Team Lead (검증)
status: completed
---

# Task 2-1-4: 다기기 연동 + 양방향 검증

## 목표
레노버를 동일 CouchDB에 연결하고 맥북↔레노버 양방향 동기화를 검증한다.

## 작업 (사용자 GUI)
- 레노버 Obsidian LiveSync 동일 접속정보 설정
- Sync Method = **LiveSync(실시간)** 으로 양쪽 통일
- (권장) Sync on Start 동작 이해 — 앱 켤 때 자동 따라잡기

## 검증 (Team Lead 독립, HR-6 / G3_smoke)
- 레노버 별도 노트(2026-06-15_deepseek_v4_opencode_api .md/source) → 서버 DB push 확인 (74→76)
- 서버 → 맥북 수신 후 .md 77개 3자 일치 (del 0, 충돌 0)
- 결론: 레노버→서버→맥북 전파 정상, 양방향 동기화 동작 확인

## 비고
- 모바일(iPhone)은 Tailscale offline으로 미검증 → 잔여 사항
