---
task_id: "1-4-1"
title: "wiki.py 진입점 + argparse + lib/ 모듈 골격"
domain: WIKI-CLI
owner: backend-dev
priority: P0
estimate_min: 25
status: pending
depends_on: []
blocks: ["1-4-2", "1-4-3", "1-4-4", "1-4-5", "1-4-6"]
---

# Task 1-4-1 — `scripts/wiki/wiki.py` 진입점 + argparse + lib/ 모듈 골격

## 목적

이후 5개 task의 공통 기반인 CLI 진입점과 4 subcommand argparse 라우팅을 구축한다. R-4(wiki.py 400줄 한계) 사전 방지를 위해 lib/ 4 모듈로 책임을 분리한다.

## 산출물

- `scripts/wiki/__init__.py` (빈 파일)
- `scripts/wiki/wiki.py` — 진입점 + argparse + dispatch
- `scripts/wiki/lib/__init__.py` (빈 파일)
- `scripts/wiki/lib/frontmatter.py` — stub (11필드 default 함수 시그니처만)
- `scripts/wiki/lib/validate.py` — stub (validate_frontmatter_strict / find_unresolved_links / find_orphan_notes 시그니처)
- `scripts/wiki/lib/moc.py` — stub (collect_notes_by_type / by_index / collect_topic_candidates / update_moc_fallback_links 시그니처)
- `scripts/wiki/lib/toc.py` — stub (parse_headings / analyze_depth / analyze_length / toc_suggest 시그니처)

## 환경 점검 (선행)

```bash
python3 -c "import frontmatter, jsonschema, yaml; print('ok')"
```

미설치 시:
```bash
pip install python-frontmatter jsonschema pyyaml
```

설치 결과를 reports/report-backend-dev.md §T-1에 기록.

## wiki.py 표준 골격

```python
#!/usr/bin/env python3
"""PAB-Wiki CLI — wiki new / link-check / moc-build / toc-suggest"""
import argparse
import sys
from pathlib import Path

VAULT_ROOT_DEFAULT = Path(__file__).resolve().parents[2]  # 프로젝트 루트


def cmd_new(args): ...        # T-2에서 구현
def cmd_link_check(args): ... # T-3
def cmd_moc_build(args): ...  # T-4
def cmd_toc_suggest(args): ...# T-5


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="wiki", description="PAB-Wiki CLI")
    parser.add_argument("--vault", type=Path, default=VAULT_ROOT_DEFAULT,
                        help="Vault root (default: 프로젝트 루트)")
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--json", dest="json_output", action="store_true",
                        help="JSON 출력 (link-check/toc-suggest)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_new = sub.add_parser("new", help="새 노트 생성")
    p_new.add_argument("type", choices=["RESEARCH_NOTE","CONCEPT","LESSON","PROJECT","DAILY","REFERENCE"])
    p_new.add_argument("slug")
    p_new.add_argument("--dry-run", action="store_true")
    p_new.set_defaults(func=cmd_new)

    p_lc = sub.add_parser("link-check", help="frontmatter strict + broken link + orphan")
    p_lc.add_argument("--full", action="store_true")
    p_lc.set_defaults(func=cmd_link_check)

    p_mb = sub.add_parser("moc-build", help="13 MOC placeholder + TOPIC 승격")
    p_mb.add_argument("--dry-run", action="store_true")
    p_mb.add_argument("--topic-threshold", type=int, default=3)
    p_mb.set_defaults(func=cmd_moc_build)

    p_ts = sub.add_parser("toc-suggest", help="노트의 outline 추천")
    p_ts.add_argument("note", type=Path)
    p_ts.add_argument("--max-depth", type=int, default=3)
    p_ts.add_argument("--threshold", type=int, default=80)
    p_ts.add_argument("--llm", action="store_true")
    p_ts.add_argument("--format", choices=["markdown","json"], default="markdown")
    p_ts.set_defaults(func=cmd_toc_suggest)

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args) or 0


if __name__ == "__main__":
    sys.exit(main())
```

> 위 코드는 **참고 예시**이며 backend-dev가 환경에 맞춰 조정 가능. 단, 4 subcommand 이름·옵션 시그니처는 master-plan §Phase 1-4와 본 task 명세를 따른다.

## 모듈 stub 예시 (`lib/frontmatter.py`)

```python
"""Frontmatter 11필드 자동 채움 + parse/dump 유틸. T-2에서 구현."""
from __future__ import annotations
from datetime import datetime
from pathlib import Path
from typing import Any

REQUIRED_FIELDS = ["title", "description", "created", "updated", "type",
                   "index", "topics", "tags", "keywords", "sources", "aliases"]


def build_default_frontmatter(type_: str, slug: str) -> dict[str, Any]:
    """11필드 default 생성. T-2에서 본격 구현."""
    raise NotImplementedError("T-2에서 구현")


def load_note(path: Path):
    """python-frontmatter로 노트 파싱. T-2/3에서 구현."""
    raise NotImplementedError
```

다른 lib/*.py도 동일한 패턴(시그니처만, NotImplementedError).

## 실행 절차

1. `python3 -c "import frontmatter, jsonschema, yaml"` 결과 보고
2. `scripts/wiki/` + `scripts/wiki/lib/` 디렉토리 생성
3. 위 골격대로 `wiki.py` + 4 lib 모듈 작성
4. `chmod +x scripts/wiki/wiki.py`
5. smoke test:
   - `python3 scripts/wiki/wiki.py --help` — 4 subcommand 모두 보임
   - `python3 scripts/wiki/wiki.py new --help` — type/slug/--dry-run 인자 보임
   - `python3 scripts/wiki/wiki.py link-check --help`
   - `python3 scripts/wiki/wiki.py moc-build --help`
   - `python3 scripts/wiki/wiki.py toc-suggest --help`

## 완료 기준

- [ ] `scripts/wiki/wiki.py` + `lib/{frontmatter,validate,moc,toc}.py` 5 파일 존재
- [ ] `__init__.py` 2개 존재
- [ ] `wiki.py --help` 및 4 subcommand `--help` 모두 정상 응답
- [ ] `wiki.py new --help`에 type choices 6종 노출
- [ ] `wiki.py toc-suggest --help`에 `--max-depth`/`--threshold`/`--llm`/`--format` 4 옵션 노출
- [ ] 각 lib 모듈은 stub이지만 import 시 에러 없음 (NotImplementedError는 호출 시에만 발생)
- [ ] wiki.py 본체 200줄 이하

## 보고

`reports/report-backend-dev.md` §T-1 섹션:
- 환경 점검 결과 (`python-frontmatter`/`jsonschema`/`pyyaml` 설치 상태)
- 작성 파일 7개 경로 + 각 줄 수
- 5개 `--help` 응답 출력
- R-4 가드 라인 카운트 (현재 / 한계 200)

## 위험

- **L-1**: `python-frontmatter` 미설치 → pip install 후 재시도. pip 사용 불가 환경이면 Team Lead에 SendMessage로 보고
- argparse 옵션 시그니처가 master-plan과 어긋나면 후속 task에서 도미노 변경 발생 → 본 task에서 확정
