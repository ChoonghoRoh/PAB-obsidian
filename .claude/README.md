# .claude — Claude Code 프로젝트 설정

## 페르소나 설정 위치

**`.claude/settings.json`에는 페르소나(시스템 프롬프트)를 넣을 수 없습니다.**

Claude Code 공식 문서 기준:

- **settings.json**: 권한(permissions), 환경변수(env), 모델(model), 훅(hooks), MCP, 플러그인 등만 설정 가능. **persona / systemPrompt 필드는 없음.**
- **페르소나·커스텀 지시**: **CLAUDE.md** 또는 **AGENTS.md**로만 등록.

### 이 프로젝트에서의 등록

| 목적           | 파일                    | 비고                          |
|----------------|-------------------------|-------------------------------|
| **페르소나**   | `.claude/CLAUDE.md`     | 6th SSOT (`SSOT/PERSONA/BACKEND.md`) 참조 (시작 시 로드) |
| **권한 등**    | `.claude/settings.json` 또는 `settings.local.json` | permissions, env 등 |

- **CLAUDE.md**: 프로젝트 루트 또는 `.claude/CLAUDE.md` — Claude Code가 시작 시 로드하는 “메모리/지시” 파일.
- **AGENTS.md**: 프로젝트 루트 — 일부 클라이언트에서 CLAUDE.md 대신 사용. 이 프로젝트에서는 루트에 AGENTS.md도 있음(동일 Backend 페르소나).

### 참고

- [Claude Code settings](https://code.claude.com/docs/en/settings): "To add custom instructions, use CLAUDE.md files or the --append-system-prompt flag."
- 스키마: https://json.schemastore.org/claude-code-settings.json — persona 필드 없음.
