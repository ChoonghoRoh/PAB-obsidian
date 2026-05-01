---
phase: "1"
type: pre-analysis
created: 2026-05-01
ssot_version: 8.0-renewal-6th
initiator: user
status: APPROVED
---

# Phase 1 사전 분석 — Obsidian Karpathy-style Wiki 환경 구축

## §1 사용자 원본 요청 (Raw Input — 수정 금지)

> 옵시디언 cli 환경 세팅 해줘. 그리고 안드레이카파시의 llm wiki 방식을 이용한 옵시디언 .md 파일 환경 구축을 진행해줘. 각 .md 파일을 링크 할 수 있는 추천해주고, .md 파일 메타 데이터는 docs > data > wiki-doc-meta-sample.jpeg 파일을 참고해줘. wiki를 나눌 때는 TOC 방식을 사용했으면해. 전반적인 내용이 정리되면 plan 문서를 만들고 현재 ssot 규정에 맞춰서 개발 진행해줘. handoff 로 진행해주고, 문제가 되는 부분은 권장사항으로 진행 진행 전 감사 부분을 체크해서 꼼꼼하게 진행해줘.

## §2 의사결정 5건 (감사 라운드)

| # | 결정 사항 | 사용자 답변 |
|---|---|---|
| D-1 | SSOT 적용 범위 | **본 프로젝트는 Obsidian 환경이므로 SSOT의 코드 규칙(G2_be/G2_fe/HR-5) 비적용** |
| D-2 | CLI 도구 선택 | **Obsidian 공식 CLI** (https://obsidian.md/cli) 사용. 향후 SSOT skill로 문서 전달 + .md 별도 제작 기능 구현 |
| D-3 | TOC 구조 | 노트 저장 시 **읽기 좋은 TOC 자동 추천** 기능 포함 |
| D-4 | Phase 분할 | 코드 task 구분 용이한 단위. 5단계 권장이면 5단계, 더 쪼개도 OK → **6 sub-phase 채택** |
| D-5 | SSOT 변형 처리 | **SSOT 본체 무수정**. 본 프로젝트만 `phase-1-exceptions.md`에 예외 등록 |

## §3 수집 자료

### 3.1 Obsidian 공식 CLI 스펙 (출처: https://obsidian.md/cli)

| 항목 | 내용 |
|---|---|
| **태그라인** | "Anything you can do in Obsidian you can do from the command line." |
| **설치 (macOS)** | (1) Obsidian 설치 → (2) Settings → General → Enable CLI → (3) `/usr/local/bin/obsidian` 심볼릭 링크 자동 생성(admin 권한) |
| **Basics 명령** | `daily`, `daily:append`, `search`, `read`, `tasks`, `create`, `tags`, `diff` |
| **Developer 명령** | `devtools`, `plugin:reload`, `dev:screenshot`, `eval`, `dev:errors`, `dev:css`, `dev:dom` |
| **Automation 명령** | `files`, `unresolved` |

**핵심 활용처(본 프로젝트 매핑)**:
- `obsidian create` → 노트 자동 생성 (시드/템플릿 적용)
- `obsidian eval` → JS 실행 → Obsidian API 활용 → TOC 추천·MOC 빌드
- `obsidian unresolved` → broken wikilink 검출 → G2_wiki 게이트
- `obsidian files` → vault 파일 enumeration → 검증·통계
- `obsidian search`/`tags` → CLI에서 vault 질의 (skill 인터페이스 기반)

### 3.2 Karpathy LLM-wiki 방식 핵심

| 원칙 | 본 프로젝트 적용 |
|---|---|
| 시간순 파일명 `YYYY-MM-DD_topic.md` | 채택. `obsidian create` + 템플릿 |
| 풍부한 frontmatter (LLM 인덱싱) | 채택. 스크린샷 기준 11개 필드 |
| Wikilink 폭증 → 그래프 형성 | 채택. `type`/`index`/`topics` 자동 + 본문 수동 |
| Index/MOC 노트 = TOC | 채택. 3중 인덱스 (TYPES/DOMAINS/TOPICS) |
| 소스 트래킹 | 채택. `sources:` 필드 |
| 폴더는 컨테이너, 분류는 프론트매터 | 채택. PARA 변형 폴더 |

### 3.3 Frontmatter 스키마 (스크린샷 추출)

11개 필드: `title`, `description`, `created`, `updated`, `type`, `index`, `topics`, `tags`, `keywords`, `sources` + (alias 추가 권장)

### 3.4 폴더 구조 (PARA 변형)

```
wiki/
├── _INDEX.md                  ← 최상위 MOC
├── 00_MOC/                    ← TYPES/DOMAINS/TOPICS MOC
├── 10_Notes/                  ← 실제 노트 (YYYY-MM-DD_*.md)
├── 20_Lessons/                ← 정제된 교훈
├── 30_Constraints/            ← 규약·제약
├── 40_Templates/              ← Templater 템플릿
└── 99_Inbox/                  ← 미분류
```

## §4 PROMPT-QUALITY 5항목 판정

| 항목 | 판정 | 근거 |
|---|---|---|
| 완전성 | PASS | 5건 의사결정으로 모호성 해소 |
| 명료성 | PASS | "Karpathy 방식" + "스크린샷 메타" + "TOC" + "handoff" 구체 명시 |
| 실행 가능성 | PASS | Obsidian CLI 스펙 확인 완료, 기술 리스크 낮음 |
| 범위 적정성 | PASS | 6 sub-phase로 분할, 단일 master-plan 적정 규모 |
| 트리아지 | **즉시 진행** | handoff 모드로 phase-1-1부터 자동 진입 |

## §5 마스터 플랜 진입 준비

### 5.1 KPI 초안

| KPI | 목표 |
|---|---|
| Vault 초기화 완료 | Phase 1-1 종료 시 프로젝트 루트 `.obsidian/` 존재, `obsidian` CLI 명령 동작 (vault.path=프로젝트 루트) |
| Frontmatter 스키마 | 11필드 + alias, 모든 시드 노트 100% 준수 |
| MOC 시스템 | TYPES(6) + DOMAINS(6) + TOPICS(가변) MOC 자동 생성 |
| CLI 자동화 명령 | `wiki new`/`link-check`/`moc-build`/`toc-suggest` 4종 동작 |
| 시드 노트 | 5건 (스크린샷 LangChain 노트 포함) |
| G2_wiki 통과 | broken link 0, frontmatter 필수필드 100%, 파일명 규약 100% |

### 5.2 리스크

| # | 리스크 | 완화 |
|---|---|---|
| R-1 | Obsidian 공식 CLI macOS sudo 권한 필요 | Phase 1-1 §1에서 사용자 직접 실행 안내 (`! sudo obsidian register` 등) |
| R-2 | `obsidian eval` JS API 명세 부족 | Phase 1-1에서 `obsidian devtools`로 API 실측 |
| R-3 | Templater 플러그인 의존성 | Phase 1-2에서 Templater 미설치 시 frontmatter 정적 템플릿으로 fallback |
| R-4 | NOTIFY-1 prefix `[PAB-v3]`이 본 프로젝트와 불일치 | E-3 예외 등록 — `[PAB-Wiki]` prefix 사용 |

## §6 SSOT 적용·예외 매트릭스

| SSOT 규칙 | 적용 | 예외 ID |
|---|---|---|
| HR-1 (Team Lead 코드 수정 금지) | 적용 | — |
| HR-2 (Phase 산출물 4종) | 적용 | — |
| HR-3 (컨텍스트 복구 SSOT 리로드) | 적용 | — |
| HR-4 (Phase 문서 경로) | 적용 | — |
| HR-5 (코드 500/700줄) | **비적용** | E-2 (.md 노트 400줄로 대체) |
| HR-6 (Task 도메인-역할) | 적용 (도메인은 wiki-* 4종) | 부분 |
| HR-7 (에이전트 라이프사이클) | 적용 | — |
| HR-8 (Telegram 알림) | 적용 (prefix 변경) | E-3 (`[PAB-Wiki]`) |
| G0 (Research Review) | 적용 | — |
| G1 (Plan Review) | 적용 | — |
| G2_be / G2_fe | **비적용** | E-1 |
| **G2_wiki** (신규) | 적용 | — (예외 아닌 신설) |
| G3 (pytest) | **비적용** | E-4 (wiki-validation으로 대체) |
| G4 (최종) | 적용 (G2_wiki + wiki-validation) | — |
| FRESH-1~12 | 적용 | — |
| ENTRY-1~5 | 적용 | — |
| AutoCycle handoff | 적용 | — |

## §7 Next Step

- [x] 사용자 답변 5건 수신 → §2 정리
- [x] Obsidian CLI 스펙 확인 → §3.1 정리
- [ ] **Master Plan 작성** (`phase-1-master-plan.md`)
- [ ] **예외 등록 문서 작성** (`phase-1-exceptions.md`)
- [ ] **Phase 1-1 entry 산출물** (status/plan/todo-list/tasks)
- [ ] **handoff next_prompt_suggestion** master-plan에 기재

---

**작성**: Team Lead (메인 세션) | **승인**: 사용자 (2026-05-01) | **다음 단계**: Phase 1-1 BUILDING 진입 (handoff)
