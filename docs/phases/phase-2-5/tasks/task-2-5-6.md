---
task: "2-5-6"
title: "iPhone LiveSync 연동 검증"
domain: "[INFRA]"
gap: "G-6 (🟢)"
assignee: "사용자 (GUI) + Team Lead (독립 검증)"
status: pending
depends_on: ["2-5-4"]
---

# Task 2-5-6: iPhone LiveSync 연동 검증

## 목표
Phase 2-1 T-4에서 폰 offline으로 미완이었던 모바일 연동을 완료한다.

## 작업 (사용자 GUI)
- `chroh-iphone` Tailscale online 확인 (Tailnet 등록 완료, 현재 idle)
- Obsidian 모바일 + Self-hosted LiveSync 플러그인 설치
- 접속정보 입력 (`http://100.109.251.86:5984/pab-llmdata`) — **T-4 회전 후 신규 자격증명 사용**
- Sync Method = LiveSync(실시간) 통일

## 검증 (Team Lead 독립, HR-6)
- 폰 → 서버 push 확인 (문서 수 증가)
- 서버 → 맥북/레노버 전파 확인 (3자 일치, del 0, 충돌 0)
- per-machine 파일 미동기화 확인

## 비고
- T-4(자격증명 회전) 이후에 수행해야 재설정 2회를 피한다
