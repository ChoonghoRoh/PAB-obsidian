# `/pab:wiki` 이식 가이드

> 본 skill을 다른 프로젝트(nexus, 다른 vault, 다른 도구)로 옮길 때의 표준 절차.

---

## 0. 이식 후 *반드시* 유지해야 할 본질 5항목

이식 후 첫 호출에서 다음을 검증한다. 1건이라도 ✗면 이식 미완성:

1. **원본 immutable 보존** — 대상 vault에 SOURCE 폴더 + `type: "[[SOURCE]]"` + 변경 금지
2. **LLM 요약본** — 대상 vault Notes 폴더 + 기존 TYPE
3. **TOC 양방향 링크** — 요약본 각 H2 직후 원본 anchor 링크
4. **두 산출물 동시 생성** — 1회 호출 → 원본+요약 두 파일 (`created` 같은 분)
5. **Karpathy 3계층 충족** — 원본 출처 / 위키 / 스키마 폴더-파일 분리

상세: 원본 프로젝트의 `docs/phases/phase-1-5/phase-1-5-intent.md`

---

## 1. 전제조건

| 항목 | 요구 |
|---|---|
| Claude Code | plugin namespace 지원 (`.claude-plugin/plugin.json` 인식) |
| 노트 시스템 | 옵시디언 vault 권장. 마크다운 + wikilink (`[[X]]`) 호환 도구도 가능 (Logseq 등) |
| Python | 3.10+ (검증 CLI `wiki.py` 사용 시. 미사용 시 LLM 직접 검증) |
| WebFetch 가능 | URL 입력 시 원문 보존을 위해 |

---

## 2. 복사 대상 — 4 범주 (총 13~17 파일)

### 범주 1 — Plugin namespace (필수, 2 파일)
```
.claude-plugin/plugin.json    # name: "pab" 매니페스트
```
- 대상 프로젝트가 이미 다른 plugin 사용 중이면 **`name` 충돌 검사** 필수
- 동일 `pab` namespace 공유 시 skill 이름은 `wiki-*` 등 prefix로 구분 권장

### 범주 2 — Skill 본체 (필수)
```
skills/wiki/SKILL.md          # 220줄, LLM intelligence 인터페이스 + §3 처리 절차 12 step
skills/wiki/PORTABILITY.md    # 본 가이드 (선택, 함께 복사 권장)
```

### 범주 3 — 옵시디언 규격 정의 (대상 vault에 이미 있으면 생략 가능)
```
wiki/40_Templates/SOURCE.md            # 신규 TYPE 템플릿 (필수 — 본 skill 핵심)
wiki/40_Templates/RESEARCH_NOTE.md     # (외 5종 — 기존 6 TYPE 템플릿)
wiki/40_Templates/_schema.json         # TYPE enum 8개 + 11필드 검증
wiki/00_MOC/TYPES/SOURCE.md            # SOURCE TYPE MOC
wiki/00_MOC/TYPES/*.md                 # (외 6종 — TYPE MOC)
wiki/00_MOC/DOMAINS/*.md               # 6 DOMAIN MOC
wiki/30_Constraints/frontmatter-spec.md  # 11필드 정의 + immutable 원칙
wiki/30_Constraints/naming-convention.md # 폴더 prefix + slug 규약
```

### 범주 4 — 자동화 (선택, 검증 정확도 ↑)
```
scripts/wiki/wiki.py                   # 4 subcommand CLI 진입점
scripts/wiki/lib/{frontmatter,validate,moc,toc}.py  # 라이브러리 모듈
wiki/15_Sources/                       # 폴더 (.gitkeep만)
wiki/10_Notes/                         # 폴더 (`.gitkeep`)
wiki/00_MOC/                           # 폴더
wiki/_attachments/                     # 폴더 (옵시디언 default)
Makefile                               # wiki-* 타겟 (선택)
```

---

## 3. 이식 시 변경 항목

