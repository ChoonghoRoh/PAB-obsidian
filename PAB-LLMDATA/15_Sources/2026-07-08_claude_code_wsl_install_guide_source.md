---
title: "Windows WSL에서 Claude Code 설치 가이드 (밤밤이)"
description: "Windows WSL2 환경에서 Claude Code를 설치·인증하고 개발환경(Node·VS Code·성능·보안)까지 세팅하는 단계별 가이드 원문"
created: 2026-07-08 17:35
updated: 2026-07-08 17:35
type: "[[SOURCE]]"
index: "[[HARNESS]]"
topics: ["[[CLAUDE_CODE]]", "[[WSL]]"]
tags: ["source", "claude-code", "wsl", "windows", "wsl2"]
keywords: ["claude-code", "wsl2", "windows", "ubuntu", "nodejs", "vscode", "wslconfig", "성능최적화", "설치가이드"]
sources: ["https://velog.io/@bambam/Windows-WSL%EC%97%90%EC%84%9C-Claude-Code-%EC%84%A4%EC%B9%98-%EA%B0%80%EC%9D%B4%EB%93%9C"]
aliases: ["Claude Code WSL 설치 원문", "WSL Claude Code 가이드"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층)
>
> 원문: https://velog.io/@bambam/Windows-WSL%EC%97%90%EC%84%9C-Claude-Code-%EC%84%A4%EC%B9%98-%EA%B0%80%EC%9D%B4%EB%93%9C · 저자 밤밤이 · 작성일 2025-06-16

# Windows WSL에서 Claude Code 설치 가이드

**저자:** 밤밤이
**작성일:** 2025년 6월 16일

## 1. WSL 2 설치

### 1.1 시스템 요구사항 확인

- Windows 10 버전 2004 이상 (빌드 19041 이상) 또는 Windows 11
- 가상화 기능 활성화 필요

### 1.2 PowerShell 관리자 권한으로 실행

```
# Windows 기능 활성화
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 또는 간단한 명령어 (Windows 10 버전 2004 이상)
wsl --install
```

### 1.3 시스템 재부팅

설치 후 반드시 시스템을 재부팅합니다.

### 1.4 WSL 2를 기본값으로 설정

```
wsl --set-default-version 2
```

### 1.5 Linux 배포판 설치

Microsoft Store에서 Ubuntu 22.04 LTS 설치를 권장합니다:

```
# 사용 가능한 배포판 확인
wsl --list --online

# Ubuntu 22.04 설치 (권장)
wsl --install -d Ubuntu-22.04
```

### 1.6 초기 설정

Ubuntu가 실행되면 사용자 계정과 비밀번호를 설정합니다.

## 2. WSL 환경 설정

### 2.1 시스템 업데이트

```
sudo apt update && sudo apt upgrade -y
```

### 2.2 필수 패키지 설치

```
# 개발 도구 설치
sudo apt install -y curl wget git build-essential

# Python과 pip 설치
sudo apt install -y python3 python3-pip

# Node.js 설치 (최신 LTS 버전)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2.3 Git 설정

```
# Git 사용자 정보 설정
git config --global user.name "seungdae.kim"
git config --global user.email "seungdae.kim@dong-a.com"

# Windows와 WSL 간 줄바꿈 문제 해결
git config --global core.autocrlf input
git config --global core.eol lf
```

## 3. Claude Code 설치

### 3.1 Claude Code 다운로드 및 설치

```
# Claude Code 설치 스크립트 다운로드
curl -fsSL https://claude.ai/install.sh | bash

# 또는 직접 바이너리 다운로드 (x86_64 리눅스용)
wget https://releases.claude.ai/claude-code/latest/claude-code-linux-x64.tar.gz
tar -xzf claude-code-linux-x64.tar.gz
sudo mv claude-code /usr/local/bin/
```

### 3.2 권한 설정

```
# 실행 권한 부여
sudo chmod +x /usr/local/bin/claude-code

# PATH 확인
echo $PATH
which claude-code
```

### 3.3 Claude Code 초기 설정

```
# Claude Code 인증
claude-code auth

# 설정 확인
claude-code config
```

## 4. 개발 환경 최적화

### 4.1 Windows Terminal 설정

Windows Terminal을 설치하고 WSL 탭을 기본값으로 설정:

**settings.json 예시:**

```json
{
    "defaultProfile": "{Ubuntu-22.04의 GUID}",
    "profiles": {
        "list": [
            {
                "name": "Ubuntu-22.04",
                "source": "Windows.Terminal.Wsl",
                "startingDirectory": "//wsl$/Ubuntu-22.04/home/username"
            }
        ]
    }
}
```

### 4.2 VS Code와 WSL 연동

```
# VS Code Server 자동 설치
code .
```

VS Code에서 "Remote - WSL" 확장 프로그램 설치 필요

### 4.3 개발 도구 설치

```
# Vue.js 개발 도구
npm install -g @vue/cli
npm install -g vite

