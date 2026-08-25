# Master Plan 템플릿 (Master Plan Template)

> **버전**: 1.0 | **생성일**: 2026-07-06 (v1.5 Batch 1)
> **적용 Step**: AutoCycle Step 0 PASS 직후 (사용자 주도) / CHAIN-13 로딩 직후 (AI handoff)
> **작성 주체**: Team Lead
> **참조**: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md §Step-0 Branch`, `3-workflow.md §3.0(15단계 정본)·§11(필수 체크리스트)`

---

## 사용법

1. 본 파일을 `docs/phases/phase-{N}-master-plan.md`로 복사 (CHAIN-10 경로 규칙).
2. YAML 헤더의 필수 필드를 채운다 — `initiator` 누락은 CRITICAL 위반.
3. §1~§7을 작성하되, **§11 체크리스트(3-workflow.md)의 필수 포함 항목 4종을 §4~§6에서 충족**시킨다.
4. 작성 후 3-workflow.md §11.3 사후 검증을 수행한다.

---

## YAML 헤더 정본

```yaml
---
phase: "{N}"
name: "{Phase 이름}"
initiator: "user"                  # 필수: "user" | "ai-handoff"
prompt_quality: "full"             # user 시 필수: "full" | "fast-path" / ai-handoff 시 "n/a"
pre_draft_ref: "docs/phases/pre/phase-{N}-pre-draft.md"   # user + full 시 필수
chain_ref: null                    # Phase Chain 소속 시: "docs/phases/phase-chain-{name}.md"
ssot_version: "v8.2-renewal-6th"
created_at: "{ISO 8601}"
---
```

| 필드 | initiator = user | initiator = ai-handoff |
|------|------------------|------------------------|
| `prompt_quality` | "full" 또는 "fast-path" 필수 | "n/a" |
| `pre_draft_ref` | full 일 때 필수 | 불필요 |
| Step 0 진입 | 필수 | 자동 스킵 |
| CHAIN-13 자동 로딩 | 선택 | 필수 (직전 최대 3 Phase의 §3·§5·§7) |

---

## §1 목적 · 원본 요청

- **원본 프롬프트**: (사용자 요청 원문 또는 직전 final-report §7 Next Prompt 채택안)
- **목적 1줄**:
- **범위 밖(Non-goals)**:

## §2 선행 컨텍스트

- CHAIN-12: 이전 tech-debt-report의 `carryover_to` 항목 → 선행 해결 여부 판단
- CHAIN-13 (ai-handoff): 직전 Phase 달성 수치·보완점 요약
- CHAIN-5: 이전 final-summary-report 이관 항목

## §3 KPI (development-plan 연계)

| KPI | 목표값 | 측정법 | Step 8 대조 방법 |
|-----|--------|--------|------------------|
| | | | |

## §4 Sub-Phase 구성 (CHAIN-7: 전 Sub-Phase 게이트 명시)

| Sub-Phase | 내용 | Task 도메인 → 담당 (ASSIGN-1) | 게이트 |
|-----------|------|------------------------------|--------|
| {N}-1 | | `[BE]`→backend-dev 등 | G1/G2/… |

## §5 HR-5 리팩토링 점검 (REFACTOR-2)

- 레지스트리(`docs/SSOT/refactoring/refactoring-registry.md`) 확인 결과: (700줄 초과 파일 Lv1/Lv2 편성 또는 "해당 없음" 명시)

## §6 Worktree 판정 (WT-1)

- 병렬 BUILDING 트랙 수 N = ___ → N ≥ 2 시 worktree 격리 필수 (`/worktree setup`)

## §7 완료 보고 계획 (CHAIN-11)

- `phase-{N}-final-summary-report.md` 작성 예정 — master-final-report.md 템플릿 6섹션 + §8 verifier 검증

---

**작성 후 점검**: 3-workflow.md §11.1(사전 4항목)·§11.2(본문 4항목)·§11.3(사후 대조) 전부 수행했는가?