| 항목 | 기본값 (PAB-obsidian) | 수정 위치 |
|---|---|---|
| **vault root** | `$WIKI_VAULT_ROOT` 우선, 미설정 시 `./wiki/` | **환경변수만 설정** (SKILL.md 변경 불요) |
| 요약본 저장 폴더 | `${VAULT_ROOT}/10_Notes/` | `SKILL.md` §2.4 + §3 Step 8b |
| 원본 저장 폴더 | `${VAULT_ROOT}/15_Sources/` | `SKILL.md` §2.4 + §3 Step 8a |
| DOMAIN 목록 | AI/HARNESS/ENGINEERING/PRODUCT/KNOWLEDGE_MGMT/MISC | `SKILL.md` §2.2 (대상 프로젝트 도메인에 맞게) |
| frontmatter 11필드 | 현재 정의 | `SKILL.md` §2.3 + `frontmatter-spec.md` |
| `wiki.py` 호출 경로 | `scripts/wiki/wiki.py` | `SKILL.md` §3 Step 9 |
| TYPE 6→7 (SOURCE 추가) | 8 enum | `_schema.json` (대상 vault가 다른 schema면 정합) |

### 3.1 vault 운영 모드 선택 (Karpathy 본래 의도 — 공통 vault 권장)

| 모드 | 설정 | 권장 시점 |
|---|---|---|
| **공통 vault (γ 하이브리드, 권장)** | `export WIKI_VAULT_ROOT="$HOME/Obsidian/Karpathy-Vault"` | **일반 운영**. 모든 프로젝트의 노트가 한 vault에 누적 — Karpathy "외부 뇌" 본질 충족 |
| **자기완결 (프로젝트별 vault)** | 환경변수 미설정 → `./wiki/` | 프로젝트 dogfooding(PAB-obsidian 같은 케이스), 임시 테스트 |

**공통 vault 셋업 절차**:
```bash
# 1. 공통 vault 생성 (한 번만)
mkdir -p "$HOME/Obsidian/Karpathy-Vault"/{00_MOC/{TYPES,DOMAINS,TOPICS},10_Notes,15_Sources,20_Lessons,30_Constraints,40_Templates,_attachments,99_Inbox}

# 2. 옵시디언 규격 복사 (원본: PAB-obsidian)
cp -r <PAB-obsidian>/wiki/40_Templates/* "$HOME/Obsidian/Karpathy-Vault/40_Templates/"
cp -r <PAB-obsidian>/wiki/00_MOC/* "$HOME/Obsidian/Karpathy-Vault/00_MOC/"
cp <PAB-obsidian>/wiki/30_Constraints/{frontmatter-spec,naming-convention}.md "$HOME/Obsidian/Karpathy-Vault/30_Constraints/"

# 3. 환경변수 설정 (.zshrc / .bashrc)
echo 'export WIKI_VAULT_ROOT="$HOME/Obsidian/Karpathy-Vault"' >> ~/.zshrc
source ~/.zshrc

# 4. 옵시디언에 vault 등록 (앱 GUI)

# 5. 프로젝트별 폴더 분리 (옵션, 권장)
#    공통 vault 안에서 노트는 자동 누적되지만, 프로젝트 컨텍스트 분리하려면:
mkdir -p "$WIKI_VAULT_ROOT"/10_Notes/<project-name>
mkdir -p "$WIKI_VAULT_ROOT"/15_Sources/<project-name>
#    또는 SKILL.md §2.4를 갱신하여 자동 sub-folder 패턴 사용
```

**프로젝트 → vault 노트 누적 흐름**:
```
PAB-obsidian/        →  $WIKI_VAULT_ROOT/10_Notes/      (PAB-obsidian의 wiki 노트)
PAB-SSOT-Nexus/      →  $WIKI_VAULT_ROOT/10_Notes/      (nexus의 wiki 노트)
다른 프로젝트들...    →  $WIKI_VAULT_ROOT/10_Notes/      (모두 누적)

각 프로젝트의 wiki/  =  Phase 산출물·baseline 등 *프로젝트 고유* 자료만 (옵시디언 노트 제외)
```

---

## 4. 4가지 이식 시나리오

### 시나리오 A — 동일 옵시디언 vault + 동일 schema (가장 단순)
대상 프로젝트가 PAB-obsidian과 같은 옵시디언 vault 구조 + frontmatter 11필드 schema를 쓰는 경우:

1. 범주 1, 2만 복사
2. 변경 항목 없음 (대상 vault에 이미 옵시디언 규격 있음)
3. Claude Code 세션 재시작 → `/pab:wiki --help` 자동완성 확인

### 시나리오 B — 옵시디언 + 다른 schema
대상 프로젝트가 다른 frontmatter 구조 사용:

1. 범주 1, 2 복사
2. 범주 3 중 `SOURCE.md` 템플릿 + `_schema.json`만 정합 갱신 (SOURCE TYPE 추가)
3. `SKILL.md` §2.3 frontmatter 표를 대상 schema에 맞게 Edit
4. 본질 5항목 유지 확인

