# Testing Procedure — SUB-SSOT

> **버전**: 1.3 | **갱신**: 2026-04-16 (Phase-G — §KPI-driven Test Plan 신설)
> **소스**: `_backup/GUIDES/tester-work-guide.md` + DEV-work-guide 파일2·4 (Phase-E·F 이관) + AutoCycle Step 10 (Phase-G)

---

## VALIDATOR 실행 원칙

### 증거 기반 감사

- VALIDATOR는 **모든 검증 항목을 실행 가능한 명령으로 명세**한다.
- "visually verify", "should work", "seems correct" 같은 정성 표현 금지 (PROBLEM-PROC-05).
- 검증 실패 시 보완 계획 없이 기준 임계값 하향 금지.

### Scope 분기

- **PHASE 3 (Spike 검증)**: Spike 결과가 NF 목표를 실제 측정값으로 뒷받침하는지 확인.
- **PHASE 7 (최종 검증)**: 모든 VAL 항목 실행 + stdout 기록 + GATE 7 통과.

### VAL 결과 포맷 (상세)

각 VAL 항목은 다음 4필드 필수:

| 필드 | 내용 |
|------|------|
| `ID` | VAL-N (요구사항 FR/NF와 매핑) |
| `방법` | 실행 가능 명령 또는 수동 절차 |
| `기대 결과` | 측정 가능한 임계값 (p99 < Nms, 특정 문자열 등) |
| `실제 결과` | stdout 최소 3줄 인용 (미기재 = 자동 FAIL — PROBLEM-CTX-07 방지) |

공통 정의: `core/7-shared-definitions.md §4.2`

### FAIL_COUNTER 관리

- VAL 실패 시 FAIL_COUNTER 누적 (+1).
- 3회 연속 실패 → BLOCKER_REVIEW_REQUEST 발행.
- 인간 승인 없이 **카운터 리셋 금지** (자율 리셋은 Forbidden).
- 공통 정의: `core/7-shared-definitions.md §4.3`

---

## 테스트 흐름

| 순서 | 단계 | 설명 |
|------|------|------|
| 1 | **수집** | 테스트 파일·목록·DB/API 정보 로딩 |
| 2 | **bash 등록** | 변경 도메인에 맞는 테스트 명령 구성 (수동) — `docs/tests/index.md` §1·§3 참조 |
| 3 | **테스트 수행** | `pytest tests/` 또는 `npx playwright test` |
| 4 | **결과 저장** | 보고서 마크다운 → `report-tester.md` |

---

## 선택적 실행 원칙

**전체 테스트 불필요.** 변경 영향 테스트만 선택 실행.

| 시점 | 범위 | 소요 |
|------|------|------|
| phase-x-Y 단계 | 변경 영향만 | ~1분 |
| phase-x-Y 완료 후 | 빠른 회귀 (`-m "not llm and not integration"`) | ~2분 |
| Phase X 전체 완료 | LLM 포함 회귀 | ~6분 |

---

## pytest 실행 규칙

### 동기 실행 (권장)

```bash
# 변경 도메인별 실행
clear && pytest tests/test_{domain}.py --tb=short -v

# 빠른 회귀
clear && pytest tests/ -m "not llm and not integration" --tb=short -q
```

### 병렬 실행 금지 (Ollama/AI)

- `pytest -n` (xdist) 금지
- 동일 환경 pytest 여러 개 동시 실행 금지
- **단일 pytest 프로세스**만 실행

### 결과 확인

- **동기 실행** → 터미널 출력 직접 확인
- 백그라운드 불가피 시 → stdout을 `/tmp/agent-messages/` 리다이렉트 → inotifywait 감시
- `.../tasks/xxx.output` 등 임시 경로 반복 조회 **금지**

---

## 1주기 = 요청서 + 결과서

**저장**: `docs/pytest-report/YYMMDD-HHMM-phase-X-Y-{name}.md`

| 산출물 | 내용 |
|--------|------|
| 요청서(목록) | backend, frontend, db, api, llm 등 수행 항목 |
| 결과서 | 항목별 PASS/FAIL, FAIL 시 원인 분석·보완점 |

