# Phase 1-4 Todo List

## T-1: wiki.py 진입점 + lib/ 모듈 골격 (backend-dev)

- [ ] 환경 점검: `python3 -c "import frontmatter, jsonschema, yaml"` 결과 보고. 미설치 시 `pip install python-frontmatter jsonschema pyyaml` 실행
- [ ] `scripts/wiki/` 디렉토리 + `__init__.py` 생성
- [ ] `scripts/wiki/lib/` 디렉토리 + `__init__.py` 생성
- [ ] `scripts/wiki/wiki.py` shebang(`#!/usr/bin/env python3`) + `if __name__ == "__main__"` 진입점
- [ ] argparse: 4 subcommand(`new`/`link-check`/`moc-build`/`toc-suggest`) + 공통 옵션(`--vault` 기본 프로젝트 루트, `--quiet`/`--json`)
- [ ] `lib/frontmatter.py`/`validate.py`/`moc.py`/`toc.py` 4 파일 stub (각각 NotImplementedError 또는 빈 함수 시그니처)
- [ ] `wiki.py --help` / `wiki.py new --help` / 4 subcommand 모두 `--help` 정상 응답
- [ ] 실행 권한 부여(`chmod +x scripts/wiki/wiki.py`)
- [ ] `reports/report-backend-dev.md` §T-1 (모듈 분리 설계 + 라인 카운트)

## T-2: `wiki new <type> <slug>` (backend-dev, T-1 후)

- [ ] `lib/frontmatter.py`: `build_default_frontmatter(type, slug)` 함수 — 11필드 자동 채움
  - `title`: slug → 사람-readable (밑줄·하이픈 → 공백)
  - `description`: 빈 문자열 또는 placeholder
  - `created`/`updated`: 현재 시각 ISO + `YYYY-MM-DD HH:MM`
  - `type`: `"[[<TYPE>]]"`
  - `index`: `"[[ROOT]]"` 기본
  - `topics`: `[]`
  - `tags`: `[<type-slug>]` (예: `research-note`)
  - `keywords`: `[]`
  - `sources`: `[]`
  - `aliases`: `[]`
- [ ] 파일명 생성: naming-convention.md 규약 — `wiki/10_Notes/YYYY-MM-DD_<slug>.md` (DAILY는 `wiki/99_Inbox/` 또는 별도)
- [ ] 템플릿 머지: `wiki/40_Templates/<TYPE>.md` 본문(frontmatter 제외) 채택. 본문 내 `{{title}}` 등 placeholder 있으면 치환
- [ ] `obsidian create <path>` subprocess 호출 (실패 시 직접 파일 작성 폴백) + 결과 반환
- [ ] `--dry-run` 옵션: 작성될 파일 경로 + frontmatter만 stdout 출력
- [ ] smoke test: `wiki new RESEARCH_NOTE smoke-test --dry-run` 출력에 11필드 모두 포함 확인
- [ ] `reports/report-backend-dev.md` §T-2 (smoke test 출력 첨부)

## T-3: `wiki link-check` (backend-dev, T-1 후)

- [ ] `lib/validate.py`:
  - `validate_frontmatter_strict(notes)` — `wiki/40_Templates/_schema.json` v1.1 strict 적용. 위반 노트 + 위반 필드 list 반환
  - `find_unresolved_links(notes)` — `obsidian unresolved` subprocess 호출 + 파싱. 폴백: 정규식으로 `[[...]]` 추출 후 vault 노트 셋 대조
  - `find_orphan_notes(notes)` — 인링크 0이고 `topics`·`index`·`type` 어느 MOC에도 등장하지 않는 노트
- [ ] `wiki link-check` 분기:
  - 빈 vault → 즉시 PASS 리턴 (exit 0, `broken=0 orphan=0 schema_violation=0`)
  - 위반 발견 → exit 1, 리포트 출력 (`--json` 시 JSON, 기본 markdown)
- [ ] G2_wiki 리포트 포맷: Critical/High/Low 등급 매핑 (broken link → Critical, orphan → High, sources 누락 → Low)
- [ ] `--full` 옵션: 모든 노트 전수 검사 (기본도 동일, 옵션은 향후 확장용)
- [ ] smoke test: 빈 vault(시드 노트 0건) 상태에서 `wiki link-check` PASS 확인. 기존 wiki/(MOC/templates/constraints) 전수 schema strict 검증 수행 → 위반 0건 확인 (Phase 1-3 T-6에서 strict 정렬 완료된 상태)
- [ ] `reports/report-backend-dev.md` §T-3 (전수 검증 결과 첨부)

## T-4: `wiki moc-build` (backend-dev, T-1 후)

- [ ] `lib/moc.py`:
  - `collect_notes_by_type(notes)` — 노트의 `type` 필드 그룹화
  - `collect_notes_by_index(notes)` — 노트의 `index`(DOMAIN) 필드 그룹화
  - `collect_topic_candidates(notes, threshold=3)` — `topics` 필드 등장 빈도 ≥ N → 승격 후보
  - `update_moc_fallback_links(moc_path, group)` — 각 MOC의 `## 폴백 정적 링크` 섹션을 group(노트 wikilink list)로 갱신 (기존 placeholder 보존, 정렬 created DESC)
