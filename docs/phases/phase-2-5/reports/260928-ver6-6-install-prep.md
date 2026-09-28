# SSOT ver6-6 설치 준비 — 검증 결과 및 실행 절차

**작성**: 2026-09-28 · **작성자**: Team Lead (Obsidian0914) · **상대 세션**: Nexus-0928
**대상 번들**: `~/pab-dist/ver6-6-260928/pab-ssot-bundle/` (고정 사본, **2차 수정판 Nexus 커밋 `48f6352`**, 22:01 갱신)
**재검증**: 번들이 2회 갱신되어 그때마다 재확인했다 — 손실 64건 불변, `scripts/monitoring`·`scripts/wiki` 매니페스트 0건 유지, 게이트 `[DONE]` 통과
**현재**: ver6-2 라인 `v8.2-renewal-6th` → **ver6-6**

> 본 문서의 모든 판정은 번들 **코드를 직접 읽어** 확인한 것이다. Nexus 회신 중 한 건은 실제 코드와 달라 정정했다(§2 ③).

---

## 1. 결론

**설치 가능.** 남은 차단은 **Phase 2-5를 DONE으로 닫는 것 하나뿐**이며 이는 범위 판단(사용자 결정)이다.
**`docs/SSOT/` 64건이 삭제되지만 이관해야 할 프로젝트 고유 내용은 없다** — 근거는 §3.

---

## 2. 검증된 사실

### ① 상태 게이트 — DONE 필수, BLOCKED 불가

`reinstall.sh`는 `docs/phases` 중 **최근 수정된** `*status.md`의 `current_state`를 읽어 `IDLE|DONE|''` 만 통과시키고, 그 외에는 **`--dry-run`조차 거부**한다. BLOCKED도 거부다 → **LOCK-2 일시정지 경로는 쓸 수 없다.**

### ② 인라인 주석 파싱 — 초판 결함, 수정 확인

초판(27442 bytes)은 `#` 주석을 자르지 않아 `current_state: DONE   # …` 를 거부했다. 원인은 `state-transition-guard.sh`에만 있던 `sed 's/#.*$//'`(ver6-2 Phase 9-4 FB-01-3ⓑ)가 형제 `lock1-guard.sh`에 없었고 신규 `reinstall.sh`가 그 파싱을 물려받은 것.
**Nexus 수정판(30090 bytes, 21:48)에서 절단이 들어갔고 우리 파일로 재시뮬레이션해 `[BUILDING]` 정상 파싱을 확인했다.** → 주석을 지울 필요 없다.

### ③ 🔴 Nexus 회신 정정 — `policy/model-assignment.md`는 보존되지 않는다

Nexus는 "두 목록에 없어 보존됩니다"라고 했으나 **삭제된다.** `reinstall.sh`는 `docs/SSOT/*`를 파일 단위 후보에서 제외한 뒤(주석: *"규칙으로 디렉터리째 지우므로"*) 마지막에 **`rm -rf docs/SSOT` 를 무조건** 실행한다. 목록 부재는 보호가 아니라 *복원되지 않음*을 뜻한다.
⚠️ 게다가 `--dry-run`의 「복원되지 않음」 보고는 `DELETE_LIST − MANIFEST`로 계산되고 `docs/SSOT/*`는 애초에 `DELETE_LIST`에서 빠지므로, **dry-run이 이 손실을 경고하지 못한다.** 그래서 손실 목록을 직접 계산했다(§3).
"고친 파일은 보존" 로직도 `.claude/`·`scripts/` 에만 적용되고 `docs/SSOT/` 에는 적용되지 않는다.

**Nexus 수용(2026-09-28)** — *"저는 `policy/model-assignment.md`를 저장소 루트의 `policy/`로 잘못 보고 「보존」이라 답했다. 실제 경로는 `docs/SSOT/policy/`이고 삭제되고 복원되지 않는다. 정확한 지적이다."*

