# MCP 서버 설계서

**버전**: 1.0
**작성일**: 2026-03-01
**Phase**: 24-6 (Task 24-6-2)
**SSOT 기준**: v7.0-renewal-5th

---

## 1. 개요

### 1.1 목적

SSOT 운영 자동화를 위한 3개 MCP(Model Context Protocol) 서버를 설계한다.
각 서버는 Phase 상태 관리, 이벤트 로깅, 산출물 검증이라는 독립된 책임을 갖는다.

### 1.2 기술 스택

| 항목 | 선택 |
|------|------|
| 프레임워크 | Python FastMCP (`from mcp.server.fastmcp import FastMCP`) |
| 런타임 | Python 3.11+ |
| YAML 파싱 | PyYAML (`yaml.safe_load`) |
| 배포 모드 | 로컬 stdio (Claude Code `settings.json` `mcpServers` 등록) |
| 데이터 형식 | YAML frontmatter (status.md), JSONL (이벤트 로그) |

### 1.3 서버 목록

| 서버명 | 역할 | Tool 수 |
|--------|------|:-------:|
| `ssot-state-manager` | Phase status.md CRUD + 상태 전이 유효성 검증 | 4 |
| `ssot-event-logger` | JSONL 이벤트 기록/조회/아카이브 | 4 |
| `ssot-artifact-validator` | CHAIN-6 산출물 존재 확인 + 내용 검증 | 4 |

---

## 2. ssot-state-manager

### 2.1 역할

Phase의 `status.md` YAML frontmatter를 CRUD하고, 상태 전이 시 20개 상태 머신
(3-workflow.md 1.1) 기반으로 유효성을 검증한다.

### 2.2 Tools

#### `get_state(phase_id: str) -> dict`

status.md YAML frontmatter를 파싱하여 현재 상태를 반환한다.

- **입력**: `phase_id` (예: `"24-6"`)
- **파일 경로**: `docs/phases/phase-{phase_id}/phase-{phase_id}-status.md`
- **반환 필드**: `phase`, `ssot_version`, `current_state`, `current_task`, `task_progress`, `blockers`, `gate_results`, `last_updated`
- **에러**: 파일 미존재 시 `FileNotFound` 에러 + 경로 안내

#### `transition_state(phase_id: str, target_state: str) -> dict`

상태 전이 유효성을 검증하고, 유효하면 status.md를 업데이트한다.

- **입력**: `phase_id`, `target_state`
- **검증**: 20개 상태 머신 기반 전이 테이블 (2.3절)
- **성공 시 반환**: `{"ok": true, "previous": "...", "current": "...", "updated_at": "..."}`
- **실패 시 반환**: `InvalidTransition` 에러 + 허용 전이 목록
- **부수 효과**: `last_updated` 타임스탬프 갱신

#### `validate_status(phase_id: str) -> dict`

status.md의 YAML 스키마를 검증한다.

- **필수 필드 검증**: `phase`, `ssot_version`, `current_state`, `task_progress`
- **값 범위 검증**: `current_state`가 20개 상태 중 하나인지 확인
- **반환**: `{"valid": bool, "errors": [...], "warnings": [...]}`

#### `list_phases() -> list`

`docs/phases/` 하위의 Phase 목록과 각 Phase의 현재 상태를 반환한다.

- **스캔 대상**: `docs/phases/phase-*/phase-*-status.md`
- **반환**: `[{"phase_id": "24-6", "current_state": "BUILDING", "last_updated": "..."}, ...]`

### 2.3 상태 전이 규칙

3-workflow.md 1.1 기준 20개 상태 머신의 허용 전이 테이블이다.

```python
TRANSITIONS: dict[str, list[str]] = {
    "IDLE":              ["TEAM_SETUP"],
    "TEAM_SETUP":        ["PLANNING", "RESEARCH"],
    "RESEARCH":          ["RESEARCH_REVIEW", "BLOCKED"],
    "RESEARCH_REVIEW":   ["PLANNING", "REWINDING"],
    "PLANNING":          ["PLAN_REVIEW", "BLOCKED"],
    "PLAN_REVIEW":       ["TASK_SPEC", "DESIGN_REVIEW", "REWINDING"],
    "DESIGN_REVIEW":     ["TASK_SPEC", "REWINDING"],
    "TASK_SPEC":         ["BUILDING", "BRANCH_CREATION", "BLOCKED"],
    "BRANCH_CREATION":   ["BUILDING"],
    "BUILDING":          ["VERIFYING", "BLOCKED"],
    "VERIFYING":         ["TESTING", "AUTO_FIX", "REWINDING"],
    "AUTO_FIX":          ["VERIFYING", "REWINDING"],
    "TESTING":           ["BUILDING", "INTEGRATION", "AB_COMPARISON", "REWINDING"],
    "AB_COMPARISON":     ["INTEGRATION", "REWINDING"],
    "INTEGRATION":       ["E2E", "REWINDING"],
    "E2E":               ["E2E_REPORT", "REWINDING"],
    "E2E_REPORT":        ["TEAM_SHUTDOWN"],
    "TEAM_SHUTDOWN":     ["DONE"],
    "BLOCKED":           [],  # 복귀 상태는 rewind_target 기반
    "REWINDING":         [],  # rewind_target 기반
    "DONE":              [],
}
```