- [ ] `wiki moc-build` 분기:
  - 13 MOC(TYPES 6 + DOMAINS 6 + TOPICS _README) 순회
  - TOPIC 승격 후보 발견 시 `wiki/00_MOC/TOPICS/<TOPIC>.md` 신규 생성 (템플릿 일치)
  - 빈 vault → noteset 0이면 즉시 정상 종료 (변경 없음)
- [ ] idempotent 보장 (반복 실행해도 결과 동일)
- [ ] `--dry-run`: 갱신 예정 MOC + 추가/삭제 링크 출력만
- [ ] smoke test: 현재 빈 vault(시드 0)에서 `wiki moc-build` 실행 → 13 MOC placeholder 변경 0건 확인. `--dry-run`도 정상
- [ ] `reports/report-backend-dev.md` §T-4 (MOC 변경 결과 + idempotent 검증)

## T-5: `wiki toc-suggest <note>` (backend-dev, T-1 후)

- [ ] `lib/toc.py`:
  - `parse_headings(text)` — frontmatter(`---`...`---`) 제외, fenced code block(``` ~ ```) 제외, H1~H6 추출. `(level, text, line_start, line_end)` 리스트 반환
  - `analyze_depth(headings, max_depth=3)` — `too_flat`/`too_deep`/`ok` 판정
  - `analyze_length(headings, threshold=80)` — section_lines 계산 + `split`/`merge`/`keep` 매핑
  - `toc_suggest(note_path, max_depth, use_llm, length_threshold)` — toc-recommendation.md 의사코드 그대로 구현
- [ ] `wiki toc-suggest <note>` 분기:
  - `--max-depth N` (기본 3) / `--threshold N` (기본 80) / `--llm` (기본 false) / `--format markdown|json` (기본 markdown)
  - `--llm`은 본 Phase에서는 stub만 (raise NotImplementedError 또는 default false 강제)
- [ ] 출력 JSON 스키마 toc-recommendation.md §출력 JSON 스키마 정확 일치 (`flatness`/`max_depth_seen`/`suggestions[]`)
- [ ] smoke test 1: `wiki/30_Constraints/toc-recommendation.md` 자체에 `wiki toc-suggest` 적용 → JSON 출력이 명세 스키마 일치
- [ ] smoke test 2: heading 0건 노트(빈 본문) → `flatness=ok max_depth_seen=0 suggestions=[]`
- [ ] `reports/report-backend-dev.md` §T-5 (smoke test 출력 첨부)

## T-6: Makefile 타겟 + README.md (backend-dev, T-1~T-5 후)

- [ ] 프로젝트 루트 `Makefile` (없으면 신규 생성, 있으면 append):
  - `wiki-new TYPE=... SLUG=...` — `python3 scripts/wiki/wiki.py new $(TYPE) $(SLUG)`
  - `wiki-link-check` — `python3 scripts/wiki/wiki.py link-check`
  - `wiki-moc-build` — `python3 scripts/wiki/wiki.py moc-build`
  - `wiki-toc-suggest NOTE=...` — `python3 scripts/wiki/wiki.py toc-suggest $(NOTE)`
  - `.PHONY` 명시
- [ ] `scripts/wiki/README.md`:
  - 4 명령 사용법 + 옵션 매트릭스
  - `make wiki-*` 단축 사용 예
  - 의존성 (`python-frontmatter`, `jsonschema`, `pyyaml`)
  - 디렉토리 구조 (wiki.py + lib/ 4 모듈)
  - 트러블슈팅 (obsidian CLI 미등록·권한 문제)
- [ ] smoke test: `make wiki-link-check` 정상 동작 확인
- [ ] `reports/report-backend-dev.md` §T-6

## G2_wiki 검증 (verifier, T-6 후)

- [ ] T-1 4 subcommand `--help` 응답 정상 확인
- [ ] T-2 `wiki new RESEARCH_NOTE verifier-test --dry-run` 결과 11필드 모두 채움 확인
- [ ] T-3 `wiki link-check` 빈 vault PASS + 기존 wiki/ 전수 schema strict 위반 0 확인
- [ ] T-4 `wiki moc-build --dry-run` idempotent 확인 (2회 실행 결과 동일)
- [ ] T-5 `wiki toc-suggest wiki/30_Constraints/toc-recommendation.md --format json` 출력이 명세 스키마 100% 일치
- [ ] T-6 `make wiki-link-check` 정상 동작
- [ ] R-4 가드: `wiki.py` + lib/ 4 모듈 각 라인 수 < 250
- [ ] REFACTOR-1: 500줄 초과 파일 스캔 (lib/ 포함)
- [ ] `reports/report-verifier.md` 작성 — Critical/High/Low 등급별 결과

## Phase 완료 (Team Lead)

- [ ] G2_wiki PASS 확인 → G4 PASS 전이
- [ ] phase-1-4-status.md `current_state: DONE` 갱신
- [ ] master-plan §Phase 1-4에 CHAIN-5 1줄 완료 요약 추가
- [ ] REFACTOR-1: lib/ 4 모듈 줄 수 레지스트리 검토 (500줄 초과 시 등록)
- [ ] NOTIFY-1: `[PAB-Wiki] ✅ Phase 1-4 완료` Telegram 발송
- [ ] HR-7 LIFECYCLE-2: backend-dev/verifier shutdown_request → TeamDelete
- [ ] next_prompt_suggestion 갱신 (Phase 1-5 SSOT skill 어댑터)
