# Phase 1-4 Plan — CLI 자동화 (`scripts/wiki/wiki.py`)

## 목표

PAB-Wiki의 일상 운용을 자동화하는 4종 CLI 명령(`new`/`link-check`/`moc-build`/`toc-suggest`)을 Python으로 구현한다. Phase 1-1~1-3에서 정립된 spec(schema v1.1, 6 템플릿, 13 MOC, toc-recommendation 명세)을 코드로 구현하는 단계.

## 범위

- **진입점**: `scripts/wiki/wiki.py` (argparse subcommand 4종, ~150~200줄)
- **모듈 분리** (R-4 wiki.py 400줄 한계 사전 방지):
  - `lib/frontmatter.py` — 11필드 자동 생성 + python-frontmatter 파싱·덤프
  - `lib/validate.py` — jsonschema strict v1.1 + broken link + orphan
  - `lib/moc.py` — `obsidian files` + frontmatter 파싱 → MOC placeholder 갱신 + TOPIC 자동 승격(N=3)
  - `lib/toc.py` — toc-recommendation.md 의사코드 그대로 구현
- **외부 의존**: `python-frontmatter` (필수), `jsonschema` (필수), `pyyaml` (보통 필수), `obsidiantools` (선택, 폴백). 본 Phase는 `python-frontmatter` + `jsonschema`만 강제.
- **CLI 호출 인터페이스**: subprocess `obsidian` (Phase 1-1 등록 완료) + 직접 vault 파일 조작 조합

## 산출물

| Task | 경로 | 설명 |
|---|---|---|
| T-1 | `scripts/wiki/wiki.py` + `lib/__init__.py` | 진입점 + argparse + 4 subcommand 라우팅 |
| T-2 | `lib/frontmatter.py` + `wiki new` 분기 | 11필드 자동 채움 + 템플릿 적용 + obsidian create |
| T-3 | `lib/validate.py` + `wiki link-check` 분기 | jsonschema strict + obsidian unresolved + orphan + G2_wiki 리포트 |
| T-4 | `lib/moc.py` + `wiki moc-build` 분기 | 13 MOC placeholder 자동 갱신 + TOPIC 승격(N=3) |
| T-5 | `lib/toc.py` + `wiki toc-suggest` 분기 | toc-recommendation.md 명세 그대로 구현 (markdown/JSON 출력) |
| T-6 | `Makefile` 타겟 + `scripts/wiki/README.md` | DX 개선 (`make wiki-new TYPE=research SLUG=foo`) + 사용 가이드 |

## Task 목록

| Task | 도메인 | 담당 | 의존 |
|---|---|---|---|
| T-1: wiki.py 진입점 + argparse + lib/ 모듈 골격 | WIKI-CLI | backend-dev | - |
| T-2: `wiki new` (frontmatter 11필드 자동 + 템플릿) | WIKI-CLI | backend-dev | T-1 |
| T-3: `wiki link-check` (jsonschema strict + unresolved + orphan) | WIKI-CLI | backend-dev | T-1 |
| T-4: `wiki moc-build` (placeholder 갱신 + TOPIC 승격) | WIKI-CLI | backend-dev | T-1 |
| T-5: `wiki toc-suggest` (휴리스틱 + JSON 출력) | WIKI-CLI | backend-dev | T-1 |
| T-6: Makefile + README.md | WIKI-CLI | backend-dev | T-1~T-5 |

## G2_wiki 게이트 (E-1 + 본 Phase 추가 항목)

- **Critical**:
  - 4 subcommand 모두 `--help` 응답 정상 (argparse 정합)
  - `wiki new RESEARCH_NOTE smoke-test` 실행 시 11필드 frontmatter 모두 채워짐 + naming-convention 규약 일치
  - `wiki link-check` 빈 vault에서 PASS 반환 (exit code 0, broken=0/orphan=0)
  - jsonschema strict v1.1 위반 0건 (기존 vault 노트 전수 검증)
