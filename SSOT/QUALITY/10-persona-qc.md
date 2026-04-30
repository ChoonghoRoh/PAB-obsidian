# 11명 Verification Council (5세대 신규)

> Multi-perspective 축의 다관점 검증 체계

---

## §1 Council 구성 (11명)

| # | 페르소나 | 핵심 검증 항목 | 비토 권한 |
|:-:|---------|--------------|:---------:|
| 1 | **Security Expert** | 보안 취약점 검증 (OWASP Top 10) | **Yes** |
| 2 | **Performance Expert** | 성능·최적화 검증 | **Yes** |
| 3 | Architecture Expert | 아키텍처 일관성 검증 | No |
| 4 | Test Engineer | 테스트 커버리지·품질 검증 | No |
| 5 | UX Expert | 사용자 경험 검증 | No |
| 6 | Accessibility Expert | 접근성 검증 | No |
| 7 | Data Expert | 데이터 모델·무결성 검증 | No |
| 8 | DevOps Expert | 배포·인프라 검증 | No |
| 9 | Documentation Expert | 문서 품질 검증 | No |
| 10 | Code Style Expert | 코드 스타일·가독성 검증 | No |
| 11 | Domain Expert | 비즈니스 로직 검증 | No |

---

## §2 동적 선택 규칙

### 2.1 선택 원칙
매 검증 시 **Task 도메인에 따라 5~6명을 동적 선택**한다.

### 2.2 필수 멤버 (항상 포함, Veto Power 보유)
1. **Security Expert** — 보안은 모든 변경에 필수 (단독 FAIL 판정 가능)
2. **Performance Expert** — 성능 영향 항상 검증 (단독 FAIL 판정 가능)

### 2.3 도메인별 추가 멤버

| 도메인 태그 | 추가 멤버 | 근거 |
|------------|----------|------|
| `[BE]` 백엔드 중심 | + Architecture Expert, Data Expert, Test Engineer | API/DB/테스트 검증 |
| `[FE]` 프론트엔드 중심 | + UX Expert, Accessibility Expert, Code Style Expert | UI/UX/스타일 검증 |
| `[FS]` 풀스택 | **전원 참여** (11명) | 양쪽 모두 검증 |
| `[DB]` 데이터베이스 중심 | + Data Expert, Architecture Expert, Test Engineer | 스키마/데이터 변경 검증 |

### 2.4 선택적 추가 멤버

| 상황 | 추가 멤버 | 근거 |
|------|----------|------|
| 리팩토링 Phase | + Code Style Expert | 코드 구조 변경 품질 |
| UI 중심 변경 | + UX Expert | 사용자 경험 검증 |
| 배포 관련 변경 | + DevOps Expert | 인프라/배포 영향 검증 |
| 마이그레이션 포함 | + Data Expert | 데이터 무결성 검증 |
| 문서 변경 포함 | + Documentation Expert | 문서 품질 검증 |
| 비즈니스 로직 변경 | + Domain Expert | 비즈니스 규칙 정합성 |

---

## §3 Veto Power 및 합성 규칙

### 3.1 비토(VETO) 규칙
- **Security Expert** 및 **Performance Expert**만 **단독 FAIL 판정** 가능
- 비토 발동 시 다른 페르소나 점수와 무관하게 최종 판정 즉시 **FAIL**

### 3.1a 다수결 규칙 (비토 미보유 Expert)
- 비토 권한이 없는 Expert는 **다수결** 방식으로 판정
- **3인 이상이 FAIL** 판정 시 → 종합 **FAIL**
- 3인 미만 FAIL 시 → 점수 합산 기반 판정 (§3.3 참조)

### 3.2 점수 산정

| 이슈 심각도 | 감점 |
|------------|------|
| Critical | -10점 |
| High | -5점 |
| Medium | -2점 |
| Low | -1점 (참고 기록만, 감점 선택적) |

- **기준 점수**: 100점 만점
- 각 페르소나가 발견한 이슈의 감점을 합산

### 3.3 최종 판정 기준

