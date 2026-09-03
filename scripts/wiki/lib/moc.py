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


# TOPIC MOC 파일명으로 안전한 stem 인가 (N-6 이중 가드 — 갱신 루프·승격 양쪽에 적용).
# `_` 접두는 vault 전역 단일 관례로 제외한다(N-4) — `_README.md` 파일명 하드코딩 대신
# 규칙으로 두면 나중에 `_draft.md` 가 생겨도 자동으로 갱신 대상에서 빠진다.
# 경로 구분자·상대경로 토큰을 막는 것이 본 가드의 보안 측면이다(승격은 파일을 만든다).
TOPIC_STEM_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")


def is_safe_topic_stem(stem: str) -> bool:
    if not stem or stem.startswith("_") or len(stem) > 64:
        return False
    return bool(TOPIC_STEM_RE.match(stem))


def is_source_note(note: dict) -> bool:
    """15_Sources 하위 노트인가 (SOURCE 원본 — 승격 계수에서 제외)."""
    return "15_Sources" in Path(note["path"]).parts


def collect_notes_by_topic(notes: list[dict]) -> dict[str, list[dict]]:
    """topic → 멤버 전건. **threshold 를 걸지 않는다**(지침 1).

    승격 문턱은 *"새 MOC 를 만들 자격"* 이지 기존 MOC 갱신과 무관하다. 여기에
    threshold 를 걸면 저빈도 TOPIC 이 다시 얼어붙어 결함이 절반만 고쳐진다.
    """
    groups: dict[str, list[dict]] = {}
    for n in notes:
        for t in n["topics"]:
            groups.setdefault(t, []).append(n)
    return groups


def collect_topic_candidates(notes: list[dict], threshold: int = 3) -> dict[str, list[dict]]:
    """승격 후보. **계수만 비-SOURCE, 멤버는 전 노트**(지침 2).

    멤버까지 비-SOURCE 로 좁히면 승격 직후 MOC 에서 SOURCE 가 빠지는데, 다음
    run_moc_build 의 갱신 루프(A)가 전 노트로 다시 채운다 ⇒ 1회차 ≠ 2회차 = 진동.
    A 가 없을 때는 드러나지 않다가 A 를 넣는 순간 실재화하는 종류다.
    """
    groups = collect_notes_by_topic(notes)
    return {
        t: ns for t, ns in groups.items()
        if sum(1 for n in ns if not is_source_note(n)) >= threshold
    }


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

    # ── A: 기존 TOPIC MOC 갱신 루프 (PAB-Prove 4067440 표적 이식) ────────────────
    # 이 루프가 없어서 T-7 자동화가 절반만 돌았다 — TYPES·DOMAINS 는 갱신되는데
    # 기존 TOPIC MOC 22건이 생성 시점에 얼어붙어 있었다. `orphans=0` 이 초록 불로
    # 보이지만 그 지표는 TYPES·DOMAINS 등재만 보고 TOPIC 정체는 보지 않는다.
    #
    # ⚠️ 모수는 **디스크 glob** 이어야 한다(N-5). TYPES·DOMAINS 를 흉내 내
    # MOC_TOPIC_NAMES 상수 목록을 만들면 승격할 때마다 손으로 넣어야 하고, 안 넣으면
    # 다시 얼어붙은 채 `exit 0` 으로 조용히 지나간다 — 결함이 그대로 재발한다.
    # TYPES·DOMAINS 가 상수인 것은 **고정 분류 체계**라서고, TOPIC 은 승격으로
    # **자라는** 집합이라 성질이 다르다.
    #
    # threshold 를 걸지 않는다(지침 1) — by_topic 은 collect_notes_by_topic 산출물이다.
    by_topic = collect_notes_by_topic(notes)
    topics_dir = vault / "00_MOC/TOPICS"
    if topics_dir.exists():
        for moc_path in sorted(topics_dir.glob("*.md")):
            stem = moc_path.stem
            if not is_safe_topic_stem(stem):
                # `_README.md`(placeholder 명세 노트, FIX-3) 등이 여기로 빠진다.
                # 차단을 **출력**하는 이유(N-6): 승격·갱신 0건이 나왔을 때 "이식 실패"인지
                # "정상 차단"인지 구분할 수 있어야 한다.
                print(f"[SKIP] TOPICS/{moc_path.name} — 비정규 TOPIC stem (갱신 대상 아님)")
                continue
            _process_moc(moc_path, by_topic.get(stem, []), f"TOPICS/{stem}.md")

    promoted: list[str] = []
    for topic, members in topic_candidates.items():
        # 이중 가드(N-6) — 승격은 파일을 **새로 만드는** 쪽이라 이름 검증이 더 중요하다.
        if not is_safe_topic_stem(topic):
            print(f"[SKIP] TOPIC 승격 차단: {topic!r} — 비정규 stem")
            continue
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
