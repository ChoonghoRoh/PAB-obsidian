---
name: project-config
description: PROJECT.md 단일 설정 문서 관리 — init(대화형 생성)/sync(hooks.env 재생성)/show(현재 설정 요약)/check(정합성 검사).
argument-hint: "[init|sync|show|check] [--help]"
user-invocable: true
context: inherit
agent: main
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion"
---

# project-config — 프로젝트 단일 설정 문서 관리

## 역할

`PROJECT.md`(프로젝트 루트)를 프로젝트별 설정의 **단일 소스**로 관리한다.
프로젝트명·성격·플랫폼·개발언어·빌드 명령·코드 영역·품질 임계값·페르소나 오버라이드를 이 문서 하나에서 설정하고,
frontmatter는 `scripts/sync-project-config.sh`를 통해 `.claude/hooks/hooks.env`로 파생된다.

```
PROJECT.md (단일 소스)
  ├─ frontmatter ──sync──▶ .claude/hooks/hooks.env ──▶ 훅 9종 (HR-1/HR-5 가드 등)
  └─ 프로즈 §1~§9 ────────▶ Team Lead·팀원 스폰 시 로드 (규칙 오버라이드·페르소나)
```

## 입력

`$ARGUMENTS` — 위치 인수 + 옵션.

### 위치 인수 (1번)

| 값 | 설명 |
|------|------|
| `init` | PROJECT.md 대화형 생성 (프로젝트 스캔 → 질문 → 작성 → sync) |
| `sync` | frontmatter → hooks.env 재생성 |
| `show` | 현재 설정 요약 출력 |
| `check` | 정합성 검사 (frontmatter vs hooks.env vs 실제 폴더 구조) |
| (생략) | `show`로 동작 |

### 옵션

| 옵션 | 종류 | 기본값 | 설명 |
|------|------|--------|------|
| `--help` | flag | false | **공통** — 본 작업 미실행, 설명·옵션 표만 출력 후 종료 |

## 실행 절차

### 0. --help 처리 (PAB 공통)

`--help` 지정 시 표준 헬프 포맷 출력 후 즉시 종료.

### 1. init 모드

1. **기존 검사**: `PROJECT.md`가 이미 있으면 사용자에게 덮어쓰기/부분 갱신/중단을 질문.
2. **프로젝트 스캔** (질문 전에 자동 추론할 수 있는 값 수집):
   - 언어·스택: `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml` 등 탐지
   - 빌드/테스트 명령: package.json scripts, Makefile, justfile 탐지
   - 코드 폴더: 루트 1-depth 디렉토리 중 코드 파일 비중이 높은 폴더 추출
3. **질문** (AskUserQuestion, 스캔 결과를 기본값으로 제시):
   - 프로젝트 이름·한 줄 성격
   - project_type (web-app/api-server/fullstack/cli/library/mobile/data)
   - 코드 영역 폴더 (HR-1 가드 대상) — 스캔 추론값 확인
   - 알림 채널 (telegram/none)
4. **작성**: 번들의 PROJECT.md 템플릿 구조(§1~§9)를 따라 생성. frontmatter에 응답 반영, 프로즈 섹션에는 스캔 결과(스택 표, 작업 폴더 표, 빌드 명령) 기입.
5. **sync 실행**: `./scripts/sync-project-config.sh` 호출 후 결과 요약 출력.

### 2. sync 모드

```bash
./scripts/sync-project-config.sh
```

- 스크립트 부재 시: PROJECT.md frontmatter를 직접 읽어 `.claude/hooks/hooks.env`를 §스키마(하단) 형식으로 생성.
- 완료 후 변경된 키를 diff 요약으로 보고.

### 3. show 모드

1. `PROJECT.md` frontmatter를 읽어 표로 요약 (이름/성격/플랫폼/언어/빌드·테스트 명령/코드 영역/HR-5/알림).
2. `hooks.env` 생성 시각과 신선도(`sync-project-config.sh check`) 표시.
3. 프로즈 섹션 중 기본값이 아닌 항목(§4 규칙 오버라이드, §6 페르소나 오버라이드에 내용이 있는 행)을 나열.

### 4. check 모드

아래 정합성을 검사하고 PASS/WARN 표로 보고:

| # | 검사 | WARN 조건 |
|---|------|-----------|
| 1 | frontmatter ↔ hooks.env 동기화 | `sync-project-config.sh check` exit 3 |
| 2 | `code_dirs` 실존 여부 | 나열된 폴더가 프로젝트에 없음 (신규 프로젝트면 정보성) |
| 3 | `build/test/run_cmd` 실행 가능성 | 명령의 실행 파일이 PATH/프로젝트에 없음 |
| 4 | `ssot_version` ↔ `docs/SSOT/VERSION.md` 일치 | 불일치 (FRESH-2) |
| 5 | 페르소나 오버라이드 파일 실존 | §6에 기입된 경로가 없음 |
| 6 | 알림 설정 | `notify_channel: telegram`인데 토큰 환경변수 미설정 |
| 7 | 번들 기본값 미변경 | `project_name`이 `PAB-claude`인데 저장소 폴더명이 다름 (이식 후 PROJECT.md 미설정) → `/project-config init` 안내 |

WARN 발견 시 수정 방법을 함께 안내한다.

## hooks.env 스키마 (파생 산출물)

| 키 | 소스 frontmatter | 소비자 |
|----|------------------|--------|
| `PAB_PROJECT_NAME` / `PAB_PROJECT_TYPE` | project_name / project_type | SessionStart 훅, /notify-telegram |
| `PAB_CODE_DIRS` / `PAB_CODE_EXTS` | code_dirs / code_exts | hr1-guard, line-count-monitor |
| `PAB_LINE_WARN` / `PAB_LINE_CRIT` | line_warn / line_crit | line-count-monitor, on-task-completed |
| `PAB_COVERAGE_TARGET` | coverage_target | tester (G3) |
| `PAB_NOTIFY_CHANNEL` / `PAB_NOTIFY_LABEL` | notify_channel / notify_project_label | /notify-telegram |
| `PAB_BUILD_CMD` 등 4종 | build/run/test/lint_cmd | tester, dev 팀원 |
| `PAB_SSOT_VERSION` / `PAB_SSOT_PATH` | ssot_version / ssot_path | FRESH-2 검사 |

## 예시

```
/project-config                    # 현재 설정 요약
/project-config init               # 새 프로젝트에서 대화형 생성
/project-config sync               # frontmatter 수정 후 반영
/project-config check              # 정합성 검사
/project-config --help
```

## 참조

- 단일 소스: `PROJECT.md` (프로젝트 루트)
- 동기화 스크립트: `scripts/sync-project-config.sh`
- 자동 동기화: SessionStart 훅(`ssot-freshness-check.sh` §0)이 변경 감지 시 자동 실행
- SSOT 업그레이드 시 보존: `docs/SSOT/UPGRADE.md`
