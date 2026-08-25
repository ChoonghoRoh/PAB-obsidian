# SSOT 업그레이드 가이드 (UPGRADE.md)

> **버전**: 1.0 | **작성일**: 2026-07-06
> **목적**: 번들(PAB-claude)의 SSOT가 개정되었을 때, 이식된 각 프로젝트의 SSOT를 **프로젝트별 커스터마이징을 보존하면서** 최신으로 갱신하는 표준 절차 정의.
> **신규 설치(첫 이식)는 본 문서가 아니라 번들 루트 `INSTALL.md`가 정본**이다 — `INSTALL.md`는 배포 대상이 아니므로(이식 시 대상 프로젝트에 복사되지 않음) 번들 원본에서만 열람 가능하다. 본 문서는 **이미 이식된 프로젝트의 갱신** 전용이다.

---

## 1. 파일 분류 — 프레임워크 vs 프로젝트

업그레이드의 핵심 원칙: **프레임워크 파일은 덮어쓰고, 프로젝트 파일은 보존한다.**

### 1.1 프레임워크 파일 (업그레이드 시 덮어씀)

| 경로 | 내용 |
|------|------|
| `docs/SSOT/0-entrypoint.md` | 진입점·역할 체크리스트 |
| `docs/SSOT/3-workflow.md` | 상태 머신·게이트·Phase Chain |
| `docs/SSOT/4-event-protocol.md` / `5-automation.md` | 이벤트·자동화 규칙 |
| `docs/SSOT/core/` | 규칙 인덱스·공통 포맷 |
| `docs/SSOT/SUB-SSOT/` | 역할별 모듈형 로딩 문서 |
| `docs/SSOT/ROLES/` | 역할 정의 정본 (불변 실행 가이드) |
| `docs/SSOT/QUALITY/` / `TEMPLATES/` / `refactoring/` / `tests/` / `infra/` / `mcp-design/` | 검증 위원회·양식·규정 |
| `docs/SSOT/GUIDE.md` / `VERSION.md` / `STRUCTURE.md` / `UPGRADE.md` | 네비게이션·버전·구조 |
| `docs/SSOT/MIGRATION-6-1-to-6-2.md` | **세대 이행 전용** — 6-x(ver6-0/구 v8.2·ver6-1·ver6-2 구버전) → `ver6-2`(현행) 이행 가이드(Phase 8-6 신설, Phase 9-4 6-x 통합 확장). §3 일반 절차를 대체하지 않고 보완한다 |
| `.claude/hooks/*.sh` | 훅 스크립트 (hooks.env 제외) |
| `.claude/skills/` | 스킬 전체 |
| `scripts/log-prompt.sh` / `scripts/sync-project-config.sh` / `scripts/pmAuto/` | 공용 스크립트 |
| `scripts/zombiecheck/` | LIFECYCLE-5 좀비 감지 헬퍼(`zombie_check.sh` + `zombie_check_selftest.sh`, ver6-1 PoC 도입 → ver6-2 8-4 분리) + LIFECYCLE-6 체크 스케줄러(`zombie_watch.sh` + `zombie_watch_selftest.sh`, ver6-2 8-3 신규; `zombie_watch_lib.sh`/`zombie_watch_poll.sh` 분리 모듈, Phase 9-1) |

> **주의 — 삭제 동기화 없음**: 업그레이드는 파일 **추가·덮어쓰기만** 수행한다. 새 번들에서 제거된 스킬·훅·문서는 대상 프로젝트에 그대로 잔존하므로, `VERSION.md` 변경 이력에 제거 항목이 있으면 수동으로 삭제한다.

### 1.2 프로젝트 파일 (업그레이드 시 보존)

