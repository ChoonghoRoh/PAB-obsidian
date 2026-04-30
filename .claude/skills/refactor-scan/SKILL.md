---
name: refactor-scan
description: 500/700줄 초과 파일 탐지. HR-5 Level 분류.
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep, Bash"
---

# refactor-scan -- 코드 파일 줄수 스캔 및 리팩토링 Level 분류

## 역할

HR-5(코드 유지관리 리팩토링 규정)에 따라 프로젝트 내 코드 파일의 줄수를 스캔하고, 500/700/1000줄 기준으로 분류하여 리팩토링 대상을 식별한다.

## 입력

`$ARGUMENTS` -- 스캔 대상 경로 (선택)

- 경로 지정: 해당 디렉토리 하위만 스캔
- 인수 없음: 프로젝트 루트에서 전체 스캔

## 실행 절차

### 1. 제외 디렉토리 설정

아래 디렉토리는 스캔에서 제외한다:

- `.venv/`
- `node_modules/`
- `.git/`
- `libs/`
- `__pycache__/`
- `.next/`
- `dist/`
- `build/`

### 2. 코드 파일 줄수 스캔

Bash로 코드 파일의 줄수를 측정한다:

```bash
find {target_path} \
  -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" \) \
  -not -path "*/.venv/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/libs/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.next/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -exec wc -l {} + | sort -rn
```

### 3. Level 분류

스캔 결과를 아래 기준으로 분류한다:

| 줄수 | 등급 | 설명 |
|------|------|------|
| 500 초과 | WATCH | 레지스트리 등록 대상 |
| 700 초과 | WARN | Level 분류 필요 (Lv1/Lv2) |
| 1000 초과 | DANGER | 즉시 리팩토링 필요 |

### 4. Level 세부 분류 (700줄 초과 파일)

700줄 초과 파일에 대해 추가 분석한다:

- **Lv1 (독립 분리 가능)**: import 관계가 단순하고 독립 모듈로 분리 가능한 경우
- **Lv2 (연관 파일 밀접)**: 다수 파일과 상호 의존하여 별도 Phase로 리팩토링이 필요한 경우

Lv1/Lv2 판정은 해당 파일의 import/export 관계를 Grep으로 확인하여 참고 정보를 제공한다. 최종 판정은 사람이 수행한다.

### 5. 레지스트리 확인

- `SSOT/refactoring/` 하위에 기존 레지스트리 파일이 있는지 Glob으로 확인한다.
- 있으면 기존 등록 파일과 신규 탐지 파일을 대비한다.

## 출력 형식

```markdown
## Refactor Scan 결과

### 요약 통계
- 전체 스캔 파일: {N}개
- WATCH (500줄 초과): {N}개
- WARN (700줄 초과): {N}개
- DANGER (1000줄 초과): {N}개

### DANGER (1000줄 초과) -- 즉시 리팩토링
| 파일 | 줄수 | Level | 비고 |
|------|------|-------|------|
| {path} | {lines} | Lv1/Lv2 | {참고} |

### WARN (700줄 초과) -- Level 분류 필요
| 파일 | 줄수 | Level | 비고 |
|------|------|-------|------|
| {path} | {lines} | Lv1/Lv2 | {참고} |

### WATCH (500줄 초과) -- 레지스트리 등록 대상
| 파일 | 줄수 |
|------|------|
| {path} | {lines} |

### 레지스트리 대비
- 기존 등록: {N}개
- 신규 탐지: {N}개
- 해소됨: {N}개
```