# TypeScript
npm install -g typescript

# 유용한 CLI 도구들
npm install -g eslint prettier

# Docker (선택사항)
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```

## 5. 프로젝트 작업 환경 설정

### 5.1 작업 디렉토리 생성

```
# 홈 디렉토리에 프로젝트 폴더 생성
mkdir -p ~/projects
cd ~/projects

# 또는 Windows 파일시스템 사용 (성능상 권장하지 않음)
# cd /mnt/c/workspace
```

### 5.2 Vue 프로젝트 클론 및 설정

```
# 프로젝트 클론
git clone [프로젝트-URL]
cd [프로젝트명]

# 의존성 설치
npm install

# 개발 서버 실행 테스트
npm run dev
```

### 5.3 Claude Code 사용법

```
# 프로젝트 분석
claude-code analyze

# 코드 리뷰
claude-code review src/

# 특정 파일에 대한 도움
claude-code help src/components/MyComponent.vue

# 리팩토링 제안
claude-code refactor src/stores/userStore.ts

# 테스트 생성
claude-code test src/utils/helpers.ts

# 문서 생성
claude-code docs
```

## 6. 성능 최적화

### 6.1 WSL 메모리 제한 설정

Windows 홈 디렉토리에 `.wslconfig` 파일 생성:

```
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

### 6.2 파일 시스템 권장사항

```
# WSL 파일시스템 내에서 작업 (권장)
~/projects/your-project

# Windows 파일시스템 사용 시 (느림)
/mnt/c/workspace/your-project
```

### 6.3 Node.js 성능 최적화

```
# .bashrc 또는 .zshrc에 추가
echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.bashrc
source ~/.bashrc
```

## 7. 문제 해결

### 7.1 일반적인 문제들

**WSL이 시작되지 않는 경우:**

```
# WSL 재시작
wsl --shutdown
wsl
```

**권한 문제:**

```
# 파일 권한 수정
sudo chown -R $USER:$USER ~/projects
chmod -R 755 ~/projects
```

**네트워크 문제:**

```
# DNS 설정 확인
cat /etc/resolv.conf

# 필요시 수동 설정
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### 7.2 Claude Code 관련 문제

**인증 문제:**

```
# 토큰 재발급
claude-code auth --reset

# 설정 초기화
claude-code config --reset
```

**실행 권한 문제:**

```
# 실행 권한 확인 및 수정
ls -la /usr/local/bin/claude-code
sudo chmod +x /usr/local/bin/claude-code
```

**PATH 문제:**

```
# PATH에 추가
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 8. 추가 도구 및 팁

### 8.1 유용한 VSCode 확장 프로그램

- Remote - WSL
- Vue Language Features (Volar)
- TypeScript Vue Plugin (Volar)
- ESLint
- Prettier
- GitLens

### 8.2 터미널 개선

```
# Oh My Zsh 설치 (선택사항)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 또는 Fish shell
sudo apt install fish
chsh -s /usr/bin/fish
```

### 8.3 유용한 별칭 설정

```
# ~/.bashrc 또는 ~/.zshrc에 추가
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias code='code-insiders'
alias cc='claude-code'

# Git 별칭
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
```

### 8.4 개발 워크플로우 예시

```
# 1. 프로젝트 시작
cd ~/projects/vue-project
code .

# 2. Claude Code로 코드 분석
claude-code analyze

# 3. 개발 서버 실행
npm run dev

# 4. 코드 작성 후 Claude Code 리뷰
claude-code review src/components/NewComponent.vue

# 5. 품질 검사
npm run quality:check

# 6. 커밋
git add .
git commit -m "feat: add new component"
git push
```

## 9. 보안 고려사항

### 9.1 SSH 키 설정

```
# SSH 키 생성
ssh-keygen -t ed25519 -C "your.email@example.com"

# SSH 에이전트 시작
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 공개 키 복사
cat ~/.ssh/id_ed25519.pub
```

### 9.2 방화벽 설정

Claude Code가 인터넷에 접근할 수 있도록 Windows Defender 방화벽에서 WSL을 허용합니다.

---

이 가이드를 따라하시면 Windows에서 WSL을 통해 Claude Code를 성공적으로 설치하고 사용할 수 있습니다. 설치 과정에서 문제가 발생하면 언제든 질문해 주세요!
