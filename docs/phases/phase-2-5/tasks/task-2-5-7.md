---
task: "2-5-7"
title: "/wiki 스킬 MOC 자동화 + link-check 게이트 강제"
domain: "[INFRA]"
gap: "G-7 (🟡)"
assignee: "Team Lead (SKILL.md) + backend-dev (wiki.py)"
status: running    # 구현 완료(SKILL.md 2판본 + validate.py). ⚠️ G2_infra E2E(/wiki 신규 노트→MOC 자동갱신) 미수행
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

---

## 검증 결과 — §작업 3 `status` 산정 정합 (2026-08-26, backend-dev)

> ⚠️ **범위**: 본 절은 **§작업 3(`validate.py`)** 만 다룬다. §작업 1·2·4(`SKILL.md` 2판본)는 Team Lead 담당분이다.

**커밋** `350d1e8` — `scripts/wiki/lib/validate.py` (201→222줄) · `scripts/wiki/wiki.py` (160→165줄)

### 변경 내용

| 등급 | 조건 |
|---|---|
| `FAIL` | `violations > 0` |
| `PARTIAL` | `violations == 0 && orphans > 0` |
| `PASS` | 둘 다 0 |

`broken`은 `counts`에만 남는 **정보 지표**로 분리. 주석에 **PO2 §4.2 R-1 근거와 `SKILL.md` Step 9 인용**을 명시했다 — 양측 계약 문서와 코드가 서로를 가리키게 했다.

### exit code 하위호환 — 영향 범위 전수 조사

| 호출부 | 판정 근거 | 영향 |
|---|---|---|
| `Makefile: wiki-link-check` | exit code | **무영향** — `--vault` 미지정(기본 vault)이라 변경 전후 모두 exit 0 |
| `.claude/hooks/` | — | **사용 0건** |
| `deploy_monitoring.sh` | — | **사용 0건** |
| `SKILL.md` Step 9 (개정본) | `--json` + `counts` | exit code 미의존 |
| **PAB-Prove FC-14 커밋 게이트** | **`status` 문자열** (PO1 §4.1 / PO2 §4.2) | exit code 미의존 |

⇒ **핵심**: Prove FC-14는 exit code가 아니라 **`status` 문자열**을 읽는다. 따라서 `status` FAIL→PASS 정정이 곧 **R-1 이행**이며, 계약을 **깨는 게 아니라 고치는 방향**이다.

의미가 바뀌는 유일한 지점은 *broken만 있는 경우: FAIL/exit1 → PASS/exit0* 이고, **그것이 본 작업의 목적 자체**다.

### 하위호환 탈출구 — `--strict-broken`

구 동작(`broken`을 critical로 합산)을 **완전히 복원**하는 플래그를 추가했다(기본값은 신규 규격).
phase-1-5 verifier 보고서 R-3/R-4가 이미 권고했던 형태다. **Prove가 R-1을 수용할지 회답 전이므로 되돌릴 수단을 남긴다** — 협상 여지 보존.

### 실측 (5종 + 회귀 1종)

| 케이스 | status | exit |
|---|---|---|
| 빈 vault | `PASS (empty vault)` | 0 |
| `violations>0` 재현 | `FAIL (violations=1, broken=0, orphans=1)` | 1 |
| `violations=0 && orphans>0` | `PARTIAL (violations=0, broken=6, orphans=1)` | 0 |
| **정본 `PAB-LLMDATA`** | **`PASS (notes=146, violations=0, broken=185, orphans=0)`** | **0** |
| 정본 + `--strict-broken` | `FAIL` (동일 counts) | 1 |
| `make wiki-link-check` 회귀 | 정상 | 0 |

**목표 조건 충족**: 정본이 `violations=0 / orphans=0` 상태에서 **PASS**가 나온다.

> 📌 `broken`은 PO2 기록 시점 **206** → 현재 **185**. 그 사이 MOC 정비·TOPIC 3종 추가로 해소된 분이며 판정에는 무관하다.

### 텍스트 리포트 — 파서 호환 유지

첫 줄 포맷은 **불변**으로 두고(기존 파서 호환) 아래에 한 줄만 덧붙였다:

```
PASS (notes=146, violations=0, broken=185, orphans=0)
  ※ broken 185건은 정보 지표 — 미래 노트 unresolved 는 정상(판정 제외)
```

