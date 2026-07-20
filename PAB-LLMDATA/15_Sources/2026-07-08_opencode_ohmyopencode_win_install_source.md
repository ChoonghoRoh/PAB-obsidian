---
title: "Windows 환경에서 opencode·oh-my-opencode 설치 (JNCD/중년코딩)"
description: "opencode와 oh-my-opencode 플러그인을 Windows PowerShell 환경에 설치·설정하는 단계별 가이드 원문"
created: 2026-07-08 17:31
updated: 2026-07-08 17:31
type: "[[SOURCE]]"
index: "[[HARNESS]]"
topics: ["[[OPENCODE]]"]
tags: ["source", "opencode", "oh-my-opencode", "windows", "ai-agent"]
keywords: ["opencode", "oh-my-opencode", "windows", "powershell", "scoop", "npm", "bun", "tui", "ai에이전트", "플러그인설치"]
sources: ["https://wikidocs.net/blog/@JNCD/7160/"]
aliases: ["opencode 설치 원문", "oh-my-opencode 설치 가이드"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층)
>
> 원문: https://wikidocs.net/blog/@JNCD/7160/ · 저자 JNCD(중년코딩) · 작성일 2026-02-11

# Windows 환경에서 opencode, oh-my-opencode 설치

## 0. 시작하기 전에: 왜 opencode인가?

opencode는 단순한 코드 완성을 넘어, 프로젝트의 전체 구조를 이해하고 파일 편집, 터미널 실행, 웹 탐색 등을 자율적으로 수행하는 AI 에이전트 플랫폼입니다. 여기에 oh-my-opencode 플러그인을 더하면 멀티 에이전트 오케스트레이션, 백그라운드 작업 관리 등 더욱 고도화된 기능을 사용할 수 있습니다.

## 1. 사전 준비 (Prerequisites)

설치를 진행하기 전, 윈도우 시스템에 다음의 소프트웨어들이 설치되어 있는지 확인해야 합니다.

| 요구 소프트웨어 | 용도 | 확인 명령 |
|---|---|---|
| Node.js (v18+) | 실행 환경 및 패키지 관리 | `node --version` |
| Git | 버전 관리 및 레포지토리 연동 | `git --version` |
| PowerShell (5.1+) | 터미널 환경 | `$PSVersionTable.PSVersion` |

Tip: 패키지 관리를 위해 Scoop이 설치되어 있으면 훨씬 간편합니다. 만약 설치되어 있지 않다면 아래 명령어로 설치할 수 있습니다.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

## 2. opencode 설치하기

가장 권장되는 방법은 Scoop을 사용하는 것이지만, npm이나 bun을 통해서도 설치가 가능합니다.

방법 1: Scoop 이용 (권장)

```powershell
scoop install opencode
```

방법 2: npm 이용

```powershell
npm install -g opencode-ai@latest
```

설치 확인

설치가 완료되면 버전을 확인하여 정상 작동 여부를 체크합니다.

```powershell
opencode --version
# 1.1.29 이상의 버전이 출력되어야 합니다.
```

## 3. 서비스 프로바이더 설정

opencode를 사용하려면 AI 모델을 제공하는 프로바이더와 연결해야 합니다.

1. 프로젝트 폴더로 이동하여 opencode를 실행합니다.

```powershell
cd C:\your\project\path
opencode
```

2. 실행된 TUI 화면에서 `/connect` 명령어를 입력합니다.
3. 원하는 프로바이더(Anthropic, OpenAI, Google 등)를 선택하고 안내에 따라 API 키를 등록하거나 OAuth 인증을 진행합니다.

opencode Zen: 입문자에게 권장되며, 별도의 설정 없이 무료 모델을 체험해 볼 수 있습니다.

## 4. oh-my-opencode 설치 (플러그인)

oh-my-opencode는 opencode의 능력을 한 단계 업그레이드해주는 플러그인입니다.

대화형 설치 (권장)

아래 명령어 중 하나를 실행하면 설치 마법사가 시작됩니다.

```powershell
npx oh-my-opencode install
# 또는 bunx 사용 시
bunx oh-my-opencode install
```

설치 옵션 선택

마법사 진행 중 본인이 사용 중인 서비스(Claude Pro, ChatGPT Plus, Gemini 등)를 선택하면 자동으로 최적의 설정이 진행됩니다.

## 5. PowerShell 프로필 설정

어느 디렉토리에서나 opencode를 원활하게 호출하고, 필요한 경로가 잡히도록 PowerShell 프로필에 설정을 추가해주는 것이 좋습니다.

1. 프로필 편집기를 엽니다.

```powershell
notepad $PROFILE
```

2. 아래 내용을 추가하고 저장합니다 (Scoop 사용자 기준).

```powershell
# opencode 경로 추가
$env:Path += ";$env:USERPROFILE\scoop\shims"
```

3. 프로필을 새로고침합니다.

```powershell
. $PROFILE
```

## 6. 자주 발생하는 문제 및 해결 방법

Q1. opencode 명령어를 찾을 수 없습니다.
A: 환경 변수 PATH에 설치 경로가 포함되지 않은 경우입니다. `$env:USERPROFILE\.opencode\bin` 또는 설치 경로를 시스템 환경 변수에 추가하세요.

Q2. PowerShell 권한 에러가 발생합니다.
A: 스크립트 실행 권한이 제한된 경우입니다. 관리자 권한으로 PowerShell을 열고 아래 명령을 실행하세요.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Q3. 플러그인이 로드되지 않습니다.
A: `~/.config/opencode/opencode.json` 파일을 열어 plugin 배열에 `"oh-my-opencode"`가 정확히 등록되어 있는지 확인하세요.

## 7. 결론

이제 윈도우 환경에서도 강력한 AI 코딩 에이전트인 opencode를 사용할 준비가 끝났습니다. 터미널에서 `/init` 명령어로 프로젝트를 초기화하고, ultrawork 기능을 활용해 복잡한 개발 태스크를 AI에게 맡겨보세요.

AI 에이전트는 이제 단순한 도구를 넘어 여러분의 든든한 동료가 되어줄 것입니다. 설치 과정에서 궁금한 점이 있다면 댓글로 남겨주세요!
