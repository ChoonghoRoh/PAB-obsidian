# Master Plan 템플릿 (Master Plan Template)

> **작성 주체**: Team Lead

---

## 사용법

1. 본 파일을 `docs/phases/phase-{N}-master-plan.md`로 복사 (CHAIN-10 경로 규칙).
2. YAML 헤더의 필드를 채운다.
3. §1~§7을 작성하되, **§1 체크리스트(master-plan.md)의 필수 포함 항목을 §4~§6에서 충족**시킨다.
4. 작성 후 master-plan.md §1.3 사후 검증을 수행한다.

---

## YAML 헤더 정본

```yaml
---
phase: "{N}"
name: "{Phase 이름}"
prompt_quality: "full"             # /plan 사용 시: "full" | "fast-path"
pre_draft_ref: "docs/phases/pre/phase-{N}-pre-draft.md"   # full 시 필수
chain_ref: null                    # Phase Chain 소속 시: "docs/phases/phase-chain-{name}.md"
ssot_version: "{SSOT 버전}"
created_at: "{ISO 8601}"
---
```

---

## §1 목적 · 원본 요청

- **원본 프롬프트**: (사용자 요청 원문)
- **목적 1줄**:
- **범위 밖(Non-goals)**:

## §2 선행 컨텍스트

- CHAIN-5: 이전 final-summary-report 이관 항목

## §3 KPI

| KPI | 목표값 | 측정법 |
|-----|--------|--------|
| | | |

## §4 Sub-Phase 구성 (CHAIN-7: 전 Sub-Phase 게이트 명시)

| Sub-Phase | 내용 | Task 도메인 → 담당 (ASSIGN-1) | 게이트 |
|-----------|------|------------------------------|--------|
| {N}-1 | | `[BE]`→backend-dev 등 | G1/G2/… |

## §5 HR-5 리팩토링 점검 (REFACTOR-2)

- 레지스트리(`docs/SSOT/WORKFLOW/refactoring/refactoring-registry.md`) 확인 결과: (700줄 초과 파일 Lv1 분리 편성 또는 "해당 없음" 명시)

## §6 Worktree 판정 (WT-1)

- 병렬 BUILDING 트랙 수 N = ___ → N ≥ 2 시 worktree 격리 필수 (`/worktree setup`)

## §7 완료 보고 계획 (CHAIN-11)

- `phase-{N}-final-summary-report.md` 작성 예정

---

**작성 후 점검**: master-plan.md §1.1(사전)·§1.2(본문)·§1.3(사후 대조) 전부 수행했는가?
