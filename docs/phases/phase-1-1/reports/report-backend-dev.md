---
phase: "1-1"
type: report
role: backend-dev
created: 2026-05-01
---

# Phase 1-1 Backend-Dev 작업 보고서

## 요약

T-2 ~ T-5 전체 완료. 모든 DoD(8/8) PASS.

| Task | 상태 | 산출물 |
|------|------|--------|
| T-2: wiki/ 7폴더 생성 | ✅ DONE | `wiki/{00_MOC,10_Notes,20_Lessons,30_Constraints,40_Templates,99_Inbox,_attachments}/` + `.gitkeep` 7개 |
| T-3: .obsidian/ 설정 JSON 튜닝 | ✅ DONE | `.obsidian/app.json`, `.obsidian/core-plugins.json`, `.obsidian/appearance.json` |
| T-4: CLI smoke test | ✅ DONE | `docs/phases/phase-1-1/reports/cli-smoke-test.md` |
| T-5: wiki/_INDEX.md 작성 | ✅ DONE | `wiki/_INDEX.md` (frontmatter 11필드) |

---

## §T-2 — wiki/ vault 7폴더 생성

**실행 명령**:
```bash
mkdir -p wiki/{00_MOC,10_Notes,20_Lessons,30_Constraints,40_Templates,99_Inbox,_attachments}
for d in wiki/{00_MOC,10_Notes,...}; do touch "$d/.gitkeep"; done
```

**결과**:
```
drwxr-xr-x  wiki/00_MOC          + .gitkeep ✓
drwxr-xr-x  wiki/10_Notes        + .gitkeep ✓
drwxr-xr-x  wiki/20_Lessons      + .gitkeep ✓
drwxr-xr-x  wiki/30_Constraints  + .gitkeep ✓
drwxr-xr-x  wiki/40_Templates    + .gitkeep ✓
drwxr-xr-x  wiki/99_Inbox        + .gitkeep ✓
drwxr-xr-x  wiki/_attachments    + .gitkeep ✓
```

**완료 기준 체크**:
- [x] 7 폴더 모두 존재
- [x] 각 폴더에 `.gitkeep` 존재
- [x] 폴더명 정확 (대소문자·언더스코어)

---

## §T-3 — .obsidian/ 설정 JSON 검증·튜닝

**사전 조치**: T-3 전에 Obsidian 앱을 graceful quit (osascript). T-4 전에 재실행.

**작성 파일 3종**:

### app.json (8 keys)
```json
{
  "alwaysUpdateLinks": true,
  "newFileLocation": "folder",
  "newFileFolderPath": "wiki/99_Inbox",
  "useMarkdownLinks": false,
  "attachmentFolderPath": "wiki/_attachments",
  "showLineNumber": true,
  "spellcheck": false,
  "promptDelete": true
}
```

### core-plugins.json (12 플러그인 활성화)

> **형식 결정**: task-1-1-3.md 명세는 배열 형식을 제시했으나, 실제 Obsidian v1.12.7이 사용하는 형식은 `{key: bool}` 객체 형식. 객체 형식으로 작성하여 호환성 확보.
> Obsidian 재실행 후 자신의 기본 플러그인을 추가 병합함 (예상된 동작). task 명세의 12개는 모두 `true` 상태 유지.

활성화 12종: `file-explorer`, `global-search`, `switcher`, `graph`, `backlink`, `outgoing-link`, `tag-pane`, `outline`, `templates`, `properties`, `command-palette`, `markdown-importer`

### appearance.json (4 keys)
```json
{
  "baseFontSize": 16,
  "enabledCssSnippets": [],
  "theme": "obsidian",
  "translucency": false
}
```

**검증 결과**:
```
OK: .obsidian/app.json (8 keys)
OK: .obsidian/core-plugins.json (12 keys)
OK: .obsidian/appearance.json (4 keys)
```
(python3 json.load 통과)

**완료 기준 체크**:
- [x] 3 파일 모두 존재 (프로젝트 루트 `.obsidian/`)
- [x] 모두 valid JSON
- [x] `app.json`에 8 키 포함
- [x] `core-plugins.json`에 12 플러그인 포함 (활성화)
- [x] `appearance.json`에 4 키 포함