| 점수 범위 | 판정 | 후속 행동 |
|----------|------|----------|
| 85점 이상 | **PASS** | 다음 Phase 진행 |
| 70 ~ 84점 | **PARTIAL** | 기술 부채 기록 후 진행 가능 |
| 70점 미만 | **FAIL** | 수정 후 재검증 필수 |

### 3.4 기술 부채 기록 (PARTIAL 시)
- `docs/phases/phase-X-Y/tech-debt.md`에 기록
- 기록 항목: 이슈 내용, 심각도, 해당 파일, 해결 예정 Phase
- Master Plan 작성 시 기술 부채 목록 참조 필수

---

## §4 페르소나별 체크리스트

### 4.1 Security Expert (비토 권한)
- [ ] SQL Injection 방어: 파라미터 바인딩 사용 여부
- [ ] XSS 방어: 사용자 입력 이스케이프 처리
- [ ] CSRF 토큰 검증 적용 여부
- [ ] 인증(Authentication) 누락 엔드포인트 존재 여부
- [ ] 인가(Authorization) 권한 검증 적절성
- [ ] 민감 정보 로깅 방지 (비밀번호, 토큰 등)
- [ ] 파일 업로드 검증 (타입, 크기, 경로 탐색)
- [ ] Rate Limiting 적용 여부
- [ ] HTTPS 강제 적용 확인
- [ ] 의존성 취약점 (알려진 CVE) 확인

### 4.2 Performance Expert (비토 권한)
- [ ] N+1 쿼리 패턴 존재 여부
- [ ] 불필요한 데이터 로딩 (eager/lazy 로딩 적절성)
- [ ] 캐싱 전략 적절성
- [ ] 응답 시간 목표 충족 (API: < 200ms)
- [ ] 메모리 누수 가능성
- [ ] 대량 데이터 처리 시 페이지네이션 적용
- [ ] 비동기 처리 적절성 (blocking 작업)
- [ ] 인덱스 활용도

### 4.3 Architecture Expert
- [ ] ORM 사용 패턴 적절성
- [ ] 트랜잭션 범위 및 격리 수준
- [ ] 에러 처리 일관성 (에러 코드, 메시지)
- [ ] API 엔드포인트 RESTful 규칙 준수
- [ ] 계층 분리 (Controller → Service → Repository)
- [ ] 비즈니스 로직 위치 적절성
- [ ] 입력 유효성 검증 완전성
- [ ] 로깅 수준 적절성

### 4.4 Test Engineer
- [ ] 단위 테스트 커버리지 (목표: 80% 이상)
- [ ] 통합 테스트 주요 경로 포함 여부
- [ ] 엣지 케이스 테스트 (빈값, 경계값, 대량)
- [ ] 테스트 격리성 (다른 테스트와 독립)
- [ ] 목(Mock) 사용 적절성
- [ ] 테스트 가독성 (Arrange-Act-Assert)
- [ ] 회귀 테스트 존재 여부
- [ ] 에러 시나리오 테스트

### 4.5 UX Expert
- [ ] 에러 메시지 사용자 친화성
- [ ] 사용자 동선 자연스러움
- [ ] 로딩 상태 피드백 제공
- [ ] 성공/실패 알림 명확성
- [ ] 실행 취소(Undo) 가능 여부
- [ ] 도움말/안내 텍스트 충분성

### 4.6 Accessibility Expert
- [ ] WCAG 2.1 AA 수준 준수
- [ ] 키보드 네비게이션 가능 여부
- [ ] 스크린 리더 호환성 (ARIA 속성)
- [ ] 색상 대비 비율 (최소 4.5:1)
- [ ] 포커스 관리 적절성
- [ ] 대체 텍스트 (alt) 제공
- [ ] 폼 레이블 연결

