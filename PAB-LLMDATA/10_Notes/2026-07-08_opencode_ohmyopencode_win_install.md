---
title: "Windows에서 opencode·oh-my-opencode 설치하기"
description: "Scoop/npm으로 opencode를 설치하고 프로바이더 연결·oh-my-opencode 플러그인·PowerShell 프로필까지 세팅하는 절차 요약 (JNCD/중년코딩 글 정리)"
created: 2026-07-08 17:31
updated: 2026-07-08 17:31
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[OPENCODE]]"]
tags: ["research-note", "opencode", "oh-my-opencode", "windows", "ai-agent", "cli"]
keywords: ["opencode", "oh-my-opencode", "windows설치", "powershell", "scoop", "npm", "bun", "provider연결", "tui", "플러그인"]
sources: ["[[15_Sources/2026-07-08_opencode_ohmyopencode_win_install_source]]", "https://wikidocs.net/blog/@JNCD/7160/"]
aliases: ["opencode 윈도우 설치", "oh-my-opencode 설치", "opencode 설치 요약"]
---

# Windows에서 opencode·oh-my-opencode 설치하기

> Windows PowerShell 환경에서 [[opencode]]를 설치하고 AI 프로바이더와 연결한 뒤, [[oh-my-opencode]] 플러그인과 PATH 설정까지 마치는 전체 절차를 정리한 노트. 원문: JNCD(중년코딩), 2026-02-11.

## opencode란 무엇인가
[원본 §0 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#0-시작하기-전에-왜-opencode인가)

[[opencode]]는 코드 자동완성을 넘어 **프로젝트 전체 구조를 이해**하고 파일 편집·터미널 실행·웹 탐색을 자율적으로 수행하는 [[AI 에이전트]] 플랫폼이다. 여기에 [[oh-my-opencode]] 플러그인을 더하면 멀티 에이전트 오케스트레이션과 백그라운드 작업 관리 같은 고급 기능까지 쓸 수 있다. 성격상 [[CLAUDE_CODE]]와 같은 계열의 CLI 코딩 에이전트 하네스다.

## 사전 준비물
[원본 §1 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#1-사전-준비-prerequisites)

설치 전 다음 세 가지가 있어야 한다.

| 소프트웨어 | 용도 | 확인 명령 |
|---|---|---|
| Node.js (v18+) | 실행 환경·패키지 관리 | `node --version` |
| Git | 버전 관리·레포 연동 | `git --version` |
| PowerShell (5.1+) | 터미널 | `$PSVersionTable.PSVersion` |

[[Scoop]]이 있으면 설치가 훨씬 간편하다. 없으면 `Set-ExecutionPolicy RemoteSigned`(CurrentUser) 후 `get.scoop.sh` 스크립트로 설치한다.

## opencode 설치
[원본 §2 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#2-opencode-설치하기)

- **Scoop (권장)**: `scoop install opencode`
- **npm**: `npm install -g opencode-ai@latest`
- **확인**: `opencode --version` → **1.1.29 이상**이면 정상.

## 프로바이더(AI 모델) 연결
[원본 §3 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#3-서비스-프로바이더-설정)

프로젝트 폴더에서 `opencode`를 실행해 TUI를 띄운 뒤, `/connect` 명령으로 프로바이더(Anthropic·OpenAI·Google 등)를 선택하고 **API 키 등록 또는 OAuth 인증**을 진행한다. 입문자는 별도 설정 없이 무료 모델을 쓸 수 있는 **opencode Zen**이 권장된다.

## oh-my-opencode 플러그인 설치
[원본 §4 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#4-oh-my-opencode-설치-플러그인)

대화형 설치 마법사를 실행한다.

```powershell
npx oh-my-opencode install
# 또는
bunx oh-my-opencode install
```

마법사에서 사용 중인 서비스(Claude Pro·ChatGPT Plus·Gemini 등)를 고르면 최적 설정이 자동 적용된다.

## PowerShell 프로필 설정
[원본 §5 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#5-powershell-프로필-설정)

어느 디렉토리에서나 호출되도록 PATH를 프로필에 고정한다. `notepad $PROFILE`로 열어 아래를 추가하고 `. $PROFILE`로 새로고침한다(Scoop 기준).

```powershell
$env:Path += ";$env:USERPROFILE\scoop\shims"
```

## 문제 해결 (Troubleshooting)
[원본 §6 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#6-자주-발생하는-문제-및-해결-방법)

- **명령어를 못 찾음**: PATH에 `$env:USERPROFILE\.opencode\bin`(또는 설치 경로)를 추가.
- **권한 에러**: 관리자 PowerShell에서 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
- **플러그인 미로드**: `~/.config/opencode/opencode.json`의 `plugin` 배열에 `"oh-my-opencode"`가 등록됐는지 확인.

## 핵심 정리
[원본 §7 →](2026-07-08_opencode_ohmyopencode_win_install_source.md#7-결론)

설치 후 `/init`로 프로젝트를 초기화하고 **ultrawork** 기능으로 복잡한 개발 태스크를 위임하면 된다. 큰 흐름은 **① 사전 준비 → ② opencode 설치 → ③ 프로바이더 연결 → ④ 플러그인 → ⑤ PATH 고정**의 5단계로 요약된다.
