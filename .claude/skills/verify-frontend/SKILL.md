---
name: verify-frontend
description: 프론트엔드 코드 심층 리뷰. G2_fe 게이트 검증. SSOT ROLES/verifier.md §2.2 기준 적용.
user-invocable: false
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep"
---

# verify-frontend — 프론트엔드 코드 심층 리뷰

## 역할

`SSOT/ROLES/verifier.md` §2.2 프론트엔드 검증 기준에 따라 변경 파일을 검토하고 G2_fe 판정을 반환한다.

## 입력

`$ARGUMENTS` — 검증 대상 파일 경로 목록 (공백 구분) 또는 디렉토리 경로

파일 목록이 비어있으면 `git diff --name-only HEAD`에서 `web/` 하위 파일을 자동 수집한다.

## 검증 기준

### Critical (1건이라도 있으면 FAIL)

1. **외부 CDN 참조 없음**: `cdn.jsdelivr.net`, `cdnjs.cloudflare.com`, `unpkg.com` 등 외부 CDN 미사용
2. **innerHTML XSS**: `innerHTML` 사용 시 `esc()` 이스케이프 함수 적용 확인
3. **ESM 패턴**: `<script>` 태그에 `type="module"` 사용, `import`/`export` 패턴 준수
4. **콘솔 에러**: 페이지 구조상 명백한 런타임 에러 유발 코드 없음
5. **기존 동작 깨짐**: 기존 페이지의 이벤트 핸들러, 라우팅 등이 변경으로 깨지지 않는지 확인

### High (권장 통과)

6. **전역 오염 없음**: `window` 전역 객체에 새 함수/변수 할당 없음
7. **컴포넌트 재사용**: 기존 공유 컴포넌트 활용 (`layout-component.js`, `header-component.js` 등)
8. **API 에러 핸들링**: fetch/API 호출 시 try-catch + 사용자 메시지 표시
9. **반응형 레이아웃**: Bootstrap grid 시스템 사용, 모바일 대응

### Low (개선 권장)

10. **JSDoc 주석**: 모듈/함수에 JSDoc 주석 존재
11. **CSS 네이밍**: 일관된 CSS 클래스 네이밍 (BEM 또는 프로젝트 컨벤션)
12. **접근성**: `aria-label`, `alt` 속성 등 기본 접근성 준수

## 실행 절차

1. `$ARGUMENTS`에서 파일 경로 파싱 (없으면 git diff에서 web/ 파일 수집)
2. 각 파일을 Read로 읽어 검증 기준 항목별 검사
3. CDN 참조 패턴 검색 (Grep)
4. innerHTML 사용 시 esc() 동반 여부 확인 (Grep)
5. script 태그의 type="module" 사용 확인 (Grep)
6. 기존 컴포넌트 import 여부 확인 (Grep)
7. 판정 결과를 아래 형식으로 반환

## 출력 형식

```markdown
## G2_fe 검증 결과

### 판정: PASS | FAIL | PARTIAL

### 검사 요약
- Critical: N건
- High: N건
- Low: N건

### 이슈 목록 (FAIL/PARTIAL 시)
| 등급 | 파일:라인 | 설명 |
|------|-----------|------|
| C/H/L | path:NN | ... |

### 검증 파일 목록
- file1.html
- file2.js
```

## 판정 규칙

| 조건 | 판정 |
|------|------|
| Critical 1건 이상 | **FAIL** |
| Critical 0건, High 있음 | **PARTIAL** |
| Critical 0건, High 0건 | **PASS** |