**특수 전이 규칙**:
- `BLOCKED`: 모든 상태에서 진입 가능. 복귀 시 `rewind_target` 필드 기반으로 이전 상태 복원
- `REWINDING`: FAIL 판정 시 진입. `rewind_target` 기반 복귀 후 `retry_count += 1`
- `TESTING` -> `BUILDING`: 다음 Task 루프 (동일 Phase 내 Task 순회)

### 2.4 에러 처리

| 에러 | 조건 | 반환 |
|------|------|------|
| `FileNotFound` | status.md 미존재 | 예상 경로 안내 |
| `InvalidTransition` | 허용되지 않는 전이 | 현재 상태 + 허용 전이 목록 |
| `YAMLParseError` | frontmatter 파싱 실패 | 파싱 에러 상세 |
| `MissingField` | 필수 필드 누락 | 누락 필드 목록 |

---

## 3. ssot-event-logger

### 3.1 역할

JSONL 형식 이벤트를 기록하고 조회한다.
4-event-protocol.md의 이벤트 스키마(1.1~1.3)를 준수한다.

### 3.2 Tools

#### `log_event(phase_id: str, event_type: str, agent: str, detail: str) -> dict`

이벤트를 JSONL 파일에 기록한다.

- **저장 경로**: `/tmp/agent-events/{phase_id}.jsonl`
  - 예: `/tmp/agent-events/24-6.jsonl`
- **기록 형식**: 1줄 1JSON, UTF-8, LF 줄바꿈
- **자동 추가 필드**: `timestamp` (ISO8601, 호출 시점 자동 생성)
- **반환**: `{"ok": true, "event_id": "...", "timestamp": "..."}`

**JSONL 레코드 예시**:
```json
{"ts":"2026-03-01T14:30:00+09:00","phase":"24-6","type":"TASK_COMPLETED","agent":"backend-dev","detail":"Task 24-6-2 MCP 설계서 작성 완료"}
```

#### `query_events(phase_id: str, event_type: str = None, agent: str = None, limit: int = 20) -> list`

이벤트를 조회한다. 필터 조합을 지원한다.

- **필터**: `event_type`, `agent` (각각 선택적)
- **정렬**: `timestamp` 내림차순 (최신 우선)
- **제한**: `limit` (기본 20건, 최대 100건)
- **반환**: `[{"ts": "...", "phase": "...", "type": "...", "agent": "...", "detail": "..."}, ...]`

#### `archive_events(phase_id: str) -> dict`

Phase 완료 시 이벤트 로그를 아카이브한다.

- **원본**: `/tmp/agent-events/{phase_id}.jsonl`
- **대상**: `docs/phases/phase-{phase_id}/events.jsonl`
- **동작**: 파일 복사 (원본 보존). 원본 삭제는 별도 확인 후 수행
- **검증**: 대상 디렉토리 존재 확인, 기존 아카이브 파일이 있으면 덮어쓰기 방지
- **반환**: `{"ok": true, "source": "...", "destination": "...", "event_count": N}`

#### `get_event_stats(phase_id: str) -> dict`

이벤트 유형별/에이전트별 통계를 반환한다.

- **반환 구조**:
```json
{
  "phase_id": "24-6",
  "total_events": 42,
  "by_type": {
    "STATE_CHANGE": 8,
    "TASK_COMPLETED": 5,
    "HEARTBEAT": 20,
    "GATE_PASSED": 3,
    "ERROR": 1
  },
  "by_agent": {
    "team-lead": 12,
    "backend-dev": 18,
    "verifier": 7,
    "tester": 5
  },
  "first_event": "2026-03-01T09:00:00+09:00",
  "last_event": "2026-03-01T17:30:00+09:00"
}
```

### 3.3 이벤트 유형

4-event-protocol.md 1.3절 기준이다.

