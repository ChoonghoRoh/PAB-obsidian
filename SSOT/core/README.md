# core/ — 이식 가능 프레임워크

> 프로젝트에 독립적인 SSOT 운영 규칙·워크플로우·자동화 모듈.
> 다른 프로젝트로 이식 시 이 디렉토리를 그대로 복사한다.

## 파일 배치 (Phase 24-1-3 비파괴적 전환)

현재 단계에서는 기존 파일 위치를 유지하고, 아래 참조 경로로 연결한다.
실제 파일 이동은 Phase 24-4 완료 후 일괄 수행한다.

| 파일 | 현재 위치 | 설명 |
|------|-----------|------|
| 3-workflow.md | [../3-workflow.md](../3-workflow.md) | 20개 상태 머신, Phase Chain, Gate |
| 4-event-protocol.md | [../4-event-protocol.md](../4-event-protocol.md) | 이벤트 프로토콜 (EVENT-1~6) |
| 5-automation.md | [../5-automation.md](../5-automation.md) | 자동화 파이프라인 (AUTO-1~6) |
| 6-rules-index.md | [6-rules-index.md](6-rules-index.md) | 규칙 통합 인덱스 (72개 상위/106개 전체) |

## 하위 디렉토리

| 디렉토리 | 현재 위치 | 설명 |
|----------|-----------|------|
| QUALITY/ | [../QUALITY/](../QUALITY/) | 10-persona-qc.md (11명 Verification Council) |
| TEMPLATES/ | [../TEMPLATES/](../TEMPLATES/) | 리서치 리포트, 이벤트 로그, A/B 비교, 의사결정 로그 템플릿 |
