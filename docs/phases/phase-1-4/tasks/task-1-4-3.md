---
task_id: "1-4-3"
title: "wiki link-check — schema strict + obsidian unresolved + orphan"
domain: WIKI-CLI
owner: backend-dev
priority: P0
estimate_min: 30
status: pending
depends_on: ["1-4-1"]
blocks: ["1-4-6"]
---

# Task 1-4-3 — `wiki link-check` 구현

## 목적

vault 전체에 대한 G2_wiki 검증을 자동화한다: ① frontmatter strict 검증 (schema v1.1) ② broken `[[wikilink]]` 검출 (obsidian unresolved 또는 정규식 폴백) ③ 고아 노트(orphan) 검출.

## 산출물

- `scripts/wiki/lib/validate.py` (validate_frontmatter_strict / find_unresolved_links / find_orphan_notes / 통합 진입 함수)
- `scripts/wiki/wiki.py` 의 `cmd_link_check` 분기

## ① frontmatter strict 검증

```python
import json, jsonschema
from pathlib import Path

def validate_frontmatter_strict(notes: list[Path], schema_path: Path) -> list[dict]:
    """notes 각각에 schema v1.1을 strict 적용. 위반 노트별 에러 리스트 반환."""
    schema = json.loads(schema_path.read_text())
    validator = jsonschema.Draft202012Validator(schema)
    violations = []
    for note in notes:
        post = frontmatter.load(note)
        errors = list(validator.iter_errors(post.metadata))
        if errors:
            violations.append({
                "path": str(note),
                "errors": [{"path": list(e.absolute_path), "msg": e.message} for e in errors],
            })
    return violations
```

- schema는 `wiki/40_Templates/_schema.json` (v1.1, type enum INDEX 포함, tags pattern nested 허용)
- Phase 1-3 T-6에서 strict 15/15 PASS 확정 상태

## ② broken link 검출

우선 `obsidian unresolved` subprocess:

```python
def find_unresolved_links_obsidian(vault: Path) -> list[str] | None:
    try:
        result = subprocess.run(
            ["obsidian", "unresolved"],
            capture_output=True, text=True, timeout=15,
            cwd=str(vault),
        )
        if result.returncode != 0:
            return None  # 폴백 사용
        return [line.strip() for line in result.stdout.splitlines() if line.strip()]
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None
```

폴백 (정규식):

```python
import re
WIKILINK_RE = re.compile(r"\[\[([^\]\|#]+)(\|[^\]]+)?(#[^\]]+)?\]\]")

def find_unresolved_links_fallback(notes: list[Path]) -> list[str]:
    all_targets, all_files = set(), {n.stem for n in notes}
    for n in notes:
        text = n.read_text()
        for m in WIKILINK_RE.finditer(text):
            target = m.group(1).strip()
            all_targets.add(target)
    # 가상 앵커 화이트리스트 (Phase 1-3 결정)
    whitelist = {"ROOT", "MOC", "CONSTRAINTS", "TYPES", "DOMAINS", "TOPICS"}
    return sorted(all_targets - all_files - whitelist)
```

## ③ orphan 검출

```python
def find_orphan_notes(notes: list[Path], moc_paths: list[Path]) -> list[str]:
    """어떤 노트·MOC 본문에서도 [[<stem>]]으로 참조되지 않는 노트."""
    referenced = set()
    for source in notes + moc_paths:
        text = source.read_text()
        for m in WIKILINK_RE.finditer(text):
            referenced.add(m.group(1).strip())
    orphans = [n.stem for n in notes if n.stem not in referenced]
    # MOC 자체는 orphan 평가 제외 (MOC는 진입점)
    return sorted(o for o in orphans if not is_moc_path(o))
```

## 통합 진입 (cmd_link_check)

```python
def cmd_link_check(args):
    vault = args.vault
    notes_dir = vault / "wiki"
    if not notes_dir.exists():
        print(json.dumps({"status": "PASS", "reason": "no wiki/ directory"}) if args.json_output else "PASS (no wiki/)")
        return 0

    notes = collect_notes(notes_dir)  # *.md 전수 (단, _attachments 제외)
    if not notes:
        print(json.dumps({"status": "PASS", "reason": "empty vault", "schema_violations": [], "broken_links": [], "orphans": []}) if args.json_output else "PASS (empty vault)")
        return 0

    schema_path = vault / "wiki/40_Templates/_schema.json"
    violations = validate_frontmatter_strict(notes, schema_path)
    broken = find_unresolved_links_obsidian(vault)
    if broken is None:
        broken = find_unresolved_links_fallback(notes)
    orphans = find_orphan_notes(notes, moc_paths=collect_mocs(vault))

    # 등급
    critical = len(violations) + len(broken)
    high = len(orphans)
    grade = "FAIL" if critical else ("PARTIAL" if high else "PASS")
    exit_code = 1 if critical else 0  # PARTIAL은 0 + 경고

    report = {
        "status": grade,
        "schema_violations": violations,
        "broken_links": broken,
        "orphans": orphans,
        "counts": {"notes": len(notes), "violations": len(violations), "broken": len(broken), "orphans": len(orphans)},
    }
    print(json.dumps(report, indent=2) if args.json_output else format_text_report(report))
    return exit_code
```

## smoke test

```bash
# 기존 vault 전수 검증 — Phase 1-3 직후 strict 15/15 PASS 상태
python3 scripts/wiki/wiki.py link-check
# 기대 출력: PASS (notes=N, violations=0, broken=0, orphans>=0)

# JSON 출력
python3 scripts/wiki/wiki.py --json link-check

# 빈 vault 시뮬레이션 (임시 디렉토리)
mkdir -p /tmp/empty-vault/wiki/40_Templates
cp wiki/40_Templates/_schema.json /tmp/empty-vault/wiki/40_Templates/
python3 scripts/wiki/wiki.py --vault /tmp/empty-vault link-check
# 기대 출력: PASS (empty vault)
```

## 완료 기준

- [ ] `lib/validate.py` 3 함수 + 통합 함수 구현
- [ ] `wiki link-check` 빈 vault에서 PASS (exit 0)
- [ ] 기존 wiki/ 전수 검증 시 PASS (Phase 1-3 strict 15/15 정합)
- [ ] schema 위반 / broken link 1건 이상 → exit 1
- [ ] `--full` 옵션 (현재는 동일하지만 향후 확장용 placeholder)
- [ ] `obsidian unresolved` 호출 + 정규식 폴백 모두 검증
- [ ] 가상 앵커(`[[ROOT]]` 등) 화이트리스트 적용
- [ ] `--json` 출력 시 위 report 스키마 일치
- [ ] `lib/validate.py` 250줄 이하

## 보고

`reports/report-backend-dev.md` §T-3:
- 기존 vault 전수 검증 결과 (notes/violations/broken/orphans 카운트)
- 빈 vault 시뮬레이션 결과
- obsidian CLI 호출 성공/폴백 사례
- 화이트리스트 적용 확인

## 위험

- **L-3**: 빈 vault에서 errno 1 반환하면 빈 vault 정책 위반 → `if not notes: return 0` 명시
- 정규식 폴백이 코드블록 내부 `[[fake]]`를 broken으로 오인식할 수 있음. 본 task에서는 단순 폴백 채택 (false positive 허용, obsidian CLI 우선)
- schema v1.1 위반 0건 가정 — 만약 backend-dev가 실측 시 위반 발견하면 즉시 Team Lead에 SendMessage로 보고 (Phase 1-3 검증 정합성 재확인)
