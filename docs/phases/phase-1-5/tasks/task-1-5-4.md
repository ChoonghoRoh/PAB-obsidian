---
task_id: "1-5-4"
title: ".claude/CLAUDE.md plugin 호출 안내 한 줄 추가"
domain: WIKI-SKILL
owner: backend-dev
priority: P1
estimate_min: 5
status: pending
depends_on: ["1-5-2"]
blocks: []
---

# Task 1-5-4 — `.claude/CLAUDE.md` plugin 호출 안내 한 줄 추가

## 목적

PAB-obsidian 프로젝트의 CLAUDE.md에 `pab` plugin 호출 안내 한 줄을 추가하여, 향후 세션에서 `/pab:wiki` 사용을 즉시 인지할 수 있도록 한다.

## 입력

- 기존 파일: `.claude/CLAUDE.md`
- 신규 skill: `/pab:wiki`

## 산출물

- `.claude/CLAUDE.md` — plugin 안내 섹션 추가 (기존 내용 보존)

## 실행 절차

1. `.claude/CLAUDE.md` 마지막 섹션 또는 적절한 위치에 다음 블록 추가:

   ```markdown
   ---

   # Plugin Skills (`pab` namespace)

   - `/pab:wiki <내용 또는 URL...>` — 옵시디언 규격 wiki 노트 자동 생성 (frontmatter 11필드 + 6 TYPE + naming-convention 자동 적용 → `wiki/10_Notes/`)
   - `/pab:wiki --help` — 도움말

   상세: `skills/wiki/SKILL.md`
   ```

2. 추가 위치는 기존 SSOT 진입점 / HR 규칙 블록 *뒤*에 배치 (덮어쓰지 말 것)

3. 파일 줄 수 확인 (R-3 500줄 한계):
   ```bash
   wc -l .claude/CLAUDE.md
   ```

## 완료 기준

- [ ] `.claude/CLAUDE.md`에 `Plugin Skills (pab namespace)` 섹션 신규 추가
- [ ] `/pab:wiki` 한 줄 안내 포함
- [ ] 기존 내용(SSOT 진입점, HR-1~HR-8) 모두 보존
- [ ] 파일 줄 수 ≤ 500줄

## 보고

`reports/report-backend-dev.md` §T-4 섹션:
- 추가한 섹션 본문 그대로
- 추가 전·후 줄 수

## 위험

- **L-1**: 기존 내용 덮어쓰기 — Edit 도구로 *추가만* 수행, Write 도구 사용 시 전체 내용 보존 확인 필수
- **L-2**: 파일 줄 수 500줄 초과 — 초과 시 Team Lead에 보고 (REFACTOR-1 트리거)
