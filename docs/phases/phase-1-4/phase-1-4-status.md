---
phase_id: "1-4"
title: "CLI 자동화 — scripts/wiki/wiki.py"
current_state: "DONE"
created_at: "2026-05-02"
updated_at: "2026-05-02"
ssot_version: "8.3-renewal-6th"
team_name: "phase-1-4"
gate_results:
  G0: SKIP
  G1: PASS
  G2_wiki: PASS
  G3: SKIP
  G4: PASS
roles:
  team_lead: main
  backend_dev: completed
  verifier: completed
  tester: not_spawned
  frontend_dev: not_spawned
exceptions:
  - E-1
  - E-2
  - E-3
  - E-4
  - E-5
exceptions_ref: docs/phases/phase-1-exceptions.md
notify_prefix: "[PAB-Wiki]"
tasks:
  - id: "1-4-1"
    owner: backend-dev
    status: pending
    note: "wiki.py 진입점 + argparse + lib/ 모듈 분리 설계 (R-4)"
  - id: "1-4-2"
    owner: backend-dev
    status: pending
    depends_on: ["1-4-1"]
    note: "wiki new — frontmatter 11필드 자동 채움 + obsidian create"
  - id: "1-4-3"
    owner: backend-dev
    status: pending
    depends_on: ["1-4-1"]
    note: "wiki link-check — jsonschema strict v1.1 + obsidian unresolved + orphan"
  - id: "1-4-4"
    owner: backend-dev
    status: pending
    depends_on: ["1-4-1"]
    note: "wiki moc-build — Phase 1-3 13 MOC placeholder 자동 채움, TOPIC 승격 N=3"
  - id: "1-4-5"
    owner: backend-dev
    status: pending
    depends_on: ["1-4-1"]
    note: "wiki toc-suggest — toc-recommendation.md 명세 그대로 구현"
  - id: "1-4-6"
    owner: backend-dev
    status: pending
    depends_on: ["1-4-1", "1-4-2", "1-4-3", "1-4-4", "1-4-5"]
    note: "Makefile 타겟 + scripts/wiki/README.md"
---

# Phase 1-4 Status — CLI 자동화 (`scripts/wiki/wiki.py`)

## 현재 상태: TEAM_SETUP

- **목표**: 4종 CLI 명령(`new`/`link-check`/`moc-build`/`toc-suggest`)을 Python으로 구현. Phase 1-2 schema v1.1과 Phase 1-3 toc-recommendation 명세를 직접 참조하여 구현한다.
- **이전 Phase**: 1-3 (DONE — TYPES 6 + DOMAINS 6 MOC + TOPICS _README + _INDEX 3중 인덱스 + toc-recommendation.md + schema v1.1)
- **다음 Phase**: 1-5 (SSOT skill 어댑터)

## 진입 흐름

1. ✅ FRESH-1 SSOT 0~3 리로드 + VERSION.md v8.3 확인
2. ✅ ENTRY-1~5 (본 status.md 작성 시점)
3. ✅ HR-4 / CHAIN-10 (phase-1-1~3 패턴 동일 레벨 생성)
4. ✅ REFACTOR-2 레지스트리 확인 (700줄 초과 0건)
5. ⏳ TEAM_SETUP — TeamCreate(phase-1-4) + backend-dev(general-purpose/sonnet) + verifier(general-purpose/opus, MODEL-1)
6. ⏳ TASK_SPEC → BUILDING → VERIFYING(G2_wiki) → DONE → NOTIFY-1

## 게이트 상태

- **G0**: SKIP (research=false, 알고리즘 명세는 Phase 1-3에서 완료)
- **G1**: PASS (master-plan §Phase 1-4 + 본 plan.md, 6 task 분해 완료)
- **G2_wiki**: pending — 4 명령 smoke test + link-check 빈 vault PASS + frontmatter 11필드 자동 생성 검증
- **G3**: SKIP (E-4: tester 미스폰. wiki-validation은 G2_wiki 통합)
- **G4**: pending (G2 PASS + Blocker 0 후 전이)

## 산출물 (예정)

- `scripts/wiki/wiki.py` (진입점, ~150~200줄 예상, R-4 400줄 한계)
- `scripts/wiki/lib/__init__.py`
- `scripts/wiki/lib/frontmatter.py` (11필드 자동 채움 · 검증)
- `scripts/wiki/lib/validate.py` (jsonschema strict v1.1 · broken link · orphan)
- `scripts/wiki/lib/moc.py` (MOC placeholder 갱신 · TOPIC 승격 N=3)
- `scripts/wiki/lib/toc.py` (toc-recommendation.md 의사코드 구현)
- `scripts/wiki/README.md`
- `Makefile` 타겟 (`wiki-new`/`wiki-link-check`/`wiki-moc-build`/`wiki-toc-suggest`)
- `docs/phases/phase-1-4/reports/report-backend-dev.md`
- `docs/phases/phase-1-4/reports/report-verifier.md`

## 의존 입력 (Phase 1-1~1-3 산출물)

| 산출물 | 경로 | 사용처 |
|---|---|---|
| schema v1.1 (strict) | `wiki/40_Templates/_schema.json` | T-3 link-check |
| 6 TYPE 템플릿 | `wiki/40_Templates/{TYPE}.md` | T-2 wiki new |
| 13 MOC + _INDEX | `wiki/00_MOC/{TYPES,DOMAINS,TOPICS}/`, `wiki/_INDEX.md` | T-4 moc-build |
| toc-recommendation 명세 | `wiki/30_Constraints/toc-recommendation.md` | T-5 toc-suggest |
| frontmatter-spec | `wiki/30_Constraints/frontmatter-spec.md` | T-2 11필드 정의 |
| naming-convention | `wiki/30_Constraints/naming-convention.md` | T-2 파일명 규약 |
| obsidian CLI | macOS 데스크톱 앱 등록 완료 (Phase 1-1) | T-2/3 obsidian create/unresolved |

## 리스크 (master-plan §6)

- **R-3** `python-frontmatter` 필수 / `obsidiantools` 선택 — backend-dev에게 첫 메시지로 환경 점검 지시
- **R-4** wiki.py 400줄 초과 방지 → T-1에서 lib/ 4분할
- **R-6** TOC LLM 보강은 default false 유지 (휴리스틱 1차 구현)

## next_prompt_suggestion

```
Phase 1-5 (SSOT skill 어댑터)를 시작한다. 이전 Phase 산출물:
- scripts/wiki/wiki.py + lib/{frontmatter,validate,moc,toc}.py
- Makefile 타겟 + scripts/wiki/README.md
- G2_wiki PASS, link-check 빈 vault PASS
진입 절차: Phase 1-1 기준 동일 (FRESH-1 → ENTRY-1 → HR-4 → REFACTOR-2 → TEAM_SETUP).
```
