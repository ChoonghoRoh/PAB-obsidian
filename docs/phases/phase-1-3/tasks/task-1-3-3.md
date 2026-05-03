---
task_id: "1-3-3"
title: "TOPICS placeholder + 자동 생성 규칙"
domain: WIKI-META
owner: backend-dev
priority: P1
estimate_min: 15
status: pending
depends_on: []
blocks: ["1-3-4"]
---

# Task 1-3-3 — TOPICS placeholder + 자동 생성 규칙

## 목적

TYPES/DOMAINS와 달리 **TOPIC은 노트가 등장하면서 동적으로 생성**된다. 본 task는 (1) `wiki/00_MOC/TOPICS/` placeholder 디렉토리를 만들고, (2) TOPIC MOC 자동 승격 규칙을 명문화하며, (3) Phase 1-4 `wiki moc-build` 구현이 참조할 dataview 템플릿 스니펫을 제공한다.

## 산출물

`wiki/00_MOC/TOPICS/_README.md` (단일 파일)

## 파일 구조

### Frontmatter

```yaml
---
title: "TOPICS — Dynamic MOC Placeholder"
description: "TOPIC MOC 자동 생성 규칙 + Phase 1-4 wiki moc-build 참조 문서. TOPIC은 노트가 등장하면서 동적으로 승격된다."
created: 2026-05-01 22:00
updated: 2026-05-01 22:00
type: "[[REFERENCE]]"
index: "[[ROOT]]"
topics: ["[[MOC]]", "[[TOPICS]]"]
tags: [moc, topics, placeholder]
keywords: [topic-moc, dynamic-moc, promotion-threshold]
sources: ["wiki/30_Constraints/frontmatter-spec.md", "wiki/30_Constraints/linking-policy.md"]
aliases: ["Topics README", "Topic MOC Rules"]
---
```

### 본문 섹션

1. **# TOPICS — Dynamic MOC Placeholder** (H1)
2. **## 개념** — TOPIC이 TYPES/DOMAINS와 다른 점 (정적 enum 아님, 동적 생성)
3. **## 자동 승격 규칙**
   - 임계치: `topics: ["[[FOO]]"]`로 등록된 노트가 **3건 이상** 누적되면 `wiki/00_MOC/TOPICS/FOO.md` MOC를 생성
   - 임계치는 Phase 1-4 `wiki moc-build` 명령의 `--topic-threshold N` 옵션으로 조정 가능 (기본 3)
   - 자동 생성된 MOC는 본 _README.md의 dataview 템플릿을 따라 작성
4. **## 명명 규약**
   - frontmatter `topics` 필드 wikilink: `[[FOO]]` (대문자 + 언더스코어)
   - tags: `topics/foo` (소문자 + 하이픈)
   - 파일명: `wiki/00_MOC/TOPICS/FOO.md` (대문자, 확장자 `.md`)
5. **## dataview 템플릿** — 자동 생성될 TOPIC MOC가 사용할 쿼리 스니펫
6. **## 현재 등록된 TOPICS** — placeholder 표 (Phase 1-4 이후 자동 채움)

### dataview 템플릿 스니펫 (자동 생성 MOC가 사용)

```dataview
LIST
FROM ""
WHERE contains(topics, "[[<TOPIC_NAME>]]")
SORT created DESC
LIMIT 100
```

또는 type/domain 결합 검색:

```dataview
LIST
FROM ""
WHERE contains(topics, "[[<TOPIC>]]") AND type = "[[RESEARCH_NOTE]]"
SORT created DESC
```

## 실행 절차

1. `wiki/00_MOC/TOPICS/` 디렉토리 생성
2. `_README.md` 작성 (위 구조)
3. 검증:
   ```bash
   python3 -c "
   import yaml
   d = yaml.safe_load(open('wiki/00_MOC/TOPICS/_README.md').read().split('---')[1])
   assert d['type'] == '[[REFERENCE]]'
   assert 'placeholder' in d['tags']
   print('OK')
   "
   ```

## 완료 기준

- [ ] `wiki/00_MOC/TOPICS/_README.md` 존재
- [ ] frontmatter 11필드 (Critical 3 필수)
- [ ] 6섹션 본문(개념/승격 규칙/명명 규약/템플릿/현재 등록)
- [ ] 임계치 기본값 3 명시
- [ ] dataview 템플릿 2종(단일 TOPIC, TOPIC+TYPE 결합) 포함

## 보고

`reports/report-backend-dev.md` §T-3 섹션:
- 파일 경로 + 줄 수
- frontmatter 검증 출력
- 승격 규칙 요약 (1줄)
