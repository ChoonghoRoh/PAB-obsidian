---
phase: "1-2"
type: todo-list
created: 2026-05-01
updated: 2026-05-01
---

# Phase 1-2 TODO List — Frontmatter 스키마 + Templater 템플릿

> 본 문서는 작업 진행 체크리스트. backend-dev / verifier가 작업 진행 시 항목별 체크.

## TEAM_SETUP

- [x] TeamCreate(team_name="phase-1-2")
- [x] backend-dev 스폰 (general-purpose/sonnet, CWD: 프로젝트 루트)
- [x] verifier 스폰 (Explore/sonnet)
- [x] tester 스폰 ❌ (E-4 비스폰)
- [x] frontend-dev 스폰 ❌ (E-5 비스폰)

## TASK_SPEC

- [x] T-1 → backend-dev (`tasks/task-1-2-1.md`) — JSON Schema
- [x] T-2 → backend-dev (`tasks/task-1-2-2.md`) — TYPE별 6 템플릿
- [x] T-3 → backend-dev (`tasks/task-1-2-3.md`) — frontmatter-spec.md
- [x] T-4 → backend-dev (`tasks/task-1-2-4.md`) — naming-convention.md
- [x] T-5 → backend-dev (`tasks/task-1-2-5.md`) — linking-policy.md
- [x] 도메인 매핑 검증: T-1 ~ T-5 모두 [WIKI-META] (E-5)

## BUILDING

- [x] T-1: `wiki/40_Templates/_schema.json` 작성 (Draft 2020-12, 11필드, 필수 3 + High 4 + Low 4) — 93 lines
- [x] T-1 검증: `python3 -c "import json; json.load(open('wiki/40_Templates/_schema.json'))"` 통과
- [x] T-2: `wiki/40_Templates/RESEARCH_NOTE.md` (frontmatter 11필드 + Question/Findings/Sources/Next) — 27 lines
- [x] T-2: `wiki/40_Templates/CONCEPT.md` (Definition/Why it matters/Examples/Related) — 27 lines
- [x] T-2: `wiki/40_Templates/LESSON.md` (Context/What I learned/Mistakes/Apply next time) — 27 lines
- [x] T-2: `wiki/40_Templates/PROJECT.md` (Goal/Status/Tasks/Decisions/Risks) — 30 lines
- [x] T-2: `wiki/40_Templates/DAILY.md` (Log/Done/TODO/Reflection) — 27 lines
- [x] T-2: `wiki/40_Templates/REFERENCE.md` (Source/Summary/Quotes/My take) — 27 lines
- [x] T-3: `wiki/30_Constraints/frontmatter-spec.md` (11필드 표 + 5 잘못된/올바른 예시 + FAQ 5건) — 196 lines
- [x] T-4: `wiki/30_Constraints/naming-convention.md` (`YYYY-MM-DD_topic.md` + slug 규칙 + 첨부 명명) — 164 lines
- [x] T-5: `wiki/30_Constraints/linking-policy.md` (상향/하향/횡적/alias) — 257 lines
- [x] backend-dev 보고서 작성 (`reports/report-backend-dev.md`) — 248 lines

## VERIFYING (G2_wiki)

- [x] verifier: JSON Schema valid 검증 (DoD-1, DoD-2) — PASS
- [x] verifier: 6 템플릿 모두 11필드 100% 준수 검증 (DoD-3, DoD-4) — 36/36
- [x] verifier: 6 템플릿 본문 권장 섹션 헤더 검증 (DoD-5) — 26/26
- [x] verifier: 3 constraints 문서 존재·내용 검증 (DoD-6, DoD-7, DoD-8)
- [x] verifier: 3 constraints 자기참조 frontmatter 검증 (DoD-9) — 33/33
- [x] verifier: wikilink 정합성 검증 (DoD-10) — TOPIC unresolved 정상 (Phase 1-3 후 해소)
- [x] verifier: 보고서 작성 (`reports/report-verifier.md`) — Team Lead 저장 (verifier read-only)
- [x] G2_wiki 판정: **PASS** (Critical 5/5, High 4/4, Low 2/2)

## TESTING (E-4 비적용)

- [x] G3 비적용 (본 sub-phase는 wiki-validation 미구현 단계)

## INTEGRATION + DONE

- [x] G4 판정 (G2_wiki PASS → 자동 PASS)
- [x] `phase-1-2-status.md`의 `current_state` → DONE
- [x] `gate_results` 갱신 (G2_wiki: PASS, G4: PASS)
- [x] `next_prompt_suggestion` 갱신 (Phase 1-3 진입 명령)
- [x] NOTIFY-1 발송: `[PAB-Wiki] ✅ Phase 1-2 완료` (Telegram message_id: 740, ok:true)
- [x] master-plan §3 Phase 1-2 체크 (CHAIN-5 1줄 요약 추가)

## TEAM_SHUTDOWN

- [x] backend-dev shutdown_request 발송
- [x] verifier shutdown_request 발송
- [x] TeamDelete("phase-1-2") — 디렉터리·worktree 정리 완료
- [x] 잔류 에이전트 0건 확인 (LIFECYCLE-4)

## CHAIN

- [x] handoff 트리거: 사용자에게 Phase 1-3 진입 안내 (next_prompt_suggestion 참조)
