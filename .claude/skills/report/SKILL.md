---
name: report
description: 직전 대화에서 생성된 분석/보고서 출력을 .md 파일로 저장한다.
argument-hint: "[--path=PATH] [--format=FMT] [--append] [--section=NAME] [--no-meta] [--help]"
user-invocable: true
allowed-tools: "Read, Write, Edit, Bash"
---

# report — 보고서 .md 파일 저장

## 역할

현재 대화에서 생성된 분석 결과, 비교 리포트, 설계 문서 등 보고서 성격의 출력물을 .md 파일로 저장한다.

## 입력

`$ARGUMENTS` — 옵션 위주. 위치 인수는 사용하지 않음 (모두 `--key=value` 형식).

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--path=PATH` | key-value | (자동) | 저장 경로/파일명 |
| `--format=FMT` | key-value | `md` | 출력 포맷 (`md` 외 `pptx`/`docx`/`html`은 미구현 — 향후 추가 예정) |
| `--append` | flag | false | 기존 파일에 이어 붙이기 (`--section`과 함께 사용 권장) |
| `--section=NAME` | key-value | (없음) | 특정 섹션만 추출/저장 |
| `--no-meta` | flag | false | 보고서 상단 메타 헤더(작성일·제목) 생략 |
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

### 상호배타

- `--append` 와 `--no-meta` 는 함께 사용 가능 (이어쓰기 시 메타 자동 생략 권장)
- `--format` 값이 `md` 가 아니면 즉시 "미구현 — 향후 추가 예정" 메시지 출력 후 종료

## 입력 파싱

`$ARGUMENTS`를 공백 단위로 토큰화하여 다음 규칙에 따라 분류:

| 패턴 | 종류 | 예시 |
|------|------|------|
| `--key=value` | 키-값 옵션 | `--path=docs/r.md` |
| `--key="value with spaces"` | 키-값 옵션 (인용) | `--section="비교 분석"` |
| `--flag` | 불린 플래그 (값 없음) | `--append`, `--no-meta` |
| 그 외 | 위치 인수 | (사용 안 함) |

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

### 1. 포맷 검증

- `--format` 기본값: `md`.
- `md` 외(`pptx`, `docx`, `html` 등) 지정 시: "미구현 — 향후 추가 예정. 현재 `--format=md`만 지원." 출력 후 종료.

### 2. 대상 콘텐츠 식별

- 현재 대화에서 가장 최근에 생성된 보고서/분석 출력을 식별한다.
- 표, 코드 블록, 구조화된 분석 등 보고서 성격의 출력을 대상으로 한다.
- `--section=NAME` 지정 시 해당 섹션 헤더 하위만 추출.

### 3. 파일명·저장 위치 결정

- `--path=PATH`가 있으면 그대로 사용.
  - 파일명만 전달 시 **기본 저장 위치**(아래)에 저장.
  - 경로 포함 시 해당 경로에 저장.
- 없으면 보고서 제목/내용에서 파일명을 자동 추출.
  - 한글 제목은 영문 kebab-case로 변환.
  - 확장자 `.md` 자동 추가.

**기본 저장 위치 (표준)**:

| 상황 | 저장 위치 | 파일명 |
|------|-----------|--------|
| 활성 Phase 있음 (status.md ≠ DONE) | `docs/phases/phase-X-Y/reports/` | `{YYMMDD}-{제목-kebab}.md` |
| 활성 Phase 없음 (일반 분석·보고) | `docs/reports/` | `{YYMMDD}-{제목-kebab}.md` |

- 디렉토리가 없으면 자동 생성한다.
- 현재 작업 디렉토리(루트)에 흩뿌리지 않는다 — 반드시 위 표준 위치 또는 `--path` 명시 경로에만 저장.

### 4. 파일 저장

- `--append` 미지정: Write 도구로 새 파일 생성.
- `--append` 지정: 기존 파일이 있으면 이어 붙이기 (없으면 신규 생성).
- `--no-meta` 미지정 시 보고서 상단에 메타 정보를 포함:
  - 작성일 (오늘 날짜)
  - 원본 제목

### 5. 결과 보고

- 저장된 파일 경로를 사용자에게 알린다.
- 파일 크기(줄 수)를 함께 표시한다.

## 예시

```
/report                                          # 자동 파일명 → docs/reports/ (Phase 활성 시 phase-X-Y/reports/)
/report --path=docs/my-report.md                 # 명시 경로
/report --path=docs/r.md --append                # 이어 붙이기
/report --section="비교 분석" --path=docs/cmp.md  # 특정 섹션만
/report --format=pptx                            # 미구현 안내 후 종료
/report --help                                   # 도움말
```

## 참조

- 기본 저장 위치 정의: `docs/guide/index.html` → 🗂 기록·알림 위치
- Phase 산출물 경로 규칙: HR-4 / CHAIN-10
