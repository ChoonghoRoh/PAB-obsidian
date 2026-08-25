---
name: menu
description: PAB 스킬 카탈로그를 출력. /menu 호출 시 .claude/skills/ 전체 스킬(18종)과 사용 예시를 일괄 표시하여 신규 사용자의 발견성을 확보.
argument-hint: "[--help]"
user-invocable: true
context: inherit
agent: main
allowed-tools: []
---

# menu — PAB 스킬 카탈로그

`/menu` 호출로 `.claude/skills/`의 활성 스킬 18종을 한눈에 확인하세요.
신규 사용자는 이 카탈로그를 진입점으로 활용하세요.

## 0. 프로젝트 설정

### /project-config

**설명**: `PROJECT.md` 단일 설정 문서 관리 — 프로젝트명·성격·플랫폼·언어·빌드·코드 영역·페르소나 오버라이드를 한 문서에서 설정.
**인수**: `[init|sync|show|check] [--help]`
**사용 예시**:
```
/project-config init    # 새 프로젝트 대화형 생성
/project-config sync    # frontmatter → hooks.env 반영
/project-config check   # 정합성 검사
```

## A. SSOT 워크플로우 스킬 (9종)

### 1. /ssot-reload

**설명**: FRESH-1 절차 자동 실행. SSOT 0→1→2→3 순서 읽기 + 버전 확인.
**인수**: `[--help]`
**사용 예시**:
```
/ssot-reload
```

### 2. /plan

**설명**: 사용자 주도 마스터 플랜 진입 전 프롬프트 품질 점검 및 자료 수집 (AutoCycle Step 0 Pre-draft).
**인수**: `[--help]`
**사용 예시**:
```
/plan
```

### 3. /phase-init

**설명**: Phase 디렉토리+산출물 4종 자동 생성. CHAIN-6/CHAIN-10 검증.
**인수**: `<phase_id> [--dry] [--force] [--no-tasks] [--help]`
**사용 예시**:
```
/phase-init 4-6
/phase-init 4-6 --dry
```

### 4. /gate-check

**설명**: G0~G4 게이트 기준 표시 + 현재 Phase 상태 대비 판정.
**사용 예시**:
```
/gate-check
```

### 5. /rules-lookup

**설명**: `docs/SSOT/core/6-rules-index.md`에서 규칙 ID 빠른 조회.
**사용 예시**:
```
/rules-lookup HR-1
```

### 6. /verify-implementation

**설명**: Task 구현 검증 오케스트레이터. 도메인([BE]/[FE]/[FS]) 판별 후 verify-backend / verify-frontend 호출, G2 통합 리포트 생성.
**사용 예시**:
```
/verify-implementation
```

### 7. /verify-backend · /verify-frontend

**설명**: 백엔드/프론트엔드 코드 심층 리뷰. G2_be / G2_fe 게이트 검증 (SSOT ROLES/verifier.md §2.1·§2.2 기준).
**사용 예시**:
```
/verify-backend
/verify-frontend
```

### 8. /refactor-scan

**설명**: 500/700줄 초과 파일 탐지. HR-5 Level 분류 (WATCH/WARN/DANGER).
**인수**: `[path] [--threshold=N] [--json] [--help]`
**사용 예시**:
```
/refactor-scan
/refactor-scan backend/ --threshold=300
```

### 9. /notify-telegram

**설명**: Phase 완료/이슈 알림을 Telegram으로 전송 (NOTIFY-1, 구 HR-8 — 의무 자동화).
**인수**: `<--phase=ID> <--status=STATUS> [--summary=TEXT] [--report-path=PATH] [--type=TYPE] [--help]`
**사용 예시**:
```
/notify-telegram --phase=4-5 --status=done --summary="구현 완료"
```

## B. 세션·기록 유틸리티 스킬 (7종)

### 10. /context-handoff

**설명**: 컨텍스트 한계 도달 시 현재 세션을 새 세션으로 무손실 인계 (prepare/resume 모드).
**인수**: `<prepare|resume> [handoff-path] [--phase=ID] [--summary=TEXT] [--no-clear-hint] [--help]`
**사용 예시**:
```
/context-handoff prepare --phase=4-5 --summary="menu 스킬 신설 완료"
/context-handoff resume
```

### 11. /worklog

**설명**: 명령형 호출로 work-log에 작업 기록 추가 (SessionStart hook 자동 init과 공존, `scripts/log-prompt.sh` 위임).
**인수**: `[init|log|check] [--prompt=TEXT] [--result=TEXT] [--help]`
**사용 예시**:
```
/worklog log --prompt="Task 4-5-2 구현" --result="menu 스킬 신설 완료"
/worklog check
```

### 12. /report

**설명**: 직전 대화에서 생성된 분석/보고서 출력을 .md 파일로 저장.
**인수**: `[--path=PATH] [--format=FMT] [--append] [--section=NAME] [--no-meta] [--help]`
**사용 예시**:
```
/report --path=docs/phases/phase-4-5/reports/my-report.md
/report --append --section="비교 분석"
```

### 13. /wiki

**설명**: 자연어 입력으로부터 옵시디언 규격 wiki 노트를 자동 생성 — 원본 immutable 보존(SOURCE) + LLM 요약본 두 파일 동시 생성.
**인수**: `<내용 또는 URL...> [--type=TYPE] [--dry] [--help]`
**사용 예시**:
```
/wiki https://example.com/article 내용 정리해줘
/wiki 위에서 논의한 RAG 패턴 정리 --type=CONCEPT
```

### 14. /worktree

**설명**: Git worktree 신설/정리/감사/옵션비교 (병렬 BUILDING 격리). 어떤 git 레포에서도 동작.
**인수**: `<setup|cleanup|audit|compare> [branch|opt-A opt-B] [--gh-pr] [--remote=URL] [--criteria=KEYS] [--branch-prefix=PREFIX] [--dry] [--help]`
**사용 예시**:
```
/worktree setup feature-x
/worktree cleanup feature-x
/worktree compare A B --criteria=lines,test-pass,readability
```

### 15. /abort

**설명**: AutoCycle/Phase/Chain 안전 중단 (3-workflow.md §8.5 사용자 중단 요청의 표준 진입점). 팀 shutdown + status.md BLOCKED 기록 + 재개 정보 보존.
**인수**: `[사유] [--help]`
**사용 예시**:
```
/abort
/abort 요구사항 변경으로 재계획 필요
```

### 16. /menu

**설명**: 본 카탈로그 출력.

## 옵션

- `--help`: 본 도움말 출력

## 참고

- 스킬 위치: `.claude/skills/` (단일 소스 — 루트 `skills/` 폴더는 폐지)
- 스킬 추가/삭제 시 본 카탈로그 수동 동기화 필요 (현재 18종)
