# Phase Chain 템플릿 (Phase Chain Template)

> **적용**: 복수 Phase 순차 실행 (phase-chain.md)
> **작성 주체**: Team Lead

---

## 사용법

1. 본 파일을 `docs/phases/phase-chain-{name}.md`로 복사한다.
2. YAML의 `phases` 배열에 실행할 Phase ID를 순서대로 기입한다 (각 Phase의 master-plan은 별도 작성 — master-plan-template.md).
3. 각 Phase DONE마다 `current_index`를 +1 갱신하고 `/clear` 후 §8.4 절차로 재개한다.
4. 중단은 `/abort` — 범위 선택에 따라 `status`가 `aborted`로 기록된다.

---

## YAML 정본 (phase-chain.md §2)

```yaml
---
chain_name: "{체인 이름}"
phases: ["{N}-1", "{N}-2", "{N}-3"]   # 실행 순서대로
current_index: 0                       # 현재 실행 중인 Phase 인덱스 (DONE 시 +1)
status: "pending"                      # pending | running | completed | aborted
ssot_version: "{SSOT 버전}"
created_at: "{ISO 8601}"
---
```

## 진행 기록

| # | Phase | 시작 | DONE | 비고 (재계획·Tech Debt·중단 등) |
|---|-------|------|------|--------------------------------|
| 0 | {N}-1 | | | |

## 체인 종료 점검

- [ ] 전 Phase DONE (또는 aborted 사유 기록)
- [ ] 각 Phase의 final-summary-report 존재 (CHAIN-11)
- [ ] Chain `status: "completed"` 갱신 + Telegram 알림 (NOTIFY-1)
