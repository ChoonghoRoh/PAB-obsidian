# scripts/wiki/ — PAB-Wiki CLI

## 개요

Phase 1-4 산출물. 4 subcommand로 PAB-Wiki(Obsidian Karpathy-style)의 일상 운용을 자동화한다.

## 의존성

- `python-frontmatter` — YAML frontmatter 파싱·덤프
- `jsonschema` (Draft 2020-12) — schema strict 검증
- `pyyaml` — YAML 직렬화
- (선택) `obsidiantools` — 향후 확장용

설치:

```bash
pip install python-frontmatter jsonschema pyyaml
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

## 4 명령

### wiki new \<TYPE\> \<SLUG\>

새 노트 생성. 11필드 frontmatter 자동 채움 + TYPE 템플릿 적용.

| 인자 | 설명 |
|---|---|
| `TYPE` | `RESEARCH_NOTE` / `CONCEPT` / `LESSON` / `PROJECT` / `DAILY` / `REFERENCE` |
| `SLUG` | 파일명 slug (`YYYY-MM-DD_<slug>.md` 형식으로 저장) |
| `--dry-run` | 실제 파일 미생성, frontmatter 미리보기만 출력 |

저장 디렉토리:

| TYPE | 저장 위치 |
|---|---|
| `RESEARCH_NOTE` / `CONCEPT` / `LESSON` / `PROJECT` / `REFERENCE` | `wiki/10_Notes/` |
| `DAILY` | `wiki/99_Inbox/` |

예:

```bash
python3 scripts/wiki/wiki.py new RESEARCH_NOTE karpathy-llm-wiki
python3 scripts/wiki/wiki.py new RESEARCH_NOTE karpathy-llm-wiki --dry-run
make wiki-new TYPE=RESEARCH_NOTE SLUG=karpathy-llm-wiki
```

### wiki link-check \[--full\] \[--json\]

schema strict (v1.1, Draft 2020-12) + broken `[[wikilink]]` + orphan 노트 검출.

| 옵션 | 설명 |
|---|---|
| `--full` | 전체 상세 출력 (향후 확장용) |
| `--json` | 결과를 JSON으로 출력 (자동화·CI 용도) |

출력 등급:

| 등급 | 조건 | exit code |
|---|---|---|
| `PASS` | violations=0, broken=0, orphans=0 | 0 |
| `PARTIAL` | violations=0, broken=0, orphans>0 | 0 |
| `FAIL` | violations>0 또는 broken>0 | 1 |

예:

```bash
python3 scripts/wiki/wiki.py link-check
python3 scripts/wiki/wiki.py --json link-check
make wiki-link-check
make wiki-link-check FULL=1
```

### wiki moc-build \[--dry-run\] \[--topic-threshold N\]

12 MOC(`TYPES/` 6 + `DOMAINS/` 6)의 `## 폴백 정적 링크` 섹션을 idempotent 갱신 (`TOPICS/_README.md`는 명세 노트이므로 제외). TOPIC 등장 빈도 N 이상이면 TOPIC MOC 자동 생성.

| 옵션 | 설명 |
|---|---|
| `--dry-run` | 갱신 예정 내역만 출력, 파일 미변경 |
| `--topic-threshold N` | TOPIC 승격 최소 등장 빈도 (기본 3) |

예:

```bash
python3 scripts/wiki/wiki.py moc-build --dry-run
python3 scripts/wiki/wiki.py moc-build
make wiki-moc-build
make wiki-moc-build DRY_RUN=1
```

### wiki toc-suggest \<NOTE\> \[options\]

노트 heading 분석 + outline 추천. `wiki/30_Constraints/toc-recommendation.md` 명세 구현.

| 옵션 | 설명 |
|---|---|
| `--max-depth N` | 허용 heading 최대 깊이 (기본 3) |
| `--threshold N` | 섹션 split 임계 라인 수 (기본 80) |
| `--format markdown\|json` | 출력 포맷 (기본 markdown) |
| `--llm` | LLM 보강 활성화 (Phase 1-5 이후 구현 예정) |

출력 JSON 스키마:

```json
{
  "flatness": "too_flat|too_deep|ok",
  "max_depth_seen": 0,
  "suggestions": [
    {"level": 2, "text": "...", "lines": 120, "suggestion": "split|merge|keep"}
  ]
}
```

예:

```bash
python3 scripts/wiki/wiki.py toc-suggest wiki/30_Constraints/toc-recommendation.md
python3 scripts/wiki/wiki.py toc-suggest wiki/30_Constraints/toc-recommendation.md --format json
make wiki-toc-suggest NOTE=wiki/30_Constraints/toc-recommendation.md
make wiki-toc-suggest NOTE=wiki/30_Constraints/toc-recommendation.md JSON=1
```

## 트러블슈팅

- **`obsidian: command not found`**: Phase 1-1에서 `obsidian register` 미실행. 데스크톱 앱 설정 → CLI 등록 후 재시도. 미등록 환경에서는 `link-check`가 정규식 폴백으로 동작 (wiki/ 범위).
- **schema strict 위반**: `wiki/40_Templates/_schema.json` v1.1과 노트 frontmatter 비교. `type` enum (`RESEARCH_NOTE|CONCEPT|LESSON|PROJECT|DAILY|REFERENCE|INDEX`) + `tags` pattern (`^[a-z0-9-]+(/[a-z0-9-]+)*$`) 확인.
- **moc-build 변경 없음**: marker `<!-- moc-build:auto-start/end -->` 가 이미 최신 상태 (idempotent). 의도된 동작.
- **`ModuleNotFoundError: No module named 'scripts'`**: `python3 scripts/wiki/wiki.py ...` 형식으로 프로젝트 루트에서 실행해야 함. wiki.py 내부에서 자동으로 sys.path에 루트를 추가함.

## SSOT 통합

- **Phase 1-5**: `.claude/skills/wiki-create-note/` 등 skill에서 `scripts/wiki/skill_bridge.py`를 통해 본 CLI 호출
- **Phase 1-6**: 시드 노트 5건 작성 + `wiki link-check` + `wiki moc-build`로 G2_wiki + wiki-validation 종료 검증