**dry-run 맹점 — 2차 수정판(커밋 `48f6352`, 22:01)에서 닫혔다.** 갱신된 `reinstall.sh` 438~460행에 `ORPHAN_REPORT` 가 있고, 계산식이 본 문서 §3 과 **동일**하다(대상 `docs/SSOT` 실파일 − 번들 MANIFEST 의 `docs/SSOT/*`, seed registry 제외). Nexus 는 기존 표시 문구(「구 install 당시 있었던 …」)가 *"삭제되고 복원되지 않는다"* 는 뜻을 전하지 못한 것이 문제였다며 문구 수정을 자기 쪽 사용자에게 올리겠다고 회신했다.
⚠️ 다만 **우리가 최초 분석한 판(27442 bytes)에 이 보고가 있었는지는 이제 확인할 수 없다** — 파일이 두 차례 교체됐다. 현재 판에는 있고 계산이 맞다는 것만 실측으로 말할 수 있다.

### ④ 보존/삭제 확정 (코드 근거)

| 대상 | 판정 | 근거 |
|---|---|---|
| `PROJECT.md` · `hooks.env` · `settings.local.json` · `pointer-map.md` · `WORKFLOW/refactoring/refactoring-registry.md` | ✅ **절대 보존** | `reinstall.sh:138` 하드 목록 (registry 는 2차 수정판 E2 에서 추가) |
| `scripts/monitoring/` (7파일) · `scripts/wiki/` | ✅ **보존** | 두 매니페스트 부재 + `KEPT_CUSTOM` 로직이 `scripts/` 비번들 파일을 남김 |
| `docs/phases/` · `docs/history/` · `docs/handoff/` | ✅ 보존 | 두 매니페스트 0건 |
| `.claude/CLAUDE.md` · `.claude/settings.json` | 🔴 번들 판으로 **덮임** | MANIFEST 등재 |
| `docs/SSOT/**` | 🔴 **통째 삭제** (64건 복원 없음) | `reinstall.sh:559` `rm -rf` |

우리 저장소엔 루트 `README.md`가 없어 Nexus가 경고한 함정은 해당 없다.

---

## 3. 이관 판정 — 옮길 프로젝트 고유 내용은 없다

**`docs/SSOT/` 77파일 → 새 번들 42파일. 삭제되고 복원되지 않는 것 64건.** 전수 확인 결과:

| 파일 | 판정 | 근거 |
|---|---|---|
| `1-project.md` (628줄) | 이관 불필요 | PAB-obsidian·vault·CouchDB 언급 **0건**, 최종수정 2026-02-28(이식 이전). §1이 스스로 *"Personal AI Brain v3 (예시 — 실제 프로젝트 정보는 루트 PROJECT.md §1)"* 라고 적고 있다 |
| `2-architecture.md` (424줄) | 이관 불필요 | 우리 언급 0건, 번들 원본 그대로 |
| `policy/model-assignment.md` (131줄) | 이관 불필요 | 프레임워크 정책(우리 커스텀 아님). ver6-6엔 동명 파일이 없고 모델 지침이 **13개 파일에 분산** — 형태 대체 |
| 나머지 61건 | 이관 불필요 | PERSONA·TEMPLATES·SUB-SSOT·ROLES 등 전부 프레임워크 |

**64건 전부 git 추적본**이라 필요 시 `git restore <경로>`로 개별 복원 가능하다.
🔴 **통째 복원 금지** (INSTALL §7.2 ⓑ) — `git restore docs/SSOT`를 하면 구세대 파일이 ver6-6 판과 섞인다. 반드시 개별 경로만.

### `.claude/CLAUDE.md` 도 이관 불필요

덮이지만, 우리 고유 내용은 **이미 보존되는 `PROJECT.md`에 중복 기록**돼 있다 — 게이트 예외는 §4(E-1~E-4), 운영 스크립트는 §5. 유일한 공백이던 `scripts/wiki/` 행은 **본 준비 작업에서 PROJECT.md §5에 추가했다.**

### 실제 이관 대상 — `settings.json` 2건뿐

`.claude/settings.json`이 덮이므로 번들 판에 없는 우리 설정만 `settings.local.json`(보존됨)으로 옮긴다.

- `permissions.allow` += `Bash(just:*)` (1건 — 나머지 11건은 번들 판이나 local에 이미 있음)
- `autoCompact: "disabled"`

스테이징 완료: `settings.local.json.staged` (allow 23 → 24). **권한 파일이라 적용은 사용자 승인 후.**

