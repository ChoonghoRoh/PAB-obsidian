---
task: "2-1-3"
title: "맥북 LiveSync 플러그인 연결 + 초기 업로드"
domain: "[INFRA]"
assignee: 사용자 (GUI) + Team Lead (검증)
status: completed
---

# Task 2-1-3: 맥북 LiveSync 연결

## 목표
맥북 Obsidian에 Self-hosted LiveSync를 연결하고 vault를 CouchDB로 초기 업로드한다.

## 작업 (사용자 GUI)
- 커뮤니티 플러그인 "Self-hosted LiveSync" 설치·활성화
- 접속정보: URI `http://100.109.251.86:5984`, DB `pab-llmdata`, user `pabadmin`
- Test Database Connection 통과, Check database configuration 통과
- "This device has the source files" → vault 업로드

## 검증 (Team Lead 독립, HR-6)
- 서버 doc_count 1 → 1533, .md 문서 74개 = 로컬 vault 74개 정확 일치
- 경로 구조(00_moc/..., _index.md) 보존 확인
