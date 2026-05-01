---
phase: "1-1"
type: todo-list
created: 2026-05-01
---

# Phase 1-1 TODO List — Obsidian CLI + Vault 초기화

> 본 문서는 작업 진행 체크리스트. backend-dev / verifier가 작업 진행 시 항목별 체크.

## TEAM_SETUP

- [x] TeamCreate(team_name="phase-1-1")
- [x] backend-dev 스폰 (general-purpose/sonnet, CWD: 프로젝트 루트)
- [x] verifier 스폰 (Explore/sonnet)
- [x] tester 스폰 ❌ (E-4 비스폰)

## TASK_SPEC

- [x] T-1 (사용자 직접): `! obsidian register` 안내 — 완료
- [x] T-2 → backend-dev (`tasks/task-1-1-2.md`)
- [x] T-3 → backend-dev (`tasks/task-1-1-3.md`)
- [x] T-4 → backend-dev (`tasks/task-1-1-4.md`)
- [x] T-5 → backend-dev (`tasks/task-1-1-5.md`)
- [x] 도메인 매핑 검증: T-1/T-3=[WIKI-INFRA], T-2/T-5=[WIKI-INFRA], T-4=[WIKI-CLI] (E-5)

## BUILDING

- [x] T-1: Obsidian CLI 등록 검증 (`which obsidian`, `obsidian version`) — 완료 (`/usr/local/bin/obsidian`, v1.12.7)
- [x] T-2: 7 폴더 생성 + `.gitkeep`
- [x] T-3: 프로젝트 루트 `.obsidian/` 3개 JSON 파일 검증·튜닝 (`app.json`, `core-plugins.json` 객체형식, `appearance.json`)
- [x] T-3 검증: python3 json.load 통과
- [x] T-4: 4 CLI 명령 smoke test → `reports/cli-smoke-test.md` (4/4 exit 0)
- [x] T-5: `wiki/_INDEX.md` 작성 (frontmatter 11필드)

## VERIFYING (G2_wiki)

- [x] verifier: vault 구조 정합성 검증 (DoD-3, DoD-4) — PASS
- [x] verifier: CLI 응답 정상 검증 (DoD-5, DoD-6) — PASS
- [x] verifier: `_INDEX.md` frontmatter 검증 (DoD-7) — PASS
- [x] verifier: 보고서 작성 (`reports/report-verifier.md`) — Team Lead 저장
- [x] G2_wiki 판정: **PASS** (Critical 5/5, High 2/2, Low 1/1)

## TESTING (E-4 비적용)

- [x] G3 비적용 (본 sub-phase는 wiki-validation 미구현 단계)

## INTEGRATION + DONE

- [x] backend-dev 보고서 작성 (`reports/report-backend-dev.md`)
- [x] G4 판정 (G2_wiki PASS → 자동 PASS)
- [x] `phase-1-1-status.md`의 `current_state` → DONE
- [x] `gate_results` 갱신 (G2_wiki: PASS, G4: PASS)
- [x] `next_prompt_suggestion` 갱신 (Phase 1-2 진입 명령)
- [x] task-1-1-3.md 명세 정정 (verifier 권고 — core-plugins.json 객체 형식)
- [x] NOTIFY-1 발송: `[PAB-Wiki] ✅ Phase 1-1 완료` (Telegram message_id: 738, ok:true)
- [x] **부수 작업**: 토큰 무효 발견 → `.env` 도입 + `report_to_telegram.sh` .env 로드로 개선 (backend-dev 추가 task)

## TEAM_SHUTDOWN

- [ ] backend-dev shutdown_request → confirm
- [ ] verifier shutdown_request → confirm
- [ ] TeamDelete("phase-1-1")
- [ ] 잔류 에이전트 0건 확인 (LIFECYCLE-4)

## CHAIN

- [ ] handoff 트리거: 사용자에게 Phase 1-2 진입 안내 (next_prompt_suggestion 참조)
