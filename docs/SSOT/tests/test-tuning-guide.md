# 테스트 절차 튜닝 가이드 (현재 기능 기준, 별도 문서)

이 문서는 “현재 프로젝트 기능”에 맞게 **테스트 절차/구성/실행 전략을 튜닝**하는 방안을 정리한다.  
목표는 ① 신뢰도(실패=의미 있는 실패) ② 실행 속도 ③ 환경 의존성 최소화 ④ 리포트 축적(리팩토링 자료)을 동시에 달성하는 것이다.

---

## 1) 실행 절차 튜닝 (운영/개발 공통)

- **수동 실행 원칙**: `pytest` 또는 `npx playwright test` 를 **한 번에 하나씩** 직접 실행한다. 자동 디스커버리·순차 실행 파이프라인(generate/run_tester_commands)은 **미구현** — 도입은 별도 Phase에서 결정.
- **heavy(LLM/임베딩/Qdrant) 항목은 단독 실행**한다.
  - 이유: 모델 로딩·네트워크·DB IO가 겹치면 타임아웃/과부하가 발생
- **결과는 1주기 문서로 남긴다.**
  - 저장: `docs/pytest-report/YYMMDD-HHMM-phase-X-Y-테스트명.md`

---

## 2) 테스트 분류/마커 튜닝 (pytest)

현재는 `@pytest.mark.integration`만 일부 사용 중이다. 아래 마커를 추가해 “상황별 선택 실행”이 쉬워지게 한다.

- `@pytest.mark.llm`: Ollama/LLM 호출 또는 모델 정책 관련
- `@pytest.mark.qdrant`: Qdrant 접근/임베딩 업서트 관련
- `@pytest.mark.redis`: Redis 접근/캐시 관련
- `@pytest.mark.db`: 실 DB(PostgreSQL) 의존 테스트 (SQLite로 대체 불가)
- `@pytest.mark.smoke`: 라우터/스키마 최소 확인(외부 의존 최소)

예시 실행:

```bash
# 빠른 smoke
pytest tests/ -m "smoke" -v --tb=short

# LLM 관련만 (단독 실행 권장)
pytest tests/ -m "llm" -v --tb=short

# 통합만
pytest tests/ -m "integration" -v --tb=short
```

---

## 3) 환경 의존성 튜닝

### 3.1 TestClient 기반 API 테스트

현재 여러 API 테스트는 “DB 미준비 시 500 허용” 또는 skip을 사용한다. 이는 **라우터 존재/응답 구조** 확인에는 유용하지만, 회귀 판단이 애매해질 수 있다.

개선안:
- “라우터/스키마” 확인은 `smoke`로 분리하고, **통합 환경이 필요한 테스트는 integration/db/llm/qdrant**로 분리한다.
- 통합 테스트가 필요한 케이스는 `/health/ready`의 `checks/latency_ms`로 사전 조건을 확인하고, 미충족 시 skip(명확한 이유 포함).

### 3.2 DB 테스트: SQLite vs PostgreSQL

현재 `db_session`은 SQLite in-memory로 안전하게 격리되지만, 일부 테스트는 `SessionLocal`(실 DB) 접근이 섞여 있다.

개선안:
- “실 DB 의존”은 `@pytest.mark.db`로 명확히 태깅하고 기본 실행에서 제외
- SQLite 호환이 가능한 부분은 `db_session`로 이동(테이블 타입 호환성 검사 유지)

---

## 4) 부하/타임아웃 튜닝

권장 원칙:
- “실패=의미 있는 실패”가 되도록 **타임아웃을 너무 짧게** 잡지 않는다.
- 대신 **중복 실행/동시 실행을 금지**하고, heavy 뒤 `--delay-heavy`로 안정성을 높인다.

추가 개선안:
- LLM 관련 테스트는 “실제 호출”과 “정책/폴백 로직(패치)”를 분리한다.
  - 로직 테스트는 네트워크 없이도 안정적이어야 한다(예: `tests/integration/test_llm_network.py`처럼 urllib patch).

---

## 5) QC/보안/인프라 테스트 정리(Phase 12 QC)

`tests/integration/test_phase_12_qc.py`는 성격이 “QC 체크리스트”에 가깝다. 아래를 권장한다.

- 실제 존재하는 엔드포인트(예: `/api/memories/`)를 기준으로 시나리오를 갱신
- CORS는 TestClient/미들웨어 처리 차이를 고려해 “200/405” 기준을 명확히 하거나,
  별도 통합 환경(uvicorn 실행 + curl) 기준으로 체크한다.
- Rate limit은 config에 따라 기대치가 달라지므로 “기계적 429”이 아니라 “메커니즘 존재”를 확인하는 형태로 유지하거나, config 기반 기대치를 문서화한다.

---

## 6) 문서/인덱스 운용 (로드 가이드)

- 테스트 전체 인덱스: `docs/tests/index.md`
- 상세 리포트: `docs/tests/test-suite-report.md`
- 본 문서(튜닝): `docs/tests/test-tuning-guide.md`

개발 시에는 “변경한 기능 영역”에 맞춰 위 인덱스에서 해당 테스트 파일만 로드(참조)하고,  
테스터에게 넘길 때는 `docs/pytest-report/`에 1주기 요청·결과를 남기는 것을 표준으로 한다.