| event_type | 설명 | 발생 주체 |
|------------|------|----------|
| `STATE_CHANGE` | 상태 전이 발생 | Team Lead |
| `TASK_STARTED` | Task 구현 시작 | 팀원 (backend-dev, frontend-dev) |
| `TASK_COMPLETED` | Task 구현 완료 | 팀원 |
| `GATE_PASSED` | 게이트 통과 | Verifier / Tester |
| `GATE_FAILED` | 게이트 실패 | Verifier / Tester |
| `ERROR` | 오류 발생 | 모든 에이전트 |
| `HEARTBEAT` | 생존 확인 신호 | 모든 에이전트 |

### 3.4 JSONL 포맷 규칙

- 인코딩: UTF-8
- 줄바꿈: LF (`\n`), CRLF 금지
- 1줄 1JSON 객체 (멀티라인 JSON 금지)
- 필수 필드: `ts`, `phase`, `type`, `agent`, `detail`

---

## 4. ssot-artifact-validator

### 4.1 역할

CHAIN-6(HR-2) 필수 산출물의 존재를 확인하고 내용을 검증한다.
5-automation.md 1절 Artifact Persister의 검증 로직을 구현한다.

### 4.2 Tools

#### `validate_artifacts(phase_id: str) -> dict`

CHAIN-6 필수 산출물의 존재를 확인한다.

- **검증 대상** (4종):
  1. `docs/phases/phase-{id}/phase-{id}-status.md` (YAML 상태 파일)
  2. `docs/phases/phase-{id}/phase-{id}-plan.md` (계획서)
  3. `docs/phases/phase-{id}/phase-{id}-todo-list.md` (체크리스트)
  4. `docs/phases/phase-{id}/tasks/task-{id}-*.md` (Task 명세, 1개 이상)
- **반환 구조**:
```json
{
  "phase_id": "24-6",
  "verdict": "PASS",
  "checks": [
    {"artifact": "status.md", "exists": true, "result": "PASS"},
    {"artifact": "plan.md", "exists": true, "result": "PASS"},
    {"artifact": "todo-list.md", "exists": true, "result": "PASS"},
    {"artifact": "tasks/", "exists": true, "count": 3, "result": "PASS"}
  ],
  "missing": []
}
```
- **판정**: 4종 모두 존재 시 `PASS`, 1개라도 누락 시 `FAIL`

#### `validate_links(phase_id: str) -> dict`

Phase 문서 내 마크다운 내부 링크의 유효성을 검사한다.

- **검사 대상**: `plan.md`, `todo-list.md`, `tasks/*.md` 내의 `[text](path)` 링크
- **검증**: 링크 대상 파일이 실제로 존재하는지 확인
- **반환**:
```json
{
  "phase_id": "24-6",
  "total_links": 12,
  "valid": 11,
  "broken": 1,
  "broken_details": [
    {"file": "plan.md", "line": 42, "link": "../nonexistent.md"}
  ]
}
```

#### `check_line_counts(path: str = "docs/SSOT/renewal/iterations/5th") -> list`

HR-5/REFACTOR-1~3 기준 코드 파일의 줄 수를 검사한다.

- **대상 확장자**: `*.py`, `*.js`, `*.css`, `*.html`
- **임계값** (refactoring-rules.md 2절 기준):
  - 500줄 초과: `WARNING` (관심선 -- 레지스트리 등록 대상)
  - 700줄 초과: `HIGH` (경고선 -- Level 분류 + 리팩토링 검토)
  - 1000줄 초과: `CRITICAL` (위험선 -- 즉시 리팩토링)
- **반환**: `[{"file": "...", "lines": N, "severity": "WARNING|HIGH|CRITICAL"}, ...]`
- 500줄 이하 파일은 결과에 포함하지 않는다

#### `validate_rules_index() -> dict`

6-rules-index.md에 정의된 규칙 ID와 소스 파일의 규칙 ID를 대조한다.

- **인덱스 파일**: `docs/SSOT/renewal/iterations/5th/core/6-rules-index.md`
- **소스 파일**: 0-entrypoint.md, 1-project.md, 3-workflow.md, 4-event-protocol.md, 5-automation.md, CLAUDE.md
- **검증**: 인덱스에 있으나 소스에 없는 규칙, 소스에 있으나 인덱스에 없는 규칙
- **반환**:
```json
{
  "verdict": "PASS",
  "index_count": 72,
  "source_count": 72,
  "missing_in_source": [],
  "missing_in_index": [],
  "mismatched": []
}
```

