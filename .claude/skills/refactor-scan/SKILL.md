---
name: refactor-scan
description: 500/700줄 초과 파일 탐지. HR-5 Level 분류.
argument-hint: "[path] [--threshold=N] [--json] [--help]"
user-invocable: true
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep, Bash"
---

# refactor-scan — 코드 파일 줄수 스캔 및 리팩토링 Level 분류

## 역할

HR-5(코드 유지관리 리팩토링 규정)에 따라 프로젝트 내 코드 파일의 줄수를 스캔하고, 500/700/1000줄 기준으로 분류하여 리팩토링 대상을 식별한다.

## 입력

`$ARGUMENTS` — 위치 인수(`path`, 선택) + 옵션.

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--threshold=N` | key-value | `500` | WATCH 임계값 변경 (예: `--threshold=300` 으로 더 엄격하게) |
| `--json` | flag | false | JSON 형식 출력 (기본은 마크다운) |
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- `--json` 과 출력 형식 옵션 충돌 없음 (현 시점). 추후 `--csv` 등 추가 시 상호배타 검토.

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | `--threshold=300` |
| `--key="value with spaces"` | 키-값 옵션 (인용) | (해당 없음) |
| `--flag` | 불린 플래그 (값 없음) | `--json`, `--help` |
| 그 외 | 위치 인수 | `backend/`, `scripts/` |

### 파싱 절차

1. `$ARGUMENTS`를 공백 기준 토큰화 (`"..."` 또는 `'...'` 안의 공백은 보존)
2. `--`로 시작하는 토큰을 옵션으로 분리
3. 나머지 토큰을 위치 인수로 수집
4. 알 수 없는 옵션은 경고 출력 (실행 계속)
5. **상호배타 옵션이 동시 지정되면 즉시 오류 종료** (결정 #4)
6. **`--help` 우선 처리**: `options.help === true`이면 §0 헬프 출력 후 즉시 종료

## 실행 절차

### 0. --help 처리 (PAB 공통)

§입력 파싱에서 `options.help === true`로 판별되면:

1. 표준 헬프 포맷으로 본 스킬 설명 출력 (description, argument-hint, 옵션 표, 예시)
2. 즉시 종료 (이후 단계 미실행)

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

위치 인수(`path`)가 있으면 해당 경로, 없으면 프로젝트 루트(`.`).

> 🔴 **스캔 범위 = HR-5 「개발 파일」에 한정**한다.
> `docs/SSOT/WORKFLOW/refactoring/refactoring-rules.md` §1 용어 정의:
> *"**개발 파일** | \*.py, \*.js, \*.css, \*.html (**테스트·설정·문서 제외**)"*
> 따라서 `tests/`·`test/`는 스캔 대상이 아니다 — 포함하면 **규칙에 없는 예산**이 산출되고,
> 그 오판이 제품 설계 결정을 바꾼다.

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
  -not -path "*/tests/*" \
  -not -path "*/test/*" \
  -exec wc -l {} + | sort -rn
```

### 3. Level 분류

`THRESHOLD = options.threshold || 500` 기준으로 분류:

| 줄수 | 등급 | 설명 |
|------|------|------|
| THRESHOLD 초과 | WATCH | 레지스트리 등록 대상 — **단 HR-5 「개발 파일」에 한함** |
| THRESHOLD * 1.4 초과 (기본 700) | WARN | Level 분류 필요 (Lv1/[예외]) |
| THRESHOLD * 2 초과 (기본 1000) | DANGER | 즉시 리팩토링 필요 |

> ⚠️ **「등록 대상」은 무조건이 아니다.** 등급은 줄수만으로 매기지만, **레지스트리 등록·
> 리팩토링 편성 의무는 규칙 §1의 「개발 파일」(테스트·설정·문서 **제외**)에만 발생**한다.
> §2 `find`가 이미 테스트를 제외하므로 정상 경로에서는 문제가 없으나, `path` 인수로
> 테스트 경로를 직접 지정한 경우 등급이 나와도 **등록 의무는 없다** — 보고 시 구분해 적는다.

### 4. Level 세부 분류 (WARN 이상 파일)

WARN 이상에 대해 추가 분석(`refactoring-rules.md` §3.2 자동 판별 기준):

- **Lv1 (분리 가능)**: 연관 파일 중 500줄 초과가 없거나, 있어도 단방향 참조만인 경우
- **[예외] 후보**: 연관 파일과 양방향 참조(밀접)가 있어 분리가 맞지 않는 경우 — §5 [예외] 확정 조건 충족 여부는 사람이 판단

Lv1/[예외] 판정은 import/export 관계를 Grep으로 확인하여 참고 정보를 제공. 최종 판정은 사람이 수행한다.

### 5. 레지스트리 확인

- `docs/SSOT/WORKFLOW/refactoring/` 하위에 기존 레지스트리 파일이 있는지 Glob으로 확인.
- 있으면 기존 등록 파일과 신규 탐지 파일을 대비한다.

### 6. 출력

- `--json` 미지정: 마크다운 표 (아래 형식)
- `--json` 지정: JSON 객체 (`{summary, danger[], warn[], watch[], registry_diff}`)

## 출력 형식 (마크다운)

```markdown
## Refactor Scan 결과

### 요약 통계
- 임계값: {THRESHOLD}줄
- 전체 스캔 파일: {N}개
- WATCH (>{THRESHOLD}): {N}개
- WARN (>{THRESHOLD*1.4}): {N}개
- DANGER (>{THRESHOLD*2}): {N}개

### DANGER — 즉시 리팩토링
| 파일 | 줄수 | Level | 비고 |
|------|------|-------|------|
| {path} | {lines} | Lv1/[예외] | {참고} |

### WARN — Level 분류 필요
| 파일 | 줄수 | Level | 비고 |
|------|------|-------|------|

### WATCH — 레지스트리 등록 대상
| 파일 | 줄수 |
|------|------|

### 레지스트리 대비
- 기존 등록: {N}개
- 신규 탐지: {N}개
- 해소됨: {N}개
```

## 예시

```
/refactor-scan                        # 전체 스캔
/refactor-scan backend/               # 특정 디렉토리만
/refactor-scan --threshold=300        # 더 엄격한 기준
/refactor-scan --json                 # JSON 출력
/refactor-scan --help                 # 도움말
```
