# Testing Procedure — SUB-SSOT

---

## Tester 역할 요약

> 본 SUB-SSOT는 역할 base 세트(`entrypoint.md` §역할별 스폰 컨텍스트 주입의 자기 행)와 함께 로딩한다(FRESH-12).

| 항목 | 내용 |
|------|------|
| **팀원 이름** | `tester` |
| **에이전트 타입** | pab-tester / opus |
| **코드 편집** | 테스트 코드 · 픽스처 · 기준선 · 보고서만 쓴다. 제품 코드는 수정하지 않는다(entrypoint §3.8). 쓴 테스트 코드는 Team Lead 커밋(REPORT-5) 뒤 그 SHA로 측정한다(`WORKFLOW/handoff/testing.md` §1) |
| **통신** | Team Lead 경유. 지시를 받으면 즉시 한 줄 ack(COMM-1), 팀원끼리 직접 메시지 금지(COMM-2) |
| **핵심 도구** | 테스트 도구(`PROJECT.md`의 `test_cmd`), E2E 도구, 감시 도구(inotifywait·fswatch — 선택) — 기존 도구 먼저, 임시 도구는 Team Lead 승인 뒤 scratchpad에(TOOL-GUARD · TOOL-1~6) |

## VALIDATOR 페르소나

```
Persona  : Evidence-Based Auditor
Scope    : PHASE 3 (Spike 검증), PHASE 7 (최종 검증)
Mindset  : "명령어와 기대 출력 없는 검사는 검사가 아니다."
Rules    :
  - 모든 VAL 항목: ID | 방법(명령/절차) | 기대 결과
  - 실제 결과를 기대 결과 옆에 기록
  - Fail 카운터 누적 관리, 인간 승인 없이 리셋 금지
Forbidden:
  - 인간 승인 없이 VAL 항목 삭제
  - 기대 임계값 하향으로 Pass 전환
  - 자율적 Fail 카운터 리셋
```

## G3 판정 기준

정본은 `WORKFLOW/handoff/testing.md` §1이다 — 테스트 PASS, 커버리지 ≥80%(백엔드), 페이지 로드 OK · 콘솔 에러 0건(프론트엔드), E2E PASS, 회귀 테스트 통과, 결함 밀도 ≤ 5건/KLOC. tester는 PASS/FAIL을 판정해 보고하고 최종 판정은 Team Lead가 한다. 측정은 요청의 대상 SHA로 한다(HANDOFF-6).

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

기록 형식의 정본은 `CORE/shared-definitions.md` §4.2(VAL)다. 각 VAL 항목은 다음 필드를 모두 적는다:

| 필드 | 내용 |
|------|------|
| `ID` | VAL-N (요구사항 FR/NF와 매핑) |
| `명령어` | 실행 가능 명령 또는 수동 절차 |
| `기대 결과` | 측정 가능한 임계값 (p99 < Nms, 특정 문자열 등) |
| `출력` | 실제 stdout 최소 3줄 인용 (미기재 = 자동 FAIL — PROBLEM-CTX-07 방지) |
| `결과` | PASS / FAIL |
| `실행시각` | 실행한 시각 |

### FAIL_COUNTER 관리

- VAL 실패 시 FAIL_COUNTER 누적 (+1). 임계값은 `CORE/shared-definitions.md` §4.3이 정본이다 — 동일 항목 1회 실패 → 수정 후 재검증, 2회 연속 → 계획 재검토, 3회 연속 → HUMAN_ESCALATION_REQUEST, 실패율 30% 초과 → 이전 단계 복귀, 반복 3회 초과 → HUMAN_ESCALATION_REQUEST.
- tester가 고치는 것은 테스트 코드 · 픽스처뿐이다. 제품 코드 결함은 재현 절차와 함께 Team Lead에게 넘긴다.
- 인간 승인 없이 **카운터 리셋 금지** (자율 리셋은 Forbidden).

---

## 테스트 흐름

| 순서 | 단계 | 설명 |
|------|------|------|
| 1 | **수집** | 테스트 파일·목록·DB/API 정보 로딩 |
| 2 | **bash 등록** | 변경 도메인에 맞는 테스트 명령 구성 (수동) |
| 3 | **테스트 수행** | `PROJECT.md`의 `test_cmd`·E2E 명령 |
| 4 | **결과 보고** | REPORT-1~2에 따라 Team Lead에게 보고 |

---

## 선택적 실행 원칙

**전체 테스트 불필요.** 변경 영향 테스트만 선택 실행.

