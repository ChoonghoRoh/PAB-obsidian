"""schema strict + broken [[wikilink]] + orphan 검출 유틸 (T-3)."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path
from typing import Any

import frontmatter as fm_lib
import jsonschema

WIKILINK_RE = re.compile(r"\[\[([^\]\|#]+)(?:\|[^\]]+)?(?:#[^\]]+)?\]\]")
INLINE_CODE_RE = re.compile(r"`[^`]+`")  # 인라인 코드 스팬 제거 (FIX-2)

# 가상 앵커 화이트리스트 — broken 판정 제외 (FIX-1: TOC 추가)
WIKILINK_WHITELIST = {"ROOT", "MOC", "CONSTRAINTS", "TYPES", "DOMAINS", "TOPICS", "TOC"}


# 판정 대상 디렉터리 화이트리스트 (PO6 §3·§4 확정 — 정본 실측 101건).
# 현행이 `00_MOC` 38건을 notes 로 세던 것은 **생성물에 노트 규격을 요구하는 범주 오류**다.
JUDGE_DIRS = ("10_Notes", "15_Sources")


def collect_notes(vault: Path) -> list[Path]:
    """**판정 대상** — 스키마·orphan 판정 모수. `10_Notes` + `15_Sources`.

    `_` 접두 경로 요소는 제외한다(vault 전역 단일 관례 — N-4). 근거는
    `10_Notes/_old/..._backup.md` 1건으로, **제외하지 않으면 영구 orphan 으로 상주해
    `orphans==0` 게이트를 영구히 막는다** — 백업 파일은 MOC 에 등재할 수도 없고
    삭제할 이유도 없다.

    ⚠️ 이 축소는 **link-check 한정**이다(지침 3). moc-build 의 수집 모수인
    `collect_notes_with_meta()` 는 무변경 — 거기까지 좁히면 MOC 에서 노트가 빠져
    **orphan 을 스스로 만들어낸다**.
    """
    out: list[Path] = []
    for d in JUDGE_DIRS:
        base = vault / d
        if not base.exists():
            continue
        for p in base.rglob("*.md"):
            rel = p.relative_to(vault)
            if any(part.startswith("_") for part in rel.parts):
                continue
            out.append(p)
    return sorted(out)


def collect_link_sources(vault: Path) -> list[Path]:
    """**참조원** — 링크 수집원. 전 vault (`_attachments`·`40_Templates` 제외).

    판정 대상만 좁히고 참조원은 전 vault 를 유지한다(지침 4). 참조원까지 좁히면
    `_INDEX.md`(17링크) · `30_Constraints`(102링크)가 빠져 **119링크가 소실되고
    orphan 이 급증한다.** `orphans==0` 이 편입 게이트이므로 이는 **게이트 오탐**이다.
    """
    return [
        p for p in vault.rglob("*.md")
        if "_attachments" not in p.parts and "40_Templates" not in p.parts
    ]


def collect_mocs(vault: Path) -> list[Path]:
    """{vault}/00_MOC/ 전체 .md 수집."""
    moc_dir = vault / "00_MOC"
    return list(moc_dir.rglob("*.md")) if moc_dir.exists() else []


def is_moc_stem(stem: str) -> bool:
    upper = stem.upper()
    return upper in {
        "RESEARCH_NOTE", "CONCEPT", "LESSON", "PROJECT", "DAILY", "REFERENCE",
        "AI", "HARNESS", "ENGINEERING", "PRODUCT", "KNOWLEDGE_MGMT", "MISC",
        "_README", "_INDEX",
    } or upper.startswith("_")


def validate_frontmatter_strict(notes: list[Path], schema_path: Path) -> list[dict[str, Any]]:
    """schema v1.1 Draft202012Validator 적용. 위반 노트별 에러 목록 반환."""
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    validator = jsonschema.Draft202012Validator(schema)
    violations: list[dict[str, Any]] = []
    for note in notes:
        try:
            post = fm_lib.load(str(note))
        except Exception as exc:
            violations.append({"path": str(note), "errors": [{"path": [], "msg": f"파싱 오류: {exc}"}]})
            continue
        errors = list(validator.iter_errors(post.metadata))
        if errors:
            violations.append({
                "path": str(note),
                "errors": [{"path": list(e.absolute_path), "msg": e.message} for e in errors],
            })
    return violations


def _extract_wikilink_targets(text: str) -> set[str]:
    """frontmatter + fenced code block + 인라인 코드 제외 후 wikilink 타겟 추출 (FIX-2)."""
    targets: set[str] = set()
    lines = text.splitlines()
    in_frontmatter = in_code_block = False
    for i, line in enumerate(lines):
        if i == 0 and line.strip() == "---":
            in_frontmatter = True; continue
        if in_frontmatter:
            if line.strip() == "---":
                in_frontmatter = False
            continue
        if line.lstrip().startswith("```"):
            in_code_block = not in_code_block; continue
        if in_code_block:
            continue
        for m in WIKILINK_RE.finditer(INLINE_CODE_RE.sub("", line)):
            if t := m.group(1).strip():
                targets.add(t)
    return targets


def find_unresolved_links_obsidian(
    vault: Path, wiki_notes: list[Path] | None = None
) -> list[str] | None:
    """obsidian unresolved 호출. wiki/ 범위 교차 필터 + 화이트리스트 제외."""
    try:
        result = subprocess.run(
            ["obsidian", "unresolved"], capture_output=True, text=True,
            timeout=15, cwd=str(vault),
        )
        if result.returncode != 0:
            return None
        obs = {l.strip() for l in result.stdout.splitlines() if l.strip()}
        # ⚠️ 결정성 가드 — **rc=0 을 목적 달성의 증거로 읽지 않는다**.
        # 실측(2026-09-03): 동일 vault·동일 명령 10회 중 1회가 281줄 대신 **1줄**을
        # rc=0 으로 반환했다. 이것이 `broken: 0` 이 단 1회 나오고 13회 재현되지 않은
        # 이상 관측의 정체다 — 인덱싱이 덜 끝난 상태에서도 종료코드는 0이다.
        # FC-14 가 이 결과를 읽으므로 비결정성은 계약 문제다. 출력이 비면 실패로 보고
        # 결정적인 정규식 폴백에 넘긴다(정상 vault 라면 폴백도 비어 결과가 같다).
        if not obs:
            return None
        if wiki_notes:
            wiki_targets: set[str] = set()
            for note in wiki_notes:
                try:
                    wiki_targets |= _extract_wikilink_targets(note.read_text(encoding="utf-8"))
                except OSError:
                    pass
            filtered = obs & wiki_targets
        else:
            filtered = obs
        return sorted(filtered - WIKILINK_WHITELIST)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def find_unresolved_links_fallback(notes: list[Path]) -> list[str]:
    """정규식 폴백 — frontmatter + fenced/inline code 제외 후 stem 교차 검증.

    path-style wikilink([[00_MOC/TYPES/FOO]])는 basename으로 비교 (FIX-4).
    """
    all_targets: set[str] = set()
    all_stems: set[str] = {n.stem for n in notes}
    for note in notes:
        try:
            all_targets |= _extract_wikilink_targets(note.read_text(encoding="utf-8"))
        except OSError:
            pass
    broken: list[str] = []
    for target in sorted(all_targets):
        if target in WIKILINK_WHITELIST:
            continue
        basename = target.split("/")[-1].split("|")[0].split("#")[0].strip()
        if basename not in all_stems and basename not in WIKILINK_WHITELIST:
            broken.append(target)
    return broken


def find_orphan_notes(targets: list[Path], sources: list[Path]) -> list[str]:
    """어떤 파일에서도 [[stem]] 미참조인 **판정 대상** 목록. MOC stem 은 제외.

    `targets` 는 판정 대상(좁힌 모수), `sources` 는 참조원(전 vault)이다. 둘을 같은
    목록으로 넘기면 지침 4 위반이 된다 — 참조원이 좁아져 orphan 이 급증한다.
    """
    referenced: set[str] = set()
    for source in sources:
        try:
            for m in WIKILINK_RE.finditer(source.read_text(encoding="utf-8")):
                referenced.add(m.group(1).strip())
        except OSError:
            pass
    return sorted(n.stem for n in targets if n.stem not in referenced and not is_moc_stem(n.stem))


def format_text_report(report: dict[str, Any]) -> str:
    c = report["counts"]
    lines = [
        f"{report['status']} (notes={c['notes']}, violations={c['violations']}, "
        f"broken={c['broken']}, orphans={c['orphans']})"
    ]
    if c["broken"] and not report.get("strict_broken"):
        lines.append(
            f"  ※ broken {c['broken']}건은 정보 지표 — 미래 노트 unresolved 는 정상(판정 제외)"
        )
    for v in report.get("schema_violations", []):
        lines.append(f"  [SCHEMA] {v['path']}")
        for e in v["errors"]:
            lines.append(f"    - {'.'.join(str(x) for x in e['path'])}: {e['msg']}")
    for b in report.get("broken_links", []):
        lines.append(f"  [BROKEN] [[{b}]]")
    if report.get("orphans"):
        lines.append(f"  [ORPHAN] {', '.join(report['orphans'])}")
    return "\n".join(lines)


def run_link_check(args: Any) -> int:
    vault: Path = args.vault
    _empty = {"schema_violations": [], "broken_links": [], "orphans": [],
               "counts": {"notes": 0, "violations": 0, "broken": 0, "orphans": 0}}

    if not vault.exists():
        _print(args, {"status": "PASS", "reason": "no vault directory", **_empty}, "PASS (no vault)")
        return 0
    # 두 축을 분리한다 — 판정 대상(좁힘) vs 참조원(전 vault). PO6 §3·§4.
    notes = collect_notes(vault)              # 판정 대상 (정본 실측 101)
    sources = collect_link_sources(vault)     # 참조원 (전 vault)
    if not notes:
        _print(args, {"status": "PASS", "reason": "empty vault", **_empty}, "PASS (empty vault)")
        return 0

    schema_path = vault / "40_Templates/_schema.json"
    violations = validate_frontmatter_strict(notes, schema_path) if schema_path.exists() else []
    # 링크는 **참조원 전체**에서 수집한다. 여기에 좁힌 모수를 넘기면 stem 우주가 줄어
    # `00_MOC` 대상 링크가 전부 broken 으로 뒤집힌다.
    broken = find_unresolved_links_obsidian(vault, wiki_notes=sources)
    if broken is None:
        broken = find_unresolved_links_fallback(sources)
    orphans = find_orphan_notes(notes, sources)

    # ── status 산정 규격 (Task 2-5-7 §작업 3 / PO2 §4.2 R-1) ───────────────────
    # broken 은 결함이 아니라 **정상 동작**이다. Karpathy 방식 wiki 는 아직 쓰지
    # 않은 노트를 미리 [[wikilink]] 로 가리키고, 산문 속 대괄호 표현도 broken 으로
    # 잡힌다. `/wiki` 스킬 자신이 이를 정상으로 규정한다 — SKILL.md Step 9:
    #   "broken=N → 미래 노트 unresolved (WARN, 정상) / schema_violations만 critical"
    # 그런데 구 로직은 broken 을 critical 에 합산해, 규격상 정상인 vault 를 FAIL 로
    # 판정했다(정본 실측: violations=0 · orphans=0 인데 broken 때문에 FAIL).
    # 따라서 판정은 violations·orphans 로만 하고 broken 은 정보 지표로 분리한다.
    #
    # 양측 계약: PAB-Prove FC-14 커밋 게이트가 이 `status` 를 읽는다(PO1 §4.1).
    # PO2 §4.2 R-1 에서 "판정 근거를 counts.violations==0 && counts.orphans==0 으로
    # 통일하자"고 요청했고, 본 변경이 우리 쪽 이행분이다.
    #
    # --strict-broken: broken 을 critical 로 합산하던 **구 동작을 그대로 복원**한다.
    #   exit code 하위호환이 필요한 호출부를 위한 탈출구이며, 기본값은 신규 규격이다.
    strict_broken = getattr(args, "strict_broken", False)
    critical = len(violations) + (len(broken) if strict_broken else 0)
    grade = "FAIL" if critical else ("PARTIAL" if orphans else "PASS")
    report = {
        "status": grade,
        "schema_violations": violations,
        "broken_links": broken,
        "orphans": orphans,
        "counts": {"notes": len(notes), "violations": len(violations),
                   "broken": len(broken), "orphans": len(orphans)},
        "strict_broken": strict_broken,
    }
    _print(args, report, format_text_report(report))
    return 1 if critical else 0


def _print(args: Any, json_data: dict, text: str) -> None:
    if getattr(args, "json_output", False):
        print(json.dumps(json_data, indent=2, ensure_ascii=False))
    else:
        print(text)
