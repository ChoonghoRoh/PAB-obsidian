"""MOC 폴백 정적 링크 idempotent 갱신 + TOPIC 승격 유틸 (T-4)."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import frontmatter as fm_lib

MARKER_START = "<!-- moc-build:auto-start -->"
MARKER_END = "<!-- moc-build:auto-end -->"
SECTION_RE = re.compile(
    rf"({re.escape(MARKER_START)}).*?({re.escape(MARKER_END)})", re.DOTALL
)

MOC_TYPE_NAMES = ["RESEARCH_NOTE", "CONCEPT", "LESSON", "PROJECT", "DAILY", "REFERENCE"]
MOC_DOMAIN_NAMES = ["AI", "HARNESS", "ENGINEERING", "PRODUCT", "KNOWLEDGE_MGMT", "MISC"]


def strip_brackets(value: Any) -> str | None:
    if not value:
        return None
    s = str(value).strip()
    return s[2:-2] if s.startswith("[[") and s.endswith("]]") else s


def collect_notes_with_meta(vault: Path) -> list[dict[str, Any]]:
    if not vault.exists():
        return []
    notes = []
    for p in vault.rglob("*.md"):
        if any(x in p.parts for x in ["00_MOC", "40_Templates", "_attachments"]):
            continue
        try:
            post = fm_lib.load(str(p))
        except Exception:
            continue
        notes.append({
            "path": p,
            "stem": p.stem,
            "type": strip_brackets(post.metadata.get("type")),
            "index": strip_brackets(post.metadata.get("index")),
            "topics": [
                t for t in (strip_brackets(x) for x in post.metadata.get("topics", [])) if t
            ],
            "title": post.metadata.get("title", p.stem),
            "created": post.metadata.get("created", ""),
        })
    return notes


def collect_notes_by_type(notes: list[dict]) -> dict[str, list[dict]]:
    groups: dict[str, list[dict]] = {}
    for n in notes:
        if n["type"]:
            groups.setdefault(n["type"], []).append(n)
    return groups


def collect_notes_by_index(notes: list[dict]) -> dict[str, list[dict]]:
    groups: dict[str, list[dict]] = {}
    for n in notes:
        d = n["index"]
        if d and d != "ROOT":
            groups.setdefault(d, []).append(n)
    return groups


def collect_topic_candidates(notes: list[dict], threshold: int = 3) -> dict[str, list[dict]]:
    counts: dict[str, list[dict]] = {}
    for n in notes:
        for t in n["topics"]:
            counts.setdefault(t, []).append(n)
    return {t: ns for t, ns in counts.items() if len(ns) >= threshold}


def update_moc_fallback_links(moc_path: Path, group: list[dict]) -> bool:
    try:
        text = moc_path.read_text(encoding="utf-8")
    except OSError:
        return False
    sorted_group = sorted(group, key=lambda n: str(n.get("created", "")), reverse=True)
    body = (
        "\n".join(f"- [[{n['stem']}]] — {n['title']}" for n in sorted_group)
        or "_(현재 등록된 노트 없음)_"
    )
    block = f"{MARKER_START}\n{body}\n{MARKER_END}"
    if SECTION_RE.search(text):
        new_text = SECTION_RE.sub(block, text)
    elif "## 폴백 정적 링크" in text:
        new_text = text.replace("## 폴백 정적 링크\n", f"## 폴백 정적 링크\n\n{block}\n", 1)
    else:
        return False
    if new_text != text:
        moc_path.write_text(new_text, encoding="utf-8")
        return True
    return False


def promote_topic(vault: Path, topic: str, members: list[dict]) -> Path | None:
    from scripts.wiki.lib.frontmatter import build_default_frontmatter

    moc_path = vault / f"00_MOC/TOPICS/{topic}.md"
    if moc_path.exists():
        return None
    slug = topic.lower().replace("_", "-")
    fm_data = build_default_frontmatter("REFERENCE", slug)
    fm_data.update({"type": "[[REFERENCE]]", "index": "[[ROOT]]",
                    "tags": ["moc", f"topics/{slug}"],
                    "title": topic.replace("_", " ").title()})
    sorted_m = sorted(members, key=lambda n: str(n.get("created", "")), reverse=True)
    fallback = "\n".join(f"- [[{n['stem']}]] — {n['title']}" for n in sorted_m)
    body = (
        f"## Dataview 쿼리\n\n"
        f'```dataview\nLIST FROM "" WHERE contains(topics, "[[{topic}]]") SORT created DESC\n```\n\n'
        f"## 폴백 정적 링크\n\n{MARKER_START}\n{fallback}\n{MARKER_END}"
    )
    post = fm_lib.Post(body, **fm_data)
    moc_path.parent.mkdir(parents=True, exist_ok=True)
    moc_path.write_text(fm_lib.dumps(post), encoding="utf-8")
    return moc_path


def run_moc_build(args: Any) -> int:
    vault: Path = args.vault
    dry_run: bool = args.dry_run
    threshold: int = args.topic_threshold

    notes = collect_notes_with_meta(vault)
    by_type = collect_notes_by_type(notes)
    by_domain = collect_notes_by_index(notes)
    topic_candidates = collect_topic_candidates(notes, threshold)

    changed, skipped, total_moc = 0, 0, 0

    def _process_moc(moc_path: Path, group: list[dict], label: str) -> None:
        nonlocal changed, skipped, total_moc
        if not moc_path.exists():
            return
        total_moc += 1
        if dry_run:
            print(f"[dry-run] {label} → {len(group)}건 갱신 예정")
            return
        if update_moc_fallback_links(moc_path, group):
            changed += 1
            print(f"[OK] {label} 갱신 ({len(group)}건)")
        else:
            skipped += 1

    for name in MOC_TYPE_NAMES:
        _process_moc(vault / f"00_MOC/TYPES/{name}.md", by_type.get(name, []), f"TYPES/{name}.md")
    for name in MOC_DOMAIN_NAMES:
        _process_moc(vault / f"00_MOC/DOMAINS/{name}.md", by_domain.get(name, []), f"DOMAINS/{name}.md")

    # TOPICS/_README.md: placeholder 명세 노트 — 폴백 정적 링크 섹션 없음. 갱신 제외 (hotfix FIX-3)
    # (Phase 1-3 산출물 보존 원칙 적용)

    promoted: list[str] = []
    for topic, members in topic_candidates.items():
        if dry_run:
            if not (vault / f"00_MOC/TOPICS/{topic}.md").exists():
                print(f"[dry-run] TOPIC 승격 예정: {topic} ({len(members)}건)")
            continue
        result_path = promote_topic(vault, topic, members)
        if result_path:
            promoted.append(topic)
            print(f"[OK] TOPIC 승격: {topic} → {result_path}")

    if dry_run:
        print(f"\n[dry-run] 총 {total_moc} MOC 인식, 실제 변경 없음")
        return 0
    if changed == 0 and not promoted:
        print(f"no changes (total={total_moc}, notes={len(notes)})")
    else:
        print(f"\n완료: {changed}개 MOC 갱신, {skipped}개 변경 없음, {len(promoted)}개 TOPIC 승격")
    return 0
