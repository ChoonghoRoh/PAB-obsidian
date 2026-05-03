---
task_id: "1-4-6"
title: "Makefile 타겟 + scripts/wiki/README.md"
domain: WIKI-CLI
owner: backend-dev
priority: P1
estimate_min: 20
status: pending
depends_on: ["1-4-1", "1-4-2", "1-4-3", "1-4-4", "1-4-5"]
blocks: []
---

# Task 1-4-6 — Makefile 타겟 + README.md

## 목적

Phase 1-4 산출물의 DX를 개선한다. `make wiki-*` 단축 명령으로 4 subcommand 호출을 표준화하고, `scripts/wiki/README.md`로 사용법·옵션·트러블슈팅을 안내한다.

## 산출물

- `Makefile` (프로젝트 루트, 신규 또는 wiki 타겟 append)
- `scripts/wiki/README.md`

## Makefile 타겟

```makefile
.PHONY: wiki-new wiki-link-check wiki-moc-build wiki-toc-suggest

WIKI := python3 scripts/wiki/wiki.py

wiki-new:
	@if [ -z "$(TYPE)" ] || [ -z "$(SLUG)" ]; then \
		echo "Usage: make wiki-new TYPE=RESEARCH_NOTE SLUG=karpathy-llm-wiki"; exit 2; \
	fi
	$(WIKI) new $(TYPE) $(SLUG)

wiki-link-check:
	$(WIKI) link-check $(if $(FULL),--full,)

wiki-moc-build:
	$(WIKI) moc-build $(if $(DRY_RUN),--dry-run,)

wiki-toc-suggest:
	@if [ -z "$(NOTE)" ]; then echo "Usage: make wiki-toc-suggest NOTE=path/to/note.md"; exit 2; fi
	$(WIKI) toc-suggest $(NOTE) $(if $(JSON),--format json,)
```

> 기존 `Makefile`이 있으면 위 타겟을 append. 없으면 신규 작성.

## README.md 구성

```markdown
# scripts/wiki/ — PAB-Wiki CLI

## 개요
Phase 1-4 산출물. 4 subcommand로 PAB-Wiki(Obsidian Karpathy-style)의 일상 운용을 자동화.

## 의존성
- python-frontmatter
- jsonschema (Draft 2020-12)
- pyyaml
- (선택) obsidiantools

설치:
```
pip install python-frontmatter jsonschema pyyaml
```

## 4 명령

### wiki new <TYPE> <SLUG>
새 노트 생성. 11필드 frontmatter 자동 채움 + TYPE 템플릿 적용.

예:
```
python3 scripts/wiki/wiki.py new RESEARCH_NOTE karpathy-llm-wiki
make wiki-new TYPE=RESEARCH_NOTE SLUG=karpathy-llm-wiki
```

### wiki link-check [--full] [--json]
schema strict + broken `[[wikilink]]` + orphan 검출.

예:
```
python3 scripts/wiki/wiki.py link-check
python3 scripts/wiki/wiki.py --json link-check
make wiki-link-check
```

### wiki moc-build [--dry-run]
13 MOC `## 폴백 정적 링크` 자동 갱신 + TOPIC 승격(N=3).

예:
```
python3 scripts/wiki/wiki.py moc-build --dry-run
python3 scripts/wiki/wiki.py moc-build
make wiki-moc-build DRY_RUN=1
```

### wiki toc-suggest <NOTE> [--max-depth N] [--threshold N] [--format markdown|json]
노트 outline 추천 (toc-recommendation.md 명세).

예:
```
python3 scripts/wiki/wiki.py toc-suggest wiki/10_Notes/...md --format json
make wiki-toc-suggest NOTE=wiki/10_Notes/...md JSON=1
```

## 디렉토리 구조
```
scripts/wiki/
├── wiki.py              # 진입점 + argparse
└── lib/
    ├── frontmatter.py   # 11필드 default + parse/dump
    ├── validate.py      # schema strict + broken link + orphan
    ├── moc.py           # MOC placeholder 갱신 + TOPIC 승격
    └── toc.py           # heading 분석 + outline 추천
```

## 트러블슈팅
- **obsidian: command not found**: Phase 1-1에서 `obsidian register` 미실행. 데스크톱 앱 설정 → CLI 등록 후 재시도. 미등록 환경에서는 link-check가 정규식 폴백 동작.
- **schema strict 위반**: `wiki/40_Templates/_schema.json` v1.1과 노트 frontmatter 비교. type enum (RESEARCH_NOTE/CONCEPT/LESSON/PROJECT/DAILY/REFERENCE/INDEX) + tags pattern (`^[a-z0-9-]+(/[a-z0-9-]+)*$`) 확인.
- **moc-build 변경 없음**: marker `<!-- moc-build:auto-* -->`가 이미 적용되어 idempotent. 수동 편집 후에도 동일 결과 유지.

## SSOT 통합
- Phase 1-5: `.claude/skills/wiki-create-note/` 등 skill에서 `scripts/wiki/skill_bridge.py`를 통해 본 CLI 호출
- Phase 1-6: 시드 노트 5건 작성 + `wiki link-check` + `wiki moc-build`로 G2_wiki + wiki-validation 종료 검증
```

## smoke test

```bash
make wiki-link-check
# 출력: PASS (현재 vault, schema strict 위반 0)

make wiki-moc-build DRY_RUN=1
# 출력: dry-run 결과
```

## 완료 기준

- [ ] `Makefile` 4 타겟 + `.PHONY` + 인자 검증
- [ ] `scripts/wiki/README.md` 4 섹션(개요/의존성/4 명령/트러블슈팅/SSOT 통합)
- [ ] `make wiki-link-check` 정상 동작 (T-3과 동일 결과)
- [ ] `make wiki-moc-build DRY_RUN=1` 정상 동작
- [ ] `make wiki-new` 인자 누락 시 사용법 출력 + exit 2
- [ ] README.md 250줄 이하

## 보고

`reports/report-backend-dev.md` §T-6:
- Makefile 추가/생성 결과 (기존 파일 존재 여부)
- 4 make 타겟 smoke test 출력
- README.md 라인 카운트

## 위험

- 기존 `Makefile`이 다른 프로젝트 타겟을 가지고 있을 경우 conflict 회피 — `wiki-*` prefix로 namespace 분리
- `python3` 경로가 시스템마다 다를 가능성 (`/usr/bin/python3` vs venv) → Makefile에서 `python3` 그대로 사용 (PATH 의존)
