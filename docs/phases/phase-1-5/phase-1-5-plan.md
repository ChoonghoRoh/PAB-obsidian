# Phase 1-5 Plan — `/pab:wiki` SSOT skill 어댑터 (REWORK rev.2)

> **본질 (잃지 말 것 — `phase-1-5-intent.md`)**:
> 1. 원본 immutable 보존 (`wiki/15_Sources/`)
> 2. LLM 요약본 (`wiki/10_Notes/`)
> 3. TOC 양방향 링크
> 4. 두 산출물 동시 생성
> 5. Karpathy 3계층 아키텍처 충족

## §1 목표 (정정)

`/pab:wiki <자연어 입력>` 1회 호출 → **원본 + 요약본 두 파일 동시 생성** + TOC anchor 양방향 링크.

호출 예시:
```
/pab:wiki https://gist.github.com/karpathy/... 내용을 읽고 정리해줘.
```

**산출**:
1. `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` — 원문 텍스트 (immutable)
2. `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` — LLM 요약본, 각 H2 섹션에 원본 anchor 링크

## §2 범위

**포함 (REWORK 추가)**:
- 신규 TYPE `SOURCE` (`wiki/40_Templates/SOURCE.md` + `_schema.json` 8 TYPE)
- 신규 폴더 `wiki/15_Sources/` (`naming-convention.md` 폴더 prefix 추가)
- TYPE MOC `wiki/00_MOC/TYPES/SOURCE.md`
- SKILL.md §3 처리 절차 — Step 8a (원본 저장) 추가, Step 6 (TOC 링크 자동 삽입) 보강
- 기존 노트 재생성 (Karpathy 글) — 백업 후 신규 SKILL로 한 쌍 생성
- `frontmatter-spec.md` TYPE 표 갱신
- 검증 절차 — 본질 5항목 강제 + cross-model + auditor mode

**제외 (`phase-1-5-intent.md` 비목표)**:
- ❌ 다중 SKILL 분리 / skill_bridge.py / JSON 프로토콜
- ❌ Type A/B 패턴 일반화 (nexus 별건)
- ❌ `/pab:report`, `/pab:research` (별건)
- ❌ 옵션 driven CLI 모드
- ❌ 이미지/PDF 자동 다운로드 (별건)

## §3 본질 통찰 (REWORK 트리거)

v1 검증에서 사용자 통찰:
> "Karpathy 패턴 자체가 원본 출처(immutable) + 위키(LLM 유지) 분리인데, 우리 SKILL.md는 위키 한쪽만 만들고 원본을 안 보존했다 — 본질 누락"

손실률 편차 (v1 검증 결과):
- 아키텍처 표 보존: 90%
- 핵심 주장 인용: 80%
- 운영 모드 절차: 40%
- **팁&트릭 실행 절차: 20%** (재현 불가)
- 모듈식 사용 안내: 0%

→ **결정**: 원본 보존을 본질로 격상. 항상 원본+요약 두 산출물.

## §4 산출물 (전체)

### 신규
| 파일 | 위상 | T |
|---|---|---|
| `wiki/40_Templates/SOURCE.md` | 신규 TYPE 템플릿 | T-5 |
| `wiki/00_MOC/TYPES/SOURCE.md` | TYPE MOC 노트 | T-5 |
| `wiki/15_Sources/` | 폴더 신설 | T-5 |
| `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` | 원본 보존 | T-6 |

### 갱신
| 파일 | 변경 | T |
|---|---|---|
| `skills/wiki/SKILL.md` | §2 옵시디언 규격에 SOURCE TYPE/15_Sources 추가, §3 Step 8a 신설, Step 6에 TOC 링크 자동 삽입, §4 nexus 이전 가이드 갱신 | T-2 |
| `wiki/40_Templates/_schema.json` | TYPE enum 7 → 8 (`SOURCE` 추가) | T-5 |
| `wiki/30_Constraints/frontmatter-spec.md` | TYPE별 frontmatter 차이 표에 SOURCE 추가 | T-5 |
| `wiki/30_Constraints/naming-convention.md` | 폴더 prefix 표에 `15_` Sources 추가 | T-5 |
| `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` | 재생성 (각 H2 섹션에 원본 anchor 링크) | T-6 |

## §5 Task 분해 (6개)

