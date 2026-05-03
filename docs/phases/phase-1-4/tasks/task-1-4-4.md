---
task_id: "1-4-4"
title: "wiki moc-build — 13 MOC placeholder 자동 갱신 + TOPIC 승격(N=3)"
domain: WIKI-CLI
owner: backend-dev
priority: P0
estimate_min: 30
status: pending
depends_on: ["1-4-1"]
blocks: ["1-4-6"]
---

# Task 1-4-4 — `wiki moc-build` 구현

## 목적

vault 노트 frontmatter를 파싱하여 13 MOC(`TYPES/` 6 + `DOMAINS/` 6 + `TOPICS/_README` 1)의 `## 폴백 정적 링크` 섹션을 자동 갱신하고, TOPIC 등장 빈도가 N=3 이상이면 신규 TOPIC MOC를 자동 생성한다.

## 산출물

- `scripts/wiki/lib/moc.py` (collect_notes_by_type / by_index / collect_topic_candidates / update_moc_fallback_links / promote_topic)
- `scripts/wiki/wiki.py` 의 `cmd_moc_build` 분기

## 노트 수집

```python
def collect_notes_with_meta(vault: Path) -> list[dict]:
    notes = []
    for p in (vault / "wiki").rglob("*.md"):
        if any(part in p.parts for part in ["_attachments", "00_MOC", "40_Templates"]):
            continue  # MOC 자체와 템플릿은 제외
        post = frontmatter.load(p)
        notes.append({
            "path": p,
            "stem": p.stem,
            "type": strip_brackets(post.metadata.get("type")),     # "[[RESEARCH_NOTE]]" → "RESEARCH_NOTE"
            "index": strip_brackets(post.metadata.get("index")),
            "topics": [strip_brackets(t) for t in post.metadata.get("topics", [])],
            "title": post.metadata.get("title", p.stem),
            "created": post.metadata.get("created", ""),
        })
    return notes
```

## TYPE/DOMAIN 그룹화

```python
def collect_notes_by_type(notes: list[dict]) -> dict[str, list[dict]]:
    groups = {}
    for n in notes:
        t = n["type"]
        if t:
            groups.setdefault(t, []).append(n)
    return groups

def collect_notes_by_index(notes: list[dict]) -> dict[str, list[dict]]:
    groups = {}
    for n in notes:
        d = n["index"]
        if d and d != "ROOT":
            groups.setdefault(d, []).append(n)
    return groups
```

## TOPIC 승격

```python
def collect_topic_candidates(notes: list[dict], threshold: int = 3) -> dict[str, list[dict]]:
    """등장 빈도 ≥ threshold인 TOPIC만 반환."""
    counts = {}
    for n in notes:
        for t in n["topics"]:
            counts.setdefault(t, []).append(n)
    return {t: ns for t, ns in counts.items() if len(ns) >= threshold}
```

승격 시 신규 TOPIC MOC 생성 — `wiki/00_MOC/TOPICS/<TOPIC>.md`:
- frontmatter 11필드 (T-2 build_default_frontmatter 재사용. type=`[[REFERENCE]]`, index=`[[ROOT]]`, tags=`["moc","topics/<slug>"]`)
- dataview 쿼리: `LIST FROM "" WHERE contains(topics, "[[<TOPIC>]]") SORT created DESC`
- `## 폴백 정적 링크` 섹션 (해당 TOPIC 노트 wikilink 목록)

`wiki/00_MOC/TOPICS/_README.md` 명세 (Phase 1-3 T-3) 정확 준수.

## 폴백 링크 갱신 (idempotent)

각 MOC 파일에 marker 주입 후 갱신:

```markdown
## 폴백 정적 링크

<!-- moc-build:auto-start -->
- [[2026-05-01_some-note]] — Some Note Title
- [[2026-05-01_other]] — Other Title
<!-- moc-build:auto-end -->
```

```python
import re
MARKER_START = "<!-- moc-build:auto-start -->"
MARKER_END = "<!-- moc-build:auto-end -->"
SECTION_RE = re.compile(rf"({re.escape(MARKER_START)}).*?({re.escape(MARKER_END)})", re.DOTALL)

def update_moc_fallback_links(moc_path: Path, group: list[dict]) -> bool:
    text = moc_path.read_text()
    sorted_group = sorted(group, key=lambda n: n["created"], reverse=True)
    body = "\n".join(f"- [[{n['stem']}]] — {n['title']}" for n in sorted_group) or "_(현재 등록된 노트 없음)_"
    block = f"{MARKER_START}\n{body}\n{MARKER_END}"
    if SECTION_RE.search(text):
        new_text = SECTION_RE.sub(block, text)
    else:
        # 마커가 없으면 "## 폴백 정적 링크" 섹션 다음에 삽입
        if "## 폴백 정적 링크" in text:
            new_text = text.replace("## 폴백 정적 링크\n", f"## 폴백 정적 링크\n\n{block}\n", 1)
        else:
            return False  # MOC 형식이 예상과 다름 — 보고만
    if new_text != text:
        moc_path.write_text(new_text)
        return True
    return False
```

## 빈 vault 처리

`notes`가 0건이면 13 MOC 모두 placeholder 빈 채로 idempotent 갱신 (또는 이미 비어있으면 변경 없음). exit 0.

## --dry-run

갱신 예정 MOC 경로 + diff 요약(추가/제거 링크 수)만 출력. 파일 미변경.

## smoke test

```bash
# dry-run
python3 scripts/wiki/wiki.py moc-build --dry-run
# 기대: 13 MOC 인식, 시드 노트 0건이므로 갱신 0 또는 placeholder 빈 채 갱신 1회만

# 실제 실행
python3 scripts/wiki/wiki.py moc-build
git diff wiki/00_MOC/  # 또는 그냥 ls/cat (git 없음)

# idempotent 검증 (2회 실행 후 변경 0)
python3 scripts/wiki/wiki.py moc-build
# 출력: "no changes" 또는 변경 0건

# 가상 TOPIC 승격 (시드 3건 임시 작성 후 실행 → 정리)
# (verifier 검증 단계에서 수행)
```

## 완료 기준

- [ ] `lib/moc.py` 5 함수 + 통합 진입 구현
- [ ] 빈 vault에서 정상 종료 (exit 0)
- [ ] 13 MOC marker 주입 + idempotent 갱신
- [ ] `--dry-run` 시 파일 미변경
- [ ] TOPIC 승격 N=3 동작 (가상 케이스로 검증)
- [ ] `lib/moc.py` 250줄 이하 (R-4)

## 보고

`reports/report-backend-dev.md` §T-4:
- dry-run / 실제 실행 결과 (갱신 MOC 수, 추가 링크 수)
- idempotent 검증 (2회 실행 후 변경 0)
- TOPIC 승격 가상 케이스 결과 (verifier가 별도 검증)

## 위험

- **L-4**: TOPIC 승격이 무한 루프하지 않도록 — `notes` 0건이면 즉시 return
- 기존 MOC가 marker 없이 작성되었을 가능성 → `## 폴백 정적 링크` 섹션 다음에 marker 주입. 섹션 자체가 없으면 보고만 (FAIL 아님)
- `created` 필드가 문자열로 정렬되므로 `YYYY-MM-DD HH:MM` 형식 일관 가정. 형식 위반 노트는 정렬 후순위로 밀려도 정상
