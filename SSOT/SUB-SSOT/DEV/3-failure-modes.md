# Failure Modes — SUB-SSOT (CODER 인식용)

> **버전**: 1.1 | **갱신**: 2026-04-15 (Phase-E task-E-2-4 — REVIEWER/VALIDATOR 소관 Fix는 VERIFIER/TESTER 참조로 축약)
> **원본**: `_backup/GUIDES/DEV-work-guide/3-dev-problem-analysis.md`
> **변경**: v1.0 Recommended fix 1줄 압축. v1.1에서 REVIEWER 소관 Fix는 `SUB-SSOT/VERIFIER/1-verification-procedure.md §REVIEWER 실패 모드 대응`, VALIDATOR 소관 Fix는 `SUB-SSOT/TESTER/1-testing-procedure.md §VALIDATOR 실패 모드 대응` 참조.
> **로딩**: 선택적 — 복잡/위험 작업에서만 로딩 권장

## 개요

AI 하네스로 기능 개발 시 발생하는 24개 공지된 실패 모드. 위험도 높은 작업 전 **CODER 인식용**. REVIEWER/VALIDATOR 완화 절차는 각자 SUB-SSOT 참조.

---

## §1 레이어별 문제 (11개)

### BE — Backend (4개)

| ID | 트리거 | 실패 유형 | Fix 요약 |
|----|--------|-----------|----------|
| PROBLEM-BE-01 | API 계약 없이 엔드포인트 구현 | DEFERRED | PHASE 0 GATE에 API_CONTRACT 잠금 추가 |
| PROBLEM-BE-02 | 인증 미들웨어 누락 | SILENT | PHASE 3에 auth decorator 검사(VUL1-06) 추가 |
| PROBLEM-BE-03 | 단위 테스트 Pass지만 통합 실패 | DEFERRED | VAL 항목에 Mock_scope 필드 + 대응 통합 VAL 필수화 |
| PROBLEM-BE-04 | PHASE 7 재작성 시 로직 subtle drift | SILENT | → `SUB-SSOT/VERIFIER/` REVIEWER가 Spike↔PHASE 7 구조 비교 |

### FE — Frontend (3개)

| ID | 트리거 | 실패 유형 | Fix 요약 |
|----|--------|-----------|----------|
| PROBLEM-FE-01 | FE를 BE 관점으로 계획 | DEFERRED | PHASE 0에 FE 컴포넌트/에러/로딩 상태 산출물 필수 |
| PROBLEM-FE-02 | 시나리오가 BE 편향 | DEFERRED | FE Layer에 FE_State_before/after/FE_Verify 필드 추가 |
| PROBLEM-FE-03 | API 변경 시 FE 미통보 | SILENT | API_CONTRACT_CHANGE 블록 + FE CODER 수신 확인 |

### DB — Database (3개)

| ID | 트리거 | 실패 유형 | Fix 요약 |
|----|--------|-----------|----------|
| PROBLEM-DB-01 | 스키마 정의 없이 테이블 추가 | SILENT | PHASE 1에 DB_SCHEMA 잠금 (PHASE 3 전) |
| PROBLEM-DB-02 | 기존 데이터 마이그레이션 실패 | DEFERRED | PHASE 7에 DB-MIGRATE-CHECK(파괴적 변경/백필/롤백) 필수 |
| PROBLEM-DB-03 | 쿼리 전략 불일치 (Spike↔본구현) | SILENT | CODER: PHASE 0에 쿼리 전략 선언 / PHASE 7 REVIEWER 검사 → `SUB-SSOT/VERIFIER/` |

### Infra — Infrastructure (3개 중 일부)

| ID | 트리거 | 실패 유형 | Fix 요약 |
|----|--------|-----------|----------|
| PROBLEM-INFRA-01 | 환경변수/설정 하드코딩 | SILENT | PHASE 0 산출물에 .env.example diff 포함, PHASE 7 grep 검사 |
| PROBLEM-INFRA-02 | 로컬 Pass / CI 실패 (환경 불일치) | DEFERRED | PHASE 1 risk에 환경 동등성 기재, PHASE 7에 Docker 테스트 VAL |
| PROBLEM-INFRA-03 | 배포 타겟 미명시 (멀티노드) | DEFERRED | PHASE 0 산출물에 Deploy Target 열 + PR 기획에 sync 방법 |

