---
phase: "2"
title: "PAB-LLMDATA 셀프호스팅 클라우드 — SSOT 예외 정의"
ssot_version: 8.0-renewal-6th
created: 2026-06-16
updated: 2026-06-16
status: ACTIVE   # Phase 2 전체 DONE 시 ARCHIVED 전이
master_plan_ref: docs/phases/phase-2-master-plan.md
---

# Phase 2 SSOT 예외 정의 (E-1 ~ E-4)

본 Phase는 코드 산출물이 아닌 **인프라·배포 산출물**(docker-compose, MCP 서버, 자동화 스크립트)을 다룬다. SSOT 본체는 무수정하며, 아래 4건의 예외를 적용한다. 각 예외는 SSOT의 어떤 규칙을 무엇으로 대체하는지 명시한다.

## E-1: G2_be/G2_fe → **G2_infra** (인프라·배포 검증 게이트)

- **사유**: 본 Phase 산출물은 백엔드/프론트엔드 애플리케이션 코드가 아니라 컨테이너·배포·동기화 인프라다. 코드 리뷰형 G2(verify-backend/frontend)가 부적합하다.
- **대체**: G2_infra 게이트로 검증한다. 판정 기준은 [phase-2-master-plan.md §6](phase-2-master-plan.md) 참조.
  - 서비스 헬스(컨테이너 healthy, 엔드포인트 응답)
  - 보안(인증 강제, Tailnet 전용 바인딩, 공개 노출 0)
  - 기능 정합성(Sub-Phase별 핵심 KPI 충족)
- **검증 주체**: Team Lead 또는 verifier가 구현자(backend-dev)와 독립적으로 수행(HR-6 유지).

## E-2: HR-5 500/700줄 리팩토링 → **인프라 설정파일 비대상**

- **사유**: docker-compose.yml, *.ini, nginx conf 등 선언형 설정파일은 라인 수 기준 리팩토링 규정(REFACTOR-1~3)의 대상이 아니다(분할이 오히려 가독성·운영성을 해침).
- **대체**: 인프라 설정파일은 레지스트리 등록 대상에서 제외. 단 본 Phase가 생성하는 **애플리케이션 코드**(MCP 서버 `pab-kb-mcp`, 인덱서, 자동화 워커 등)는 HR-5를 정상 적용한다.

## E-3: G3 pytest → **G3_smoke** (서비스 헬스체크·E2E)

- **사유**: 인프라/동기화 동작은 단위 테스트(pytest)보다 실제 서비스 기동·엔드포인트·E2E 흐름 검증이 적합하다.
- **대체**: G3_smoke로 대체. 각 Sub-Phase의 smoke 기준:
  - 2-1: CouchDB 헬스 OK, 다기기 양방향 동기화 확인, per-machine 파일 미동기화 확인
  - 2-2: stateless MCP 호출 정상, search 결과 정합
  - 2-3: URL 트리거 → 노트쌍 생성 → 동기화 → 인덱싱 E2E, 외부 API 호출 0
- **검증 주체**: tester 비스폰. Team Lead/verifier가 smoke 수행.

## E-4: 자동화 추론 외부 API → **영구 금지** (데이터 주권)

- **사유**: PAB = Personal AI Brain. 데이터 주권·비용 통제가 설계 철학이다. 무인 자동화 추론에 엔터프라이즈 API(GPT/Claude/Gemini)를 쓰면 노트 내용이 외부로 유출된다.
- **대체**: 무인 자동화 추론은 **로컬(3800X vLLM Qwen3.6-27B)** 으로만 수행. 대화형 `/pab:wiki`(Claude Code)는 사용자 주도이므로 허용(하이브리드, DP-3). 이 예외는 영구 유효하며 ARCHIVED되지 않는다.

---

## 적용 현황

| Sub-Phase | E-1 | E-2 | E-3 | E-4 |
|---|---|---|---|---|
| 2-1 동기화/백업 | G2_infra 적용 | 설정파일 비대상 | G3_smoke 적용 | 해당 없음(추론 무) |
| 2-2 RAG/MCP | G2_infra 적용 | MCP 코드는 HR-5 적용 | G3_smoke 적용 | 검색만, 추론 무 |
| 2-3 자동화 | G2_infra 적용 | 워커 코드는 HR-5 적용 | G3_smoke 적용 | **로컬 vLLM 강제** |
| 2-4 통합검증 | G2_infra 통합 | — | G3_smoke 통합 | 호출 0 검증 |