### 4.3 검증 결과 형식

모든 검증 Tool은 통일된 판정 형식을 따른다.

| 판정 | 조건 |
|------|------|
| `PASS` | 모든 검증 항목 통과 |
| `FAIL` | 필수 항목 1개 이상 미통과 |
| `WARNING` | 필수 항목 통과, 권장 항목 미통과 |

---

## 5. settings.json 등록 예시

Claude Code `settings.json`의 `mcpServers` 섹션에 아래와 같이 등록한다.

```json
{
  "mcpServers": {
    "ssot-state-manager": {
      "command": "python",
      "args": ["-m", "mcp_servers.state_manager"],
      "type": "stdio"
    },
    "ssot-event-logger": {
      "command": "python",
      "args": ["-m", "mcp_servers.event_logger"],
      "type": "stdio"
    },
    "ssot-artifact-validator": {
      "command": "python",
      "args": ["-m", "mcp_servers.artifact_validator"],
      "type": "stdio"
    }
  }
}
```

**등록 위치**: 프로젝트 루트 `.claude/settings.json` 또는 사용자 전역 설정

---

## 6. 디렉토리 구조

```
mcp_servers/
├── __init__.py
├── state_manager.py        # ssot-state-manager (FastMCP 서버)
├── event_logger.py          # ssot-event-logger (FastMCP 서버)
├── artifact_validator.py    # ssot-artifact-validator (FastMCP 서버)
└── utils/
    ├── __init__.py
    ├── yaml_parser.py       # YAML frontmatter 파싱/쓰기 유틸
    └── state_machine.py     # 20개 상태 전이 테이블 + 유효성 검증
```

### 6.1 모듈별 책임

| 모듈 | 책임 |
|------|------|
| `state_manager.py` | FastMCP 서버 초기화, 4개 Tool 등록, status.md 파일 I/O |
| `event_logger.py` | FastMCP 서버 초기화, 4개 Tool 등록, JSONL 파일 I/O |
| `artifact_validator.py` | FastMCP 서버 초기화, 4개 Tool 등록, 파일 존재/링크/줄 수 검증 |
| `utils/yaml_parser.py` | YAML frontmatter 추출(`---` 구분), 파싱, 직렬화 |
| `utils/state_machine.py` | `TRANSITIONS` 딕셔너리, `is_valid_transition()`, `get_allowed_targets()` |

### 6.2 서버 진입점 패턴

각 서버 모듈은 다음 패턴을 따른다.

```python
# mcp_servers/state_manager.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ssot-state-manager")

@mcp.tool()
def get_state(phase_id: str) -> dict:
    """Phase의 현재 상태를 반환한다."""
    ...

@mcp.tool()
def transition_state(phase_id: str, target_state: str) -> dict:
    """상태 전이를 검증하고 실행한다."""
    ...

@mcp.tool()
def validate_status(phase_id: str) -> dict:
    """status.md YAML 스키마를 검증한다."""
    ...

@mcp.tool()
def list_phases() -> list:
    """Phase 목록과 현재 상태를 반환한다."""
    ...

if __name__ == "__main__":
    mcp.run()
```

---

## 7. 향후 계획

### 7.1 Phase 25+ 구현 착수

| 항목 | 내용 |
|------|------|
| 구현 우선순위 | state_manager > event_logger > artifact_validator |
| 단위 테스트 | pytest 기반, 각 Tool별 정상/에러 케이스 |
| 통합 테스트 | 3개 서버 조합 시나리오 (상태 전이 -> 이벤트 기록 -> 산출물 검증) |

### 7.2 테스트 전략

- `tests/test_state_manager.py`: 전이 유효성, YAML 파싱, 에러 케이스
- `tests/test_event_logger.py`: JSONL 쓰기/읽기, 필터, 아카이브
- `tests/test_artifact_validator.py`: 산출물 존재, 링크 검증, 줄 수 검사
- `tests/test_state_machine.py`: 20개 상태 전이 테이블 전수 검증

### 7.3 CI/CD 통합

- pre-commit hook: `artifact_validator.validate_rules_index()` 실행
- Phase 완료 시: `check_line_counts()` 자동 실행 (REFACTOR-1 자동화)

---

**문서 관리**:
- 버전: 1.0
- 작성일: 2026-03-01
- Phase: 24-6 (Task 24-6-2)
- 참조: 3-workflow.md (상태 머신), 4-event-protocol.md (이벤트 스키마), 5-automation.md (자동화), 6-rules-index.md (규칙 인덱스), refactoring-rules.md (줄 수 임계값)
