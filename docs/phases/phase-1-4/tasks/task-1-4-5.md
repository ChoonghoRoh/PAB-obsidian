---
task_id: "1-4-5"
title: "wiki toc-suggest — heading 분석 + outline 추천 (toc-recommendation 명세 구현)"
domain: WIKI-CLI
owner: backend-dev
priority: P0
estimate_min: 25
status: pending
depends_on: ["1-4-1"]
blocks: ["1-4-6"]
---

# Task 1-4-5 — `wiki toc-suggest <note>` 구현

## 목적

`wiki/30_Constraints/toc-recommendation.md`의 의사코드를 그대로 Python으로 구현한다. 입출력 JSON 스키마를 명세와 100% 일치시키는 것이 핵심.

## 산출물

- `scripts/wiki/lib/toc.py` (parse_headings / analyze_depth / analyze_length / toc_suggest / format_markdown / format_json)
- `scripts/wiki/wiki.py` 의 `cmd_toc_suggest` 분기

## 명세 참조

본 task는 `wiki/30_Constraints/toc-recommendation.md`의 §의사코드와 §출력 JSON 스키마를 변경 없이 구현한다.

핵심 알고리즘:
1. **Step 1**: 노트 파싱 — frontmatter(`---`...`---`) 제외, fenced code block(```...```) 제외, heading `(level, text, line_start, line_end)` 추출
2. **Step 2**: depth 분석 — `flatness = "too_flat" | "too_deep" | "ok"`
3. **Step 3**: 길이 분석 — `section_lines > threshold` → `split` / `< 5 AND level >= 2` → `merge` / 그 외 `keep`
4. **Step 4**: LLM 보강 (default false, 본 Phase에서는 stub)
5. **Step 5**: 출력 포맷 변환

## 출력 JSON 스키마 (강제 일치)

```json
{
  "flatness": "too_flat | too_deep | ok",
  "max_depth_seen": 0~6,
  "suggestions": [
    {
      "level": 1~6,
      "text": "...",
      "lines": <int>,
      "suggestion": "keep | split | merge"
    }
  ]
}
```

## parse_headings 구현 주의

```python
def parse_headings(text: str) -> list[Heading]:
    lines = text.splitlines()
    headings = []
    in_frontmatter = False
    in_code_block = False

    for i, line in enumerate(lines):
        # frontmatter
        if i == 0 and line.strip() == "---":
            in_frontmatter = True
            continue
        if in_frontmatter:
            if line.strip() == "---":
                in_frontmatter = False
            continue
        # fenced code block
        if line.lstrip().startswith("```"):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            continue
        # heading
        m = re.match(r"^(#{1,6})\s+(.+)$", line)
        if m:
            level = len(m.group(1))
            text_h = m.group(2).strip()
            headings.append({"level": level, "text": text_h, "line_start": i, "line_end": -1})

    # line_end 채움 (다음 heading의 line_start - 1, 마지막은 EOF)
    for j in range(len(headings)):
        headings[j]["line_end"] = headings[j+1]["line_start"] - 1 if j + 1 < len(headings) else len(lines) - 1

    return headings
```

## toc_suggest 함수 (toc-recommendation.md §의사코드 직역)

```python
def toc_suggest(note_path: Path, max_depth: int = 3, use_llm: bool = False, length_threshold: int = 80) -> dict:
    text = note_path.read_text()
    headings = parse_headings(text)

    if not headings:
        return {"flatness": "ok", "max_depth_seen": 0, "suggestions": []}

    depths = [h["level"] for h in headings]
    if max(depths) == 1:
        flatness = "too_flat"
    elif max(depths) > max_depth:
        flatness = "too_deep"
    else:
        flatness = "ok"

    suggestions = []
    for h in headings:
        section_lines = h["line_end"] - h["line_start"]
        if section_lines > length_threshold:
            sg = "split"
        elif section_lines < 5 and h["level"] >= 2:
            sg = "merge"
        else:
            sg = "keep"
        suggestions.append({
            "level": h["level"],
            "text": h["text"],
            "lines": section_lines,
            "suggestion": sg,
        })

    if use_llm:
        suggestions = llm_augment(suggestions, text)  # 본 Phase: NotImplementedError

    return {
        "flatness": flatness,
        "max_depth_seen": max(depths),
        "suggestions": suggestions,
    }
```

## 출력 포맷

`--format json` (정확히 위 스키마):

```python
print(json.dumps(result, ensure_ascii=False, indent=2))
```

`--format markdown` (default):

```markdown
# TOC 추천 — <note 파일명>

- **Flatness**: too_flat
- **Max depth seen**: 2

## Suggestions

| Level | Text | Lines | Suggestion |
|---|---|---:|---|
| 2 | A | 200 | split |
| 2 | B | 10 | keep |
| 2 | C | 5 | merge |
```

## smoke test

```bash
# Phase 1-3에서 작성된 toc-recommendation.md 자체로 검증 (재귀적 자기 평가)
python3 scripts/wiki/wiki.py toc-suggest wiki/30_Constraints/toc-recommendation.md --format json

# 기대: 스키마 일치 (jsonschema validate 또는 수기 검토)

# heading 0건 — 빈 본문
echo "---" > /tmp/empty.md
echo "title: Empty" >> /tmp/empty.md
echo "---" >> /tmp/empty.md
echo "" >> /tmp/empty.md
python3 scripts/wiki/wiki.py toc-suggest /tmp/empty.md --format json
# 기대: {"flatness":"ok","max_depth_seen":0,"suggestions":[]}

# 본 plan.md
python3 scripts/wiki/wiki.py toc-suggest docs/phases/phase-1-4/phase-1-4-plan.md
```

## 완료 기준

- [ ] `lib/toc.py` 5 함수 + format helper 구현
- [ ] toc-recommendation.md 자체 검증 시 출력이 명세 §출력 JSON 스키마 100% 일치
- [ ] 빈 노트(heading 0건) → `flatness=ok max_depth_seen=0 suggestions=[]`
- [ ] frontmatter / fenced code block 내부의 `#`는 heading으로 인식하지 않음
- [ ] `--llm` 미구현 (default false 강제, true 시 명시적 NotImplementedError 또는 무시)
- [ ] `lib/toc.py` 200줄 이하

## 보고

`reports/report-backend-dev.md` §T-5:
- toc-recommendation.md 자체 검증 출력 발췌
- 빈 노트 / 일반 노트 검증 출력
- frontmatter / code-block 제외 검증 (테스트 픽스처 1건)

## 위험

- **L-5**: code block 내 라인을 section_lines에 포함할지 — toc-recommendation.md §위험 결정 "포함" 채택. 명세와 동일하게 코드블록 라인도 section length에 포함
- frontmatter 인덱싱 미스로 첫 heading의 line_start가 잘못 계산될 가능성 → 단위 테스트 또는 smoke test로 보강