---

## 4. 실행 절차

```
[사전] git status 청결 확인          ← reinstall 전제
       settings.local.json 이관 적용 (승인 후)
[1]    status.md:8 → current_state: DONE   (인라인 주석 유지 가능)
[2]    Claude 세션 닫고 터미널에서:
       B=~/pab-dist/ver6-6-260928/pab-ssot-bundle
       bash $B/reinstall.sh ~/WORKS/PAB-obsidian --dry-run
         → 확인: 삭제 목록에 scripts/monitoring·scripts/wiki 없음
         → 확인: 「docs/SSOT/ 전체(디렉터리) — 존재, 삭제 대상」
         → 확인: 백업 tar 경로 기록
[3]    bash $B/reinstall.sh ~/WORKS/PAB-obsidian
[4]    git restore docs/phases/phase-2-5/phase-2-5-status.md   ← 줄 전체 원문 복원
[5]    git status 로 위조 흔적 0 확인
[6]    PROJECT.md ssot_version → "ver6-6"  (정본: 새 docs/SSOT/entrypoint.md 머리 **SSOT 버전**:)
       /project-config sync → /project-config check
[7]    /ssot-reload
```

⚠️ **autocommit 창** — `pab_git_autocommit_local.sh`는 `git add -A`로 전부 스테이징하고 cron은 `17 */2 * * *`(짝수시 :17)다. 위조된 DONE이 그 순간 트리에 있으면 **PUBLIC 저장소에 커밋·푸시된다.** crontab 쓰기는 BL-3로 차단 상태라 끌 수 없으므로 **:17 발화 직후에 시작해 2시간 안에 [1]~[5]를 끝낸다.**

---

## 5. 설치 후 대조 항목

| # | 항목 |
|---|---|
| 1 | **상태 코드 20종 → 17종.** `auto_fix_count` 폐지, `token_budget` 7키 재정의 → 기존 status.md 칸 대조 |
| 2 | ver6-6 VP의 **G2 판정이 「등급 산출」 표**(사실 4칸 I·R·D·V → 등급)로 바뀜 → `phase-2-exceptions.md`가 옛 판정 표현을 인용하는지 대조 |
| 3 | `state-transition-guard`가 무효 전이에 **경고만 하고 막지 않음**(exit 0) → 진행 중 산출물 차단 없음 |
| 4 | ver6-2 이월 7항목 — **Nexus 1차 대조 수신(2026-09-28), 전부 「상태 미확인」으로 유지 권고**. 아래 표 |
| 5 | `UPGRADE.md` 폐지 → 절차 정본은 `INSTALL.md` §7 |

### 5.1 ver6-2 이월 7항목 — Nexus 1차 대조 (2026-09-28)

> Nexus 원문: *"항목별로 추적한 기록이 없어서 ver6-6 코드와 문서를 짧게 확인한 정도. 「해소 확정」이 아니니 설치 후 확인 목록에서 빼지 말고 「상태 미확인」으로 남기길 권한다."*

| 항목 | Nexus 판단 | 우리 검증 |
|---|---|---|
| **D8-1** `--arm` 폴링 rc 폐기 | **미해소로 보임** | 🔴 **미해소 확정** — 직접 확인: ver6-6 `zombie_watch_poll.sh:52,55` 가 `_zw_check_one … \|\| true`. pane/inproc 2경로로 분리됐으나 rc 폐기는 그대로 |
| **V-2** cmd_once 회귀 케이스 | 해소 가능성 높음 (selftest 21건·regression 8건, regression 파일 분리) | 미검증 — D-1 필터 케이스 여부는 Nexus도 미확인 |
| **T-5** shell prompt 정규식 회귀 수단 | 부분 해소 (`zombie_check_selftest` 가 tmux 있으면 `_zc_pane_tail_real` 실제 실행, 134·157행) | 미검증 — 정규식 오탐(`$` 종결 문장) 개선 여부 불명 |
| **V-5** self-test 스텁 3종 미복원 | 미확인 | 미검증 |
| **FB-01-2** shutdown_approved 잔존 pane 억제 | 미확인 | 미검증 |
| **FB-01-4** 워처 로그 타임스탬프 | 미확인 | 미검증 |
| **FB-01-6** 다중 프로젝트 전역 상태 혼선 | 미확인 | 미검증 |

