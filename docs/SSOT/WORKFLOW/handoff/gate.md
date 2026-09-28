# 전달 게이트 (HANDOFF)

Team Lead가 팀원에게 일을 넘길 때마다 통과하는 절차 게이트다. 품질 게이트(G1~G4)와 별개다.

## 1. 규칙

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **HANDOFF-1** | 전달 시점 | 팀원이 수행하는 상태(PLANNING · BUILDING · VERIFYING · TESTING · INTEGRATION · E2E)에 진입할 때, 게이트를 통과한 뒤 스폰·지시한다 |
| **HANDOFF-2** | 전달물 | ① **base SSOT** — `entrypoint.md` 스폰 주입표의 팀원 행 ② **업무 지시** — 목표 · 경계(담당 구역 · 다른 팀원 일 · 금지) · 읽을 것(파일:줄 · 블록명 · `point-N`으로 **범위 좁힘**, 확인은 grep 명령) · **방향 가이드**(어떻게 해라) · 검증 명령 · 보고 형식 · 중단 조건. SSOT 전체와 다른 단계 단위는 넘기지 않고, 개방형 "전체 파악" 지시를 하지 않는다(DELEGATE-1~4) |
| **HANDOFF-3** | 추가 로드 요청 처리 | 팀원이 `[SSOT 요청]`을 보내면 Team Lead가 파일:절을 지정해 승인하거나, 거절하고 대안을 준다 |
| **HANDOFF-4** | 통과 조건 | base 세트 · 담당 구역 · 역할별 병렬 정책(`entrypoint.md` §3.9) 적용 · 보고 형식이 모두 정해져야 스폰·지시한다 |
| **HANDOFF-5** | 기록 | 추가 로드 승인 내역은 팀원 보고의 「지시와 다르게 한 것」 칸에 남는다 |
| **HANDOFF-6** | 판정 대상 SHA 고정 | G2 · G3 요청에는 `대상 SHA`(판정할 커밋)와 작업 공간(worktree 경로)을 적는다. 결과 파일을 쓰는 팀원(G2 = verifier, G3 = tester)은 그 SHA로 읽고 측정하며(`git show <SHA>:<경로>` · `git diff <기준> <SHA>`), 결과 파일 머리에 `대상 SHA`를 적는다. 요청부터 회신까지 편집자는 그 커밋을 amend · rebase · force-push로 바꾸지 않는다 — 고칠 것은 새 커밋으로 넣고 새 SHA로 다시 요청한다. 단계별 절차: `handoff/verifying.md` §3 · `handoff/testing.md` §1 |

### 1.1 유형별 지시 최소 항목 (HANDOFF-2 확장)

HANDOFF-2의 목표 · 경계 · 읽을 것 · 방향 가이드 · 검증 명령 · 보고 형식 · 중단 조건 7항목에 아래 유형별 칸을 더한다. 역할 문서는 이 표를 가리키고 항목을 복제해 적지 않는다.

| 유형 | 더하는 칸 |
|------|-----------|
| 공통 | 지시 ID(COMM-3) · 예산(OPS-3 — 단위는 `CORE/shared-definitions.md` §8) |
| BE · FE | 기준 커밋 · CWD · 예시 입력 · 기대 출력 |
| TEST | 대상 SHA · 변경 도메인 · 파일 · 완료 기준 · 원본(이식 · 옛 판) 기대값을 현재 결정 · 계약과 대조한 결과(`handoff/testing.md` §2) |
| VERIFY | 대상 SHA · 기준 커밋 · 변경 파일 목록 · 완료 기준 · 프로젝트 규칙 오버라이드(`PROJECT.md` §4 · §5 「G2 등급 산출」 행) · 편집자 DoD(`handoff/verifying.md` §3) |
| PLAN | 줄 상한 · 편집 경로(설치본 · 번들) 구분 |
| DOC 위임 | 편집자 DoD(LOCK-7) |

## 2. 보고 회수

| 규칙 ID | 규칙 | 설명 |
|---------|------|------|
| **REPORT-6** | 파일 상태로 판정 | 완료 판정은 메시지가 아니라 파일 상태(git diff, 검증 명령 재실행)로 한다. 메시지가 늦게 오거나 엇갈려도 팀원이 멈춘 것으로 단정하지 않는다 |

- 보고서 파일이 필요하면 Team Lead가 `docs/phases/phase-X-Y/reports/`에 남긴다 (양식: `TEMPLATES/task-report-template.md`).
