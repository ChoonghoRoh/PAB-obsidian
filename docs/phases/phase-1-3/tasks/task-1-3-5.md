---
task_id: "1-3-5"
title: "TOC 추천 알고리즘 명세"
domain: WIKI-META
owner: backend-dev
priority: P1
estimate_min: 20
status: pending
depends_on: []
blocks: []
---

# Task 1-3-5 — TOC 추천 알고리즘 명세

## 목적

Phase 1-4 T-5 (`wiki toc-suggest <note>` CLI)가 구현 시 참조할 **알고리즘 명세 문서**를 작성한다. 본 task는 명세만, 실제 구현은 Phase 1-4.

핵심 휴리스틱:
- heading depth 분석 (H1~H4) — 너무 평탄 / 너무 깊음 감지
- 섹션 길이 분석 — 너무 긴 섹션은 분할 권고
- LLM 보강 기준 — 휴리스틱으로 부족 시 LLM 호출 (선택적, Phase 1-4에서 결정)

## 산출물

`wiki/30_Constraints/toc-recommendation.md` (단일 파일)

## 파일 구조

### Frontmatter

```yaml
---
title: "TOC Recommendation Algorithm"
description: "wiki toc-suggest 명령의 알고리즘 명세. heading depth + 길이 휴리스틱 + LLM 보강 기준."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[TOC]]", "[[CONSTRAINTS]]"]
tags: [reference, toc, algorithm, constraints]
keywords: [toc, table-of-contents, heading-analysis, llm-augmentation]
sources: ["wiki/30_Constraints/frontmatter-spec.md", "docs/phases/phase-1-master-plan.md"]
aliases: ["TOC Algo", "toc-suggest spec"]
---
```

### 본문 섹션

1. **# TOC Recommendation Algorithm** (H1)
2. **## 목적** — 본 명세의 의도, Phase 1-4 T-5와의 관계
3. **## 입력**
   - 마크다운 노트 1건 (절대경로)
   - 옵션: `--max-depth N` (기본 3), `--llm` (선택)
4. **## 출력**
   - 마크다운 outline (들여쓰기 리스트)
   - 또는 JSON `[{"level": 2, "text": "...", "suggestion": "split|merge|keep"}]`
5. **## 알고리즘 단계**
   - Step 1: 노트 파싱 — heading 추출(레벨 + 텍스트 + 라인 범위)
   - Step 2: depth 분석 — H1만 있으면 "너무 평탄", H4 이상 빈번하면 "너무 깊음"
   - Step 3: 길이 분석 — 각 섹션의 라인 수 계산, 임계치(기본 80라인) 초과 시 "split" 제안
   - Step 4: LLM 보강 (선택) — heading 텍스트가 의미적으로 유사한 인접 섹션 검출 → "merge" 제안
   - Step 5: 출력 포맷 변환
6. **## 의사코드** — 1블록 (아래 참조)
7. **## 적용 예시** — 1건 (Before/After)
8. **## Phase 1-4 T-5 인터페이스** — 입출력 JSON 스키마

### 의사코드

```python
def toc_suggest(note_path: str, max_depth: int = 3, use_llm: bool = False) -> list[dict]:
    text = open(note_path).read()
    headings = parse_headings(text)  # [(level, text, line_start, line_end)]

    depths = [h.level for h in headings]
    if max(depths) == 1:
        flatness = "too_flat"
    elif max(depths) > max_depth:
        flatness = "too_deep"
    else:
        flatness = "ok"

    suggestions = []
    for h in headings:
        section_lines = h.line_end - h.line_start
        suggestion = "keep"
        if section_lines > 80:
            suggestion = "split"
        elif section_lines < 5 and h.level >= 2:
            suggestion = "merge"
        suggestions.append({
            "level": h.level,
            "text": h.text,
            "lines": section_lines,
            "suggestion": suggestion,
        })

    if use_llm:
        suggestions = llm_augment(suggestions, text)  # heading 의미 유사도 보강

    return {
        "flatness": flatness,
        "max_depth_seen": max(depths),
        "suggestions": suggestions,
    }
```

### 적용 예시 (Before/After)

**Before** (heading 평탄, 길이 과다):
```markdown
# Note
## A (200줄)
## B (10줄)
## C (5줄)
```

**After 추천**:
```markdown
# Note
## A
### A-1 (분할)
### A-2 (분할)
## B + C (병합)
```

JSON:
```json
{
  "flatness": "too_flat",
  "max_depth_seen": 2,
  "suggestions": [
    {"level": 2, "text": "A", "lines": 200, "suggestion": "split"},
    {"level": 2, "text": "B", "lines": 10, "suggestion": "merge"},
    {"level": 2, "text": "C", "lines": 5, "suggestion": "merge"}
  ]
}
```

### Phase 1-4 T-5 인터페이스

**입력 JSON 스키마**:
```json
{
  "note_path": "string (absolute)",
  "max_depth": "integer (default 3)",
  "use_llm": "boolean (default false)"
}
```

**출력 JSON 스키마**:
```json
{
  "flatness": "string (too_flat|too_deep|ok)",
  "max_depth_seen": "integer",
  "suggestions": [
    {
      "level": "integer (1-6)",
      "text": "string",
      "lines": "integer",
      "suggestion": "string (keep|split|merge)"
    }
  ]
}
```

## 실행 절차

1. `wiki/30_Constraints/toc-recommendation.md` 작성
2. 검증:
   ```bash
   python3 -c "
   import yaml
   d = yaml.safe_load(open('wiki/30_Constraints/toc-recommendation.md').read().split('---')[1])
   assert d['type'] == '[[REFERENCE]]'
   assert 'toc' in d['tags']
   print('OK')
   "
   ```

## 완료 기준

- [ ] `wiki/30_Constraints/toc-recommendation.md` 존재
- [ ] frontmatter 11필드 (Critical 3 필수)
- [ ] 8섹션 본문(목적/입력/출력/알고리즘 5단계/의사코드/예시/인터페이스)
- [ ] 의사코드 1블록 (Python 또는 의사문법, 5단계 모두 포함)
- [ ] 적용 예시 Before/After 1건
- [ ] 입출력 JSON 스키마 명시 (Phase 1-4 T-5가 직접 참조 가능)

## 보고

`reports/report-backend-dev.md` §T-5 섹션:
- 파일 경로 + 줄 수
- frontmatter 검증 출력
- 알고리즘 5단계 요약 (1줄)

## 위험

- LLM 보강 단계는 본 명세에서 "선택" 상태. Phase 1-4 T-5 구현 시 LLM 호출 비용·지연 평가 후 default false 유지 또는 변경 결정.
- heading 길이 임계치(80라인)는 권고치. 도메인별로 조정 가능 (Phase 1-4에서 `--threshold N` 옵션 추가 권고)
