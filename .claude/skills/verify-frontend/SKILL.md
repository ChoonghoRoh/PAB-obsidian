---
name: verify-frontend
description: "프론트엔드 코드 심층 리뷰. G2_fe 게이트 검증. 기준: ROLES/SUB-SSOT/VERIFIER/verification-procedure.md §G2 판정 기준(G2_fe) + PROJECT.md §4."
user-invocable: false
context: fork
agent: Explore
allowed-tools: "Read, Glob, Grep, Bash(git diff:*), Bash(git show:*), Bash(python3 scripts/comment/comment-lint.py:*)"
---

# verify-frontend — 프론트엔드 코드 심층 리뷰

## 역할

`docs/SSOT/ROLES/SUB-SSOT/VERIFIER/verification-procedure.md` §G2 판정 기준(G2_fe — 항목 · 등급의 정본) + `PROJECT.md` §4(개발 규칙 오버라이드)에 따라 변경 파일을 검토하고 G2_fe 판정을 반환한다.

## 입력

`$ARGUMENTS` — 검증 대상 파일 경로 목록 (공백 구분) 또는 디렉토리 경로. `--sha <커밋>`을 주면 그 SHA로만 읽는다(`git show <SHA>:<경로>` — HANDOFF-6, 판정 근거로 쓴다). 없으면 작업 트리를 읽되 판정 증거로 쓰지 않는다. `--base <커밋>`을 함께 주면 주석 판정(`lint --changed`)의 기준 커밋으로 쓴다. 없으면 `HEAD`를 기준으로 커밋 전 작업 트리 변경만 본다 — 이미 커밋된 변경을 검증할 때는 `--base`를 반드시 준다

파일 목록이 비어있으면 `git -c core.quotePath=false diff --name-only HEAD`에서 `.claude/hooks/hooks.env`의 `PAB_CODE_DIRS` 하위 파일을 자동 수집한다 (실제 폴더는 `PROJECT.md` §3 작업 폴더 참조).


## 프로젝트 오버라이드 (검증 전 필수 확인)

프로젝트 루트에 `PROJECT.md`가 있으면 **§4 개발 규칙 오버라이드**를 먼저 읽는다.

- §4.1 추가 규칙 → 아래 기준에 **추가**하여 검사
- §4.2 완화·제외 규칙 → 해당 항목은 명시된 범위에서 **검사 제외** (판정 리포트에 "§4.2 완화 적용" 표기)
- 충돌 시 PROJECT.md가 SSOT 기본 기준에 우선한다.

## 검증 기준

항목은 `docs/SSOT/ROLES/SUB-SSOT/VERIFIER/verification-procedure.md` §G2 판정 기준 — G2_fe 목록을 읽어 그대로 적용하고, 등급은 같은 절 「등급 산출」 표(사실 네 칸 → 3 × 3)에서 낸다. 이 스킬은 항목을 따로 적지 않는다(LOCK-6).

- 주석 판정 범위: 제품 코드 구역(`PROJECT.md` §3)의 주석에 적용한다(COMMENT-2). 구역 밖 하네스 파일은 COMMENT-1로 판정한다. `lint <대상> --changed <기준 커밋>` 위반 0이 기준이며 위반이 있으면 결함(COMMENT-2 — 건드린 블록). 참조(NOTE-6): `points <대상>` 죽은 참조 0이 기준이며 위반이 있으면 결함. 판정 범위는 대상 파일 전체다 — `--changed` 범위와 무관하게 본다(NOTE-6). 파일 전체 위반 수가 부채 레지스트리 기준선보다 늘어도 결함이다. 등급은 VP §G2 판정 기준 「등급 산출」 표. 기준 커밋은 `--base` 인자 또는 판정 요청에서 받는다
- NOTE-5(읽기 3단계)는 lint 대상이 아니다 — 코드는 L3 → L2 → L1 순으로 읽고 주석으로 결론을 내지 않는다. 어긋남은 판독으로 적는다

## 실행 절차

0. `docs/SSOT/ROLES/SUB-SSOT/VERIFIER/verification-procedure.md` §G2 판정 기준을 읽는다
1. `$ARGUMENTS`에서 파일 경로 파싱(없으면 git diff에서 `PAB_CODE_DIRS` 하위 파일 수집). `--sha <커밋>`이 있으면 각 파일을 `git show <SHA>:<경로>`로 읽는다(판정 근거) — 없으면 작업 트리를 Read로 읽되 판정 증거로 쓰지 않는다
2. 1단계에서 읽은 내용을 검증 기준 항목별로 검사
3. 사용자 입력 출력 시 이스케이프 처리 여부 확인 (Grep)
4. 콘솔 에러 유발 여지 확인
5. 정본 컴포넌트 재사용 여부 확인 (`PROJECT.md` 정본 컴포넌트 레지스트리 대조 + Grep)
6. 제품 코드 구역(`PROJECT.md` §3)의 코드·마크업 파일에 한해(누가 썼든 — COMMENT-1 위치 기준) `python3 scripts/comment/comment-lint.py lint <대상>`과 `python3 scripts/comment/comment-lint.py points <대상>` 실행 — lint는 `--changed <기준 커밋>`을 붙여 건드린 블록의 위반(L1~L8)을, points는 죽은 참조를 집계한다(등급은 VP §G2 판정 기준 「등급 산출」 표 — NOTE-1~6). 구역 밖 하네스 파일은 COMMENT-1로 판정한다(등급은 같은 표). lint 출력 머리의 「범위: … 변경 줄 N줄」을 리포트에 옮기고, 판정 범위가 비었는지는 VP §G2 판정 기준 「주석 판정」 — 판정 범위 확인을 따른다(변경 줄이 0인데 판정 대상 파일에 변경이 있으면 「주석 판정 범위가 비어 있음 — `--base` 확인」을 결함으로 — 등급은 표. 삭제 전용은 제외)
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
- {file1}
- {file2}
```

## 판정 규칙

| 조건 | 판정 |
|------|------|
| Critical 1건 이상 | **FAIL** |
| Critical 0건, High 있음 | **PARTIAL** |
| Critical 0건, High 0건 | **PASS** |
