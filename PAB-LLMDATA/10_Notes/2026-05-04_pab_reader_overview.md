---
title: "PAB-Reader — 프로젝트 개요"
description: "다중 루트 마크다운 문서를 브라우저에서 탐색·렌더링하는 경량 HTTP 뷰어"
created: 2026-05-04 22:39
updated: 2026-05-04 22:39
type: "[[PROJECT]]"
index: "[[PRODUCT]]"
topics: ["[[PAB_ECOSYSTEM]]", "[[MARKDOWN_VIEWER]]", "[[DOCS_BROWSER]]"]
tags: ["project", "pab-reader", "viewer"]
keywords: ["markdown", "viewer", "http server", "marked.js", "docs", "multi-root"]
sources: ["~/WORKS/PAB-Reader", "~/WORKS/PAB-Reader/server.py", "~/WORKS/PAB-Reader/index.html"]
aliases: ["PAB-Reader", "Reader"]
---

# PAB-Reader

## 시스템 목적 및 역할
**프로젝트 문서 뷰어** — 여러 루트 폴더(예: 프로젝트 문서·와이어프레임·시나리오 뷰어)에 흩어진 마크다운 파일을 한 곳에서 인덱싱·브라우징·렌더링하는 경량 웹앱. Python 표준 라이브러리(`http.server`) 기반의 단일 서버 + marked.js + highlight.js 클라이언트 렌더링 조합.

## 위치
`~/WORKS/PAB-Reader`

## 구조 요약
- `server.py` — Python HTTP 서버 (`http.server` 기반, 8070 포트 기본)
- `build_md_index.py` — 지정 루트의 .md 파일을 스캔해 `md-index.json` 생성
- `index.html`, `css/md-viewer.css` — 클라이언트 UI
- `config.json` / `config.docker.json` — 다중 루트 정의
- `Dockerfile`, `docker-compose.yml` — 컨테이너 배포
- `md-index.json` — 빌드된 인덱스 결과

## 핵심 기능
1. **다중 루트 관리**: `config.json`의 `roots: [{name, path}]`로 임의 폴더 등록
2. **인덱스 빌드**: `GET /api/rebuild-index?root=<key>` → `build_md_index.py` 호출
3. **파일 서빙**: `GET /api/files/<root_key>/<path>` → 해당 루트 하위 파일 반환
4. **클라이언트 렌더링**: marked.js로 마크다운 → HTML, highlight.js로 코드 하이라이팅, github-markdown-css 스타일

## 연동 현황

### 흐름 도식
```
[사용자 브라우저]
    │ ① index.html 접속 (localhost:8070)
    ▼
[server.py]
    ├─ GET /api/config         → config.json 반환
    ├─ GET /api/rebuild-index  → build_md_index.py 실행 → md-index.json
    └─ GET /api/files/<root>/<path>
        │
        ▼
[루트 폴더의 .md 파일]
    │ ② 파일 내용 회신
    ▼
[브라우저 — marked.js 렌더링]
    ③ 사용자에게 표시
```

### 절차 상세
1. **초기 로드**
   - 1-1. 사용자가 `localhost:8070` 접속
   - 1-2. `index.html` + JS/CSS 정적 파일 다운로드
   - 1-3. JS가 `/api/config` 호출 → 루트 목록 가져와 드롭다운 채움
2. **루트 선택 + 인덱스 빌드**
   - 2-1. 사용자가 드롭다운에서 루트 선택
   - 2-2. JS가 `/api/rebuild-index?root=<key>` 호출
   - 2-3. `server.py`가 `build_md_index.py` subprocess 실행 → `md-index.json` 갱신
3. **파일 탐색·렌더링**
   - 3-1. JS가 인덱스에서 파일 트리 표시
   - 3-2. 사용자가 파일 클릭 → `/api/files/<root>/<path>` 호출
   - 3-3. server.py가 파일 원문 회신 → marked.js가 HTML로 변환 → 표시

## 다른 PAB 프로젝트와의 관계
- [[PAB_project_overview|PAB 생태계 MOC]] — 진입점
- 다른 PAB 컴포넌트의 docs/ 디렉토리를 루트로 등록해 **공용 문서 뷰어로 사용 가능**
  - 예: `roots: [{name: "Conductor 문서", path: "../PAB-Conductor/docs"}, ...]`
- [[2026-05-04_pab_obsidian_overview|PAB-obsidian wiki]]와는 목적 다름 (Reader=원본 .md 브라우징, obsidian=정제된 wiki 노트 작성·연결)

## 구현 정보
- 의존성: Python 표준 라이브러리만 (서버), CDN 기반 JS 라이브러리 (클라이언트)
- 외부 패키지 의존 0 — `requirements.txt` 없음
- Docker 배포 지원 (`docker-compose.yml` + `config.docker.json`)
- 가벼운 단일 목적 도구

## 참고
- `/PAB-Reader/server.py` — HTTP 서버 본체
- `/PAB-Reader/build_md_index.py` — 인덱스 빌더
- `/PAB-Reader/index.html` — 클라이언트 진입점
- `/PAB-Reader/config.json` — 다중 루트 설정