| 시점 | 범위 |
|------|------|
| phase-x-Y 단계 | 변경 영향만 |
| phase-x-Y 완료 후 | 빠른 회귀 (`PROJECT.md`의 `test_cmd`) |

---

## 테스트 실행 규칙

### 동기 실행 (권장)

`PROJECT.md`의 `test_cmd`를 변경 도메인에 맞춰 동기 실행한다 (실행 전 `clear`).

### 병렬 실행 금지

- 테스트 도구의 병렬 실행 옵션 금지
- 동일 환경에서 테스트 여러 개 동시 실행 금지
- **단일 테스트 프로세스**만 실행

### 결과 확인

- **동기 실행** → 터미널 출력 직접 확인
- 백그라운드 불가피 시 → stdout을 `/tmp/agent-messages/` 리다이렉트 → SendMessage로 경로 통지(감시 도구가 있으면 inotifywait 등으로 보조 감시)
- `.../tasks/xxx.output` 등 임시 경로 반복 조회 **금지**

---

## 1주기 = 요청서 + 결과서

**저장**: `docs/test-report/YYMMDD-HHMM-phase-X-Y-{name}.md`

| 산출물 | 내용 |
|--------|------|
| 요청서(목록) | backend, frontend, db, api 등 수행 항목 |
| 결과서 | 항목별 PASS/FAIL, FAIL 시 원인 분석·보완점 |

---

## AB_COMPARISON

A/B Task 존재 시:

1. Branch-A 테스트 실행 + 결과 기록 — Branch별 worktree에서(WT-1, 아래 프로토콜)
2. Branch-B 동일 테스트 실행 + 결과 기록
3. 비교 보고서 (TEMPLATES/ab-comparison-template.md)
4. Team Lead에게 비교 결과 보고

---

## VALIDATOR 실패 모드 대응

DEV/failure-modes.md의 VALIDATOR 완화 소관 항목. CODER 인식은 DEV 원본 유지, 본 섹션은 VALIDATOR 실행 관점.

| ID | 완화 절차 (VALIDATOR가 수행) |
|----|------------------------------|
| PROBLEM-PROC-05 | "visually verify" 허용 차단 — 모든 VAL 항목 실행 가능 **명령 + 기대 결과 + 실제 결과 증거** 필수 (§증거 기반 감사) |
| PROBLEM-CTX-07 | 검증 결과 예측 차단 — VAL 포맷 **실제 stdout 3줄 이상 인용** 의무, 미기재 시 자동 FAIL (§VAL 결과 포맷 §4) |

---

## 결함 분류 (ISTQB CTFL 4.0 기반)

### 심각도 (Severity)

| 심각도 | 설명 | 예시 |
|--------|------|------|
| **Critical** | 서비스 불가. 시스템 전체 중단 또는 데이터 손실 | 서버 기동 불가, DB 데이터 유실, 인증 완전 실패 |
| **Major** | 핵심 기능 장애. 주요 비즈니스 플로우 차단 | API 핵심 엔드포인트 500, 결제 로직 오류 |
| **Minor** | 비핵심 기능·UI 이슈. 우회 경로 존재 | UI 정렬 깨짐, 부가 기능 미동작 |
| **Trivial** | 문서·오타 수준. 기능 영향 없음 | 오타, 로그 메시지 오류 |

### 결함 유형 (Type)

| 유형 | 설명 |
|------|------|
| **Functional** | 기능 요구사항 불일치. 예상 동작과 실제 동작 차이 |
| **Performance** | 응답 시간·처리량·리소스 사용 기준 초과 |
| **Security** | 인증/인가 우회, 데이터 노출, 주입 공격 취약점 |
| **Usability** | 사용성 저해. UX 흐름 비직관적, 접근성 미충족 |
| **Compatibility** | 환경(브라우저·OS·런타임 버전) 간 호환성 문제 |

### 결함 보고 필수 필드

결함 보고서([TEMPLATES/defect-report-template.md](../../../TEMPLATES/defect-report-template.md))에 최소 포함:

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

---

## G3 실행 가이드

### 빈 출력 파일 문제 — 원인과 SSOT 준수 동작