### 부수 발견 — `.pyc` 추적

본 작업의 자동 커밋(`350d1e8`)에 `scripts/wiki/lib/__pycache__/validate.cpython-312.pyc`가 함께 들어갔다.
저장소에 **`.pyc`가 이미 추적 중이었고 `.gitignore` 규칙이 없었기** 때문이다.
→ `1cae4a8`(Team Lead)에서 6건 인덱스 제거 + `.gitignore` 규칙 추가로 해소. 오염 경로 폐쇄 실증 완료.

---

## ⚠️ 미수행 — G2_infra E2E 검증 (2026-08-26 시점)

구현은 완료됐으나 **정의서 §검증의 첫 항목이 아직 실행되지 않았다**:

> `/wiki` 신규 노트 1건 생성 → **MOC 자동 갱신 확인**(수동 실행 없이 orphan 0 유지)

**의도적으로 미실행**이다. 이 검증은 **정본 vault에 실제 노트를 만드는 것**이라 시험용 더미 노트를 지식베이스에 남기게 된다. `PROJECT.md` §6이 *"이 프로젝트는 지식 자산을 다룬다"*고 명시하므로, 검증 편의로 정본을 오염시키지 않는다.

⇒ **다음에 사용자가 실제로 `/wiki`를 쓸 때 자연스럽게 검증**한다. 그때 확인할 것:
- Step 9.5가 **실제로 `make wiki-moc-build`를 실행**하는가 (안내 문자열만 출력하고 넘어가지 않는가)
- 실행 후 `link-check`가 `orphans=0`을 유지하는가
- `violations > 0`이면 Step 9 게이트가 **중단·보고**하는가

> 이 항목이 남아 있는 한 T-7은 `completed`가 아니다. **구현했다는 사실과 동작한다는 사실은 다르다** — 오늘 T-3에서 "백업했다 ≠ 복구된다"로 정리한 것과 같은 구분이다.

---

## ⭐ 후속 발견 (2026-08-26, PAB-Prove PO3 제보) — **T-7 자동화가 절반만 돈다**

`run_moc_build`가 **TYPES·DOMAINS만 갱신하고 기존 TOPIC MOC을 누락**한다.

```python
# scripts/wiki/lib/moc.py — run_moc_build
for name in MOC_TYPE_NAMES:   _process_moc(vault / f"00_MOC/TYPES/{name}.md", ...)
for name in MOC_DOMAIN_NAMES: _process_moc(vault / f"00_MOC/DOMAINS/{name}.md", ...)
# TOPICS/ 는 promote_topic() 으로 신규 생성만 — 기존 갱신 루프가 없다
```

**정본에 기존 TOPIC MOC 22건**(`_README.md` 제외)이 있고 **전부 생성 시점에 얼어붙어 있다.** 같은 TOPIC의 노트가 추가돼도 링크가 붙지 않는다. `moc-build --dry-run`에 기존 TOPIC 갱신 항목 **0건**으로 실증됨.

### 왜 T-7 항목인가

본 Task가 신설한 **Step 9.5(MOC 필수 실행)** 는 orphan 재발 차단이 목적이었다. 그런데 그 실행이 TOPIC은 갱신하지 않는다 — **자동화를 켰는데 절반만 돈다.**

> **"자동화를 넣었다"가 "자동화가 다 돈다"는 아니다.** `orphans=0`이 초록 불로 보이지만 그 지표는 TYPES·DOMAINS 등재만 보고 TOPIC 정체는 보지 않는다. **초록 불이 켜진 지표가 문제를 가리고 있었다** — 어제 여섯 번 마주친 그 형태다.

⇒ **우리 지표로는 영원히 안 보였을 결함**이며, PAB-Prove가 자기 fork에서 고치고(`4067440`, 2026-08-15) 알려주지 않았으면 몰랐다.

### 후속 작업 (다음 세션, backend-dev 위임 — `scripts/` = `code_dirs`)