### 시나리오 C — 마크다운 vault 다른 도구 (Logseq, Foam 등)
1. 범주 1, 2 복사
2. wikilink 형식 차이 검증:
   - 옵시디언: `[[Note]]`
   - Logseq: `[[Note]]` (호환), 단 anchor는 `((block-id))` 다름
3. `SKILL.md` §3 Step 6 anchor 정규화 함수를 대상 도구 규약으로 교체
4. `SKILL.md` §3 Step 9 검증 — `wiki.py` 미존재 시 LLM 직접 검증으로 fallback 명시

### 시나리오 D — 완전히 새 프로젝트 (vault 없음)
선택지:
- (D-1) **PAB-obsidian Phase 1-1 ~ 1-5 절차 그대로 진행** (권장 — 검증된 풀 셋업)
- (D-2) 범주 1, 2, 3 모두 복사 + `wiki/{15_Sources,10_Notes,00_MOC,_attachments}/` 폴더 신설

---

## 5. nexus 프로젝트 이식 (실전 사례 — 시나리오 B)

`PAB-SSOT-Nexus`는 이미 `name: pab` plugin namespace 보유. 본 skill을 추가하려면:

```bash
# 대상: /Users/map-rch/WORKS/PAB-SSOT-Nexus/
# 1. 기존 plugin.json 그대로 사용 (충돌 회피)
# 2. skill 본체 복사
cp -r skills/wiki/ <NEXUS>/skills/wiki/

# 3. 옵시디언 vault 사용 여부 확인
#    - 사용 O: 범주 3 정합 갱신 (대부분 그대로 OK)
#    - 사용 X: 범주 3 + 범주 4 폴더 모두 신설
ls <NEXUS>/wiki/                       # 결과 확인

# 4. 차이 정합 (시나리오 B)
#    - SKILL.md §2.4 폴더 prefix가 nexus vault 구조와 일치하는지
#    - _schema.json TYPE enum이 nexus 정의와 정합하는지

# 5. Claude Code 세션 재시작 후 nexus에서:
#    /pab:wiki --help     # 자동완성 확인
#    /pab:wiki <test>     # 첫 호출 → 본질 5항목 검증
```

**주의**: nexus는 `pab` namespace에 이미 다른 skill(`/pab:phase-init`, `/pab:report` 등)이 있을 수 있음. `/pab:wiki`는 신규 skill 이름이라 충돌 없음.

---

## 6. 이식 후 검증 절차 (필수)

### Step 1 — 환경 확인
```bash
ls .claude-plugin/plugin.json skills/wiki/SKILL.md
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"  # JSON valid
```

### Step 2 — 자동완성 확인
Claude Code 세션 재시작 후:
```
/pab:wiki --help
```
표준 헬프가 출력되면 namespace 인식 정상.

### Step 3 — 본질 5항목 검증 (핵심)
첫 실제 호출:
```
/pab:wiki https://example.com/some-article 정리해줘
```

기대 결과:
| # | 항목 | 검증 |
|---|---|---|
| 1 | 원본 immutable | `wiki/15_Sources/<date>_<slug>_source.md` 생성 + `type: "[[SOURCE]]"` + "변경 금지" 헤더 |
| 2 | LLM 요약본 | `wiki/10_Notes/<date>_<slug>.md` 생성 + 기존 TYPE |
| 3 | TOC 양방향 | 요약본 각 H2 직후 `[원본 §... →](..._source.md#anchor)` 링크 |
| 4 | 동시 생성 | 두 파일 `created` 같은 분 |
| 5 | 3계층 | 원본 폴더 / 위키 폴더 / 스키마 폴더 모두 존재 |

1건이라도 ✗면 이식 미완성. 차이 위치를 본 가이드 §3 변경 항목 표와 대조하여 정정.

### Step 4 — 검증 도구 (선택)
```bash
python3 scripts/wiki/wiki.py link-check
```
`violations=0`이면 frontmatter Critical/High PASS. `broken=N`은 미래 노트 unresolved (정상).

---

