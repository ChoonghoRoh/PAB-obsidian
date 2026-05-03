# Phase 1-4 Verifier 검증 보고서 (G2_wiki)

| 항목 | 값 |
|---|---|
| 작성자 | verifier (opus) |
| 게이트 | G2_wiki (E-1) + G3 wiki-validation 통합 (E-4) |
| 검증 시각 | 1차 2026-05-02 09:37~09:45, 재검증 09:55 KST |
| 산출물 commit 기준 | hotfix FIX-1/2/3 → 재검증 후 hotfix2 FIX-4/5/6 적용 |
| 종합 판정 | **PASS** (재검증 후 갱신) — Critical 0 / High 0 / Low 0 |

---

## 1. 산출물 줄 수 / R-4 / REFACTOR-1 가드

| 파일 | 줄 수 | R-4 권고 | R-4 한계 | REFACTOR-1 (500) | 결과 |
|---|---:|---:|---:|---:|---|
| scripts/wiki/wiki.py | 152 | (200) | — | 500 | ✓ |
| scripts/wiki/lib/frontmatter.py | 134 | 250 | 400 | 500 | ✓ |
| scripts/wiki/lib/validate.py | 192 | 250 | 400 | 500 | ✓ |
| scripts/wiki/lib/moc.py | 177 | 250 | 400 | 500 | ✓ |
| scripts/wiki/lib/toc.py | 200 | 250 | 400 | 500 | ✓ |
| scripts/wiki/README.md | 138 | 250 | — | — | ✓ |
| Makefile | 19 | — | — | — | ✓ |

- **R-4 PASS**: lib 4개 모두 250줄 미만, 한계 400 / REFACTOR 500 모두 안전
- **REFACTOR-1 사전 스캔**: 500줄 초과 0건 → 레지스트리 등록 불필요

---

## 2. T-1 — 4 subcommand `--help` + lib import

| 항목 | 결과 |
|---|---|
| `wiki --help` (root) | ✓ subcommand 4개 노출, 옵션(--vault/--quiet/--json) 정상 |
| `wiki new --help` | ✓ TYPE 6 choice + slug + --dry-run |
| `wiki link-check --help` | ✓ --full 옵션 |
| `wiki moc-build --help` | ✓ --dry-run + --topic-threshold N |
| `wiki toc-suggest --help` | ✓ --max-depth + --threshold + --llm + --format {markdown,json} |
| wiki.py 본체 < 200줄 | ✓ 152 |
| `from scripts.wiki.lib import frontmatter, validate, moc, toc` | ✓ ImportError 없음 |

**T-1 PASS**.

---

## 3. T-2 — `wiki new <TYPE> <slug> --dry-run` (6 TYPE)

6 TYPE 모두 11필드 자동 채움 정상. naming-convention 일치 (`YYYY-MM-DD_<slug>.md`).

| TYPE | 출력 경로 | 11필드 | tags 기본값 |
|---|---|---|---|
| RESEARCH_NOTE | wiki/10_Notes/2026-05-02_verifier-test.md | ✓ | research-note |
| CONCEPT | wiki/10_Notes/2026-05-02_verifier-test.md | ✓ | concept |
| LESSON | wiki/10_Notes/2026-05-02_verifier-test.md | ✓ | lesson |
| PROJECT | wiki/10_Notes/2026-05-02_verifier-test.md | ✓ | project |
| DAILY | wiki/99_Inbox/2026-05-02_verifier-test.md | ✓ | daily |
| REFERENCE | wiki/10_Notes/2026-05-02_verifier-test.md | ✓ | reference |

11필드 확인: `aliases, created, description, index, keywords, sources, tags, title, topics, type, updated` — 정확히 11. `created/updated` `YYYY-MM-DD HH:MM`, `type "[[TYPE]]"`, `index "[[ROOT]]"`, `title` slug → Title-case (`verifier-test` → `Verifier Test`).

**T-2 PASS**.

---

## 4. T-3 — `wiki link-check`

| 케이스 | 결과 | exit | 상태 |
|---|---|---:|---|
| 빈 vault (`/tmp/pab-empty-vault/wiki/` 빈 폴더) | `PASS (empty vault)` | 0 | ✓ |
| 기존 vault (실 PAB-obsidian, obsidian CLI 활성) | `PASS (notes=19, violations=0, broken=0, orphans=0)` | 0 | ✓ |
| schema strict 위반 (실 vault) | 0건 | — | ✓ |
| 가상 broken 1건 (fallback 경로) | `FAIL (broken=1) [BROKEN] [[NonexistentTarget]]` | 1 | ✓ |

**T-3 PASS** — exit 코드/등급 모두 명세 일치.