| Task | 도메인 | 담당 | 의존 | 산출 | 상태 |
|---|---|---|---|---|---|
| T-1 | [BE] | backend-dev | — | `.claude-plugin/plugin.json` + `skills/wiki/` | ✅ DONE |
| T-2 | [BE] | backend-dev | T-5 | `skills/wiki/SKILL.md` v2 — SOURCE 처리 + Step 8a + TOC 링크 | 🔄 REWORK |
| T-3 | [TEST] | verifier | T-2, T-6 | G2_wiki 재검증 — **본질 5항목 + Hard 9 + Soft 6 + auditor mode** | 🔄 REWORK |
| T-4 | [BE] | backend-dev | — | `.claude/CLAUDE.md` plugin 안내 | ✅ DONE |
| **T-5** (신규) | [BE] | backend-dev | — | vault 확장 — SOURCE TYPE 정의 + 15_Sources 폴더 + 4 파일 갱신 | 🆕 |
| **T-6** (신규) | [BE] | backend-dev | T-2, T-5 | 기존 노트 백업 + 신규 SKILL로 재생성 (원본+요약 한 쌍) | 🆕 |

**역할 매핑 검증 (HR-6 ASSIGN-1~5)**:
- T-1, T-2, T-4, T-5, T-6: `[BE]` → backend-dev ✅
- T-3: `[TEST]` → verifier ✅ (cross-model: backend-dev=sonnet vs verifier=opus)

## §6 게이트 (정정)

- **G0**: SKIP
- **G1**: PASS (본 plan + 6 task)
- **G2_wiki_v1**: PASS_PARTIAL (REWORK 트리거)
- **G2_wiki**: pending — 다음 *모두* PASS 필요
  - **본질 5항목** (intent.md): 모두 ✓ (FAIL 1건이라도 G2_wiki FAIL)
  - Hard Match 9항목 (baseline §11.1) — 단, baseline 갱신: TYPE/index 그대로, sources에 원본 wikilink 추가, slug 동일
  - Soft Match 6항목 (baseline §11.2) — 섹션 수 5~12로 완화
  - **두 파일 모두 schema PASS**: 원본 SOURCE TYPE schema + 요약본 RESEARCH_NOTE schema
  - **TOC 링크 검증**: 요약본 각 H2 섹션 직후 anchor 링크 존재 + 원본 anchor가 실제 헤더와 일치
- **G3**: SKIP (E-4)
- **G4**: pending

## §7 리스크 (정정)

| ID | 리스크 | 완화 |
|---|---|---|
| R-1 | 원본 보존 시 분량 ↑ → R-3(파일 500줄) 위반 가능 | 원본은 데이터 파일이므로 R-3 적용 제외 (코드/문서 한계 ≠ 자료 보존). 매우 큰 원문은 `_attachments/` 임베드 검토 |
| R-2 | TOC anchor 충돌 — 옵시디언 anchor 슬러그화 (공백→하이픈) | 원본 헤더와 요약본 anchor를 정규화 함수로 일치시킴 (SKILL.md §Step 6에 명시) |
| R-3 | 신규 TYPE `SOURCE`로 schema/MOC 갱신 시 기존 노트 영향 | 기존 6 TYPE 유지, SOURCE는 *추가*만 — 기존 노트 영향 없음 |
| R-4 | 본질 5항목 중 1건 FAIL 시 G2_wiki FAIL — 도미노 발생 | Chapter end 리마인드로 사전 검증, FAIL 즉시 정정 후 다음 단계 |

## §8 nexus 이전 가이드 (갱신)

복사 대상 (4개):
1. `.claude-plugin/plugin.json`
2. `skills/wiki/SKILL.md` (v2)
3. `wiki/30_Constraints/{frontmatter-spec,naming-convention}.md`
4. `wiki/40_Templates/SOURCE.md` + `_schema.json`

이전 시 vault 구조 동기화: `wiki/15_Sources/`, `wiki/00_MOC/TYPES/SOURCE.md` 폴더/파일 신설.

## §9 Chapter end 리마인드 (강제)

매 Task 완료 시 Team Lead가 본 표를 status.md에 추가:

| 본질 | 이번 chapter? | 근거 |
|---|---|---|
| 1. 원본 immutable 보존 | ✓/✗ | ... |
| 2. LLM 요약본 | ✓/✗ | ... |
| 3. TOC 양방향 링크 | ✓/✗ | ... |
| 4. 두 산출물 동시 생성 | ✓/✗ | ... |
| 5. Karpathy 3계층 충족 | ✓/✗ | ... |

✗ 1건이라도 발생 시 즉시 정정. 다음 Task 진입 금지.