1. **기존 TOPIC MOC 갱신 루프 추가** — Prove `4067440` 수정분 **표적 이식**. ⚠️ 단순 복사 불가: 저쪽은 `lib/paths.py` 상수 참조로 리팩터돼 **228줄 차이**
2. `TOPICS/_README.md` 제외 유지 (우리 FIX-3 — placeholder 명세 노트라 폴백 링크 섹션 없음)
3. **22건 일괄 갱신 후 재측정**
4. **판정 모집단 변경과 함께** 처리 — `collect_notes()`를 화이트리스트(`10_Notes`+`15_Sources`)로. 현행은 `00_MOC` 38건을 `notes`로 세는데, **생성물에 노트 규격을 요구하는 범주 오류**다 (PO4 §3.2 결정)
5. Prove `4067440`이 함께 담은 **TOPIC 임계 계수 정정**(`15_Sources` 중복 계상 제거) 판단 — R-9로 상세 요청 중

> ⚠️ **미해결 이상 관측**: `link-check` 측정 중 **단 1회** `broken: 0`이 출력됐고 이후 **13회 재실행에서 전부 185**로 재현되지 않았다. 오독 가능성이 높으나 확정하지 못했다. **FC-14가 `status`를 읽는 이상 비결정성은 계약 문제**이므로 모집단 변경 작업 시 결정성을 함께 확인한다 (PO4 R-8로 Prove에도 관측 요청).

### 🔴 이식 지침 6종 (PO5·PO6 확정) — **어기면 각각 이런 일이 난다**

PAB-Prove가 **실제로 밟고 나서 고친** 함정들이다. 각각은 옳아 보이는 선택이라 근거 없이는 반드시 반대로 간다.

| # | 지침 | 어기면 |
|:-:|---|---|
| 1 | **A(갱신 루프)에 threshold 걸지 말 것** — 승격 문턱은 *"새 MOC를 만들 자격"*이지 기존 MOC 갱신과 무관 | 저빈도 TOPIC이 다시 얼어붙어 **결함 부분 재현**. "고쳤다"고 기록되는데 절반만 고쳐진다 |
| 2 | **B(승격 계수)는 계수만 비-SOURCE, 멤버는 전 노트** | 승격 직후 MOC에서 SOURCE가 빠지는데 **다음 `run_moc_build`(A)가 전 노트로 다시 채운다 → 1회차 ≠ 2회차 = 진동.** A 없이는 안 드러나고 A를 넣는 순간 실재화 |
| 3 | **판정 모집단 축소는 `link-check` 한정.** `collect_notes_with_meta()`(moc-build 수집 모수) 무변경 | MOC에서 노트가 빠져 **orphan을 스스로 만들어낸다** |
| 4 | **참조원은 전 vault 유지** — 판정 대상만 좁힌다 | `_INDEX.md`(17링크, vault 루트)·`30_Constraints`(102링크)가 빠져 **119링크 소실 → orphan 급증.** `orphans==0`이 편입 게이트라 **게이트 오탐** |
| 5 | `TOPICS/_README.md` 제외 유지 (우리 FIX-3) | placeholder 명세 노트라 폴백 링크 섹션이 없어 오작동 |
| 6 | 이식 후 **`moc-build` 2회 연속 실행 → 2회차 `no changes`** 확인 | **idempotent 미검증 — 2번의 진동을 못 잡는다.** 이것이 W-2 회귀 시험의 본체 |

> ⚠️ **1번과 2번은 "각각 시험하면 둘 다 통과하고 합쳐야 깨지는" 종류다.** 개별 검증으로는 안 나온다. 6번을 반드시 돌릴 것.

### 판정 모집단 최종 확정 (PO6 §3·§4)

| 축 | 범위 | 값 |
|---|---|---:|
| **판정 대상** (`notes`, 스키마·orphan 판정) | `10_Notes` + `15_Sources`, **`_` 접두 디렉터리 하위 제외** | **101** |
| **참조원** (링크 수집원) | **전 vault** (`00_MOC`·`30_Constraints`·`_INDEX.md`·`99_Inbox` 포함) | — |

- `_` 접두 제외 근거: `10_Notes/_old/2026-05-02_karpathy_llm_wiki_v1_backup.md` 1건. **제외하지 않으면 영구 orphan으로 상주해 `orphans==0` 게이트를 영구히 막는다** — 백업 파일은 MOC에 등재할 수도 없고 삭제할 이유도 없다
- 규칙을 `_` 접두 일반화로 바꾸면 기존 `_attachments` 특수 케이스도 흡수된다
- 이 값으로 **PAB-Prove 판정값(101)과 완전 일치**하고, Observer `#26` 화이트리스트와도 정렬된다