다만 **HI-1 (별도 항목 §8.1)**: fallback 정규식 규약이 path-style wikilink를 처리하지 못함. 정상 흐름(obsidian 활성)에서는 영향 없으나 obsidian-미설치 환경 fallback 시 false-positive 19건 발생.

---

## 5. T-4 — `wiki moc-build`

| 항목 | 결과 |
|---|---|
| dry-run 1회차 출력 | TYPES 6 + DOMAINS 6 = 12 MOC 인식, REFERENCE.md 4건 갱신 예정, 0건 변경 |
| dry-run 2회차 출력 | 1회차와 100% 동일 (idempotent ✓) |
| 13 MOC vs 12 MOC | TYPES/_README는 hotfix FIX-3로 갱신 대상에서 제외. 코드는 TYPES 6 + DOMAINS 6만 순회하므로 `total_moc = 12`. 13개 정의 자체는 README/CLI help 텍스트에만 남아 있음 (LI-1) |
| TOPIC 승격 N=3 가상 케이스 | seed 3건 (`topics: ["[[VirtualTopic]]"]`) 작성 후 `moc-build --dry-run`: `[dry-run] TOPIC 승격 예정: VirtualTopic (3건)` ✓<br>실행: `[OK] TOPIC 승격: VirtualTopic → wiki/00_MOC/TOPICS/VirtualTopic.md` ✓ |
| 승격된 TOPIC MOC 검증 | frontmatter (`type: [[REFERENCE]]`, `index: [[ROOT]]`, `tags: [moc, topics/virtualtopic]`) + Dataview 쿼리 + 폴백 정적 링크 (3건, marker 포함) ✓ |
| 정리 | /tmp 시드 디렉토리 삭제 완료 |

**T-4 PASS**.

---

## 6. T-5 — `wiki toc-suggest --format json`

대상: `wiki/30_Constraints/toc-recommendation.md`

출력 JSON 키 (toc-recommendation.md §출력 JSON 스키마 대조):

| 명세 키 | 출력 | 일치 |
|---|---|---|
| `flatness` ("too_flat\|too_deep\|ok") | `"ok"` | ✓ |
| `max_depth_seen` (integer) | `3` | ✓ |
| `suggestions[].level` | int (1~3) | ✓ |
| `suggestions[].text` | str | ✓ |
| `suggestions[].lines` | int | ✓ |
| `suggestions[].suggestion` ("keep\|split\|merge") | keep/merge 혼합 | ✓ |

스키마 100% 일치 — additionalProperties 없음, 누락 키 없음.

**T-5 PASS**.

---

## 7. T-6 — Makefile + README

| 항목 | 결과 |
|---|---|
| `make wiki-link-check` | `PASS (notes=19, violations=0, broken=0, orphans=0)` exit=0 ✓ |
| `make wiki-new` (TYPE/SLUG 누락) | `Usage: make wiki-new TYPE=... SLUG=...` exit=2 ✓ |
| `make wiki-toc-suggest` (NOTE 누락) | `Usage: make wiki-toc-suggest NOTE=...` exit=2 ✓ |
| README.md `## 4 명령` 하 H3 4건 | `### wiki new`, `### wiki link-check`, `### wiki moc-build`, `### wiki toc-suggest` (4건 정확) ✓ |
| README.md H2 섹션 (참고) | 6개 (개요·의존성·디렉토리 구조·4 명령·트러블슈팅·SSOT 통합) — "4 섹션 존재" 요구는 4 명령 H3 기준으로 충족 |

**T-6 PASS**.

---

## 8. Hotfix 영향 검증

### 8.1 FIX-1 — `WIKILINK_WHITELIST`에 `TOC` 추가

- 위치: `lib/validate.py:17` `WIKILINK_WHITELIST = {"ROOT", "MOC", "CONSTRAINTS", "TYPES", "DOMAINS", "TOPICS", "TOC"}`
- 검증: `wiki/30_Constraints/toc-recommendation.md` frontmatter `topics: ["[[TOC]]", "[[CONSTRAINTS]]"]` → 두 항목 모두 화이트리스트로 broken 판정 제외 ✓
- **Team Lead 질문**: 향후 진짜 broken `[[TOC_X]]` 누락 가능성? → **부정 (위험 없음)**. WHITELIST는 정확 매칭(set membership), `TOC_NEW`/`TOC_X` 등 prefix 변형은 매칭되지 않음. `[[TOC]]` 단일 식별자만 통과.

### 8.2 FIX-2 — `_extract_wikilink_targets` (frontmatter + fenced + inline 제외)