---

## AB_COMPARISON (5th 확장)

`5th_mode.branch: true` + A/B Task 존재 시:

1. Branch-A 테스트 실행 + 결과 기록
2. Branch-B 동일 테스트 실행 + 결과 기록
3. 비교 보고서 (TEMPLATES/ab-comparison-template.md)
4. Team Lead에게 비교 결과 보고

---

## 이벤트 로그 (5th 확장)

`5th_mode.event: true` 시 테스트 결과를 JSONL 이벤트 로그에도 기록:

```json
{"timestamp":"...","agent":"tester","event_type":"gate_result","state":"TESTING","detail":{"gate":"G3","verdict":"PASS","coverage":85,"test_count":42,"failures":0},"phase_id":"X-Y"}
```

---

## VALIDATOR 실패 모드 대응

DEV/3-failure-modes.md의 VALIDATOR 완화 소관 항목. CODER 인식은 DEV 원본 유지, 본 섹션은 VALIDATOR 실행 관점.

| ID | 완화 절차 (VALIDATOR가 수행) |
|----|------------------------------|
| PROBLEM-PROC-05 | "visually verify" 허용 차단 — 모든 VAL 항목 실행 가능 **명령 + 기대 결과 + 실제 결과 증거** 필수 (§증거 기반 감사) |
| PROBLEM-CTX-07 | 검증 결과 예측 차단 — VAL 포맷 **실제 stdout 3줄 이상 인용** 의무, 미기재 시 자동 FAIL (§VAL 결과 포맷 §4) |

→ 원본 목록: `SUB-SSOT/DEV/3-failure-modes.md`

---

## 결함 분류 (ISTQB CTFL 4.0 기반, Phase-F 확장)

### 심각도 (Severity)

| 심각도 | 설명 | 예시 |
|--------|------|------|
| **Critical** | 서비스 불가. 시스템 전체 중단 또는 데이터 손실 | 서버 기동 불가, DB 데이터 유실, 인증 완전 실패 |
| **Major** | 핵심 기능 장애. 주요 비즈니스 플로우 차단 | API 핵심 엔드포인트 500, 결제 로직 오류 |
| **Minor** | 비핵심 기능·UI 이슈. 우회 경로 존재 | UI 정렬 깨짐, 부가 기능 미동작 |
| **Trivial** | 문서·오타 수준. 기능 영향 없음 | 오타, 로그 메시지 오류, 주석 누락 |

### 결함 유형 (Type)

| 유형 | 설명 |
|------|------|
| **Functional** | 기능 요구사항 불일치. 예상 동작과 실제 동작 차이 |
| **Performance** | 응답 시간·처리량·리소스 사용 기준 초과 |
| **Security** | 인증/인가 우회, 데이터 노출, 주입 공격 취약점 |
| **Usability** | 사용성 저해. UX 흐름 비직관적, 접근성 미충족 |
| **Compatibility** | 환경(브라우저·OS·런타임 버전) 간 호환성 문제 |

### 결함 보고 필수 필드

결함 보고서([TEMPLATES/defect-report-template.md](../../TEMPLATES/defect-report-template.md))에 최소 포함:

| # | 필드 | 설명 |
|:-:|------|------|
| 1 | **Defect ID** | 고유 식별자 (예: `DEF-phase-21-3-001`) |
| 2 | **심각도** | Critical / Major / Minor / Trivial |
| 3 | **유형** | Functional / Performance / Security / Usability / Compatibility |
| 4 | **재현 절차** | 결함 재현 단계별 절차 |
| 5 | **기대 결과** | 정상 동작 시 예상 결과 |
| 6 | **실제 결과** | 결함 발생 시 관찰된 실제 결과 |
| 7 | **환경** | OS, 런타임 버전, Docker 이미지, 브라우저 등 |

### 결함 밀도

- 계산: `결함 수 / (LOC / 1000)` (건/KLOC)
- G3 PASS: ≤5건/KLOC
- 참조: `3-workflow.md §4.2 G3`

---

## G3 실행 가이드 (Phase-F 이관)

