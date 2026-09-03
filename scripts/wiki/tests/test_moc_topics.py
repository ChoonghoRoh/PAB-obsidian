"""T-7 TOPIC 갱신 루프 이식 회귀 시험 (지침 1~7 · N-1~N-7).

⚠️ 이 파일의 시험 대부분은 **"하지 않았음"을 증명**하려는 것이다(부작위 요구).
부작위는 리뷰에서 눈에 띄지 않는다 — diff 에 `-` 줄로만 나타나거나
"개선"처럼 보이는 `+` 줄로 우회적으로 무력화된다. 그래서 관측 가능한 형태로 바꾼다.

정본 vault 는 절대 건드리지 않는다. 전부 tmp_path 픽스처다.
"""
from __future__ import annotations

import sys
from argparse import Namespace
from pathlib import Path

import pytest

_ROOT = Path(__file__).resolve().parents[3]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from scripts.wiki.lib.moc import (  # noqa: E402
    MARKER_END,
    MARKER_START,
    collect_notes_by_topic,
    collect_notes_with_meta,
    collect_topic_candidates,
    is_safe_topic_stem,
    run_moc_build,
)
from scripts.wiki.lib.validate import (  # noqa: E402
    collect_link_sources,
    collect_notes,
    find_orphan_notes,
)

THRESHOLD = 2


