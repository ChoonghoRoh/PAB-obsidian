---
phase: "1-2"
title: "Frontmatter 스키마 + Templater 템플릿"
team_name: "phase-1-2"
ssot_version: 8.0-renewal-6th
created: 2026-05-01
updated: 2026-05-01
current_state: DONE
exceptions: [E-1, E-2, E-3, E-4, E-5]
exceptions_ref: docs/phases/phase-1-exceptions.md
master_plan_ref: docs/phases/phase-1-master-plan.md
notify_prefix: "[PAB-Wiki]"
gate_results:
  G0: SKIP    # 5th_mode.research = false (스키마 정의는 master-plan에서 이미 결정)
  G1: PASS    # master-plan §3 Phase 1-2 정의가 G1 역할 수행
  G2_wiki: PASS  # Critical 5/5, High 4/4, Low 2/2 — verifier 보고서 참조
  G3: SKIP    # E-4 비적용
  G4: PASS    # G2_wiki PASS + G3 SKIP(E-4) 조합으로 자동 PASS
blockers: []
domain_tags_in_use: [WIKI-META]
roles:
  team_lead: main
  backend_dev: completed    # T-1~T-6 9 산출물 + 보고서 완료
  verifier: completed        # G2_wiki PASS 판정 보고
  tester: not_spawned        # E-4
  frontend_dev: not_spawned  # E-5
sub_phase_artifacts:
  status: docs/phases/phase-1-2/phase-1-2-status.md
  plan: docs/phases/phase-1-2/phase-1-2-plan.md
  todo_list: docs/phases/phase-1-2/phase-1-2-todo-list.md
  tasks_dir: docs/phases/phase-1-2/tasks/
  tasks:
    - tasks/task-1-2-1.md  # Frontmatter JSON Schema
    - tasks/task-1-2-2.md  # TYPE별 6 템플릿
    - tasks/task-1-2-3.md  # frontmatter-spec.md
    - tasks/task-1-2-4.md  # naming-convention.md
    - tasks/task-1-2-5.md  # linking-policy.md
5th_mode:
  research: false
  event: true
  automation: true
  branch: false              # git init 안 된 프로젝트
  multi_perspective: false   # 단일 verifier 충분
ssot_loaded_at: 2026-05-01T22:33:00
prev_phase: "1-1"
prev_phase_artifacts:
  - .obsidian/ (3 JSON: app.json, core-plugins.json, appearance.json)
  - wiki/ (7 폴더: 00_MOC, 10_Notes, 20_Lessons, 30_Constraints, 40_Templates, 99_Inbox, _attachments)
  - wiki/_INDEX.md (frontmatter 11필드 placeholder)
  - reports/cli-smoke-test.md, report-backend-dev.md, report-verifier.md
  - G2_wiki PASS (Critical 5/5, High 2/2)
next_prompt_suggestion: |
  Phase 1-3 (TOC/MOC 시스템 — 3중 인덱스)을 시작한다. 이전 Phase 산출물:
  - wiki/40_Templates/_schema.json (11필드 JSON Schema, Draft 2020-12)
  - wiki/40_Templates/{RESEARCH_NOTE,CONCEPT,LESSON,PROJECT,DAILY,REFERENCE}.md (6 템플릿)
  - wiki/30_Constraints/{frontmatter-spec,naming-convention,linking-policy}.md (3 constraints)
  - reports/ 2종 (report-backend-dev.md, report-verifier.md)
  - G2_wiki PASS (Critical 5/5, High 4/4, Low 2/2), G4 PASS

  진입 절차:
  1. FRESH-1: SSOT 0~3 리로드
  2. ENTRY-1: docs/phases/phase-1-3/phase-1-3-status.md 읽기 (없으면 Team Lead가 phase-init 수행)
  3. TEAM_SETUP: phase-1-2 팀 해산 후 phase-1-3 신규 팀 생성
  4. backend-dev + verifier 재스폰 (역할 동일, 컨텍스트만 phase-1-3로 갱신)
  5. T-1~T-5 시작 (TYPES MOC 6 + DOMAINS MOC 6 + TOPICS placeholder + _INDEX.md 갱신 + TOC 알고리즘 명세)

  주의:
  - Phase 1-3은 6 TYPE MOC (`wiki/00_MOC/TYPES/`) + 6 DOMAIN MOC (`wiki/00_MOC/DOMAINS/`) 작성 — 이로써 Phase 1-2의 unresolved [[AI]]/[[ROOT]] 등이 해소됨
  - TOPIC은 동적 생성 정책 → 본 Phase에서 placeholder + 자동 생성 규칙 문서만 작성
  - dataview 쿼리 + 정적 wikilink 폴백 병행 (linking-policy.md 정책)
last_phase_completed_at: 2026-05-01
---

# Phase 1-2 Status — Frontmatter 스키마 + Templater 템플릿

본 파일이 **단일 진입점**(ENTRY-1). 모든 Phase 1-2 작업은 위 YAML의 `current_state` 값을 먼저 확인한 뒤 분기한다.

## 현재 상태: IDLE

### 다음 행동

1. **FRESH-1**: SSOT 0~3 리로드 (필요 시)
2. **컨텍스트 로드**: master-plan §3 Phase 1-2, exceptions(E-1~E-5), phase-1-1 산출물(`_INDEX.md` 11필드 패턴)
3. **TEAM_SETUP 전이**: TeamCreate(team_name="phase-1-2")
4. **팀원 스폰**:
   - backend-dev (general-purpose/sonnet) — T-1~T-5 단일 implementer (E-5)
   - verifier (Explore/sonnet) — G2_wiki 검증
   - **tester 비스폰** (E-4)
   - **frontend-dev 비스폰** (E-5: 본 프로젝트 코드 BE/FE 분리 없음)
5. **TASK_SPEC**: 5 task를 backend-dev에게 SendMessage로 할당

### Blocker

없음. Phase 1-1 DONE 산출물(`_INDEX.md`, `wiki/40_Templates/`, `wiki/30_Constraints/`)이 모두 준비됨.

### 종료 조건 (DONE 전이 기준)

- [ ] T-1 ~ T-5 모두 completed
- [ ] 9 산출물 작성 완료 (1 schema + 6 templates + 3 constraints)
  - `wiki/40_Templates/_schema.json`
  - `wiki/40_Templates/RESEARCH_NOTE.md`
  - `wiki/40_Templates/CONCEPT.md`
  - `wiki/40_Templates/LESSON.md`
  - `wiki/40_Templates/PROJECT.md`
  - `wiki/40_Templates/DAILY.md`
  - `wiki/40_Templates/REFERENCE.md`
  - `wiki/30_Constraints/frontmatter-spec.md`
  - `wiki/30_Constraints/naming-convention.md`
  - `wiki/30_Constraints/linking-policy.md`
- [ ] G2_wiki PASS
  - **Critical**: JSON Schema valid / 6 템플릿이 schema 통과 / 11필드 100% 준수
  - **High**: 사용 예시 포함 / cross-link 정합성 (constraints ↔ template ↔ schema)
  - **Low**: 보고서 누락 (있으면 PASS 가능)
- [ ] reports/ 보고서 작성 (`report-backend-dev.md`, `report-verifier.md`)
- [ ] NOTIFY-1 발송 (`[PAB-Wiki] ✅ Phase 1-2 완료`)
- [ ] `next_prompt_suggestion` 갱신 → Phase 1-3 진입 명령
