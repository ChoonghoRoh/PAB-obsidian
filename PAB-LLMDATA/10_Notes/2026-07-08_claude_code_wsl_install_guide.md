---
title: "Windows WSL2에서 Claude Code 설치·설정하기"
description: "WSL2 설치부터 Ubuntu 개발환경, Claude Code 설치·인증, 성능(.wslconfig)·보안(SSH)까지 이어지는 세팅 절차 요약 (밤밤이 글 정리)"
created: 2026-07-08 17:35
updated: 2026-07-08 17:35
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[CLAUDE_CODE]]", "[[WSL]]"]
tags: ["research-note", "claude-code", "wsl", "windows", "wsl2", "setup"]
keywords: ["claude-code", "wsl2", "windows설치", "ubuntu", "nodejs", "vscode-remote", "wslconfig", "성능최적화", "ssh키"]
sources: ["[[15_Sources/2026-07-08_claude_code_wsl_install_guide_source]]", "https://velog.io/@bambam/Windows-WSL%EC%97%90%EC%84%9C-Claude-Code-%EC%84%A4%EC%B9%98-%EA%B0%80%EC%9D%B4%EB%93%9C"]
aliases: ["Claude Code WSL 설치", "WSL2 Claude Code 설정", "윈도우 클로드코드 설치"]
---

# Windows WSL2에서 Claude Code 설치·설정하기

> Windows에서 [[WSL]]2를 켜고 Ubuntu 개발환경을 갖춘 뒤 [[CLAUDE_CODE|Claude Code]]를 설치·인증하고, 성능(`.wslconfig`)과 보안(SSH)까지 마무리하는 전체 흐름을 정리한 노트. 원문: 밤밤이, 2025-06-16.
>
> ⚠️ 원문은 2025년 6월 기준이라 설치 명령이 현재와 다를 수 있다. 특히 §3의 `curl -fsSL https://claude.ai/install.sh | bash`·바이너리 tar 방식과 `claude-code` 실행명은 당시 표기로, 현재 공식 설치는 **npm 전역 설치(`npm install -g @anthropic-ai/claude-code`)**와 실행명 **`claude`**가 표준이다. 최신 설치법은 공식 문서 확인 권장.

## WSL2 설치
[원본 §1 →](2026-07-08_claude_code_wsl_install_guide_source.md#1-wsl-2-설치)

Windows 10 2004+(빌드 19041) 또는 Windows 11에서 가상화를 켠 뒤, 관리자 PowerShell에서 `wsl --install`(구버전은 `dism.exe`로 Linux 서브시스템+VirtualMachinePlatform 기능 활성화)로 설치하고 **재부팅**한다. 이후 `wsl --set-default-version 2`로 WSL2를 기본값으로 두고, `wsl --install -d Ubuntu-22.04`로 Ubuntu 22.04 LTS를 설치한 뒤 계정·비밀번호를 초기 설정한다.

## Ubuntu 개발환경 구성
[원본 §2 →](2026-07-08_claude_code_wsl_install_guide_source.md#2-wsl-환경-설정)

`sudo apt update && upgrade` 후 필수 패키지(`curl wget git build-essential`, `python3/pip`)와 **Node.js LTS**(nodesource 스크립트)를 설치한다. [[Git]]은 사용자 정보와 함께 **줄바꿈 정책**을 WSL에 맞춰 `core.autocrlf input`·`core.eol lf`로 설정하는 것이 핵심이다.

## Claude Code 설치·인증
[원본 §3 →](2026-07-08_claude_code_wsl_install_guide_source.md#3-claude-code-설치)

원문은 설치 스크립트(`curl … install.sh | bash`) 또는 바이너리 tar 다운로드 → `/usr/local/bin` 이동 → 실행권한 부여 → `claude-code auth`로 인증하는 흐름을 제시한다. (위 주의처럼 현재는 npm 설치·`claude` 실행명이 표준이니 명령어는 최신 문서로 대체할 것.)

## 개발 환경 최적화 (Terminal·VS Code)
[원본 §4 →](2026-07-08_claude_code_wsl_install_guide_source.md#4-개발-환경-최적화)

Windows Terminal의 기본 프로필을 Ubuntu-22.04로 지정하고, [[VS Code]]에서 **Remote - WSL** 확장을 설치해 `code .`로 WSL 폴더를 연다. Vue CLI·Vite·TypeScript·ESLint·Prettier, 선택적으로 Docker 등 전역 도구를 설치한다.

## 프로젝트 작업 환경
[원본 §5 →](2026-07-08_claude_code_wsl_install_guide_source.md#5-프로젝트-작업-환경-설정)

작업 폴더는 **WSL 파일시스템(`~/projects`)** 안에 두는 것이 권장된다(`/mnt/c`는 성능 저하). 프로젝트 클론 → `npm install` → `npm run dev`로 검증하고, `claude-code analyze/review/refactor/test/docs` 등으로 코드 작업을 보조한다.

## 성능 최적화
[원본 §6 →](2026-07-08_claude_code_wsl_install_guide_source.md#6-성능-최적화)

Windows 홈에 `.wslconfig`를 만들어 `memory`/`processors`/`swap`/`localhostForwarding`을 제한·설정한다. 작업은 WSL 네이티브 경로에서 하고, Node는 `NODE_OPTIONS="--max-old-space-size=4096"`으로 힙을 늘린다.

## 문제 해결 (Troubleshooting)
[원본 §7 →](2026-07-08_claude_code_wsl_install_guide_source.md#7-문제-해결)

- **WSL 미시작**: `wsl --shutdown` 후 재시작.
- **권한 문제**: `chown -R $USER:$USER ~/projects`, `chmod -R 755`.
- **네트워크/DNS**: `/etc/resolv.conf`에 `nameserver 8.8.8.8` 수동 설정.
- **Claude Code**: `auth --reset`/`config --reset`, 실행권한·PATH 재설정.

## 추가 도구·팁
[원본 §8 →](2026-07-08_claude_code_wsl_install_guide_source.md#8-추가-도구-및-팁)

VS Code 확장(Remote-WSL, Volar, ESLint, Prettier, GitLens), Oh My Zsh/Fish 셸, `ll`·`cc='claude-code'`·git 단축 별칭, 그리고 분석→개발서버→리뷰→커밋으로 이어지는 워크플로우 예시가 제공된다.

## 보안 고려사항
[원본 §9 →](2026-07-08_claude_code_wsl_install_guide_source.md#9-보안-고려사항)

`ssh-keygen -t ed25519`로 SSH 키를 만들고 에이전트에 등록해 공개키를 배포한다. Windows Defender 방화벽에서 WSL의 인터넷 접근을 허용한다.
