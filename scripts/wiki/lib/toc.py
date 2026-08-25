"""heading 분석 + TOC outline 추천.

toc-recommendation.md §의사코드 직역. T-5에서 본격 구현.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

HEADING_RE = re.compile(r"^(#{1,6})\s+(.+)$")


# ── Step 1: heading 파싱 ──────────────────────────────────────────────────

def parse_headings(text: str) -> list[dict[str, Any]]:
    """frontmatter·fenced code block 제외 후 heading 추출.

    Returns:
        [{"level": int, "text": str, "line_start": int, "line_end": int}, ...]
    """
    lines = text.splitlines()
    headings: list[dict[str, Any]] = []
    in_frontmatter = False
    in_code_block = False

    for i, line in enumerate(lines):
        # frontmatter 시작
        if i == 0 and line.strip() == "---":
            in_frontmatter = True
            continue
        if in_frontmatter:
            if line.strip() == "---":
                in_frontmatter = False
            continue
        # fenced code block 토글
        if line.lstrip().startswith("```"):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            continue
        # heading 추출
        m = HEADING_RE.match(line)
        if m:
            level = len(m.group(1))
            text_h = m.group(2).strip()
            headings.append({
                "level": level,
                "text": text_h,
                "line_start": i,
                "line_end": -1,  # 후처리
            })

    # line_end 채움 (다음 heading의 line_start - 1, 마지막은 EOF)
    for j in range(len(headings)):
        if j + 1 < len(headings):
            headings[j]["line_end"] = headings[j + 1]["line_start"] - 1
        else:
            headings[j]["line_end"] = len(lines) - 1

    return headings


# ── Step 2: depth 분석 ───────────────────────────────────────────────────

def analyze_depth(depths: list[int], max_depth: int) -> str:
    """flatness 값 결정.

    Returns:
        "too_flat" | "too_deep" | "ok"
    """
    if not depths:
        return "ok"
    if max(depths) == 1:
        return "too_flat"
    if max(depths) > max_depth:
        return "too_deep"
    return "ok"


# ── Step 3: 길이 분석 ────────────────────────────────────────────────────

def analyze_length(heading: dict[str, Any], threshold: int) -> str:
    """섹션 라인 수 기반 suggestion.

    Returns:
        "split" | "merge" | "keep"
    """
    section_lines = heading["line_end"] - heading["line_start"]
    if section_lines > threshold:
        return "split"
    if section_lines < 5 and heading["level"] >= 2:
        return "merge"
    return "keep"


# ── Step 4: LLM 보강 (stub) ──────────────────────────────────────────────

def llm_augment(suggestions: list[dict], text: str) -> list[dict]:  # noqa: ARG001
    """LLM 보강 — 본 Phase에서는 미구현."""
    raise NotImplementedError("--llm 옵션은 Phase 1-5 이후 구현 예정입니다.")


# ── 핵심 함수: toc_suggest ────────────────────────────────────────────────

def toc_suggest(
    note_path: Path,
    max_depth: int = 3,
    use_llm: bool = False,
    length_threshold: int = 80,
) -> dict[str, Any]:
    """toc-recommendation.md §의사코드 직역.

    Returns:
        {
            "flatness": "too_flat|too_deep|ok",
            "max_depth_seen": int,
            "suggestions": [{"level", "text", "lines", "suggestion"}, ...]
        }
    """
    text = note_path.read_text(encoding="utf-8")
    headings = parse_headings(text)

    if not headings:
        return {"flatness": "ok", "max_depth_seen": 0, "suggestions": []}

    depths = [h["level"] for h in headings]
    flatness = analyze_depth(depths, max_depth)

    suggestions: list[dict[str, Any]] = []
    for h in headings:
        sg = analyze_length(h, length_threshold)
        suggestions.append({
            "level": h["level"],
            "text": h["text"],
            "lines": h["line_end"] - h["line_start"],
            "suggestion": sg,
        })

    if use_llm:
        suggestions = llm_augment(suggestions, text)

    return {
        "flatness": flatness,
        "max_depth_seen": max(depths),
        "suggestions": suggestions,
    }


# ── 출력 포맷 헬퍼 ───────────────────────────────────────────────────────

def format_json(result: dict[str, Any]) -> str:
    """JSON 포맷 (출력 JSON 스키마 100% 일치)."""
    return json.dumps(result, ensure_ascii=False, indent=2)


def format_markdown(result: dict[str, Any], note_path: Path) -> str:
    """Markdown 테이블 포맷."""
    lines = [
        f"# TOC 추천 — {note_path.name}",
        "",
        f"- **Flatness**: {result['flatness']}",
        f"- **Max depth seen**: {result['max_depth_seen']}",
        "",
        "## Suggestions",
        "",
        "| Level | Text | Lines | Suggestion |",
        "|---|---|---:|---|",
    ]
    for s in result["suggestions"]:
        lines.append(f"| {s['level']} | {s['text']} | {s['lines']} | {s['suggestion']} |")
    return "\n".join(lines)


# ── 통합 진입 ────────────────────────────────────────────────────────────

def run_toc_suggest(args: Any) -> int:
    """cmd_toc_suggest 진입점."""
    note_path: Path = args.note
    if not note_path.is_absolute():
        note_path = Path.cwd() / note_path

    if not note_path.exists():
        print(f"[ERROR] 파일 없음: {note_path}")
        return 1

    result = toc_suggest(
        note_path=note_path,
        max_depth=args.max_depth,
        use_llm=args.llm,
        length_threshold=args.threshold,
    )

    fmt = getattr(args, "format", "markdown")
    if fmt == "json" or getattr(args, "json_output", False):
        print(format_json(result))
    else:
        print(format_markdown(result, note_path))
    return 0
