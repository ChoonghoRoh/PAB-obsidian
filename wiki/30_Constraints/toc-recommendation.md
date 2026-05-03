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

# TOC Recommendation Algorithm

## 목적

본 명세는 Phase 1-4 T-5(`wiki toc-suggest <note>` CLI 구현)가 직접 참조할 **알고리즘 사양**이다. Phase 1-3에서는 명세만 작성하고, 실제 구현은 Phase 1-4에서 수행한다.

핵심 휴리스틱:

- **heading depth 분석** (H1~H4) — 너무 평탄(`too_flat`) / 너무 깊음(`too_deep`) 감지
- **섹션 길이 분석** — 임계치(기본 80라인) 초과 섹션은 `split` 권고
- **LLM 보강 기준** — 휴리스틱으로 부족 시(`use_llm=true`) 의미적 유사성 기반 `merge` 권고

본 명세는 Phase 1-4 T-5의 **인터페이스 계약**이다. 본 명세에서 변경되는 입출력 JSON 스키마는 Phase 1-4 코드 변경과 동기화되어야 한다.

## 입력

- **마크다운 노트 1건** — 절대경로(`note_path: str`)
- **옵션**:
  - `--max-depth N` — 허용 heading 최대 깊이 (기본 3)
  - `--llm` — LLM 보강 활성화 (기본 false)
  - `--threshold N` — 섹션 길이 split 임계치 (권고 80, Phase 1-4 추가 옵션)

## 출력

- **마크다운 outline** (들여쓰기 리스트, 사람이 읽는 형태)
- **또는 JSON** (자동화·CLI 파이프 용도):

```json
[
  {"level": 2, "text": "...", "lines": 120, "suggestion": "split|merge|keep"}
]
```

JSON 출력은 항상 다음 wrapper 구조를 따른다:

```json
{
  "flatness": "too_flat|too_deep|ok",
  "max_depth_seen": 2,
  "suggestions": [...]
}
```

## 알고리즘 단계

### Step 1: 노트 파싱

마크다운 텍스트를 line-by-line으로 스캔하여 heading을 추출한다. 각 heading은 `(level, text, line_start, line_end)` 튜플로 저장.

- `level`: `#` 개수 (1~6)
- `text`: heading 텍스트 (앞뒤 공백 제거)
- `line_start`: heading이 등장한 라인 번호
- `line_end`: 다음 heading 직전 라인 (또는 EOF)

> **주의**: 코드 블록(```) 내부의 `#`은 heading이 아니므로 fenced code block 추적 필수. frontmatter(`---` ~ `---`) 내부도 제외.

### Step 2: depth 분석

전체 heading의 `level` 리스트를 검사한다.

- `max(depths) == 1` → `flatness = "too_flat"` (H1만 존재, 분할 필요)
- `max(depths) > max_depth` → `flatness = "too_deep"` (H4 이상 빈번, 평탄화 권고)
- 그 외 → `flatness = "ok"`

### Step 3: 길이 분석

각 heading 섹션의 라인 수(`line_end - line_start`)를 계산하고 다음 규칙을 적용:

- `section_lines > 80` (기본) → `suggestion = "split"`
- `section_lines < 5 AND level >= 2` → `suggestion = "merge"` (너무 짧은 하위 섹션은 부모와 병합 권고)
- 그 외 → `suggestion = "keep"`

### Step 4: LLM 보강 (선택)

`use_llm=true`일 경우, heading 텍스트의 의미적 유사도를 LLM(Claude Haiku 권장)에 질의하여 **인접 섹션이 의미적으로 동일 주제**라면 `merge` 권고 추가. 기본 false.

LLM 비용·지연 우려로 default는 false. 사용자가 명시적으로 `--llm` 플래그 지정 시에만 활성화.

### Step 5: 출력 포맷 변환

CLI 옵션(`--format markdown` / `--format json`)에 따라 결과 객체를 변환하여 stdout 출력.

## 의사코드

```python
def toc_suggest(note_path: str, max_depth: int = 3, use_llm: bool = False, length_threshold: int = 80) -> dict:
    text = open(note_path).read()
    headings = parse_headings(text)  # [(level, text, line_start, line_end)] — frontmatter/code block 제외

    depths = [h.level for h in headings]
    if not depths:
        return {"flatness": "ok", "max_depth_seen": 0, "suggestions": []}

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
        if section_lines > length_threshold:
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
        suggestions = llm_augment(suggestions, text)  # 의미 유사도 기반 merge 보강

    return {
        "flatness": flatness,
        "max_depth_seen": max(depths),
        "suggestions": suggestions,
    }
```

## 적용 예시

### Before (heading 평탄, 섹션 길이 불균형)

```markdown
# Note
## A   (200줄)
## B   (10줄)
## C   (5줄)
```

→ `flatness = "too_flat"` (max depth = 2이지만 H1만 단독, 실제 콘텐츠는 H2 단일 레벨)
→ A는 `split`, B는 `keep`, C는 `merge`

### After 추천

```markdown
# Note
## A
### A-1   (분할)
### A-2   (분할)
## B + C  (병합)
```

### JSON 출력 예

```json
{
  "flatness": "too_flat",
  "max_depth_seen": 2,
  "suggestions": [
    {"level": 2, "text": "A", "lines": 200, "suggestion": "split"},
    {"level": 2, "text": "B", "lines": 10, "suggestion": "keep"},
    {"level": 2, "text": "C", "lines": 5,   "suggestion": "merge"}
  ]
}
```

## Phase 1-4 T-5 인터페이스

본 명세는 Phase 1-4 T-5 구현이 직접 참조해야 할 **계약**이다. 변경 시 코드 동기화 필수.

### 입력 JSON 스키마

```json
{
  "note_path": "string (absolute path)",
  "max_depth": "integer (default 3)",
  "use_llm": "boolean (default false)",
  "length_threshold": "integer (default 80)"
}
```

### 출력 JSON 스키마

```json
{
  "flatness": "string — too_flat | too_deep | ok",
  "max_depth_seen": "integer (0~6)",
  "suggestions": [
    {
      "level": "integer (1~6)",
      "text": "string",
      "lines": "integer",
      "suggestion": "string — keep | split | merge"
    }
  ]
}
```

### CLI 사용 예 (Phase 1-4 구현 후)

```bash
# 기본 (휴리스틱만, markdown 출력)
wiki toc-suggest wiki/10_Notes/2026-05-01_example.md

# JSON 출력 + LLM 보강
wiki toc-suggest wiki/10_Notes/2026-05-01_example.md --format json --llm

# 임계치 조정
wiki toc-suggest path/to/note.md --max-depth 4 --threshold 120
```

## 위험 및 결정 보류

- **LLM 보강 단계**는 본 명세에서 "선택" 상태(default false). Phase 1-4 T-5 구현 시 LLM 호출 비용·지연을 평가한 뒤 default 유지/변경 결정.
- **heading 길이 임계치 80라인**은 권고치. 도메인별로 적정 값이 다를 수 있으므로 Phase 1-4에서 `--threshold N` 옵션 도입 권고.
- **frontmatter/code block 라인 카운팅 정책**은 명시 필요(섹션 라인 수 계산 시 코드 블록을 라인으로 셀지 여부). 본 명세는 "포함"으로 가정.