---

## §2 프로세스·협업 문제 (8개)

| ID | 트리거 | 실패 유형 | Fix 요약 |
|----|--------|-----------|----------|
| PROBLEM-PROC-01 | 의미론적 모호성 (패턴 매칭 부족) | SILENT | PHASE 0에 DIMENSION_SCAN (6차원 분해) 추가 |
| PROBLEM-PROC-02 | fn/integration 요청 단위 혼재 | VISIBLE | PHASE 0에 IMPL_GRANULARITY 선언 필수 |
| PROBLEM-PROC-03 | 시나리오↔TODO 매핑 누락 | VISIBLE | TODO에 covered_by 필드 + 고아 시나리오 정리 |
| PROBLEM-PROC-04 | 인터페이스 정의가 PLANNER 단독 | VISIBLE | PHASE 6에 CODER 미니리뷰(INTERFACE_REVIEW) 추가 |
| PROBLEM-PROC-05 | "visually verify" 허용 | SILENT | → `SUB-SSOT/TESTER/` VALIDATOR 증거 기반 감사 규칙 |
| PROBLEM-PROC-06 | 동일 컨텍스트 리뷰 bias | SILENT | Option B(같은 세션 역할전환) 폐기, A/C만 허용 |
| PROBLEM-PROC-07 | 구현 순서↔VAL 실행 순서 불일치 | VISIBLE | PHASE 6에 DEPENDENCY_ORDER_AUDIT 추가 |
| PROBLEM-PROC-08 | 역할 간 문서 읽기 목록 미정의 | SILENT | 각 역할의 PHASE 7 진입 시 READ 목록 의무화 |

---

## §3 Long Context 문제 (7개)

| ID | 유형 | 실패 유형 | Fix 요약 |
|----|------|-----------|----------|
| PROBLEM-CTX-01 | ID 참조 drift (VAL-3에 VAL-7 내용) | SILENT | ID + 내용 1줄 echo 의무 |
| PROBLEM-CTX-02 | 시간적 혼란 (이전 버전 기억) | SILENT | PHASE 7 시작 시 CHECKPOINT_READ 의무 |
| PROBLEM-CTX-03 | 크로스 피처 오염 (다른 기능 참조) | SILENT | PHASE 0에 FEATURE_NAMESPACE 선언 |
| PROBLEM-CTX-04 | 체크리스트 일괄 통과 | SILENT | ANTI-COMPRESSION 규칙 (core/7-shared §1.2) |
| PROBLEM-CTX-05 | 문서 말미 잘림 (truncation) | SILENT | CONTENT_COMPLETENESS_CHECK (wc -l + tail -20) |
| PROBLEM-CTX-06 | 역할 페르소나 붕괴 | VISIBLE | ROLE_CHECK 의무 (core/7-shared §2.1) |
| PROBLEM-CTX-07 | 검증 결과 예측 (미실행) | **SILENT** | → `SUB-SSOT/TESTER/` VAL 포맷 stdout 3줄 의무 |

---

## §4 우선순위 매트릭스

### P1 — 즉시 적용 (보안·무결성 위험)

| ID | 문제 | 최우선 이유 |
|----|------|-------------|
| CTX-07 | 검증 미실행 예측 | 가장 위험한 침묵 실패 — GATE 무력화 |
| CTX-04 | 체크리스트 일괄 통과 | GATE 자체 무효화 |
| BE-02 | 인증 미들웨어 누락 | 보안 취약점이 테스트 통과 |
| DB-01 | 스키마 두 버전 공존 | Spike↔본구현 불일치 |
| PROC-06 | 동일 컨텍스트 리뷰 | 자기 합리화 BLOCKER→PASS |

### P2 — 조기 적용 (품질 영향)

BE-01, FE-01, FE-02, DB-02, PROC-01, PROC-02, CTX-01, CTX-02

### P3 — 계획적 적용 (효율 개선)

BE-03, FE-03, DB-03, INFRA-01~03, PROC-03~05, CTX-03

### P4 — 여유 시 적용 (시스템 보완)

PROC-07, PROC-08, CTX-05, CTX-06

---

**문서 관리**: v1.0, 원본 3-dev-problem-analysis.md 축약