### 4.7 Data Expert
- [ ] 데이터 정합성 제약 조건 (UNIQUE, NOT NULL)
- [ ] 인덱스 설계 적절성 (복합 인덱스 포함)
- [ ] 정규화/비정규화 판단 근거
- [ ] 쿼리 실행 계획 확인 (EXPLAIN)
- [ ] 마이그레이션 롤백 가능성
- [ ] 외래 키 관계 정합성
- [ ] NULL 처리 전략 일관성
- [ ] 참조 무결성 유지
- [ ] 동시성 처리 (레이스 컨디션 방지)
- [ ] 소프트 삭제 vs 하드 삭제 전략

### 4.8 DevOps Expert
- [ ] Docker 설정 적절성 (멀티스테이지 빌드)
- [ ] 로그 형식 표준화 (구조화된 로그)
- [ ] 환경 변수 관리 (.env 파일 보안)
- [ ] 배포 스크립트 정상 동작
- [ ] 헬스체크 엔드포인트 존재
- [ ] 리소스 제한 설정 (CPU, 메모리)

### 4.9 Documentation Expert
- [ ] API 문서 완전성 (엔드포인트, 파라미터, 응답)
- [ ] 코드 내 주석 적절성 (WHY 위주)
- [ ] README 업데이트 여부
- [ ] 변경 로그(CHANGELOG) 기록
- [ ] 설정 파일 문서화

### 4.10 Code Style Expert
- [ ] 순환 복잡도 (함수당 10 이하)
- [ ] 파일 길이 (500줄 이하, HR-5 준수)
- [ ] 함수 길이 (50줄 이하)
- [ ] 네이밍 컨벤션 일관성
- [ ] 코드 중복 (DRY 원칙)
- [ ] ESM 모듈 시스템 적용 여부
- [ ] 사용하지 않는 코드 제거

### 4.11 Domain Expert
- [ ] 비즈니스 로직 정합성
- [ ] 도메인 규칙 준수 여부
- [ ] 비즈니스 로직 위치 적절성 (Controller vs Service)
- [ ] 입력 유효성 검증 완전성
- [ ] 도메인 이벤트 처리 적절성

---

## §5 검증 프로세스

### 5.1 검증 요청

```
1. Team Lead가 검증 요청 + 도메인 태그 전달
2. Phase 도메인 태그 확인 ([BE], [FE], [FS], [DB])
3. 도메인 기반 Council 멤버 자동 선택 (§2 규칙)
4. Council 멤버 목록 → status.md에 기록
```

### 5.2 병렬 검증

```
5. 각 멤버가 전문 영역 검증 수행 (Read-only)
   - 코드 파일 읽기만 허용
   - 수정, 커밋, 브랜치 변경 금지
6. 각 페르소나 체크리스트(§4) 기반 검증 수행
7. 이슈 발견 시 심각도 태깅 (Critical/High/Medium/Low)
```

### 5.3 결과 합성

```
8. 개별 판정 종합 → 최종 G2 결과
9. 비토 확인: Security/Performance Expert FAIL 여부
   → FAIL: 즉시 전체 FAIL 판정
10. 다수결 확인: 3인+ FAIL 여부 (비토 미보유 Expert)
   → FAIL: 종합 FAIL 판정
11. 점수 합산 (§3.2 기준) → 최종 판정 (§3.3 기준)
```

### 5.4 결과 보고

```
12. gate-report.md 자동 생성 (AutoReporter)
13. Team Lead에게 최종 판정 보고
    - PASS: 다음 상태로 전이
    - PARTIAL: 기술 부채 기록 + 진행 가능
    - FAIL: 수정 항목 목록 + 이전 상태 복귀
```

---

## §6 활성화

### 6.1 활성화 조건
- `5th_mode.multi_perspective: true` 설정 시 본 Council 체계가 활성화된다

### 6.2 미활성화 시 동작
- `5th_mode.multi_perspective: false` 또는 미설정 시 **기존 단일 Verifier 방식**(4th 호환)으로 동작한다
- 단일 Verifier가 [ROLES/verifier.md](../ROLES/verifier.md) 기준으로 검증 수행

### 6.3 설정 예시

```yaml
5th_mode:
  multi_perspective: true    # true: 11명 Council, false: 단일 Verifier
```
