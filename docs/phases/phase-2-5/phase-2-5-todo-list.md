# Phase 2-5 Todo List — 운영 안정화 + 백업 무결성

상태: **IN_PROGRESS** (G1 PASS 2026-08-25 · T-1 완료 · 2026-08-26 T-7 신설)

## 진입 (ENTRY-1~5)
- [ ] SSOT 0-entrypoint 리로드 (FRESH-1)
- [ ] status.md 읽기 → current_state 확인
- [ ] plan.md 확정 → G1 PASS 기록
- [ ] 팀 생성 (`phase-2-5`) + backend-dev 스폰

## T-1: [G-1 🔴] 헬스 모니터링 + Telegram 알림
- [ ] CouchDB `/_up` 주기 점검 스크립트 작성
- [ ] `pab-livesync-bridge` 컨테이너 상태 점검 추가
- [ ] 연속 N회 실패 시에만 발송 + 복구 시 1회 발송 (PR-2 플래핑 방지)
- [ ] `scripts/pmAuto/report_to_telegram.sh` 재사용 + `_` 토큰 escape (PR-4)
- [ ] "마지막 git 커밋 경과 > 24h" 감시 항목 포함 (DP-2-5-2 잔여 위험 커버)
- [ ] 3800X crontab 등록 (DP-2-5-1)
- [ ] 맥북발 주 1회 역방향 확인 보조 장치 등록 (서버 침묵 감지)

## T-2: [G-2 🔴] GitHub 오프사이트 백업 정상화
- [ ] 미커밋 잔여 해소 (노트 8종 + `_INDEX.md` 수정 + `무제.canvas` 삭제)
- [ ] 자동 커밋·푸시 스크립트 작성 (**커밋·푸시만, 병합 금지** — PR-3)
- [ ] DP-1 데스크톱 git-authority 정책 무변경 확인
- [ ] 맥북 로컬 cron 등록 (DP-2-5-2)
- [ ] 커밋 공백 ≤ 24h KPI 달성 확인

## T-3: [G-3 🟡] CouchDB 볼륨 덤프 백업
- [ ] `pab_couchdb_data` 덤프 스크립트 작성
- [ ] 세대 보존 정책 구현 — 일 1회 × 7세대 (DP-2-5-3)
- [ ] 서버 crontab 등록
- [ ] **복원 리허설** — 덤프에서 실제 복구 가능 확인 (G2_infra 필수)

## T-4: [G-4 🟡] 자격증명 회전  ← T-1·T-2 완료 후 착수 (PR-1)
- [ ] 회전 절차서 + 롤백 절차 문서화 (선행)
- [ ] `pabadmin`(관리자) 회전
- [ ] `pabbridge`(읽기전용) 회전
- [ ] 전 기기(맥북·레노버·iPhone) LiveSync 재설정
- [ ] 평문 노출 0 확인 (스크립트·로그·커밋 이력·세션)

## T-5: [G-5 🟡] workspace.json git 추적 해제
- [ ] `PAB-LLMDATA/.obsidian/workspace.json` `git rm --cached`
- [ ] `.gitignore` 반영 확인
- [ ] master-plan §7 R-2 (per-machine churn) 해소 확인

## T-6: [G-6 🟢] iPhone LiveSync 연동 검증
- [ ] `chroh-iphone` Tailscale online 확인
- [ ] Obsidian 모바일 + LiveSync 플러그인 설정
- [ ] 양방향 동기화 E2E 확인 (Team Lead 독립 검증)

## T-7: [G-7 🟡] `/wiki` 스킬 MOC 자동화 + link-check 게이트  ← 2026-08-26 신설 (PO1 §4.4 대응)
- [x] 정본 정비 2건 적용 — anchor 수선 + `moc-build` (orphan 8→0, 2026-08-26)
- [x] SKILL.md Step 9.5 신설 — 실제 `make wiki-moc-build` 필수 실행 (2026-08-26, Team Lead)
- [x] SKILL.md Step 9 게이트화 — 판정 근거를 `counts`로, `violations>0` 시 중단·보고 (2026-08-26, Team Lead)
- [ ] `validate.py` status 산정 정합 (`broken`은 정보 지표로 분리) — backend-dev
- [x] 플러그인 판본(`skills/wiki/`) 동기화 (2026-08-26)

## PAB-Prove 편입 (T-4와 동시 실행) ← 2026-08-26 편성
- [x] PO1 회답 발신 — PO2 (조건부 승인 + 정정 2건 + 요청 6건)
- [ ] R-5 수신 — Prove 측 검증 시점 이동 완료 통지 (**편입 게이트 P-1**)
- [ ] Observer 사전 통지 (홉2 구조 변경, 리드타임 24h)
- [ ] `Hub.patched.ts` `allowWriteBack` 플래그 조건부화 — backend-dev
- [ ] Prove 전용 bridge 컨테이너 + config 신설 — backend-dev
- [ ] `pabprove` 계정 발급 + 쓰기 통과 실증 (T-4 회전과 동시) — backend-dev
- [ ] 3800X `PAB-LLMDATA` 사본 생성 + LiveSync 참여 확인
- [ ] PO3 발신 — 편입 실행 일시 통지

## 게이트
- [ ] G0 SKIP (research=false — 사전 분석 APPROVED)
- [ ] G1 PASS (plan 승인)
- [ ] G2_infra PASS (6항목 — 알림 수신 / 백업 생성·복원 / 회전 후 동기화 / per-machine 미추적 / cron 등록 / 평문 노출 0)
- [ ] G3_smoke PASS (**tester 담당** — 장애 주입 → 알림 → 복구 → 복구 알림 E2E)
- [ ] G4 PASS (G2_infra + G3_smoke)

## 완료 처리
- [ ] REFACTOR-1 — 신규 bash 스크립트 500줄 스캔 → 레지스트리 등록 (E-2 예외 아님)
- [ ] CHAIN-5 — master-plan에 1줄 완료 요약 기록
- [ ] NOTIFY-1 / HR-8 — `report_to_telegram.sh` 발송 (`[PAB-LLMDATA]` prefix)
- [ ] LIFECYCLE — 전원 shutdown_request → TeamDelete

## 이월 (범위 밖)
- [ ] G-7 Phase 2-2 범위 재정의 — PAB-v4 기존 RAG 중복 인덱싱 회피 판단 (2-2 진입 전)
