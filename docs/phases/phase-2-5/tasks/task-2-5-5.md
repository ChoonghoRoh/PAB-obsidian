---
task: "2-5-5"
title: "workspace.json git 추적 해제"
domain: "[INFRA]"
gap: "G-5 (🟡)"
assignee: backend-dev
status: completed    # workspace.json 추적 해제 + skip-worktree 비트 제거 (2026-08-26)
depends_on: []
---

# Task 2-5-5: per-machine 파일 git 추적 해제

## 목표
`PAB-LLMDATA/.obsidian/workspace.json`의 git 추적을 해제하여 master-plan §7 R-2(per-machine churn)를 해소한다.

## 배경
Phase 2-1 T-5는 **LiveSync 제외**는 처리했으나 **git 추적 해제는 누락**. 파일이 여전히 tracked 상태로 기기별 UI 상태 변경이 커밋 노이즈를 만든다. §3 KPI "per-machine 제외" 미달.

## 작업
- `git rm --cached PAB-LLMDATA/.obsidian/workspace.json` (파일 자체는 로컬 유지)
- `.gitignore` 패턴 반영·확인 (`graph.json` 등 유사 per-machine 파일 동시 점검)
- T-2 자동 커밋과의 상호작용 확인 — 추적 해제 후 자동 커밋이 이 파일을 되살리지 않는지

## 산출물
- `.gitignore` 갱신 + 추적 해제 커밋

## 검증 (G2_infra)
- `git ls-files` 결과에 `workspace.json` 부재
- 기기별 UI 변경 후 `git status` clean 유지

## 비고
- T-2(자동 커밋) 착수 전 또는 직후에 처리해야 노이즈 커밋 누적을 막는다

---

## 검증 결과 — **완료** (2026-08-26, backend-dev / Team Lead 독립 검증)

**커밋** `eda839b` — 변경 **1건**(`D PAB-LLMDATA/.obsidian/workspace.json`, 인덱스 제거만).
`.gitignore`는 **수정하지 않았다** — `:13` 규칙이 이미 있었고 중복 추가는 불필요했다.

### ⚠️ 단순 `git rm --cached` 하나로 끝나지 않았다 — `skip-worktree` 발견

`git rm --cached`가 *"outside of your sparse-checkout definition"* 으로 **거부**됐다. 조사 결과:

- worktree는 **sparse가 아니다** (`fatal: this worktree is not sparse`, `.git/info/sparse-checkout` 비어 있음)
- 그런데 **`workspace.json` 이 한 파일에만 `skip-worktree` 비트**가 걸려 있었다 (`git ls-files -v` → `S`, 나머지 전부 `H`)

churn을 막으려는 임시 조치로 보이나 **문제를 고친 게 아니라 계기를 끈 것**이었다:

| 겉보기 | 실제 |
|---|---|
| `git status`가 조용하다 | 파일은 **여전히 tracked** → KPI "per-machine 제외"는 **미달인 채** |
| 해결된 것 같다 | `skip-worktree`는 **clone 로컬 플래그** → 레노버·아이폰에는 **적용 안 됨** |
| 아무도 확인하지 않는다 | **증상이 안 보이면 확인할 동기도 없다** |

⇒ **비트를 먼저 해제한 뒤 인덱스에서 제거**했다(순서 중요 — 반대로 하면 플래그가 남는다). 잔재 `S` **0건**.

### 검증 (커밋 후 재측정)

| 항목 | 결과 |
|---|---|
| `git ls-files`에 부재 | **0건** ✅ |
| 작업트리 파일 보존 | **7361B 존재** ✅ (`--cached`만 사용 — Obsidian 실사용 파일) |
| **기기별 UI 변경 후 `git status` clean** | 파일 내용 변경 → `git status` **완전히 빈 상태** ✅ (KPI 충족) |
| **T-2 자동커밋이 되살리지 않음** | dry-run 스테이징 목록 **0건** ✅ |
| `skip-worktree` 잔재 | **0건** ✅ |
| 추적 중 ignore 대상 **전수** | **0건** ✅ (`git ls-files \| git check-ignore --no-index --stdin`) |

> `git check-ignore`는 **인덱스에 있는 파일을 기본 제외**한다. 추적-중-무시대상을 찾으려면 `--no-index`가 필요하다 — 없이 돌리면 "이상 없음"으로 보인다.

### `.obsidian` 전수 판단 (Team Lead 점검과 일치)

| 파일 | 판정 | 근거 |
|---|---|---|
| `app.json` · `appearance.json` · `core-plugins.json` | **유지** | 기기 간 공유해야 하는 공통 설정 (`.gitignore` 주석의 프로젝트 정책) |
| **`workspace.json`** | **제거** | per-machine UI 상태. 규칙은 있었으나 추적 중이라 무력 |
| `community-plugins.json` · `graph.json` · `cache` · `plugins/` 등 | 조치 불요 | 이미 ignored + 미추적 |

추가로 뺄 것도, 새로 넣을 것도 없었다. **`workspace.json` 하나만 어긋나 있었다.**

### R-2(per-machine churn) 해소 — 실측 근거

```
c7efa04 (05-07) chore(vault): 옵시디언 workspace 상태 업데이트 (Qwen3.6 source 노트 활성 탭)
 PAB-LLMDATA/.obsidian/workspace.json | 23 +++++++++++++++++++----
 1 file changed, 19 insertions(+), 4 deletions(-)
```
**활성 탭 하나 옮긴 것이 19줄 추가/4줄 삭제의 커밋**이 됐다.
T-2 자동 커밋이 2시간마다 도는 상태에서 이게 남아 있었으면 **탭만 옮겨도 커밋이 찍혔을 것**이다.
