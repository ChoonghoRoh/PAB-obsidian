---
title: "PAB SSOT — 9 PERSONA Charter + 11명 Verification Council (QUALITY/10-persona-qc)"
description: "역할별 페르소나 9종(LEADER/PLANNER/BACKEND/FRONTEND/QA/RESEARCH x3)의 마인드셋 + 11명 Verification Council의 동적 선택·비토 권한·점수 산정·체크리스트 (5세대 Multi-perspective)"
created: 2026-05-05 05:13
updated: 2026-05-05 05:13
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[PAB_SSOT]]", "[[PERSONA]]", "[[VERIFICATION_COUNCIL]]", "[[QC]]"]
tags: [research-note, pab-ssot-nexus, persona, qc, verification-council, multi-perspective]
keywords: ["LEADER", "PLANNER", "BACKEND", "FRONTEND", "QA", "RESEARCH_LEAD", "RESEARCH_ARCHITECT", "RESEARCH_ANALYST", "11명 Council", "Security Veto", "Performance Veto", "동적 선택", "다수결", "점수 산정", "PASS 85+", "PARTIAL 70~84", "FAIL <70", "Tech Debt"]
sources:
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/PERSONA/"
  - "~/WORKS/PAB-SSOT-Nexus/docs/SSOT/docs/QUALITY/10-persona-qc.md"
aliases: ["페르소나 Charter", "11명 Council", "Verification Council"]
---

# PAB SSOT — 페르소나 Charter + Verification Council

## §1 PERSONA — 마인드셋 레이어 (10파일)

