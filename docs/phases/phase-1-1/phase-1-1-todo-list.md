---
phase: "1-1"
type: todo-list
created: 2026-05-01
---

# Phase 1-1 TODO List — Obsidian CLI + Vault 초기화

> 본 문서는 작업 진행 체크리스트. backend-dev / verifier가 작업 진행 시 항목별 체크.

## TEAM_SETUP

- [ ] TeamCreate(team_name="phase-1-1")
- [ ] backend-dev 스폰 (general-purpose/sonnet, CWD: 프로젝트 루트)
- [ ] verifier 스폰 (Explore/sonnet)
- [ ] tester 스폰 ❌ (E-4 비스폰)

## TASK_SPEC

- [ ] T-1 (사용자 직접): `! obsidian register` 안내
- [ ] T-2 → backend-dev (`tasks/task-1-1-2.md`)
- [ ] T-3 → backend-dev (`tasks/task-1-1-3.md`)
- [ ] T-4 → backend-dev (`tasks/task-1-1-4.md`)
- [ ] T-5 → backend-dev (`tasks/task-1-1-5.md`)
- [ ] 도메인 매핑 검증: T-1/T-3=[WIKI-INFRA], T-2/T-5=[WIKI-INFRA], T-4=[WIKI-CLI] (E-5)

## BUILDING

- [ ] T-1: Obsidian CLI 등록 검증 (`which obsidian`, `obsidian --version`)
- [ ] T-2: 7 폴더 생성 (`mkdir -p wiki/{00_MOC,10_Notes,20_Lessons,30_Constraints,40_Templates,99_Inbox,_attachments}` + `.gitkeep`)
- [ ] T-3: `.obsidian/` 3개 JSON 파일 작성 (`app.json`, `core-plugins.json`, `appearance.json`)
- [ ] T-3 검증: `python3 -c "import json; [json.load(open(p)) for p in ['wiki/.obsidian/app.json','wiki/.obsidian/core-plugins.json','wiki/.obsidian/appearance.json']]"`
- [ ] T-4: 4 CLI 명령 smoke test (`files`/`search`/`tags`/`unresolved`) → `reports/cli-smoke-test.md`
- [ ] T-5: `wiki/_INDEX.md` 작성 (frontmatter 11필드)

## VERIFYING (G2_wiki)

- [ ] verifier: vault 구조 정합성 검증 (DoD-3, DoD-4)
- [ ] verifier: CLI 응답 정상 검증 (DoD-5, DoD-6)
- [ ] verifier: `_INDEX.md` frontmatter 검증 (DoD-7)
- [ ] verifier: 보고서 작성 (`reports/report-verifier.md`)
- [ ] G2_wiki 판정: PASS / FAIL / PARTIAL

## TESTING (E-4 비적용)

- [x] G3 비적용 (본 sub-phase는 wiki-validation 미구현 단계)

## INTEGRATION + DONE

- [ ] backend-dev 보고서 작성 (`reports/report-backend-dev.md`)
- [ ] G4 판정 (G2_wiki PASS 시 자동)
- [ ] `phase-1-1-status.md`의 `current_state` → DONE
- [ ] `gate_results` 갱신
- [ ] `next_prompt_suggestion` 갱신 (Phase 1-2 진입 명령)
- [ ] NOTIFY-1 발송: `[PAB-Wiki] ✅ Phase 1-1 완료: Obsidian CLI + Vault 초기화\n📊 결과: vault 7폴더, CLI 4명령 OK\n📁 보고서: docs/phases/phase-1-1/reports/`

## TEAM_SHUTDOWN

- [ ] backend-dev shutdown_request → confirm
- [ ] verifier shutdown_request → confirm
- [ ] TeamDelete("phase-1-1")
- [ ] 잔류 에이전트 0건 확인 (LIFECYCLE-4)

## CHAIN

- [ ] `phase-chain-1.md`(있으면)에 1줄 완료 요약 기록 (CHAIN-5)
- [ ] handoff 트리거: 사용자에게 다음 명령 안내 또는 자동 진입