| 경로 | 내용 | 근거 |
|------|------|------|
| **`PROJECT.md`** | 프로젝트 단일 설정 문서 | 프로젝트별 가변 |
| `.claude/hooks/hooks.env` | PROJECT.md에서 자동 생성 | sync로 재생성 |
| `docs/SSOT/1-project.md` | 프로젝트 정의·팀 구성 (커스터마이징 시) | 프로젝트별 |
| `docs/SSOT/2-architecture.md` | 인프라·BE/FE 구조 (커스터마이징 시) | 프로젝트별 |
| `docs/SSOT/PERSONA/` | 마인드셋 (교체 가능 레이어) | ROLES=불변 / PERSONA=교체 원칙 |
| `docs/persona-overrides/` | 프로젝트 페르소나 추가 지시 | PROJECT.md §6 |
| `docs/phases/` / `docs/history/` / `docs/handoff/` | 실행 산출물 | 프로젝트 이력 |
| `.claude/CLAUDE.md` 하단 프로젝트 섹션 | 프로젝트 개요 | 충돌 시 `.pab-new` 분리 |
| `.claude/settings.local.json` | 개인 로컬 설정 | — |

> **주의**: `1-project.md`/`2-architecture.md`는 번들 원본이 예시(Personal AI Brain v3) 기준이다. 새 프로젝트에서는 PROJECT.md를 기반으로 두 문서를 프로젝트에 맞게 재작성하는 것을 권장하며, 재작성한 경우 업그레이드에서 자동 보존된다(§3 절차의 충돌 처리).

---

## 2. 버전 정책

- SSOT 버전의 정본은 `docs/SSOT/VERSION.md`.
- 각 프로젝트의 `PROJECT.md` frontmatter `ssot_version`이 **적용 시점의 버전**을 기록한다 (FRESH-2 대조용).
- `/project-config check`가 두 값의 불일치를 감지하면 업그레이드 필요 신호다.
- SSOT 개정은 번들 저장소에서 Phase 트랙으로 수행하고(LOCK-1~5), `VERSION.md`에 변경 이력을 기록한 뒤 각 프로젝트로 배포한다.

---

## 3. 업그레이드 절차 (이식된 프로젝트에서)

```
[전제] 대상 프로젝트의 Phase 상태가 IDLE 또는 DONE (LOCK-1)
  │
[1] 고정 위치의 번들 최신화 (예: ~/pab-ssot-bundle/ — git pull 또는 새 zip 덮어 풀기)
  │
[2] bash <번들경로>/install.sh <대상프로젝트> --upgrade
  │    → §1.1 프레임워크 파일만 덮어씀
  │    → §1.2 프로젝트 파일 보존 (수정된 1-project/2-architecture/PERSONA 자동 감지)
  │
[3] PROJECT.md frontmatter의 ssot_version을 새 버전으로 갱신
  │    → /project-config sync (hooks.env 재생성)
  │
[4] 변경 이력 확인: docs/SSOT/VERSION.md 새 항목 검토 (LOCK-5)
  │
[5] /ssot-reload 실행 (FRESH-3)
  │
[6] 팀 운영 중이었다면: 전 팀원 SendMessage로 SSOT 리로드 지시 (LOCK-3)
```

### 3.1 충돌 처리

- `--upgrade`는 `1-project.md`, `2-architecture.md`, `PERSONA/`가 **번들 원본과 다르면(=프로젝트가 수정했으면) 보존**하고, 새 버전을 `*.pab-new`로 옆에 저장한다.
- 수정한 적이 없으면(원본과 동일) 새 버전으로 갱신한다.
- `.pab-new` 파일이 생기면 diff 후 수동 병합하고 삭제한다.

### 3.2 롤백

- 업그레이드 전 git 커밋을 권장한다. 문제가 있으면 `git checkout -- docs/SSOT .claude`로 복원.

---

## 4. SSOT 자체 개정 절차 (번들 저장소에서)

SSOT 문서 개정은 일반 코드와 동일하게 **Phase 트랙**으로 다룬다:

1. **IDLE/DONE 확인** (LOCK-1) — 실행 중 Phase가 있으면 BLOCKED 전이 후 진행 (LOCK-2)
2. 개정 Phase 실행 (planner 분석 → 문서 수정 → verifier 검증)
3. `VERSION.md` 버전·변경 이력 갱신 (LOCK-5)
4. 프레임워크/프로젝트 분류 변동이 있으면 **본 문서 §1 표 갱신**
5. `STRUCTURE.md` 구조 변동 반영
6. 이식된 각 프로젝트에 §3 절차로 배포

---

**문서 관리**: v1.0, 2026-07-06 신설. 분류 표(§1)는 install.sh `--upgrade` 로직과 일치해야 하며, 변경 시 양쪽을 함께 갱신한다.
