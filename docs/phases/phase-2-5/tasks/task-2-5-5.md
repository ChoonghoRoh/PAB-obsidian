---
task: "2-5-5"
title: "workspace.json git 추적 해제"
domain: "[INFRA]"
gap: "G-5 (🟡)"
assignee: backend-dev
status: pending
depends_on: []
---

# Task 2-5-5: per-machine 파일 git 추적 해제

## 목표
`PAB-LLMDATA/.obsidian/workspace.json`의 git 추적을 해제하여 master-plan §7 R-2(per-machine churn)를 해소한다.

## 배경
Phase 2-1 T-5는 **LiveSync 제외**는 처리했으나 **git 추적 해제는 누락**. 파일이 여전히 tracked 상태로 기기별 UI 상태 변경이 커밋 노이즈를 만든다. §3 KPI "per-machine 제외" 미달.

## 작업
- `git rm --cached PAB-LLMDATA/.obsidian/workspace.json` (파일 자체는 로컬 유지)
- `.gitignore` 패턴 반영·확인 (`graph.json` 등 유사 per-machine 파일 동시 점검)
- T-2 자동 커밋과의 상호작용 확인 — 추적 해제 후 자동 커밋이 이 파일을 되살리지 않는지

## 산출물
- `.gitignore` 갱신 + 추적 해제 커밋

## 검증 (G2_infra)
- `git ls-files` 결과에 `workspace.json` 부재
- 기기별 UI 변경 후 `git status` clean 유지

## 비고
- T-2(자동 커밋) 착수 전 또는 직후에 처리해야 노이즈 커밋 누적을 막는다