- **High**:
  - `wiki moc-build` 실행 후 13 MOC `## 폴백 정적 링크` placeholder가 비어있어도 정상 종료 (시드 노트 0건 가정)
  - `wiki toc-suggest` JSON 출력이 toc-recommendation.md §출력 JSON 스키마 일치
  - lib 4 모듈 각 200줄 이하 (REFACTOR-1 사전 방지)
- **Low**:
  - LLM 보강(`--llm`)은 default false 유지
  - `obsidiantools` 미설치 환경에서 폴백 동작

## 의존 관계

- **입력**: Phase 1-1 (vault 등록 + obsidian CLI), Phase 1-2 (schema v1.1 + 6 템플릿 + 3 constraints), Phase 1-3 (13 MOC + toc-recommendation.md)
- **출력**: Phase 1-5 (skill_bridge.py가 본 wiki.py를 subprocess 호출), Phase 1-6 (시드 노트 5건 작성 + `wiki link-check --full` + `wiki moc-build`)

## 예외 (E-1 ~ E-5 적용)

- **E-1** G2 → G2_wiki: 본 Phase에서 적용 (4 명령 smoke test + spec 준수 검증)
- **E-2** HR-5 → 노트 400줄 권장: 코드 파일에는 적용 안 함. wiki.py 본체는 R-4(400줄)로 자체 가드
- **E-3** prefix `[PAB-Wiki]`: NOTIFY-1 시 적용
- **E-4** G3 → wiki-validation: tester 미스폰. verifier가 G2_wiki 통합 검증
- **E-5** WIKI-CLI 도메인: 6 task 모두 backend-dev 단일 implementer

## 리스크 + 완화

| # | 리스크 | 완화 |
|---|---|---|
| L-1 | `python-frontmatter` 미설치 | T-1 첫 작업: `python3 -c "import frontmatter"` 확인. 미설치 시 `pip install python-frontmatter pyyaml jsonschema` 안내 |
| L-2 | `obsidian` CLI 비대화형 호출 시 종료 코드 불명확 | T-2/T-3에서 subprocess.run() capture_output=True + returncode 검사. 실패 시 fallback (직접 파일 작성) |
| L-3 | 빈 vault에서 link-check가 errno 1 반환 가능 | T-3 구현 시 `if not notes: return PASS` 명시 처리 |
| L-4 | TOPIC 자동 승격 N=3이 빈 vault에서 무한 루프 가능 | T-4 구현 시 noteset 비어있으면 즉시 return |
| L-5 | toc-suggest의 frontmatter/code-block 라인 카운팅 일관성 | T-5는 toc-recommendation.md §위험 결정 (코드 블록 "포함")을 따름 |

## 소요 추정

6 task / 120~180분 (master-plan과 동일)

## 모듈 책임 분리 (R-4 가드)

| 모듈 | 책임 | 예상 줄 수 |
|---|---|---|
| `wiki.py` | argparse + subcommand dispatch + 공통 옵션 | 100~200 |
| `lib/frontmatter.py` | 11필드 default + parse/dump + 템플릿 머지 | 100~150 |
| `lib/validate.py` | jsonschema strict + broken link + orphan + 리포트 포맷 | 150~250 |
| `lib/moc.py` | obsidian files + frontmatter 그룹화 + placeholder 패치 + TOPIC 승격 | 150~250 |
| `lib/toc.py` | heading parser + depth/length 분석 + JSON/markdown 출력 | 100~200 |

각 모듈 200줄 이하 유지 권장. 250줄 초과 시 추가 분리 검토 (Phase 완료 후 REFACTOR-1 스캔 대상).

## NOTIFY-1 발송 (HR-8)

```
[PAB-Wiki] ✅ Phase 1-4 완료: CLI 자동화 wiki.py + 4 subcommand
📊 결과: G2_wiki PASS, jsonschema strict <pass>/<total>, lib 4 모듈 평균 <N>줄
📁 보고서: docs/phases/phase-1-4/reports/
```