## 7. 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `/pab:wiki` 자동완성 안 됨 | namespace 미로드 | Claude Code 세션 재시작 |
| `Unknown skill: pab:wiki` | plugin.json 위치/내용 오류 | `.claude-plugin/plugin.json` `name: "pab"` 확인 |
| frontmatter validation 실패 | schema 정합 깨짐 | `_schema.json`과 `SKILL.md` §2.3 일치 확인 |
| TOC anchor 불일치 | 옵시디언 anchor 정규화 차이 | `SKILL.md` §3 Step 6 정규화 함수 검토 (한글 처리) |
| `WebFetch` 차단 (Reddit 등) | 사이트별 인증 필요 | `curl + User-Agent` fallback (`/pab:wiki` 본문에서 사용자가 수동 페치 후 입력) |
| 두 파일 중 하나만 생성됨 | Step 8a/8b 분기 누락 | `SKILL.md` §3 Step 8a + 8b 분리 명시 확인 |
| 원본이 너무 큼 (R-3 위반?) | 원본 자료는 R-3 적용 제외 | `SKILL.md` §1 명시: 원본 자료 파일은 코드 한계 미적용 |
| 노트가 *호출 프로젝트*의 wiki/에 저장됨 (의도: 공통 vault) | `WIKI_VAULT_ROOT` 미설정 | `echo $WIKI_VAULT_ROOT` 확인. 공통 vault 모드는 환경변수 필수 |
| 옵시디언이 새 노트 못 봄 (공통 vault 모드) | 옵시디언 vault 미등록 | 옵시디언 앱에서 `$WIKI_VAULT_ROOT` 경로를 vault로 등록 |
| 프로젝트별 노트가 한 폴더에 섞임 | 프로젝트별 sub-folder 미사용 | `$WIKI_VAULT_ROOT/10_Notes/<project>/` 패턴 도입 (SKILL.md §2.4 갱신 또는 호출 시 사용자가 폴더 명시) |

---

## 8. 본 skill의 *비목표* (이식 시에도 추가하지 말 것)

- ❌ 다중 SKILL 분리 (wiki-link-suggest, wiki-moc-update 등) — `/pab:wiki` 1개로 통합
- ❌ skill_bridge.py + JSON 프로토콜 — LLM이 직접 작성
- ❌ Type A/B 패턴 일반화
- ❌ 옵션 driven CLI 모드 (`--mode=full` 같은 분기) — *항상* 두 산출물 생성이 기본
- ❌ 이미지/PDF 자동 다운로드 — 별건 후속

본질만 유지하고 추가 기능을 덧붙이지 않는다. 사용자가 본질을 자주 잃는다는 통찰이 본 skill의 핵심 교훈.

---

## 9. 검증된 이식 사례

| 프로젝트 | 시나리오 | 상태 |
|---|---|---|
| PAB-obsidian (origin) | A (자기 자신, dogfooding) | ✅ G2-wiki PASS+ (STAGE A 5/5 + Hard 12/12 + Soft 6/6 + AUDITOR 4/4) |
| PAB-SSOT-Nexus | **D 최소 셋업** (vault 없음, 사용자 명령은 B였으나 조사 결과 D로 정정) | ✅ 이식 완료 (2026-05-03). 복사: `skills/wiki/` + `wiki/{15_Sources,10_Notes}/.gitkeep`. plugin.json 변경 0건 (이미 `name: pab`). nexus 세션에서 `/pab:wiki --help` 자동완성 + 첫 호출 본질 5/5 검증 대기. |

### 9.1 v0.2 보강 (2026-05-03) — 공통 vault 지원

| 변경 | 영향 |
|---|---|
| SKILL.md §3 Step 8 vault root 결정 로직 추가 | `$WIKI_VAULT_ROOT` 환경변수 우선, 미설정 시 `./wiki/` (기존 동작 보존) |
| SKILL.md §4 이전 가이드 — 운영 모드 선택 명시 | 공통 vault (Karpathy 본래 의도) vs 자기완결 (dogfooding) |
| PORTABILITY.md §3.1 공통 vault 셋업 절차 추가 | 5 step 셋업 명령 + 누적 흐름 다이어그램 |
| PORTABILITY.md §7 트러블슈팅 3건 추가 | 환경변수 미설정 / 옵시디언 미등록 / 프로젝트 분리 |
| 본질 5항목 영향 | **변경 없음** — vault 위치만 추상화. 본질 #5 Karpathy 3계층은 *강화* (공통 vault = 진짜 외부 뇌) |
| 후방 호환성 | ✅ — 환경변수 미설정 시 기존 `./wiki/` 동작 그대로

---

## 10. 본 가이드 변경 정책

- skill 명세(`SKILL.md`)가 변경되면 본 가이드도 함께 갱신
- 본질 5항목과 비목표 8항목은 변경 불가 (변경 시 plugin namespace에서 분리하여 새 skill로)