→ **7항목 전부 확인 목록에 남긴다.** 정식 대조가 필요하면 Nexus 측 별도 작업으로 올린다고 회신받았다.

---

## 6. 미결

- 🔴 **Phase 2-5 DONE 처리 방식** — 잔여 T-4(Prove 게이트 대기)·T-6(T-4 의존)·T-7(승인 대기) + `G3_smoke`·`G4` PENDING. 완료가 아니라 **범위 축소·이관으로 닫는 판단**이 필요하며 사용자 결정 사항
- `settings.local.json` 이관 적용 승인
- LOCK-1 우회 기록 — 팀원 0명이라 LOCK-1이 실제로 막는 위험(팀원이 바뀐 규칙 위에서 작업)은 없으나, LOCK-5 취지상 우회 사실은 남긴다(본 문서가 그 기록)

---

## 부록 — 삭제·복원 없는 64건 (`docs/SSOT/` 기준 상대경로)

- `0-entrypoint.md`
- `1-project.md`
- `2-architecture.md`
- `3-workflow.md`
- `4-event-protocol.md`
- `5-automation.md`
- `core/6-rules-index.md`
- `core/7-shared-definitions.md`
- `core/README.md`
- `GUIDE.md`
- `infra/git-subtree-guide.md`
- `infra/git-worktree-guide.md`
- `mcp-design/mcp-server-design.md`
- `MIGRATION-6-1-to-6-2.md`
- `PERSONA/BACKEND.md`
- `PERSONA/FRONTEND.md`
- `PERSONA/LEADER.md`
- `PERSONA/PLANNER.md`
- `PERSONA/QA.md`
- `PERSONA/README.md`
- `PERSONA/RESEARCH_ANALYST.md`
- `PERSONA/RESEARCH_ARCHITECT.md`
- `PERSONA/RESEARCH_LEAD.md`
- `policy/model-assignment.md`
- `QUALITY/10-persona-qc.md`
- `refactoring/refactoring-registry.md`
- `refactoring/refactoring-rules.md`
- `ROLES/README.md`
- `ROLES/research-analyst.md`
- `ROLES/research-architect.md`
- `ROLES/research-lead.md`
- `STRUCTURE.md`
- `SUB-SSOT/0-sub-ssot-index.md`
- `SUB-SSOT/DEV/0-dev-entrypoint.md`
- `SUB-SSOT/DEV/1-fn-procedure.md`
- `SUB-SSOT/DEV/2-ai-execution-rules.md`
- `SUB-SSOT/DEV/3-failure-modes.md`
- `SUB-SSOT/PLANNER/0-planner-entrypoint.md`
- `SUB-SSOT/PLANNER/1-planning-procedure.md`
- `SUB-SSOT/RESEARCH/0-research-entrypoint.md`
- `SUB-SSOT/RESEARCH/1-lead-procedure.md`
- `SUB-SSOT/RESEARCH/2-architect-procedure.md`
- `SUB-SSOT/RESEARCH/3-analyst-procedure.md`
- `SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md`
- `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md`
- `SUB-SSOT/TEAM-LEAD/2-lifecycle-procedure.md`
- `SUB-SSOT/TEAM-LEAD/3-leader-contract.md`
- `SUB-SSOT/TESTER/0-tester-entrypoint.md`
- `SUB-SSOT/TESTER/1-testing-procedure.md`
- `SUB-SSOT/VERIFIER/0-verifier-entrypoint.md`
- `SUB-SSOT/VERIFIER/1-verification-procedure.md`
- `TEMPLATES/development-plan-template.md`
- `TEMPLATES/event-log-template.md`
- `TEMPLATES/master-final-report.md`
- `TEMPLATES/phase-achievement-report.md`
- `TEMPLATES/prompt-alignment-check.md`
- `TEMPLATES/research-report-template.md`
- `TEMPLATES/tech-debt-report.md`
- `tests/index.md`
- `tests/test-phase-mapping.md`
- `tests/test-suite-report.md`
- `tests/test-tuning-guide.md`
- `UPGRADE.md`
- `VERSION.md`
