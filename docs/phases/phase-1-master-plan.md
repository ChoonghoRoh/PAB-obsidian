---
phase: "1"
title: "Obsidian Karpathy-style Wiki 환경 구축"
type: master-plan
created: 2026-05-01
ssot_version: 8.2-renewal-6th
initiator: user
prompt_quality: pass
pre_draft_ref: docs/phases/phase-1-pre-analysis.md
exceptions_ref: docs/phases/phase-1-exceptions.md
exceptions: [E-1, E-2, E-3, E-4, E-5]
sub_phases: [1-1, 1-2, 1-3, 1-4, 1-5, 1-6]
status: APPROVED
notify_prefix: "[PAB-Wiki]"
---

# Phase 1 — Obsidian Karpathy-style Wiki 환경 구축 (Master Plan)

## §0 요약

Andrej Karpathy 스타일의 LLM-친화 wiki를 Obsidian으로 구축한다. 공식 [Obsidian CLI](https://obsidian.md/cli)를 활용해 vault 초기화·노트 생성·TOC 추천·링크 검증을 자동화하고, 향후 SSOT skill에서 wiki에 문서를 전달하거나 wiki 노트를 별도 제작하는 기능을 호출할 수 있는 인터페이스 어댑터까지 구축한다.

본 Phase는 **6 sub-phase**로 분할되며, 각 sub-phase는 **AutoCycle handoff** 방식으로 다음 sub-phase에 자동 진입한다.

## §1 SSOT 적용 범위

본 Phase는 [phase-1-exceptions.md](phase-1-exceptions.md)의 5건 예외(E-1~E-5)를 적용한다. **SSOT 본체는 무수정**.

| 적용되는 SSOT 규칙 | HR-1, HR-2, HR-3, HR-4, HR-6, HR-7, HR-8(prefix 변경), G0, G1, G2_wiki(신설), G4, FRESH-1~12, ENTRY-1~5, AutoCycle handoff, CHAIN-5/6/10/11/13 |
| 비적용/대체 | G2_be(E-1), G2_fe(E-1), HR-5(E-2), G3 pytest(E-4), tester 스폰(E-4), 기존 도메인 태그(E-5) |

## §2 KPI

| KPI | 목표 | 측정 |
|---|---|---|
| Obsidian CLI 동작 | `obsidian search "test"` 정상 응답 | Phase 1-1 |
| Vault 초기화 | `wiki/.obsidian/` 존재, 7 폴더 생성 | Phase 1-1 |
| Frontmatter 스키마 준수 | 모든 시드 노트 11필드 100% | Phase 1-2 → Phase 1-6 |
| MOC 시스템 | TYPES(6) + DOMAINS(6) MOC 자동 갱신 | Phase 1-3 |
| CLI 자동화 명령 | `wiki new`/`link-check`/`moc-build`/`toc-suggest` 4종 동작 | Phase 1-4 |
| SSOT skill 어댑터 | `/wiki-create-note` skill 1건 동작 | Phase 1-5 |
| 시드 노트 | 5건, G2_wiki PASS | Phase 1-6 |
| broken link | 0건 | Phase 1-6 |

## §3 Sub-Phase 분할

### Phase 1-1: Obsidian CLI + Vault 초기화 [WIKI-INFRA]

**목표**: Obsidian 공식 CLI를 macOS에 설치·등록하고, 프로젝트 내 `wiki/` vault를 초기화한다.

**Tasks**:
- T-1: Obsidian 데스크톱 앱 설치 확인 + CLI 등록 절차 검증 (사용자 sudo 필요 — `! obsidian register` 안내)
- T-2: `wiki/` 디렉터리 vault 초기화 + 7 폴더(00_MOC, 10_Notes, 20_Lessons, 30_Constraints, 40_Templates, 99_Inbox, _attachments) 생성
- T-3: `.obsidian/` 핵심 설정 파일 작성 (`app.json`, `core-plugins.json`, `appearance.json`)
- T-4: `obsidian` CLI 명령 4건 smoke test (`files`, `search`, `tags`, `unresolved`)
- T-5: 기본 `wiki/_INDEX.md` (최상위 MOC placeholder) 작성

**산출물**: `wiki/` vault, `wiki/.obsidian/`, `wiki/_INDEX.md`, smoke test 보고서

**G2_wiki**: vault 구조 정합성, CLI 응답 정상

**소요 추정**: 3~4 task / 30~60분

---

### Phase 1-2: Frontmatter 스키마 + Templater 템플릿 [WIKI-META]

**목표**: 11필드 frontmatter 스키마를 확정하고, TYPE별 6종 템플릿을 작성한다.

**Tasks**:
- T-1: Frontmatter JSON Schema 작성 (`wiki/40_Templates/_schema.json`) — 11필드 + alias + 검증 규칙
- T-2: TYPE별 템플릿 6종 (`RESEARCH_NOTE`, `CONCEPT`, `LESSON`, `PROJECT`, `DAILY`, `REFERENCE`)
- T-3: `wiki/30_Constraints/frontmatter-spec.md` — 스키마 사용 가이드 (사용자가 직접 작성 시 참조)
- T-4: `wiki/30_Constraints/naming-convention.md` — 파일명 규약(`YYYY-MM-DD_topic.md`) + slug 규칙
- T-5: `wiki/30_Constraints/linking-policy.md` — 링크 작성 정책 (상향/하향/횡적/alias)

**산출물**: 6 템플릿 + 3 constraints 문서 + JSON Schema

**G2_wiki**: 모든 템플릿이 스키마 통과

**소요 추정**: 5 task / 60~90분

---

### Phase 1-3: TOC/MOC 시스템 (3중 인덱스) [WIKI-META] [WIKI-CONTENT]

**목표**: TYPES/DOMAINS/TOPICS 3중 인덱스 MOC를 구축하고, 자동 수집 메커니즘을 설계한다.

**Tasks**:
- T-1: `wiki/00_MOC/TYPES/` — 6 TYPE MOC (RESEARCH_NOTE.md, CONCEPT.md, LESSON.md, PROJECT.md, DAILY.md, REFERENCE.md)
- T-2: `wiki/00_MOC/DOMAINS/` — 6 DOMAIN MOC (AI.md, HARNESS.md, ENGINEERING.md, PRODUCT.md, KNOWLEDGE_MGMT.md, MISC.md)
- T-3: `wiki/00_MOC/TOPICS/` — placeholder + 자동 생성 규칙 문서 (TOPIC은 노트가 등장하면서 동적 추가)
- T-4: `wiki/_INDEX.md` 갱신 — 3중 인덱스 진입점, dataview 쿼리 + 폴백 정적 링크
- T-5: TOC 추천 알고리즘 명세 (`wiki/30_Constraints/toc-recommendation.md`) — heading depth 분석 + LLM 보강 기준

**산출물**: 12+ MOC 노트 + TOC 알고리즘 명세 + `_INDEX.md` 완성

**G2_wiki**: MOC 간 상호 링크 정합성, dataview 쿼리 valid

**소요 추정**: 5 task / 90~120분

---

### Phase 1-4: CLI 자동화 (`scripts/wiki/`) [WIKI-CLI]

**목표**: 4종 CLI 명령을 Python으로 구현. Obsidian 공식 CLI와 직접 vault 조작을 조합한다.

**Tasks**:
- T-1: `scripts/wiki/wiki.py` 진입점 + argparse 설정 (`new`/`link-check`/`moc-build`/`toc-suggest` 4 subcommand)
- T-2: `wiki new <type> <slug>` — 템플릿 적용 + frontmatter 자동 채움 + `obsidian create` 호출
- T-3: `wiki link-check` — `obsidian unresolved` 호출 + frontmatter 필수필드 검증 + 고아 노트 검출 → G2_wiki 리포트
- T-4: `wiki moc-build` — `obsidian files` + frontmatter 파싱 → MOC 자동 갱신
- T-5: `wiki toc-suggest <note>` — 노트 heading 분석 + outline 추천 (필요 시 `obsidian eval`로 메타 보강)
- T-6: `Makefile` 또는 `just` 타겟 (`make wiki-new TYPE=research SLUG=foo`) + `scripts/wiki/README.md`

**산출물**: `scripts/wiki/wiki.py` (~400줄 권장 한계), `scripts/wiki/lib/*.py` (frontmatter, validate, moc, toc 모듈), Makefile 타겟, README

**G2_wiki**: 4 명령 smoke test 통과, link-check가 빈 vault에서 PASS 반환

**소요 추정**: 6 task / 120~180분

---

### Phase 1-5: SSOT skill 어댑터 [WIKI-CLI] [WIKI-META]

**목표**: 향후 SSOT 작업 결과를 wiki로 전달하거나 wiki 노트를 별도 제작하는 skill 인터페이스를 구축한다.

**Tasks**:
- T-1: `.claude/skills/wiki-create-note/SKILL.md` — SSOT 결과 → wiki 노트 변환 skill 명세 (입력: type, title, body, sources / 출력: `wiki/10_Notes/YYYY-MM-DD_*.md`)
- T-2: `.claude/skills/wiki-link-suggest/SKILL.md` — 본문에서 wikilink 후보 추출 + 추천 skill (LLM-assisted)
- T-3: `.claude/skills/wiki-moc-update/SKILL.md` — MOC 일괄 갱신 skill (Phase DONE 시 호출)
- T-4: `scripts/wiki/skill_bridge.py` — skill에서 호출되는 단일 진입점 (subprocess `wiki.py` 호출 wrapper)
- T-5: `wiki/30_Constraints/skill-bridge-protocol.md` — skill ↔ wiki 인터페이스 계약 문서 (입출력 JSON 스키마)

**산출물**: 3 skill 명세 + skill_bridge.py + 프로토콜 문서

**G2_wiki**: 각 skill을 빈 입력으로 실행 시 정상 에러 메시지 반환

**소요 추정**: 5 task / 90~120분

---

### Phase 1-6: 시드 노트 + 사용 가이드 + 통합 검증 [WIKI-CONTENT]

**목표**: 5건의 실제 시드 노트를 작성하고 (스크린샷의 LangChain agentic engineering 노트 포함), 사용자 가이드를 완성하며, 전체 G2_wiki + wiki-validation을 통과한다.

**Tasks**:
- T-1: 시드 노트 5건 작성
  - `2026-05-01_obsidian_cli_setup.md` (LESSON, DOMAIN: HARNESS) — 본 Phase 1-1 결과 기록
  - `2026-04-21_agentic_engineering.md` (RESEARCH_NOTE, DOMAIN: AI, TOPICS: LANGGRAPH/MULTI_AGENT) — 스크린샷 재현
  - `2026-05-01_karpathy_llm_wiki.md` (CONCEPT, DOMAIN: KNOWLEDGE_MGMT)
  - `2026-05-01_pab_wiki_project.md` (PROJECT, DOMAIN: PRODUCT) — 본 프로젝트 자체
  - `2026-05-01_para_method.md` (REFERENCE, DOMAIN: KNOWLEDGE_MGMT)
- T-2: 시드 노트로 MOC 자동 갱신 실행 (`wiki moc-build`) → MOC 갱신 검증
- T-3: `wiki link-check --full` 실행 → broken link 0 확인
- T-4: `wiki/README.md` — 사용자용 가이드 (4 CLI 명령 사용법, 노트 작성 워크플로우, 자주 묻는 질문)
- T-5: `docs/phases/phase-1-final-summary-report.md` — 전체 요약, KPI 달성 보고, 향후 운영 권고
- T-6: NOTIFY-1 발송 (Phase 1 전체 완료) — `[PAB-Wiki] ✅ Phase 1 완료` 텔레그램

**산출물**: 시드 노트 5 + README + master-final-report

**G2_wiki + G3 wiki-validation**: 전체 vault 통과 (broken link 0, frontmatter 100%, MOC 정합성)

**소요 추정**: 6 task / 120~180분

---

## §4 Sub-Phase 의존 관계

```
1-1 (CLI + Vault 초기화)
   ↓
1-2 (Frontmatter 스키마 + 템플릿)
   ↓
1-3 (TOC/MOC 3중 인덱스)
   ↓
1-4 (CLI 자동화 wiki.py)
   ↓
1-5 (SSOT skill 어댑터) ──┐
                          ├→ 1-6 (시드 노트 + 통합 검증)
                          ┘
```

각 sub-phase 완료 시 NOTIFY-1 (`[PAB-Wiki]` prefix) 발송 → 다음 sub-phase status.md 진입.

## §5 G2_wiki 통합 판정 기준 (E-1 신설 게이트)

| 등급 | 조건 |
|---|---|
| **Critical (FAIL)** | broken `[[wikilink]]` 1건 이상 / frontmatter 필수필드(`title`, `type`, `created`) 누락 1건 이상 / 파일명 규약 위반 1건 이상 |
| **High (PARTIAL)** | `description` 누락 / `topics` 또는 `tags` 빈 배열 / MOC 미포함 노트 |
| **Low (PASS 가능)** | `keywords` 누락 / `sources` 빈 배열 (외부 참조 없는 노트) |

**판정**:
- Critical 1건+ → **FAIL** → 수정 후 재검증
- Critical 0건, High 있음 → **PARTIAL** → Team Lead 판단 (진행 또는 수정)
- Critical 0건, High 0건 → **PASS**

## §6 리스크 + 완화

| # | 리스크 | 완화 |
|---|---|---|
| R-1 | Obsidian CLI sudo 필요 (T-1) | 사용자에게 `! obsidian register` 직접 실행 요청 (Bash `!` 프리픽스로 세션 내 실행) |
| R-2 | `obsidian eval` JS API 명세 부족 | Phase 1-4 T-5 진행 시 `obsidian devtools`로 실측 → 부족 시 `obsidiantools` Python 폴백 |
| R-3 | `obsidiantools` 미설치 환경 | Phase 1-4 T-1 시 `pip install python-frontmatter` (필수) + `obsidiantools`(선택) |
| R-4 | wiki.py 400줄 초과 | Phase 1-4 T-1에서 모듈 분리 설계 — `lib/frontmatter.py`, `lib/validate.py`, `lib/moc.py`, `lib/toc.py` |
| R-5 | NOTIFY 스크립트 prefix 옵션 부재 | Phase 1-1 T-4 후 wrapper `scripts/pmAuto/notify_wiki.sh` 작성 (5분) |
| R-6 | TOC 추천 알고리즘 품질 | Phase 1-3 T-5에 명세만, Phase 1-4 T-5에 휴리스틱(heading depth + 길이) 1차 구현 → 추후 LLM 보강 |

## §7 Handoff 체인 (AutoCycle)

각 sub-phase 종료 시 `phase-1-X-status.md`의 `next_prompt_suggestion` 필드에 다음 sub-phase 진입 명령을 자동 기재한다. CHAIN-13(직전 3 Phase 기억)이 자동 로딩된다.

### Phase 1-1 진입 (handoff #0 — 본 응답에서 직접 작성)

**다음 세션이 본 master-plan 수신 후 이어서 실행할 명령**:

```
Phase 1-1을 시작한다.

1. 0-entrypoint.md 리로드 (FRESH-1)
2. docs/phases/phase-1-1/phase-1-1-status.md 읽기 (ENTRY-1)
3. docs/phases/phase-1-master-plan.md, phase-1-exceptions.md 컨텍스트 로드
4. current_state: IDLE → TEAM_SETUP 전이
5. backend-dev (general-purpose/sonnet) + verifier (Explore/sonnet) 2명 스폰 (tester 비스폰 — E-4)
6. tasks/ 의 5개 task를 backend-dev에게 할당
7. 사용자 sudo 필요한 T-1은 사용자에게 `! obsidian register` 안내
```

### Phase 1-N → 1-(N+1) 전이 규칙

각 sub-phase status.md 완료 시 다음 형식 사용:

```yaml
next_prompt_suggestion: |
  Phase 1-(N+1)을 시작한다. 이전 Phase 산출물:
  - phase-1-(N)/reports/...
  - 핵심 결과: ...
  진입 절차: 위 Phase 1-1 기준 동일.
```

## §8 산출물 요약 (Phase 1 전체)

| 카테고리 | 파일/디렉터리 |
|---|---|
| Phase 문서 | `docs/phases/phase-1-master-plan.md` (본 문서), `phase-1-exceptions.md`, `phase-1-pre-analysis.md`, `phase-1-final-summary-report.md` |
| Sub-phase 산출물 | `docs/phases/phase-1-1/` ~ `phase-1-6/` 각 4종 (status/plan/todo-list/tasks) |
| Vault | `wiki/` (모든 폴더 + `.obsidian/` + 시드 5건 + MOC 12+ + 가이드 3건) |
| 자동화 | `scripts/wiki/wiki.py`, `scripts/wiki/lib/*.py`, `scripts/wiki/skill_bridge.py`, `scripts/wiki/README.md` |
| Skill | `.claude/skills/wiki-create-note/`, `wiki-link-suggest/`, `wiki-moc-update/` |
| NOTIFY wrapper | `scripts/pmAuto/notify_wiki.sh` (E-3 prefix 적용) |

## §9 종료 조건 (Phase 1 DONE)

- [x] Phase 1-1 ~ 1-6 모두 DONE
- [x] G2_wiki + wiki-validation 전체 PASS
- [x] master-final-report 작성
- [x] 시드 노트 5건 작성
- [x] CLI 4 명령 동작
- [x] SSOT skill 어댑터 3종 동작
- [x] `[PAB-Wiki]` 텔레그램 알림 발송 완료 (각 sub-phase + 최종)
- [x] `phase-1-exceptions.md` status: ARCHIVED 전이

---

**작성**: Team Lead (메인 세션) | **승인**: 사용자 (2026-05-01) | **다음 단계**: Phase 1-1 entry artifacts 생성 → handoff
