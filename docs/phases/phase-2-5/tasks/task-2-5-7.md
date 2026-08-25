---
task: "2-5-7"
title: "/wiki 스킬 MOC 자동화 + link-check 게이트 강제"
domain: "[INFRA]"
gap: "G-7 (🟡)"
assignee: "Team Lead (SKILL.md) + backend-dev (wiki.py)"
status: pending
depends_on: []
---

# Task 2-5-7: `/wiki` 스킬 MOC 자동화 + link-check 게이트 강제

## 목표

`/wiki` 스킬이 노트를 생성한 뒤 **MOC 갱신과 검증을 실제로 실행**하도록 만들어, orphan 재발과 규격 위반 유입을 차단한다.

## 배경

PAB-Prove PO1 §4.4가 정본 vault의 link-check FAIL(critical 1 + orphan 8)을 보고했고, **8건 전부 `/wiki` 스킬 산출물**임이 확인됐다. 정비 2건은 2026-08-26 적용 완료(orphan 8→0)했으나 **생성 경로를 고치지 않으면 재발한다**.

확인된 사실 (`docs/interop/pab-prove/260826-PO2-...md` §5.2):

| 항목 | 실태 | 근거 |
|---|---|---|
| 파일 write | LLM이 `Write` 도구로 직접 — `wiki.py` 미경유 | `SKILL.md:6` allowed-tools, Step 8a/8b(`:202-213`) |
| MOC 갱신 | **수동 안내 문자열만** — 실행 단계 아님 | `SKILL.md:225-237` Step 10은 출력 템플릿 |
| link-check | Step 9에 명령은 있으나 **결과가 게이트가 아님** | `SKILL.md:218-224` |

> ⚠️ PO1이 말한 "vault 가드 4겹 우회"는 **사실이 아니다** — 그 가드는 PAB-Prove 저장소 전용 코드이고 PAB-obsidian에는 **미구현**이다(`scripts/wiki/lib/`에 `paths.py`·`vault.py` 부재). 우회가 아니라 없는 것이며, 가드 계층 신설은 본 Task 범위 밖이다(PO2 §5.4 — upstream 편입 방향을 별도 판단).

## 작업

1. **Step 10 승격** — 안내 문자열 → **실제 `make wiki-moc-build` 실행 단계**로. 실행 결과(갱신 MOC 수·TOPIC 승격)를 사용자 응답에 포함
2. **Step 9 게이트화** — `link-check` 결과를 판정에 사용. `violations > 0` 이면 **중단 + 보고**(노트는 남기되 사용자에게 규격 위반 명시)
3. **`status` 산정 규격 정합** (`scripts/wiki/lib/validate.py`) — 현행은 `broken>0`이면 `FAIL`. 그러나 `SKILL.md:220`이 규정한 대로 broken(미래 노트 unresolved)은 **정상 동작**이다. 판정을 `violations`·`orphans` 기준으로 정렬하고 `broken`은 정보 지표로 분리
   - PO2 §4.2에서 PAB-Prove에 동일 정렬을 요청함(R-1) — 양측 판정 근거를 `counts`로 통일
4. **플러그인 판본 동기화** — `skills/wiki/SKILL.md`(`/pab:wiki`)에 1~2 동일 반영

## 담당 분리 (HR-1)

| 대상 | 담당 | 근거 |
|---|---|---|
| `.claude/skills/wiki/SKILL.md` · `skills/wiki/SKILL.md` | **Team Lead 직접** | `PROJECT.md` code_dirs = `scripts` — 스킬 문서는 가드 대상 밖 |
| `scripts/wiki/lib/validate.py` | **backend-dev 위임** | code_dirs 내부 (HR-1) |

## 산출물

- 개정된 `SKILL.md` 2판본 (Step 9 게이트 + Step 10 실행)
- `validate.py` status 산정 정합 패치

## 검증 (G2_infra)

- `/wiki` 신규 노트 1건 생성 → **MOC 자동 갱신 확인**(수동 실행 없이 orphan 0 유지)
- `violations > 0` 상황 재현 → 스킬이 중단·보고하는지 확인
- 정비 후 정본 `link-check`: `violations=0` · `orphans=0` 유지

## 비고

- 본 Task는 PO1 §4.4 지적의 **최소 대응**이다. Prove가 제안한 "저장 계층 통합"(스킬이 Prove `safe_write_*` 경유)은 **범위 밖** — 정본 authority가 상대 저장소 코드에 의존하는 역전이 생긴다(PO2 §5.4). 가드 계층은 **원산지(PAB-obsidian)로 upstream 편입**하는 방향을 대안으로 제시했고, Prove 확정 통지 후 별도 판단한다
- **C-2 idempotent 요건**: 편입 후 `/wiki`와 Prove 워커가 **둘 다** `moc-build`를 호출한다. 두 판본이 같은 출력을 내야 진동하지 않는다 (PO2 §6.3 C-2, R-3으로 Prove에 확인 요청 중)
