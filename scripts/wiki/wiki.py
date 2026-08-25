#!/usr/bin/env python3
"""PAB-Wiki CLI — wiki new / link-check / moc-build / toc-suggest

Vault root 결정 우선순위:
1. --vault 인자
2. $WIKI_VAULT_ROOT 환경변수
3. default: <project-root>/wiki  (자기완결 모드)
"""
import argparse
import os
import sys
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parents[2]
VAULT_ROOT_DEFAULT = Path(os.environ.get("WIKI_VAULT_ROOT") or (_PROJECT_ROOT / "wiki"))

# 프로젝트 루트를 sys.path에 추가 (직접 실행 시 패키지 탐색 보장)
_root = str(_PROJECT_ROOT)
if _root not in sys.path:
    sys.path.insert(0, _root)


def cmd_new(args):
    """T-2에서 구현 — wiki new <TYPE> <slug>"""
    from scripts.wiki.lib.frontmatter import render_note, write_note, build_default_frontmatter
    from scripts.wiki.lib.frontmatter import DRY_RUN_PREFIX

    today = __import__("datetime").date.today().isoformat()
    type_dir_map = {
        "RESEARCH_NOTE": "10_Notes",
        "CONCEPT": "10_Notes",
        "LESSON": "10_Notes",
        "REFERENCE": "10_Notes",
        "PROJECT": "10_Notes",
        "DAILY": "99_Inbox",
    }
    note_dir = args.vault / type_dir_map.get(args.type, "10_Notes")
    filename = f"{today}_{args.slug}.md"
    out_path = note_dir / filename

    fm = build_default_frontmatter(args.type, args.slug)
    content = render_note(fm, args.vault, args.type)

    if args.dry_run:
        import yaml
        print(f"{DRY_RUN_PREFIX} 생성 예정: {out_path}")
        print("---")
        print(yaml.dump(fm, allow_unicode=True, default_flow_style=False).strip())
        print("---")
        return 0

    return write_note(out_path, fm, content, args.vault, args.type)


def cmd_link_check(args):
    """T-3에서 구현 — wiki link-check"""
    from scripts.wiki.lib.validate import run_link_check
    return run_link_check(args)


def cmd_moc_build(args):
    """T-4에서 구현 — wiki moc-build"""
    from scripts.wiki.lib.moc import run_moc_build
    return run_moc_build(args)


def cmd_toc_suggest(args):
    """T-5에서 구현 — wiki toc-suggest <note>"""
    from scripts.wiki.lib.toc import run_toc_suggest
    return run_toc_suggest(args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="wiki",
        description="PAB-Wiki CLI — Obsidian Karpathy-style wiki 자동화",
    )
    parser.add_argument(
        "--vault",
        type=Path,
        default=VAULT_ROOT_DEFAULT,
        help="Vault root (우선순위: --vault > $WIKI_VAULT_ROOT > <project>/wiki)",
    )
    parser.add_argument("--quiet", action="store_true", help="최소 출력")
    parser.add_argument(
        "--json",
        dest="json_output",
        action="store_true",
        help="JSON 출력 (link-check / toc-suggest)",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    # wiki new <TYPE> <slug>
    p_new = sub.add_parser("new", help="새 노트 생성 (11필드 frontmatter 자동 채움 + 템플릿 적용)")
    p_new.add_argument(
        "type",
        choices=["RESEARCH_NOTE", "CONCEPT", "LESSON", "PROJECT", "DAILY", "REFERENCE"],
        help="노트 TYPE (6종)",
    )
    p_new.add_argument("slug", help="파일 slug (YYYY-MM-DD_<slug>.md 형식)")
    p_new.add_argument("--dry-run", action="store_true", help="실제 파일 미생성, frontmatter만 출력")
    p_new.set_defaults(func=cmd_new)

    # wiki link-check
    p_lc = sub.add_parser(
        "link-check",
        help="frontmatter strict (schema v1.1) + broken [[wikilink]] + orphan 검출",
    )
    p_lc.add_argument("--full", action="store_true", help="전체 상세 출력 (향후 확장용)")
    p_lc.set_defaults(func=cmd_link_check)

    # wiki moc-build
    p_mb = sub.add_parser(
        "moc-build",
        help="12 MOC 폴백 정적 링크 idempotent 갱신 + TOPIC 승격 (N≥threshold)",
    )
    p_mb.add_argument("--dry-run", action="store_true", help="갱신 예정 내역만 출력, 파일 미변경")
    p_mb.add_argument(
        "--topic-threshold",
        type=int,
        default=3,
        metavar="N",
        help="TOPIC 승격 최소 등장 빈도 (기본 3)",
    )
    p_mb.set_defaults(func=cmd_moc_build)

    # wiki toc-suggest <note>
    p_ts = sub.add_parser(
        "toc-suggest",
        help="노트 heading 분석 + outline 추천 (toc-recommendation.md 명세)",
    )
    p_ts.add_argument("note", type=Path, help="분석할 노트 경로")
    p_ts.add_argument("--max-depth", type=int, default=3, help="허용 heading 최대 깊이 (기본 3)")
    p_ts.add_argument(
        "--threshold",
        type=int,
        default=80,
        help="섹션 split 임계 라인 수 (기본 80)",
    )
    p_ts.add_argument("--llm", action="store_true", help="LLM 보강 활성화 (현재 stub)")
    p_ts.add_argument(
        "--format",
        choices=["markdown", "json"],
        default="markdown",
        help="출력 포맷 (기본 markdown)",
    )
    p_ts.set_defaults(func=cmd_toc_suggest)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    result = args.func(args)
    return result if isinstance(result, int) else 0


if __name__ == "__main__":
    sys.exit(main())
