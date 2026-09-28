# SSOT — Phase Chain

## 1. 개요

Phase Chain은 복수의 Phase를 사전 정의된 순서로 실행하는 프로토콜이다.  
각 Phase DONE 후 `/clear`로 컨텍스트를 초기화하고, 다음 Phase를 시작한다.

## 2. Phase Chain 정의 파일

```yaml
# docs/phases/phase-chain-{name}.md
---
chain_name: "phase-15-fullstack"
phases: ["15-4", "15-5", "15-6", "15-7", "15-8"]
current_index: 0          # 현재 실행 중인 Phase 인덱스
status: "running"         # pending | running | completed | aborted
ssot_version: "{SSOT 버전}"
created_at: "2026-02-28T..."
---
```

## 3. Phase Chain 실행 프로토콜

```
[1] Chain 파일 생성 (phase-chain-{name}.md)
[2] Phase[current_index] Cold Start: SSOT 리로드 → 팀 생성(첫 팀원 스폰 시 자동) → PLANNING → … → DONE (상태 진입마다 담당 팀원 스폰)
[3] Phase DONE → TEAM_SHUTDOWN(전원 shutdown_request → 팀 config 확인 → 센티넬 해제 확인) → Chain 파일 current_index += 1 → 완료 리포트 출력
[4] 리팩토링 레지스트리 갱신 ← REFACTOR-1 (500줄 초과 파일 스캔 → 등록만, 계획 삽입 아님)
[5] /clear 실행 (토큰 최적화, Chain 파일은 디스크에 유지)
[6] current_index < len(phases)? → 다음 Phase Cold Start(Step 2), else Chain 완료
```

## 4. Chain 중단·재개

| 상황 | 처리 |
|------|------|
| Phase 실패 (retry ≥ 3) | Chain 일시정지, 사용자 판단 대기 |
| 사용자 중단 요청 | **`/abort` 스킬이 표준 진입점** — 팀 shutdown + status.md BLOCKED 기록 + 재개 정보 보존. Chain `status`를 `"aborted"`로 바꾸는 것은 Chain 전체 중단을 고른 경우뿐이고, 현재 Phase만 중단하면 Chain은 그대로 둔다. `/abort`는 LIFECYCLE-6 워처를 회수하지 않는다 — `zombie_watch.sh --stop <team>`으로 회수한다 |
| 세션 끊김 | SSOT 리로드 후 Chain 파일 current_index가 가리키는 Phase의 status.md부터 재개 |

## 5. Phase Chain 규칙

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **CHAIN-1** | Phase 독립성 | 각 Phase는 Chain 없이도 단독 실행 가능해야 함 |
| **CHAIN-2** | `/clear` 필수 | Phase 간 전환 시 `/clear`로 토큰 초기화 |
| **CHAIN-3** | Chain 파일 유지 | `/clear` 후에도 Chain 파일은 디스크에 영속 |
| **CHAIN-4** | 순차 보장 | phases 배열 순서대로만 실행 (건너뛰기 금지) |
| **CHAIN-5** | 완료 리포트 | 각 Phase DONE 시 1줄 요약을 Chain 파일에 기록 |
| **CHAIN-6** | 산출물 의무 | plan.md, todo-list.md, tasks/task-X-Y-N.md, status.md(YAML) 최소 필수 |
| **CHAIN-7** | Gate 의무 | G1~G4 생략 불가 (단독 실행 시 G2·G3는 자체 검증으로 대체 가능, status에 기록) |
| **CHAIN-8** | Status 형식 | status.md는 YAML frontmatter 형식(workflow.md §2.2 스키마) 준수 |
| **CHAIN-9** | Task 문서 형식 | task-X-Y-N.md: 메타 필드(우선순위/의존성/담당 팀원/상태) + §1~§4 섹션 번호. 선택 칸 「COMMENT-3 요청」(일시 · 요청 요지 · 대상 파일 목록 — COMMENT-3 발동 때만) |
| **CHAIN-10** | 파일 경로 규칙 | 아래 §6 디렉토리 구조 준수 필수. 기존 파일 패턴을 반드시 확인 후 생성 |
| **CHAIN-11** | Master Plan 완료 보고서 | Master Plan 전체 Sub-Phase 완료 시 `phase-{N}-final-summary-report.md`를 `docs/phases/` 루트에 작성 필수 |

## 6. Phase 문서 디렉토리 구조

```
docs/phases/
├── phase-chain-{name}.md                ← Chain 정의 (phases 루트)
├── phase-{N}-master-plan.md             ← 마스터 플랜 (phases 루트, 하위 폴더 아님)
├── phase-{N}-final-summary-report.md    ← 완료 보고서 (phases 루트, CHAIN-11)
├── pre/                                 ← Master Plan 이전 산출물 (평탄 구조)
│    └── phase-{N}-pre-draft.md          ← `/plan` Pre-draft
├── phase-{N}-{M}/                       ← 개별 Phase 산출물 폴더
│    ├── phase-{N}-{M}-status.md         ← YAML 상태 파일 (ENTRY-1 진입점)
│    ├── phase-{N}-{M}-plan.md           ← Phase 계획서
│    ├── phase-{N}-{M}-todo-list.md      ← Todo 체크리스트
│    └── tasks/                          ← Task 명세 폴더
│         └── task-{N}-{M}-{T}.md        ← 개별 Task 명세
```

**핵심 규칙**:
- `master-plan.md`·`phase-chain-*.md`·`final-summary-report.md`는 **`docs/phases/` 루트**에 위치 (하위 폴더 생성 금지)
- `status.md`·`plan.md`·`todo-list.md`·`tasks/`는 **`phase-{N}-{M}/` 폴더** 안에 위치
- `pre-draft.md`는 **`docs/phases/pre/` 평탄 폴더**에 `phase-{N}-pre-draft.md` 형식으로 위치
- **pre-draft**는 `/plan` 호출 시에만 생성
- 새 파일 생성 전 **기존 파일 패턴을 `Glob`으로 확인** 후 동일 경로 레벨에 생성
