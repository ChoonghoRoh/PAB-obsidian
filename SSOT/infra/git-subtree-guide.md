# Core/Custom git subtree 분리 가이드

## 1. 개요

- **목적**: `docs/SSOT/renewal/iterations/5th/core/` 를 별도 리포지토리(`ssot-core`)로 분리
- **이유**: Core 프레임워크의 이식성 확보, 다른 프로젝트에서 git subtree로 Core만 가져와 사용
- **전제 조건**: Phase 24-1~24-5 완료, `core/` 디렉토리 확립

## 2. 디렉토리 구조 (분리 전/후)

### 분리 전 (현재)

```
personal-ai-brain-v3/
└── docs/SSOT/renewal/iterations/5th/
    ├── core/           ← 이식 대상
    │   ├── 6-rules-index.md
    │   └── README.md
    └── project/        ← 프로젝트 고유
```

### 분리 후

```
ssot-core/ (별도 리포지토리)
├── 6-rules-index.md
├── README.md
├── 3-workflow.md (향후 이동)
├── 4-event-protocol.md (향후 이동)
├── 5-automation.md (향후 이동)
├── QUALITY/
└── TEMPLATES/

personal-ai-brain-v3/
└── docs/SSOT/renewal/iterations/5th/
    ├── core/        ← git subtree로 ssot-core 연결
    └── project/     ← 프로젝트 고유 유지
```

## 3. 분리 절차

### Step 1: ssot-core 리포지토리 생성

```bash
# GitHub에 ssot-core 리포지토리 생성 (빈 리포지토리)
gh repo create ssot-core --private --description "SSOT Core Framework"
```

### Step 2: core/ 내용을 ssot-core로 초기 push

```bash
# 임시 디렉토리에서 작업
cd /tmp
git clone https://github.com/{user}/ssot-core.git
cp -r ~/WORKS/personal-ai-brain-v3/docs/SSOT/renewal/iterations/5th/core/* ssot-core/
cd ssot-core
git add -A
git commit -m "Initial: SSOT Core framework files"
git push origin main
```

### Step 3: 원래 프로젝트에서 core/ 를 subtree로 교체

```bash
cd ~/WORKS/personal-ai-brain-v3
# 기존 core/ 백업
mv docs/SSOT/renewal/iterations/5th/core docs/SSOT/renewal/iterations/5th/core.bak
# subtree 추가
git subtree add --prefix=docs/SSOT/renewal/iterations/5th/core https://github.com/{user}/ssot-core.git main --squash
```

### Step 4: 검증

```bash
# 파일 존재 확인
ls docs/SSOT/renewal/iterations/5th/core/
# SSOT 검증
just validate-ssot
# 백업 제거
rm -rf docs/SSOT/renewal/iterations/5th/core.bak
```

## 4. 업데이트 워크플로우

### Core 변경 -> ssot-core 반영 (push)

```bash
git subtree push --prefix=docs/SSOT/renewal/iterations/5th/core https://github.com/{user}/ssot-core.git main
```

### ssot-core 변경 -> 프로젝트 반영 (pull)

```bash
git subtree pull --prefix=docs/SSOT/renewal/iterations/5th/core https://github.com/{user}/ssot-core.git main --squash
```

## 5. 다른 프로젝트에서 Core 사용

```bash
# 새 프로젝트에서 ssot-core 가져오기
cd new-project
git subtree add --prefix=docs/SSOT/core https://github.com/{user}/ssot-core.git main --squash
```

## 6. 주의사항

- `core/` 내 파일은 프로젝트 종속 내용 포함 금지 (`1-project.md`, `2-architecture.md` 등은 `project/`)
- subtree push/pull 시 충돌 해결은 로컬에서 먼저 수행
- `git subtree split` 대신 `subtree add/push/pull` 워크플로우 사용 (단순성)
- Copier 템플릿(`ssot-template/`)과의 관계: Copier는 신규 프로젝트 초기화, subtree는 Core 업데이트 수신

## 7. 자동화 (Justfile Task)

```just
# Core subtree push
core-push:
    git subtree push --prefix=docs/SSOT/renewal/iterations/5th/core {REMOTE} main

# Core subtree pull
core-pull:
    git subtree pull --prefix=docs/SSOT/renewal/iterations/5th/core {REMOTE} main --squash
```

## 8. 실행 타임라인

- **Phase 25+**: ssot-core 리포지토리 생성 + 초기 분리 실행
- **분리 전 core/ 파일 이동 완료 필요**: 현재 일부 Core 파일은 아직 `5th/` 루트에 위치
  - `3-workflow.md`, `4-event-protocol.md`, `5-automation.md` -> `core/` 이동 선행
  - `QUALITY/`, `TEMPLATES/` -> `core/` 이동 선행
