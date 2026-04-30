---
task_id: "1-1-2"
title: "wiki/ vault 7 폴더 생성"
domain: WIKI-INFRA
owner: backend-dev
priority: P0
estimate_min: 5
status: pending
depends_on: ["1-1-1"]
blocks: ["1-1-4", "1-1-5"]
---

# Task 1-1-2 — wiki/ vault 폴더 구조 생성

## 목적

PARA 변형 폴더 구조 7개를 `wiki/` 하위에 생성한다. 각 폴더에 `.gitkeep` 파일을 두어 빈 디렉터리도 git에 보존되게 한다.

## 폴더 구조

```
wiki/
├── 00_MOC/          ← TYPES/DOMAINS/TOPICS MOC (Phase 1-3에서 채움)
├── 10_Notes/        ← 실제 노트 (YYYY-MM-DD_*.md)
├── 20_Lessons/      ← 정제된 교훈
├── 30_Constraints/  ← 규약·제약 문서 (Phase 1-2에서 채움)
├── 40_Templates/    ← Templater 템플릿 (Phase 1-2에서 채움)
├── 99_Inbox/        ← 미분류 임시 보관
└── _attachments/    ← 이미지·첨부 (Obsidian 기본 첨부 폴더)
```

## 실행 절차

```bash
mkdir -p wiki/{00_MOC,10_Notes,20_Lessons,30_Constraints,40_Templates,99_Inbox,_attachments}
for d in wiki/00_MOC wiki/10_Notes wiki/20_Lessons wiki/30_Constraints wiki/40_Templates wiki/99_Inbox wiki/_attachments; do
  touch "$d/.gitkeep"
done
ls -la wiki/
```

## 완료 기준

- [ ] 7 폴더 모두 존재 (`ls wiki/`)
- [ ] 각 폴더에 `.gitkeep` 존재
- [ ] 폴더명 정확 (대소문자·언더스코어)

## 보고

backend-dev는 `reports/report-backend-dev.md`의 §T-2 섹션에 `ls -la wiki/` 결과 캡처.

## 위험

- 기존 `wiki/` 폴더 존재 시 덮어씀 위험 → `mkdir -p`는 안전(idempotent)이지만 기존 파일은 보존됨. 시작 전 `ls wiki/ 2>/dev/null` 점검.