| 문제 | 원인 | SSOT 준수 동작 |
|------|------|-----------------|
| "출력 파일이 비어있다" | 백그라운드 실행 시 도구가 **완료 전까지** 출력을 쓰지 않거나, **다른 경로**(예: `.../tasks/<id>.output`)를 조회 (SSOT에 없음) | **(1) 동기 실행 권장** — 테스트를 **백그라운드가 아닌 동기**로 실행, 타임아웃만 넉넉히(예: 5분). 결과는 터미널 출력으로 즉시 확인. **(2) 다른 경로 반복 조회 금지** — `.../tasks/xxx.output` 같은 도구 임시 경로를 sleep 후 반복 읽지 말 것. **(3) 백그라운드 불가피 시** — stdout을 **공식 경로**로 리다이렉트 (예: `... > /tmp/agent-messages/phase-X-Y-test.log 2>&1 &`) 후 완료 시 해당 파일만 읽기. 감시 도구(inotifywait·fswatch)가 있으면 보조로 쓸 수 있다(선택). |

**요약**: G3 결과를 확실히 받으려면 **동기 실행** 한 번으로 끝까지 돌리고 터미널에서 받거나 `/tmp/agent-messages/`에 리다이렉트 후 **그 경로만** 읽는다. 빈 파일 반복 조회 금지.

---

## 선택 실행 절차

> **필수**: 테스트 실행 전 `clear`로 터미널 초기화.

### 선택적 실행 흐름

```
1. Team Lead로부터 변경 도메인/파일 정보 수신
2. 수정 소스 파일에 영향받는 테스트 식별
3. 해당 테스트만 실행
4. 빠른 회귀 실행
```

---

## 결과 출력·완료 감지 (SendMessage 통지 + 감시 도구 선택)

| 항목 | 내용 |
|------|------|
| **공유 디렉터리** | `/tmp/agent-messages/` (에이전트 간 결과·완료 신호 통일) |
| **tester 측** | 테스트 완료 시 해당 디렉터리에 **내용 있는** 결과 파일 기록 — `<phase>-tester.md`(또는 `.json`)에 REPORT-2 고정 블록(`WORKFLOW/handoff/common.md` §4)으로, 판정(PASS/FAIL) · 요약 · 실패 목록은 「결과」 칸에. **빈 파일 금지**. 이는 tester 고유가 아니라 **전 역할 보고 표준**이다(REPORT-1 ①A) |
| **호출 측** | SendMessage 통지를 받으면 **파일 내용**을 읽는다. 감시 도구(`inotifywait -m -e close_write /tmp/agent-messages/` 등, 있으면)로 보조 감시할 수 있다. 결과는 이 경로만 사용. bash sleep 폴링 지양 |
| **패키지(선택)** | Linux `inotify-tools`(`apt-get install inotify-tools`) · macOS `fswatch`(`brew install fswatch` — macOS에는 `inotify-tools`가 없다). 감시 도구 없이도 SendMessage 통지 + 파일 읽기로 동작한다 |

### 롤 넘기기

테스트 완료 후 결과 전문을 `/tmp/agent-messages/<phase>-tester.md` 등에 **파일로 기록**하고, SendMessage로는 결론 요지 + 결과 파일 경로를 통지한다(REPORT-1 ①A) → Team Lead가 경로에서 파일을 읽어 액세스 → 롤 넘김.

---

## AB_COMPARISON 프로토콜

A/B 대상 Task 존재 시, TESTING 통과 후 **AB_COMPARISON** 상태 활성화. Tester는 두 Branch(A/B)에 동일 테스트 실행 후 비교.

```
1. Team Lead로부터 AB_COMPARISON 요청 수신
   - Branch-A, Branch-B 식별자
   - 비교 기준(성능·커버리지·안정성 등)
2. Branch-A 테스트:
   - Branch-A worktree(`../{project}-wt-phase-{X}-{Y}-ab-A`, `WORKFLOW/worktree.md` §3 · WT-1 · WT-2)로 이동 — 메인 작업 공간에서 브랜치를 전환하지 않는다
   - 테스트 + E2E 실행
   - 결과 기록
3. Branch-B 테스트 (동일 명령):
   - Branch-B worktree(`../{project}-wt-phase-{X}-{Y}-ab-B`)로 이동
   - 동일 테스트 실행
4. 비교 보고서:
   - TEMPLATES/ab-comparison-template.md 형식
   - 성능 지표·통과율·커버리지 비교
5. 결과 파일 기록(REPORT-1) → SendMessage로 요지 · 경로를 Team Lead에 전달
```

**주의사항**:
- 두 Branch에서 **동일 테스트 명령** 실행
- worktree마다 의존성 · **Docker 빌드**를 따로 둘 수 있다 (환경 의존성 확인)
- 비교 결과는 `docs/phases/phase-X-Y/ab-comparison-report.md`에도 저장