> **원칙**: ROLES/*.md = **불변 실행 가이드**, PERSONA/*.md = **교체 가능 마인드셋**. 스폰 시 PERSONA가 Charter를 덮어씀. 다른 페르소나 유형으로 자유 교체 가능.

### 9 페르소나 일람

| 파일 | 적용 팀원 | 페르소나 핵심 |
|---|---|---|
| **LEADER.md** | Team Lead | 최상위 지휘자 — 기술 스택·폴더 구조·업무 배분 총괄, 인터페이스 먼저 확정 |
| **PLANNER.md** | planner | 분석가 — 영향 범위·요구사항·Task 분해, 쓰기 금지 SendMessage 전용 |
| **BACKEND.md** | backend-dev | "데이터 모델링·비즈니스 로직의 정답" 추구 (Claude 비유) |
| **FRONTEND.md** | frontend-dev | "사용자 중심 UI 구현·상태 관리 최적화" (Gemini 비유) |
| **QA.md** | verifier·tester 공유 | **냉철한 검수자** — "단 한 줄의 버그도 허용 안 함", 취약점 발견·최적화 대안 제시 |
| **RESEARCH_LEAD.md** | research-lead | 리서치 총괄자 — 기술 트렌드·선택지·팀원 조율, research-report.md 통합 작성 |
| **RESEARCH_ARCHITECT.md** | research-architect | 아키텍처 영향도 분석가 — PoC 설계·기술 스택 비교 |
| **RESEARCH_ANALYST.md** | research-analyst | 코드베이스·벤치마크 분석가 — WebSearch/WebFetch 활용 |
| **README.md** | — | 페르소나 교체 원칙 설명 |

### 페르소나 교체 메커니즘

스폰 시 다른 PERSONA를 덮어쓰기 가능. 예: backend-dev에 보안 페르소나 BACKEND.md 대신 SECURITY_BACKEND.md를 주입하면 보안 관점 1차 — 단, 이는 향후 확장 옵션이고 현재 9개가 표준.

### 핵심 협업 원칙 (Charter 인용)

| 페르소나 | 협업 지시 |
|---|---|
| LEADER → Claude (BE) | "데이터 모델링과 비즈니스 로직의 '정답'을 요구하라" |
| LEADER → Gemini (FE) | "사용자 중심의 UI 구현과 상태 관리 최적화를 지시하라" |
| LEADER → Copilot (QC) | "전체 시스템의 안정성 검토와 배포 전 최종 QC를 명령하라" |
| QA → Gemini/Claude | "발견된 결함에 대해 구체적인 수정안을 제시하며 재작업 요구" |
| QA → Cursor | "현재 프로젝트의 코드 품질 점수와 배포 가능 여부를 보고하라" |

> "Claude/Gemini/Cursor"는 4세대 단계의 도구별 비유로 작성된 표현. 현재는 모두 Claude Code 단일 환경에서 역할 페르소나로만 운영.

---

## §2 11명 Verification Council (5세대 Multi-perspective)

> **활성화 조건**: `5th_mode.multi_perspective: true`. 미설정 시 4세대 호환 — 단일 verifier가 ROLES/verifier.md 기준으로 검증.

### Council 구성

| # | 페르소나 | 핵심 검증 항목 | 비토 |
|:--:|---|---|:--:|
| 1 | **Security Expert** | OWASP Top 10 보안 취약점 | **✅** |
| 2 | **Performance Expert** | 성능·최적화·N+1·메모리 | **✅** |
| 3 | Architecture Expert | 아키텍처 일관성·계층 분리 | ❌ |
| 4 | Test Engineer | 커버리지·엣지 케이스·테스트 품질 | ❌ |
| 5 | UX Expert | 사용자 경험·동선·피드백 | ❌ |
| 6 | Accessibility Expert | WCAG 2.1·키보드·스크린 리더 | ❌ |
| 7 | Data Expert | 데이터 정합성·인덱스·마이그레이션 | ❌ |
| 8 | DevOps Expert | Docker·로그·배포·환경변수 | ❌ |
| 9 | Documentation Expert | API 문서·README·CHANGELOG | ❌ |
| 10 | Code Style Expert | 복잡도·중복·네이밍·HR-5 준수 | ❌ |
| 11 | Domain Expert | 비즈니스 로직·도메인 규칙 | ❌ |

### 동적 선택 규칙 — Phase별 5~6명

#### 필수 멤버 (항상 포함, Veto 보유)
1. **Security Expert** — 보안은 모든 변경에 필수
2. **Performance Expert** — 성능 영향 항상 검증

#### 도메인별 추가

| 도메인 태그 | 추가 멤버 |
|---|---|
| `[BE]` | Architecture Expert, Data Expert, Test Engineer |
| `[FE]` | UX Expert, Accessibility Expert, Code Style Expert |
| `[FS]` | **전원 참여 (11명)** |
| `[DB]` | Data Expert, Architecture Expert, Test Engineer |

#### 선택적 추가

| 상황 | 추가 멤버 |
|---|---|
| 리팩토링 Phase | Code Style Expert |
| UI 중심 변경 | UX Expert |
| 배포 관련 변경 | DevOps Expert |
| 마이그레이션 포함 | Data Expert |
| 문서 변경 포함 | Documentation Expert |
| 비즈니스 로직 변경 | Domain Expert |

### Veto Power + 합성 규칙

#### 비토 발동
- **Security/Performance Expert만 단독 FAIL 판정** 가능
- 비토 발동 시 다른 점수 무관 즉시 **FAIL**

#### 다수결 (비토 미보유 9명)
- **3인 이상 FAIL 판정 → 종합 FAIL**
- 3인 미만 FAIL → 점수 합산 기반 판정

#### 점수 산정

| 심각도 | 감점 |
|---|---:|
| Critical | -10 |
| High | -5 |
| Medium | -2 |
| Low | -1 (선택적) |

기준 점수 100점.

#### 최종 판정

| 점수 | 판정 | 후속 |
|---:|---|---|
| **85+** | **PASS** | 다음 Phase 진행 |
| **70~84** | **PARTIAL** | 기술 부채 기록 후 진행 가능 |
| **<70** | **FAIL** | 수정 후 재검증 필수 |

#### Tech Debt 기록 (PARTIAL 시)
- 경로: `docs/phases/phase-X-Y/tech-debt.md`
- 항목: 이슈 내용·심각도·해당 파일·해결 예정 Phase
- Master Plan 작성 시 참조 필수 (CHAIN-12)

### 페르소나별 핵심 체크리스트

#### Security Expert (10항목)
SQL Injection 방어 / XSS 방어 / CSRF 토큰 / 인증 누락 / 인가 권한 / 민감 정보 로깅 방지 / 파일 업로드 검증 / Rate Limiting / HTTPS 강제 / 의존성 CVE

#### Performance Expert (8항목)
N+1 쿼리 / 불필요한 데이터 로딩 / 캐싱 전략 / 응답 시간 (API <200ms) / 메모리 누수 / 페이지네이션 / 비동기 처리 / 인덱스 활용도

#### Architecture Expert (8항목)
ORM 패턴 / 트랜잭션 격리 / 에러 처리 일관성 / RESTful 규칙 / 계층 분리 (Controller→Service→Repository) / 비즈니스 로직 위치 / 입력 유효성 / 로깅 수준

#### Test Engineer (8항목)
단위 테스트 커버리지 (≥80%) / 통합 테스트 주요 경로 / 엣지 케이스 (빈값·경계·대량) / 테스트 격리성 / 목 사용 적절성 / Arrange-Act-Assert / 회귀 테스트 / 에러 시나리오

#### UX Expert (6항목)
에러 메시지 친화성 / 사용자 동선 자연스러움 / 로딩 피드백 / 성공·실패 알림 명확성 / Undo 가능성 / 도움말 충분성

#### Accessibility Expert (7항목)
WCAG 2.1 AA / 키보드 네비게이션 / 스크린 리더 (ARIA) / 색상 대비 ≥4.5:1 / 포커스 관리 / 대체 텍스트 (alt) / 폼 레이블 연결

#### Data Expert (10항목)
UNIQUE/NOT NULL 제약 / 인덱스 설계 (복합 포함) / 정규화 판단 / EXPLAIN 확인 / 마이그레이션 롤백 / 외래 키 정합성 / NULL 처리 / 참조 무결성 / 동시성 (레이스 컨디션) / 소프트 vs 하드 삭제

#### DevOps Expert (6항목)
Docker 멀티스테이지 빌드 / 구조화 로그 / .env 보안 / 배포 스크립트 / 헬스체크 / 리소스 제한

#### Documentation Expert (5항목)
API 문서 완전성 / 코드 주석 (WHY 위주) / README 업데이트 / CHANGELOG / 설정 파일 문서화

#### Code Style Expert (7항목)
순환 복잡도 (≤10) / 파일 길이 (≤500, **HR-5**) / 함수 길이 (≤50) / 네이밍 일관성 / DRY (코드 중복) / ESM 모듈 / 미사용 코드 제거

#### Domain Expert (5항목)
비즈니스 로직 정합성 / 도메인 규칙 준수 / 로직 위치 (Controller vs Service) / 입력 유효성 완전성 / 도메인 이벤트 처리

### 검증 프로세스

```
[1] Team Lead 검증 요청 + 도메인 태그 전달
[2] Phase 도메인 확인 ([BE]/[FE]/[FS]/[DB])
[3] 도메인 기반 Council 멤버 자동 선택 (필수 2 + 도메인 3~4 + 선택적)
[4] Council 멤버 목록 → status.md 기록
   ↓
[5] 각 멤버 병렬 검증 (Read-only — 수정·커밋·브랜치 변경 금지)
[6] 페르소나 체크리스트 기반 검증
[7] 이슈 발견 시 심각도 태깅 (Critical/High/Medium/Low)
   ↓
[8] 개별 판정 종합 → 최종 G2 결과
[9] 비토 확인 (Security/Performance FAIL?)
   → FAIL: 즉시 전체 FAIL
[10] 다수결 확인 (3인+ FAIL?)
   → FAIL: 종합 FAIL
[11] 점수 합산 → 최종 판정
   ↓
[12] gate-report.md 자동 생성 (AutoReporter)
[13] Team Lead에게 최종 판정 보고
   - PASS: 다음 상태 전이
   - PARTIAL: Tech Debt 기록 + 진행
   - FAIL: 수정 항목 + 이전 상태 복귀
```

## §3 활성화 제어

```yaml
# status.md
5th_mode:
  multi_perspective: true   # true: 11명 Council, false: 단일 Verifier (4th 호환)
```

`false` 또는 미설정 시 → ROLES/verifier.md 기준 단일 검증.

## 다음 노트

- [[2026-05-05_pab_ssot_roles|역할 9종]] — verifier/tester가 Council 위원 자격으로 참여
- [[2026-05-05_pab_ssot_workflow|워크플로우]] — G2 PARTIAL → AUTO_FIX 6조건 AND
- [[2026-05-05_pab_ssot_event_automation|이벤트·자동화]] — DecisionEngine + AutoReporter
- [[2026-05-05_pab_ssot_templates|템플릿]] — tech-debt-report.md, defect-report-template.md
- [[PAB_SSOT_overview|MOC]]

## 참고

- `/PAB-SSOT-Nexus/docs/SSOT/docs/PERSONA/` (10파일)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/QUALITY/10-persona-qc.md` (259줄)
- `/PAB-SSOT-Nexus/docs/SSOT/docs/ROLES/verifier.md` — 단일 verifier 모드 정본
