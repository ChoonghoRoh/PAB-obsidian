---
task_id: "1-3-4"
title: "_INDEX.md 갱신 — 3중 인덱스 진입점"
domain: WIKI-META
owner: backend-dev
priority: P0
estimate_min: 15
status: pending
depends_on: ["1-3-1", "1-3-2", "1-3-3"]
blocks: []
---

# Task 1-3-4 — _INDEX.md 갱신 (3중 인덱스 진입점)

## 목적

T-1~T-3에서 생성된 13개 MOC(TYPES 6 + DOMAINS 6 + TOPICS 1 placeholder)를 `wiki/_INDEX.md`의 3중 인덱스 placeholder 섹션에 연결한다. wiki 진입 시 모든 MOC에 1-hop으로 도달 가능해야 한다.

## 산출물

`wiki/_INDEX.md` (덮어쓰기 갱신, 신규 파일 아님)

## 갱신 대상 섹션

기존 `_INDEX.md`의 다음 placeholder 3개를 채운다:

```markdown
### By Type
- (placeholder — Phase 1-3에서 `00_MOC/TYPES/` 링크 자동 채움)

### By Domain
- (placeholder — Phase 1-3에서 `00_MOC/DOMAINS/` 링크 자동 채움)

### By Topic
- (placeholder — Phase 1-3에서 `00_MOC/TOPICS/` 링크 자동 채움)
```

## 갱신 후 구조

### By Type 섹션

```markdown
### By Type

> 노트의 `type` 필드 기준 자동 수집. dataview 사용 시 자동, 미사용 시 폴백 정적 링크로 도달.

```dataview
LIST
FROM "00_MOC/TYPES"
SORT file.name ASC
```

**폴백 정적 링크**:
- [[00_MOC/TYPES/RESEARCH_NOTE|RESEARCH_NOTE]] — 외부 자료 분석 노트
- [[00_MOC/TYPES/CONCEPT|CONCEPT]] — 개념·이론 정리
- [[00_MOC/TYPES/LESSON|LESSON]] — 경험 기반 교훈
- [[00_MOC/TYPES/PROJECT|PROJECT]] — 프로젝트 노트
- [[00_MOC/TYPES/DAILY|DAILY]] — 일별 메모
- [[00_MOC/TYPES/REFERENCE|REFERENCE]] — 참조·치트시트·MOC
```

### By Domain 섹션

dataview + 폴백 정적 링크 6개 (`AI`/`HARNESS`/`ENGINEERING`/`PRODUCT`/`KNOWLEDGE_MGMT`/`MISC`).

### By Topic 섹션

dataview + 폴백 placeholder + `[[00_MOC/TOPICS/_README|TOPICS — Rules]]` 링크.

## 추가 갱신 항목

1. frontmatter `updated` 필드를 현재 시각으로 갱신 (`2026-05-01 HH:MM`)
2. 마지막 줄 메타 갱신: `**갱신 완료**: Phase 1-3 (2026-05-01) — 3중 인덱스 자동 생성 + 폴백 정적 링크`
3. 사용 가이드 섹션에 1줄 추가: "새 TOPIC은 노트 frontmatter `topics: ["[[NEW_TOPIC]]"]`로 등록 → 3건 누적 시 자동 MOC 승격 (Phase 1-4 `wiki moc-build`)"

## 실행 절차

1. `wiki/_INDEX.md` Read
2. 3 placeholder 섹션 식별
3. Edit으로 각 섹션 교체 (위 구조)
4. frontmatter `updated` 갱신
5. 검증:
   - dataview 코드블록 3개 존재
   - 폴백 wikilink: TYPES 6 + DOMAINS 6 + TOPICS 1 = 13개 명시
   - YAML frontmatter parse 통과

## 완료 기준

- [ ] 3 placeholder 모두 실제 내용으로 치환됨
- [ ] dataview 코드블록 3개(TYPES/DOMAINS/TOPICS) 존재
- [ ] 폴백 wikilink 13개 모두 정확한 경로(`00_MOC/TYPES/...`, `00_MOC/DOMAINS/...`, `00_MOC/TOPICS/_README`)
- [ ] frontmatter `updated` 갱신
- [ ] T-1~T-3 결과물과 cross-link 정합성: `_INDEX.md` → 13 MOC, 13 MOC의 `index: "[[ROOT]]"` ↔ _INDEX.md

## 보고

`reports/report-backend-dev.md` §T-4 섹션:
- 갱신 전후 diff 요약 (3 placeholder → 실 내용)
- 폴백 wikilink 13개 리스트
- broken link 점검 결과