---

## §T-4 — CLI Smoke Test 4건

**환경**: Obsidian v1.12.7, vault `PAB-obsidian` (프로젝트 루트)

| 명령 | 결과 | exit |
|------|------|------|
| `obsidian files` | 94 파일 열거 (vault root 하위 전체) | 0 |
| `obsidian search query="INDEX"` | 35건 매칭 (SSOT·docs .md 포함) | 0 |
| `obsidian tags` | "No tags found." (wiki 노트 없음, 정상) | 0 |
| `obsidian unresolved` | SSOT 내 broken link 목록 출력 (본 sub-phase 해결 범위 외) | 0 |

**완료 기준 체크**:
- [x] 4 명령 모두 exit 0
- [x] `reports/cli-smoke-test.md` 생성
- [x] 모든 stdout 캡처

**비고**: vault root = 프로젝트 루트이므로 SSOT/docs/scripts 등 모든 .md가 인덱싱됨 (master-plan §3 Phase 1-1 "의도된 동작" 명시). unresolved 항목은 SSOT 내부 상대 경로 참조로 Phase 1-4 이후 단계에서 별도 관리.

---

## §T-5 — wiki/_INDEX.md 진입점 노트

**작성 파일**: `wiki/_INDEX.md`

**frontmatter 11필드 검증**:
```
OK: all 11 fields present
  title: 'PAB Wiki — Index'
  description: 'PAB Obsidian Karpathy-style Wiki 최상위 진입점. TYPES/DOMAINS/TOPICS 3중 인덱스로 분기.'
  created: '2026-05-01 00:00'
  updated: '2026-05-01 00:00'
  type: '[[INDEX]]'
  index: '[[ROOT]]'
  topics: []
  tags: ['moc', 'root']
  keywords: ['pab-wiki', 'root-index', 'moc']
  sources: []
  aliases: ['MOC', 'Root', 'Wiki Home']
```

**Obsidian 인식 확인**: `obsidian search query="Index"` 결과에 `wiki/_INDEX.md` 포함 ✓

**완료 기준 체크**:
- [x] `wiki/_INDEX.md` 존재
- [x] frontmatter 11필드 모두 존재
- [x] `obsidian search query="Index"` 결과에 `_INDEX.md` 포함
- [x] 본문에 폴더 구조 표 + 사용 가이드 포함

---

## DoD 전체 결과 (8/8 PASS)

| DoD | 항목 | 결과 |
|-----|------|------|
| DoD-1 | `which obsidian` → `/usr/local/bin/obsidian` | ✅ PASS |
| DoD-2 | `obsidian version` → `1.12.7` | ✅ PASS |
| DoD-3 | `.obsidian/` 존재 | ✅ PASS |
| DoD-4 | `wiki/` 하위 7 폴더 존재 | ✅ PASS |
| DoD-5 | `obsidian files` 정상 응답 (94 파일) | ✅ PASS |
| DoD-6 | `obsidian search query="INDEX"` ≥1건 (35건) | ✅ PASS |
| DoD-7 | `wiki/_INDEX.md` + frontmatter 11필드 | ✅ PASS |
| DoD-8 | `.obsidian/` 3 JSON 파일 존재 | ✅ PASS |

---

## 특이사항 (verifier 참고)

1. **core-plugins.json 형식**: Obsidian v1.12.7은 `{key: bool}` 객체 형식 사용. task 명세의 배열 형식 대신 호환 형식으로 작성함. 12개 플러그인 모두 `true` 상태 확인.
2. **Obsidian 재실행 후 core-plugins.json 병합**: Obsidian이 재실행되며 자신의 기본 플러그인 목록을 병합함. task 명세의 12개 플러그인은 유지됨.
3. **unresolved 링크**: SSOT 내부 상대 경로 참조 항목 약 15건. wiki/ 콘텐츠가 없는 현 단계에서는 정상. Phase 1-4 `link-check` 기능 구현 후 관리 예정.

---

**작성**: backend-dev | **Phase**: 1-1 | **일시**: 2026-05-01