def _note(path: Path, title: str, topics: list[str], created: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    topic_yaml = "".join(f'\n  - "[[{t}]]"' for t in topics) or " []"
    path.write_text(
        f"---\ntitle: {title}\ndescription: \"\"\ncreated: {created}\n"
        f"updated: {created}\ntype: \"[[CONCEPT]]\"\nindex: \"[[ROOT]]\"\n"
        f"topics:{topic_yaml}\ntags:\n  - concept\nkeywords: []\nsources: []\n"
        f"aliases: []\n---\n\n# {title}\n\n본문.\n",
        encoding="utf-8",
    )


def _moc_with_markers(path: Path, stale_body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f"---\ntitle: MOC\n---\n\n## 폴백 정적 링크\n\n"
        f"{MARKER_START}\n{stale_body}\n{MARKER_END}\n",
        encoding="utf-8",
    )


@pytest.fixture()
def vault(tmp_path: Path) -> Path:
    """N-3 조건을 만족하는 픽스처.

    승격이 **실제로 일어나고**(T_PROMO), 그 topic 멤버에 `15_Sources` 가 **최소 1건**
    있어야 지침 2 위반(진동)이 드러난다. 승격 0건이면 2회차가 자동으로 깨끗해
    **헛통과**한다 — 정본으로 그냥 돌리면 승격 0건이라 바로 이 함정에 빠진다.
    """
    v = tmp_path / "vault"
    # T_PROMO — 비-SOURCE 2건(임계 도달) + SOURCE 1건(멤버에는 포함돼야 한다)
    _note(v / "10_Notes/b.md", "B", ["T_PROMO"], "2026-01-02 10:00")
    _note(v / "10_Notes/c.md", "C", ["T_PROMO"], "2026-01-03 10:00")
    _note(v / "15_Sources/s1_source.md", "S1", ["T_PROMO"], "2026-01-01 10:00")
    # T_LOW — 1건뿐이라 임계 미달. 그래도 **기존 MOC 는 갱신돼야 한다**(지침 1)
    _note(v / "10_Notes/a.md", "A", ["T_LOW"], "2026-01-04 10:00")
    _moc_with_markers(v / "00_MOC/TOPICS/T_LOW.md", "- [[stale]] — 낡은 내용")
    # 참조원 전용 — 판정 대상은 아니지만 링크를 제공한다(지침 4)
    (v / "30_Constraints").mkdir(parents=True, exist_ok=True)
    (v / "30_Constraints/rules.md").write_text(
        "# rules\n\n- [[a]]\n- [[b]]\n- [[c]]\n- [[s1_source]]\n", encoding="utf-8"
    )
    # `_` 접두 — 판정 대상에서 빠져야 한다(N-4). 안 빠지면 영구 orphan 이 된다
    _note(v / "10_Notes/_old/backup.md", "Backup", [], "2025-01-01 10:00")
    return v


def _build(vault: Path, dry_run: bool = False, capsys=None) -> str:
    rc = run_moc_build(Namespace(vault=vault, dry_run=dry_run, topic_threshold=THRESHOLD))
    assert rc == 0
    return capsys.readouterr().out if capsys else ""


# ── 지침 7 / N-2 — 부작위 요구의 능동 검증 ────────────────────────────────────
def test_guideline7_manual_moc_is_byte_identical(vault: Path, capsys):
    """마커도 `## 폴백 정적 링크` 헤더도 없는 MOC 는 **바이트 단위로 불변**이어야 한다.

    `update_moc_fallback_links` 의 `else: return False` 한 줄이 사람이 손으로 만든 MOC 를
    지키는 **유일한 가드**다. A 가 갱신 모수를 "디스크의 TOPICS/*.md 전부"로 넓히므로
    이 skip 이 없으면 수동 MOC 가 덮인다 — 그리고 그 write 는 LiveSync 로 즉시
    정본→CouchDB→미러→v4 까지 전파돼 롤백이 파일 하나로 끝나지 않는다.

    이식 중 *"헤더가 없으면 만들어 주자"* 는 개선이 자연스러워 보인다.
    그게 정확히 이 가드를 무력화한다.
    """
    manual = vault / "00_MOC/TOPICS/MANUAL.md"
    manual.parent.mkdir(parents=True, exist_ok=True)
    original = "---\ntitle: 손으로 만든 MOC\n---\n\n사람이 쓴 본문. 자동 갱신 대상이 아니다.\n"
    manual.write_bytes(original.encode("utf-8"))
    before = manual.read_bytes()

    _build(vault, capsys=capsys)

    assert manual.read_bytes() == before, "수동 MOC 가 변경됐다 — N-2 가드가 무력화됐다"


def test_no_write_when_content_identical(vault: Path, capsys):
    """내용이 같으면 쓰지 않는다 — idempotency 의 실체이자 불필요 LiveSync 전파 차단."""
    _build(vault, capsys=capsys)
    moc = vault / "00_MOC/TOPICS/T_LOW.md"
    mtime_before = moc.stat().st_mtime_ns
    _build(vault, capsys=capsys)
    assert moc.stat().st_mtime_ns == mtime_before, "내용이 같은데 다시 썼다 — 4홉 체인이 헛돈다"


# ── 지침 6 / N-3 — idempotency (1번+2번이 합쳐져야 드러나는 진동) ──────────────
def test_guideline6_second_run_reports_no_changes(vault: Path, capsys):
    """2회 연속 실행 → 2회차 `no changes`.

    ⚠️ 이 시험은 **픽스처 조건이 맞아야만** 결함을 잡는다(N-3). 승격이 1회차에
    실제로 일어나고 그 topic 멤버에 SOURCE 가 있어야 한다.
    지침 2 를 어기면(멤버까지 비-SOURCE 로 좁히면) 1회차 승격이 SOURCE 빠진 MOC 를
    만들고 2회차 A 가 전 노트로 다시 채워 **여기서 깨진다**.
    """
    out1 = _build(vault, capsys=capsys)
    assert "TOPIC 승격: T_PROMO" in out1, "픽스처 무효 — 승격이 안 일어나면 헛통과한다"

    out2 = _build(vault, capsys=capsys)
    assert "no changes" in out2, f"2회차가 깨끗하지 않다 = 진동.\n--- 2회차 ---\n{out2}"


def test_promoted_moc_contains_source_member(vault: Path, capsys):
    """지침 2 — 승격 MOC 멤버에 `15_Sources` 가 **포함**돼야 한다(계수에서만 제외)."""
    _build(vault, capsys=capsys)
    text = (vault / "00_MOC/TOPICS/T_PROMO.md").read_text(encoding="utf-8")
    assert "[[s1_source]]" in text, "승격 MOC 에서 SOURCE 가 빠졌다 — 다음 회차에 진동한다"


def test_threshold_counts_exclude_sources(vault: Path):
    """지침 2 — 계수는 비-SOURCE 만. SOURCE 를 세면 임계가 헐거워진다."""
    notes = collect_notes_with_meta(vault)
    # T_LOW 는 비-SOURCE 1건뿐 → 임계 2 미달로 승격 후보가 아니다
    assert "T_LOW" not in collect_topic_candidates(notes, THRESHOLD)
    # T_PROMO 는 비-SOURCE 2건 → 후보. 단 멤버는 SOURCE 포함 3건
    cands = collect_topic_candidates(notes, THRESHOLD)
    assert "T_PROMO" in cands
    assert len(cands["T_PROMO"]) == 3, "멤버까지 좁혔다 — 지침 2 위반"


# ── 지침 1 — A 에 threshold 를 걸지 말 것 ─────────────────────────────────────
def test_guideline1_low_frequency_topic_still_updated(vault: Path, capsys):
    """임계 미달 TOPIC 의 기존 MOC 도 갱신돼야 한다.

    A 에 threshold 를 걸면 저빈도 TOPIC 이 다시 얼어붙어 **결함이 절반만 고쳐진다** —
    그런데 기록에는 "고쳤다"로 남는다.
    """
    _build(vault, capsys=capsys)
    text = (vault / "00_MOC/TOPICS/T_LOW.md").read_text(encoding="utf-8")
    assert "[[a]]" in text, "임계 미달 TOPIC 이 갱신되지 않았다 — A 에 threshold 가 걸렸다"
    assert "stale" not in text, "낡은 내용이 남았다"


# ── N-5 — 갱신 모수는 디스크 glob ─────────────────────────────────────────────
def test_n5_new_topic_moc_picked_up_from_disk(vault: Path, capsys):
    """상수 목록이 아니라 디스크 glob 이어야 한다.

    `MOC_TOPIC_NAMES` 상수를 만들면 승격할 때마다 손으로 넣어야 하고, 안 넣으면
    다시 얼어붙은 채 `exit 0` 으로 조용히 지나간다.
    """
    _note(vault / "10_Notes/z.md", "Z", ["BRAND_NEW"], "2026-02-01 10:00")
    _moc_with_markers(vault / "00_MOC/TOPICS/BRAND_NEW.md", "- [[stale]]")
    _build(vault, capsys=capsys)
    text = (vault / "00_MOC/TOPICS/BRAND_NEW.md").read_text(encoding="utf-8")
    assert "[[z]]" in text, "디스크에 새로 생긴 TOPIC MOC 이 갱신되지 않았다"


# ── N-4 / N-6 — `_` 접두 제외 + [SKIP] 출력 ───────────────────────────────────
def test_n4_underscore_stem_rule():
    assert is_safe_topic_stem("VLLM")
    assert not is_safe_topic_stem("_README"), "`_` 접두는 갱신 대상이 아니다"
    assert not is_safe_topic_stem("_draft"), "파일명 하드코딩이 아니라 규칙이어야 한다"
    # 승격은 파일을 만든다 — 경로 구분자·상대경로가 통과하면 안 된다
    assert not is_safe_topic_stem("../escape")
    assert not is_safe_topic_stem("a/b")
    assert not is_safe_topic_stem("")


def test_n6_skip_is_printed(vault: Path, capsys):
    """차단을 출력해야 승격·갱신 0건이 '이식 실패'인지 '정상 차단'인지 구분된다."""
    readme = vault / "00_MOC/TOPICS/_README.md"
    readme.parent.mkdir(parents=True, exist_ok=True)
    readme.write_text("placeholder 명세 노트\n", encoding="utf-8")
    out = _build(vault, capsys=capsys)
    assert "[SKIP]" in out and "_README.md" in out


def test_readme_is_never_written(vault: Path, capsys):
    """FIX-3 — `_README.md` 는 폴백 링크 섹션이 없는 placeholder 라 건드리면 안 된다."""
    readme = vault / "00_MOC/TOPICS/_README.md"
    readme.parent.mkdir(parents=True, exist_ok=True)
    readme.write_bytes(b"placeholder\n")
    before = readme.read_bytes()
    _build(vault, capsys=capsys)
    assert readme.read_bytes() == before


# ── N-7 — 삭제 로직을 만들지 않는다 ───────────────────────────────────────────
def test_n7_promotion_does_not_delete_anything(vault: Path, capsys):
    """B 는 회수하지 않는다. 허수 승격분 MOC 도 A 가 계속 갱신하므로 낡지 않는다.

    "지우지 않으면 낡은 파일이 쌓인다"는 걱정이 삭제 로직의 또 다른 동기가 되는데,
    그 걱정은 성립하지 않는다 — 지식 자산을 지우는 코드를 새로 만들 이유가 없다.
    """
    orphan_moc = vault / "00_MOC/TOPICS/NO_MEMBERS.md"
    _moc_with_markers(orphan_moc, "- [[gone]]")
    _build(vault, capsys=capsys)
    assert orphan_moc.exists(), "멤버 0건 MOC 가 삭제됐다 — 지식 자산 삭제 코드가 생겼다"
    assert "현재 등록된 노트 없음" in orphan_moc.read_text(encoding="utf-8")


# ── 지침 3 / 4 — 모집단 분리 ──────────────────────────────────────────────────
def test_guideline3_moc_build_population_not_narrowed(vault: Path):
    """moc-build 수집 모수는 무변경 — 좁히면 MOC 에서 노트가 빠져 orphan 을 자초한다."""
    stems = {n["stem"] for n in collect_notes_with_meta(vault)}
    assert {"a", "b", "c", "s1_source"} <= stems
    assert "rules" in stems, "moc-build 모수가 판정 모집단으로 좁혀졌다 — 지침 3 위반"


def test_judge_population_is_whitelisted(vault: Path):
    """판정 대상 = `10_Notes` + `15_Sources`, `_` 접두 제외."""
    stems = {p.stem for p in collect_notes(vault)}
    assert stems == {"a", "b", "c", "s1_source"}
    assert "backup" not in stems, "`_old/` 가 판정 대상에 남았다 — 영구 orphan 이 된다"
    assert "rules" not in stems, "`30_Constraints` 는 판정 대상이 아니다"


def test_guideline4_link_sources_stay_whole_vault(vault: Path):
    """참조원은 전 vault. 좁히면 링크가 소실돼 orphan 이 급증하고 게이트가 오탐한다."""
    src_stems = {p.stem for p in collect_link_sources(vault)}
    assert "rules" in src_stems, "`30_Constraints` 가 참조원에서 빠졌다 — 지침 4 위반"

    targets, sources = collect_notes(vault), collect_link_sources(vault)
    assert find_orphan_notes(targets, sources) == [], "참조원 전 vault 인데 orphan 이 생겼다"
    # 참조원을 판정 대상으로 좁히면 실제로 orphan 이 발생함을 대조로 보인다
    assert find_orphan_notes(targets, targets), "대조 실패 — 이 시험이 무의미해졌다"


def test_topic_grouping_has_no_threshold(vault: Path):
    """A 가 쓰는 그룹핑에는 임계가 없어야 한다."""
    by_topic = collect_notes_by_topic(collect_notes_with_meta(vault))
    assert "T_LOW" in by_topic and len(by_topic["T_LOW"]) == 1


# ── §5 미해결 관측 — link-check 비결정성 ──────────────────────────────────────
# 실측(2026-09-03): 정본 vault 에서 `obsidian unresolved` 10회 중 **1회**가 281줄 대신
# **1줄**을 rc=0 으로 반환했다. 이것이 `broken: 0` 이 단 1회 나오고 13회 재현되지 않은
# 이상 관측의 정체다. 종료코드는 목적 달성의 증거가 아니다.
class _FakeCompleted:
    def __init__(self, stdout: str, returncode: int = 0):
        self.stdout, self.returncode = stdout, returncode


@pytest.fixture()
def link_vault(tmp_path: Path) -> Path:
    v = tmp_path / "vault"
    _note(v / "10_Notes/x.md", "X", [], "2026-01-01 10:00")
    (v / "10_Notes/x.md").write_text(
        (v / "10_Notes/x.md").read_text(encoding="utf-8") + "\n[[없는노트]]\n",
        encoding="utf-8",
    )
    return v


def test_degenerate_obsidian_run_falls_back(link_vault: Path, monkeypatch):
    """인덱싱이 덜 끝난 rc=0 응답을 **폴백으로 넘긴다**.

    ⚠️ 가드를 원시 출력이 아니라 **필터 후 결과**에 걸어야 한다. 관측된 이상은 1줄을
    반환했고 그 1줄이 교차 필터에서 떨어져 0이 됐다 — 원시 출력만 보면 "비어 있지
    않다"로 통과해 버려 가드가 헛돈다.
    """
    import scripts.wiki.lib.validate as V

    monkeypatch.setattr(
        V.subprocess, "run",
        lambda *a, **k: _FakeCompleted("../../docs/phases/phase-1-exceptions\n"),
    )
    notes = V.collect_link_sources(link_vault)
    assert V.find_unresolved_links_obsidian(link_vault, wiki_notes=notes) is None, (
        "퇴화 응답이 그대로 채택됐다 — broken 이 0으로 뒤집힌다"
    )


def test_link_check_deterministic_under_degenerate_obsidian(link_vault: Path, monkeypatch, capsys):
    """퇴화 응답이 와도 최종 결과는 obsidian 부재 시와 **같아야** 한다."""
    import scripts.wiki.lib.validate as V

    args = Namespace(vault=link_vault, json_output=False, strict_broken=False, quiet=False)

    monkeypatch.setattr(V.subprocess, "run",
                        lambda *a, **k: (_ for _ in ()).throw(FileNotFoundError()))
    V.run_link_check(args)
    baseline = capsys.readouterr().out

    monkeypatch.setattr(V.subprocess, "run",
                        lambda *a, **k: _FakeCompleted("../../docs/phases/phase-1-exceptions\n"))
    V.run_link_check(args)
    degenerate = capsys.readouterr().out

    assert degenerate == baseline, f"비결정적이다.\nbaseline={baseline!r}\ndegenerate={degenerate!r}"
    assert "broken=1" in baseline, f"픽스처 무효 — broken 이 잡혀야 대조가 성립한다: {baseline!r}"