### 빈 출력 파일 문제 — 원인과 SSOT 준수 동작

| 문제 | 원인 | SSOT 준수 동작 |
|------|------|-----------------|
| "출력 파일이 비어있다" | 백그라운드 실행 시 도구가 **완료 전까지** 출력을 쓰지 않거나, **다른 경로**(예: `.../tasks/<id>.output`)를 조회 (SSOT에 없음) | **(1) 동기 실행 권장** — pytest를 **백그라운드가 아닌 동기**로 실행, 타임아웃만 넉넉히(예: 5분). 결과는 터미널 출력으로 즉시 확인. **(2) 다른 경로 반복 조회 금지** — `.../tasks/xxx.output` 같은 도구 임시 경로를 sleep 후 반복 읽지 말 것. **(3) 백그라운드 불가피 시** — stdout을 **공식 경로**로 리다이렉트 (예: `... > /tmp/agent-messages/phase-X-Y-pytest.log 2>&1 &`) 후 완료 시 해당 파일만 읽기. inotifywait로 감시 가능. |

**요약**: G3 결과를 확실히 받으려면 **동기 실행** 한 번으로 끝까지 돌리고 터미널에서 받거나 `/tmp/agent-messages/`에 리다이렉트 후 **그 경로만** 읽는다. 빈 파일 반복 조회 금지.

---

## 시나리오별 pytest 명령 (Phase-F 이관)

> **필수**: 테스트 실행 전 `clear`로 터미널 초기화.
> **필수 참조**: `docs/tests/index.md` — 변경 시나리오별 실행 명령어

### 선택적 실행 흐름

```
1. Team Lead로부터 변경 도메인/파일 정보 수신
2. docs/tests/index.md §1 에서 시나리오(A~I) 확인
3. docs/tests/index.md §3 에서 수정 소스 → 실행할 테스트 확인
4. 해당 테스트만 실행
5. 빠른 회귀 (~2분) 실행
```

### 시나리오별 명령 (A~E, 나머지는 index.md §3 참조)

```bash
# A. AI/LLM 변경 시
clear && OLLAMA_BASE_URL=http://192.168.0.22:11434 \
pytest tests/test_ai_api.py tests/test_keyword_recommenders.py --tb=short -v

# B. Reasoning 변경 시
clear && OLLAMA_BASE_URL=http://192.168.0.22:11434 \
pytest tests/test_reasoning_api.py tests/test_reason_document.py --tb=short -v

# C. Knowledge 변경 시
clear && pytest tests/test_knowledge_api.py tests/test_approval_bulk_api.py tests/test_phase20_5.py --tb=short -v

# D. 검색/캐시 변경 시
clear && pytest tests/test_api_routers.py tests/test_search_service.py tests/test_hybrid_search.py --tb=short -v

# E. 인증/권한 변경 시
clear && pytest tests/test_auth_permissions.py tests/test_admin_api.py --tb=short -v

# 빠른 회귀 (위 시나리오 PASS 후)
clear && pytest tests/ -m "not llm and not integration" --tb=short -q
```

---

## 결과 출력·완료 감지 (inotifywait — Phase-F 이관)

| 항목 | 내용 |
|------|------|
| **공유 디렉터리** | `/tmp/agent-messages/` (에이전트 간 결과·완료 신호 통일) |
| **tester 측** | 장시간 테스트 완료 시 해당 디렉터리에 **내용 있는** 결과 파일 기록 (예: `<phase>-tester.json`에 `{"verdict":"PASS/FAIL","summary":"...","failures":[...]}`). **빈 파일 금지** |
| **호출 측** | `inotifywait -m -e close_write /tmp/agent-messages/` 등으로 감시 후 **파일 내용** 읽기. 결과는 이 경로만 사용. bash sleep 폴링 지양 |
| **패키지** | `inotify-tools` (`apt-get install inotify-tools` / `brew install inotify-tools`) |

### 롤 넘기기

테스트 완료 후 SendMessage와 **동일 내용**을 `/tmp/agent-messages/<phase>-tester.json` 등에 기록 → Team Lead가 경로에서 파일을 읽어 액세스 → 롤 넘김.

