---
task: "2-1-6"
title: "백업 경로 확정 (GitHub 오프사이트)"
domain: "[INFRA]"
assignee: Team Lead
status: completed
---

# Task 2-1-6: 백업 경로 확정

## 목표
실시간 동기화(LiveSync)와 오프사이트 백업(GitHub)의 역할을 분리해 단일 쓰기 경로를 확립한다 (R-1, DP-1).

## 결정
- **DP-1 = 데스크톱 git-authority** (단순). 서버 CouchDB→git 미러 cron은 보류.
- 백업 위치: GitHub `ChoonghoRoh/PAB-obsidian` (기존 유지)
- 역할 분리:
  - **LiveSync** = 기기 간 실시간 동기화 (CouchDB 경유)
  - **GitHub** = 시점 백업 (데스크톱에서 git commit/push)

## 검증
- vault 노트가 git에 백업되는 경로 정상 (본 Phase 커밋으로 확인)

## 잔여
- 무인 백업 자동화(cron)는 Phase 2-3 자동화 파이프라인과 함께 검토