- 위치: `lib/validate.py:63~82`
- 코드 검토: `in_frontmatter` 토글 (line 0 `---`~`---`), `in_code_block` 토글 (\`\`\` lstrip 매칭), `INLINE_CODE_RE.sub("", line)` 제거 후 wikilink 캡처 — 3중 제외 적용 ✓
- 적용 범위: fallback 경로 (`find_unresolved_links_fallback`) + obsidian 교차필터 (`find_unresolved_links_obsidian` line 101) 양쪽 동일 ✓
- 인위 픽스처 검증: `[[NonexistentTarget]]` (본문 + frontmatter 외부) → fallback에서 broken=1 검출 (PATH 차단 후) ✓

### 8.3 FIX-3 — `TOPICS/_README.md` 갱신 제외

- 위치: `lib/moc.py:156~157` 명시적 주석 (placeholder 명세 노트)
- 코드 검토: `_process_moc(...)` 호출이 TYPES 6 + DOMAINS 6 = 12회만 실행. TOPICS/_README 호출 없음 ✓
- 결과: `total_moc = 12` (README/help 텍스트의 "13 MOC" 표기와 불일치 — LI-1)
- 의도: Phase 1-3 산출물 보존 + idempotent 보장. 적절한 처리 ✓

---

## 9. Issue 분류

### Critical (FAIL 사유)
**0건**.

### High (PARTIAL 사유)

#### HI-1 — fallback 정규식이 path-style wikilink를 인식하지 못함

- **현상**: `obsidian` CLI 비활성 환경 fallback 경로에서 path-style wikilink (`[[00_MOC/TYPES/RESEARCH_NOTE|RESEARCH_NOTE]]` 등)이 모두 broken으로 오탐
- **재현**: `PATH=/tmp/fake-obsidian-exit1:$PATH python3 scripts/wiki/wiki.py link-check` → `FAIL broken=19` (실제로는 모두 정상 link)
- **원인**: `find_unresolved_links_fallback`이 `WIKILINK_RE` 캡처값(`00_MOC/TYPES/RESEARCH_NOTE`)을 `note.stem`(`RESEARCH_NOTE`)과 비교 → path 부분 때문에 매칭 실패
- **영향 범위**:
  - 실 운용 (`obsidian` 활성): **무영향** (위 검증 케이스에서 PASS 확인)
  - CI 환경에서 obsidian 미설치 시: 19건 false-positive로 wiki link-check가 항상 FAIL → CI 진행 불가
- **권고 수정 방향** (코드 미수정, 정보 제공만):
  1. fallback 측 `target.split("/")[-1]`로 basename 비교 추가, 또는
  2. fallback 측에서 `notes`의 path 정보(`vault 상대경로`)를 모두 stems와 함께 비교 셋에 포함, 또는
  3. CI에 obsidian CLI 설치 강제 + fallback은 로컬 보조용으로 명시
- **G2_wiki 등급 기준 적용**: "Makefile 인자 검증 미흡"과 동일 카테고리(High PARTIAL — 운용 시점 robustness 결함). Phase 1-5/1-6 중 하나에서 보정 권장.

### Low (정보성)

#### LI-1 — 13 MOC vs 12 MOC 텍스트 불일치
- `wiki.py:107` help 텍스트: "13 MOC 폴백 정적 링크 idempotent 갱신"
- `README.md:80`: "13 MOC(`TYPES/` 6 + `DOMAINS/` 6 + `TOPICS/_README` 1)"
- runtime 출력: `[dry-run] 총 12 MOC 인식`
- **권고**: help/README 텍스트를 "12 MOC + TOPICS/_README placeholder는 갱신 제외"로 정정 또는 출력에서 13(_README skip)로 카운팅 일치.

#### LI-2 — DAILY 노트 라우팅 위치
- T-2 검증 결과 DAILY는 `wiki/99_Inbox/`로 출력. 명세상 `wiki/10_Notes`와 분리된 의도 (Inbox = 일기/메모 임시 저장) — 코드 의도 일치 ✓
- 단 README §wiki new 표에 DAILY → `wiki/99_Inbox` 라우팅 명시가 누락. 테이블 1줄 보강 권고.

---

## 10. 종합 판정

| 등급 | 판정 |
|---|---|
| **PARTIAL** | **PASS with reservation** |

**판정 근거**:
- T-1~T-6 모두 명세 통과, schema strict 위반 0건, idempotent + TOPIC 승격 동작 확인
- R-4 (250 권고 / 400 한계) 모두 안전, REFACTOR-1 (500) 0건 등록
- hotfix FIX-1/2/3 모두 코드+동작 양쪽으로 검증 완료
- HI-1 fallback robustness 결함은 **현행 운용(obsidian 활성)에서 무영향**, CI 도입 시점에 보정 필요 → DONE 전이는 가능, 후속 조치 권고

**Team Lead 결정 권고**:
1. **DONE 전이 진행** (PARTIAL 등급) — HI-1은 Phase 1-5/1-6에서 fallback 강화 또는 CI obsidian 강제 도입으로 후속 처리
2. LI-1 (13 vs 12 MOC) / LI-2 (DAILY 라우팅 표기)는 backend-dev에 1줄 패치 위임 가능 (선택)

이상으로 G2_wiki + G3 wiki-validation 통합 검증 1차 종료. team-lead에게 종합 판정 보고 후 LIFECYCLE-2 대기.

---

## 11. 재검증 (hotfix2: FIX-4/5/6 적용 후)

### 11.1 R-4 재확인

| 파일 | hotfix2 후 | 한계 | 결과 |
|---|---:|---:|---|
| scripts/wiki/wiki.py | 152 | 200 | ✓ |
| scripts/wiki/lib/validate.py | 202 (191 → 202, +10) | 250 | ✓ |
| scripts/wiki/lib/frontmatter.py | 134 | 250 | ✓ |
| scripts/wiki/lib/moc.py | 177 | 250 | ✓ |
| scripts/wiki/lib/toc.py | 200 | 250 | ✓ |
| scripts/wiki/README.md | 145 (138 → 145, +7) | 250 | ✓ |
| Makefile | 19 | — | ✓ |

모두 한계 안전. 500줄 미만 (REFACTOR-1 등록 불필요).

### 11.2 HI-1 재검증 (FIX-4 — fallback basename 비교)

- 코드 검토: `lib/validate.py:112~131` `find_unresolved_links_fallback` — `basename = target.split("/")[-1].split("|")[0].split("#")[0].strip()` 적용 후 stem/whitelist 매칭 ✓
- 동작 검증: `PATH=/tmp/fake-obsidian-exit1:$PATH python3 scripts/wiki/wiki.py link-check` (obsidian CLI 강제 None) → `PASS (notes=19, violations=0, broken=0, orphans=0)` exit=0
- 1차 결과 19건 false-positive 모두 해소. path-style `[[00_MOC/TYPES/RESEARCH_NOTE|RESEARCH_NOTE]]` / heading-anchor `[[A#section]]` 모두 정상 처리.
- **HI-1 종결**: ✓

### 11.3 LI-1 재검증 (FIX-5 — 13 MOC → 12 MOC 일관)

- `grep -rn "13 MOC" scripts/wiki/ Makefile` → **잔존 0건** ✓
- `wiki.py:107` argparse help: `"12 MOC 폴백 정적 링크 idempotent 갱신 + TOPIC 승격 (N≥threshold)"` ✓
- `README.md:87`: `12 MOC(TYPES/ 6 + DOMAINS/ 6)의 ... TOPICS/_README.md는 명세 노트이므로 제외` ✓
- runtime 출력: `[dry-run] 총 12 MOC 인식, 실제 변경 없음` ✓
- **LI-1 종결**: ✓

### 11.4 LI-2 재검증 (FIX-6 — DAILY 라우팅 매트릭스)

- `README.md:44~49` 신규 매트릭스:
  - `RESEARCH_NOTE / CONCEPT / LESSON / PROJECT / REFERENCE` → `wiki/10_Notes/`
  - `DAILY` → `wiki/99_Inbox/`
- 6 TYPE 모두 명시, 라우팅 분기 정확 ✓
- **LI-2 종결**: ✓

### 11.5 회귀 영향 확인

| 명령 | 결과 | 회귀 |
|---|---|---|
| `wiki link-check` (obsidian 활성) | `PASS (notes=19, violations=0, broken=0, orphans=0)` exit=0 | 없음 ✓ |
| `wiki link-check` (fallback only) | `PASS (notes=19, ...)` exit=0 | **HI-1 해소** ✓ |
| `wiki moc-build --dry-run` | 12 MOC, REFERENCE 4건, exit=0 | 없음 ✓ |
| `wiki toc-suggest --format json` | flatness/max_depth_seen/suggestions 정상 출력 | 없음 ✓ |

### 11.6 종합 판정 갱신

| 분류 | 1차 | 재검증 후 |
|---|---|---|
| Critical | 0 | **0** |
| High | 1 (HI-1) | **0** |
| Low | 2 (LI-1/LI-2) | **0** |
| **종합** | PARTIAL | **PASS** ✓ |

G2_wiki + G3 wiki-validation **PASS** — DONE 전이 가능. NOTIFY-1 (Telegram 발송) 후 Phase 1-4 종료 권고.