---

## AB_COMPARISON 프로토콜 (Phase-F 상세화)

`5th_mode.branch: true` + A/B 대상 Task 존재 시, TESTING 통과 후 **AB_COMPARISON** 상태 활성화. Tester는 두 Branch(A/B)에 동일 테스트 실행 후 비교.

```
1. Team Lead로부터 AB_COMPARISON 요청 수신
   - Branch-A, Branch-B 식별자
   - 비교 기준(성능·커버리지·안정성 등)
2. Branch-A 테스트:
   - git checkout phase-{X}-{Y}-branch-A
   - pytest + E2E 실행
   - 결과 기록
3. Branch-B 테스트 (동일 명령):
   - git checkout phase-{X}-{Y}-branch-B
   - 동일 테스트 실행
4. 비교 보고서:
   - TEMPLATES/ab-comparison-template.md 형식
   - 성능 지표·통과율·커버리지 비교
5. SendMessage → Team Lead에 비교 결과
```

**주의사항**:
- 두 Branch에서 **동일 테스트 명령** 실행
- Branch 전환 시 **Docker 재빌드** 필요 가능 (환경 의존성 확인)
- 비교 결과는 `docs/phases/phase-X-Y/ab-comparison-report.md`에도 저장

---

## §KPI-driven Test Plan (Phase-G, AutoCycle Step 10)

**규칙 ID**: 해당 없음 (절차 확장)
**적용 시점**: Step 7~9 Phase Chain 완료 후, Step 10 진입 시
**입력**: `TEMPLATES/development-plan-template.md §3.2 KPI→테스트 매핑` 표
**출력**: 단위/통합/시나리오/E2E/Playwright 5종 테스트 계획서

### 절차

```
[1] Team Lead → tester: SendMessage로 development-plan.md §3.2 KPI→테스트 매핑 표 전달
[2] tester: KPI별 테스트 유형·명령·판정 기준 확인
[3] tester: 아래 5종 테스트 계획 표 작성
[4] tester: SendMessage → Team Lead에게 테스트 계획서 전달
```

### 5종 테스트 계획 표 (템플릿)

```markdown
## KPI-driven Test Plan — Phase X-Y

### 단위 테스트 (Unit)
| KPI ID | 테스트 파일 | 테스트 명령 | 판정 기준 |
|--------|-----------|-----------|-----------|
| KPI-01 | tests/test_{module}.py | `clear && pytest tests/test_{module}.py --tb=short -v` | {PASS 조건} |

### 통합 테스트 (Integration)
| KPI ID | 테스트 범위 | 명령 | 판정 기준 |
|--------|-----------|------|-----------|
| KPI-01 | {모듈 간 연동} | `clear && pytest tests/ -m integration --tb=short -v` | {조건} |

### 사용자 시나리오 테스트 (User Scenario)
| KPI ID | 시나리오 | 수행 절차 | 기대 결과 |
|--------|---------|-----------|-----------|
| KPI-03 | {사용자 행동 흐름} | {단계별 조작} | {화면·응답} |

### E2E 테스트 (End-to-End)
| KPI ID | E2E 명령 | 판정 기준 |
|--------|---------|-----------|
| KPI-03 | `clear && npx playwright test tests/e2e/{scenario}.spec.ts` | PASS 100% |

### Playwright 테스트 (UI 자동화)
| KPI ID | 스펙 파일 | 주요 검증 | 판정 기준 |
|--------|---------|-----------|-----------|
| KPI-03 | `tests/e2e/{name}.spec.ts` | {UI 요소 존재·동작·응답시간} | PASS + 스크린샷 |
```

### KPI 미매핑 처리

- KPI 표에 테스트 방법이 "N/A"인 항목 → tester가 "측정 불가 사유 + 대체 검증법" 명시
- 대체 검증이 불가능한 KPI → `tech-debt-report.md`에 "미검증 KPI" 등록

---

**문서 관리**: v1.3, TESTER 테스트 절차 (2026-04-13 생성, 2026-04-15 Phase-E·F, 2026-04-16 Phase-G 확장)
