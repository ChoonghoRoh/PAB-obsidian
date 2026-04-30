---
name: rules-lookup
description: 6-rules-index.md에서 규칙 ID 빠른 조회.
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Grep"
---

# rules-lookup -- 규칙 빠른 조회

## 역할

`6-rules-index.md`에서 규칙 ID 또는 키워드로 빠르게 규칙을 검색하고 관련 정보를 반환한다.

## 입력

`$ARGUMENTS` -- 규칙 ID 또는 키워드 (선택)

- 규칙 ID 지정: "HR-1", "CHAIN-6", "FRESH-1", "REFACTOR-2" 등
- 키워드 지정: "CRITICAL", "팀원", "리팩토링", "Phase" 등
- 인수 없음: 규칙 개요(총 규칙 수, 카테고리 목록) 표시

## 실행 절차

### 1. 인수 파싱

- `$ARGUMENTS`에서 검색어를 파싱한다.
- 검색어가 없으면 개요 모드로 동작한다.

### 2. 규칙 인덱스 파일 읽기

- `SSOT/core/6-rules-index.md`를 대상으로 한다.
- 둘 다 없으면 오류를 반환한다.

### 3-A. 개요 모드 (인수 없음)

- 파일 전체를 Read로 읽는다.
- 총 규칙 수를 집계한다.
- 카테고리(HR, CHAIN, FRESH, REFACTOR 등) 목록과 각 카테고리별 규칙 수를 표시한다.

### 3-B. 검색 모드 (인수 있음)

- Grep으로 검색어와 매칭되는 줄을 찾는다.
- 매칭된 규칙의 ID, 제목, 요약, 심각도를 추출한다.
- 매칭 결과가 없으면 NO MATCH를 반환한다.

## 출력 형식

### 개요 모드

```markdown
## Rules Overview

### 통계
- 총 규칙 수: {N}개

### 카테고리
| 카테고리 | 규칙 수 | 설명 |
|----------|---------|------|
| HR | {N} | Hard Rules (절대 위반 금지) |
| CHAIN | {N} | Chain Rules (연쇄 규칙) |
| FRESH | {N} | Fresh Rules (세션 규칙) |
| REFACTOR | {N} | Refactor Rules (리팩토링) |
| ... | ... | ... |
```

### 검색 모드

```markdown
## Rules Lookup: "{검색어}"

### 매칭 결과: {N}건

| ID | 제목 | 심각도 | 요약 |
|----|------|--------|------|
| {id} | {title} | {severity} | {summary} |

### 상세 (매칭 1건일 경우)

#### {id}: {title}
- 심각도: {severity}
- 카테고리: {category}
- 내용: {full_description}
```
