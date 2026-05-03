---
task_id: "1-5-5"
title: "vault 확장 — SOURCE TYPE 정의 + 15_Sources/ 폴더"
domain: WIKI-SKILL
owner: backend-dev
priority: P0
estimate_min: 35
status: pending
depends_on: []
blocks: ["1-5-2", "1-5-6"]
intent_ref: docs/phases/phase-1-5/phase-1-5-intent.md
---

# Task 1-5-5 (NEW) — vault 확장: SOURCE TYPE + 15_Sources 폴더

> **본질 (잃지 말 것)**:
> - 원본 immutable 보존을 위한 vault 인프라 신설. SKILL.md(T-2)와 노트 재생성(T-6)의 *전제 조건*.

## 목적

`/pab:wiki`가 원본을 저장할 위치(`wiki/15_Sources/`)와 원본의 frontmatter 구조(`SOURCE` TYPE)를 vault에 정의한다. 기존 6 TYPE은 그대로 유지하고 *추가*만 — 기존 노트 영향 없음.

## 산출물 (6개)

### 신규
1. `wiki/40_Templates/SOURCE.md` — SOURCE TYPE 템플릿
2. `wiki/00_MOC/TYPES/SOURCE.md` — TYPE MOC 노트
3. `wiki/15_Sources/.gitkeep` — 폴더 신설 (또는 README.md)

### 갱신
4. `wiki/40_Templates/_schema.json` — TYPE enum 7 → 8 (`SOURCE` 추가)
5. `wiki/30_Constraints/frontmatter-spec.md` — TYPE별 frontmatter 차이 표 + DOMAIN MOC 표 갱신 (필요 시)
6. `wiki/30_Constraints/naming-convention.md` — 폴더 prefix 표에 `15_ Sources` 추가

## 산출물 상세 명세

### 1. `wiki/40_Templates/SOURCE.md` (신규)

frontmatter 11필드 — SOURCE 특이사항:
- `type: "[[SOURCE]]"`
- `tags: [source, ...]` 첫 항목 `source`
- `index`: 짝 요약본의 index와 동일 (DOMAIN 일치)
- `topics`: 짝 요약본과 동일
- `sources`: 외부 URL 1개 (원본 자체)
- `aliases`: 원문 제목 정확히 (한국어 alias 1~2개 추가 가능)
- 본문: 원문 텍스트 *그대로* (사용자 개인 vault 보관용 placeholder 표시)
- 헤더에 명시: "⚠️ 변경 금지 — 원본 immutable 보존"

기존 TYPE 템플릿(예: `wiki/40_Templates/RESEARCH_NOTE.md`)을 참고하여 동일한 구조로 작성하되, 위 SOURCE 특이사항을 반영.

### 2. `wiki/00_MOC/TYPES/SOURCE.md` (신규)

다른 TYPE MOC(`RESEARCH_NOTE.md` 등)과 동일한 구조:
- frontmatter: `type: "[[SOURCE]]"`, `index: "[[ROOT]]"`, `tags: [moc, types/source]`
- 본문: SOURCE TYPE의 정의 + immutable 원칙 + Dataview 쿼리 (원본 노트 목록 자동 갱신용)

### 3. `wiki/15_Sources/.gitkeep` (또는 README.md)

폴더 신설용 sentinel. README.md로 작성 시 다음 1줄 포함:
```
원본 자료 보존 폴더. 변경 금지 — `/pab:wiki`가 자동 생성.
```

### 4. `wiki/40_Templates/_schema.json` 갱신

기존 TYPE enum 7개 → 8개:
```json
"type": {
  "type": "string",
  "enum": [
    "[[RESEARCH_NOTE]]",
    "[[CONCEPT]]",
    "[[LESSON]]",
    "[[PROJECT]]",
    "[[DAILY]]",
    "[[REFERENCE]]",
    "[[INDEX]]",
    "[[SOURCE]]"
  ]
}
```

기타 schema 규칙은 변경 없음.

### 5. `wiki/30_Constraints/frontmatter-spec.md` 갱신

§"TYPE별 frontmatter 차이" 표 마지막에 SOURCE row 추가:

| TYPE | `type` 값 | `tags` 첫 항목 | `index` 기본값 | 특이 |
|---|---|---|---|---|
| SOURCE | `"[[SOURCE]]"` | `source` | (짝 요약본의 index와 동일) | 본문=원문 텍스트, 변경 금지, sources=외부 URL |

또한 §"필드 등급" 또는 §개요에 SOURCE TYPE의 immutable 원칙 1줄 추가.

### 6. `wiki/30_Constraints/naming-convention.md` 갱신

§"폴더 prefix 규칙" 표에 row 추가:

| 폴더 | 의미 | 용도 |
|---|---|---|
| `15_` | Sources (원본 보존) | 외부 자료 원문 immutable 사본 (`/pab:wiki` 자동 생성) |

## 실행 절차

1. 기존 TYPE 템플릿 확인 (`ls wiki/40_Templates/`) + 1개 읽기 (예: `RESEARCH_NOTE.md`)로 구조 파악
2. 기존 TYPE MOC 확인 (`ls wiki/00_MOC/TYPES/`) + 1개 읽기로 구조 파악
3. 위 6개 산출물 작성·갱신 (Write/Edit)
4. 검증:
   - `python3 -c "import json; json.load(open('wiki/40_Templates/_schema.json'))"` — JSON valid
   - `ls wiki/15_Sources/` — 폴더 존재
   - `python3 scripts/wiki/wiki.py link-check` — 갱신된 frontmatter-spec과 schema 일치 확인 (vault-wide PASS)

## 완료 기준

- [ ] `wiki/40_Templates/SOURCE.md` 존재 + frontmatter 11필드 + immutable 헤더 명시
- [ ] `wiki/00_MOC/TYPES/SOURCE.md` 존재 + 다른 TYPE MOC와 동일 구조
- [ ] `wiki/15_Sources/` 폴더 존재 (.gitkeep 또는 README.md 포함)
- [ ] `_schema.json` TYPE enum 8개 (SOURCE 추가) + JSON valid
- [ ] `frontmatter-spec.md` SOURCE row 추가 + immutable 원칙 명시
- [ ] `naming-convention.md` 15_ Sources row 추가
- [ ] vault link-check PASS (기존 노트 영향 없음)

## 보고

`reports/report-backend-dev-v2.md` §T-5 섹션:
- 6개 산출물 경로 + 각 파일 처리 방식 (신규/갱신)
- `_schema.json` 변경 diff (TYPE enum 7→8)
- `frontmatter-spec.md` 추가 row + immutable 원칙 문구
- `naming-convention.md` 추가 row
- vault link-check 결과 (영향 없음 확인)

## 위험

- **L-1**: 기존 노트의 schema validation에 영향 — SOURCE는 *추가*이므로 기존 6 TYPE 노트는 영향 없어야 함. 영향 발생 시 schema enum 뒤에 *append*하여 backward compat
- **L-2**: TYPE MOC `SOURCE.md`의 Dataview 쿼리 — Dataview 플러그인 필수, 미설치 환경에서는 단순 link list로 fallback
- **L-3**: 폴더 신설 시 `.gitignore` 영향 — `wiki/_attachments/` 정책과 다름. README.md로 감지 가능하게 권장
