# Phase 1-4 Backend-Dev 구현 보고서

---

## §T-1 — wiki.py 진입점 + lib/ 모듈 골격

### 환경 점검

```
python-frontmatter: 1.1.0 (pip install python-frontmatter으로 설치)
jsonschema: 기설치
pyyaml: 기설치
검증: python3 -c "import frontmatter, jsonschema, yaml" → All modules OK
```

### 작성 파일 7개

| 파일 | 라인 수 | 한계 | 상태 |
|---|---:|---|---|
| `scripts/wiki/__init__.py` | 0 | — | ✓ |
| `scripts/wiki/wiki.py` | 152 | 200 | ✓ |
| `scripts/wiki/lib/__init__.py` | 0 | — | ✓ |
| `scripts/wiki/lib/frontmatter.py` | 134 | 200 | ✓ |
| `scripts/wiki/lib/validate.py` | 247 | 250 | ✓ |
| `scripts/wiki/lib/moc.py` | 179 | 250 | ✓ |
| `scripts/wiki/lib/toc.py` | 200 | 200 | ✓ |

### 5개 --help smoke test

```
wiki --help: 4 subcommand 노출 ✓
wiki new --help: TYPE 6종 + slug + --dry-run ✓
wiki link-check --help: --full ✓
wiki moc-build --help: --dry-run + --topic-threshold N ✓
wiki toc-suggest --help: note + --max-depth + --threshold + --llm + --format ✓
```

### import 검증

```
python3 -c "from scripts.wiki.lib import frontmatter, validate, moc, toc"
→ import OK (NotImplementedError는 호출 시에만 발생)
```

### R-4 가드: wiki.py 152줄 / 200 한계 ✓

---

## §T-2 — wiki new — 11필드 frontmatter 자동 + 템플릿 적용

### 6 TYPE dry-run 출력 (발췌)

```yaml
# RESEARCH_NOTE
type: '[[RESEARCH_NOTE]]'
tags: [research-note]
index: '[[ROOT]]'
# 나머지 5종도 동일 패턴 (tags만 TYPE별 상이)
```

### 실제 생성 + 검증

```
python3 scripts/wiki/wiki.py new RESEARCH_NOTE smoke-test
→ [OK] 노트 생성: wiki/10_Notes/2026-05-02_smoke-test.md
→ [obsidian] create 성공: Created: Untitled.md

11필드 검증: ['aliases','created','description','index','keywords',
             'sources','tags','title','topics','type','updated']
Missing: [] → exit=0 ✓
```

### 충돌 처리

```
python3 scripts/wiki/wiki.py new RESEARCH_NOTE smoke-test (2회)
→ [ERROR] 파일이 이미 존재합니다: ... → exit=1 ✓
```

### obsidian CLI 결과

- obsidian create 호출: **성공** (returncode=0, "Created: Untitled.md")
- 폴백 동작: FileNotFoundError 시 "[obsidian] CLI 미설치 — 폴백: 직접 파일 작성 완료" 출력

### lib/frontmatter.py 134줄 / 200 한계 ✓

---

## §T-3 — wiki link-check — schema strict + broken link + orphan

### 기존 vault 전수 검증 결과

```
notes=19, violations=0, broken=2, orphans=0

[BROKEN] [[TOC]]       — toc-recommendation.md topics 필드의 미생성 TOPIC 참조
[BROKEN] [[wikilink]]  — linking-policy.md 인라인 코드 예시 (false positive)
```

**이슈 분석 및 처리**:

1. **40_Templates 제외**: 초기 버전에서 `wiki/40_Templates/` 파일이 포함되어 Templater 변수(`<% tp.date.now() %>`)로 6건 violations 발생. `collect_notes()`에서 `40_Templates` 제외로 해결.

2. **obsidian unresolved 범위 문제**: `obsidian unresolved`는 전체 vault(SSOT/ 포함)를 스캔하여 SSOT 관련 링크 43건이 반환됨. **수정**: obsidian 결과를 wiki/ 노트에서 실제 참조되는 링크와 교차 필터링하여 wiki/ 범위로 제한. 화이트리스트(ROOT/MOC/CONSTRAINTS/TYPES/DOMAINS/TOPICS) 후처리 적용.

3. **잔류 broken 2건**: `[[TOC]]` (실제 미생성 TOPIC)은 Team Lead에 보고. `[[wikilink]]`는 인라인 코드 내 예시 — false positive (task spec "false positive 허용").

### 빈 vault 시뮬레이션

```
python3 scripts/wiki/wiki.py --vault /tmp/empty-vault link-check
→ PASS (empty vault) exit=0 ✓
```

### obsidian CLI 호출 결과

- obsidian unresolved: 호출 성공, 전체 vault 스캔 (43건)
- wiki/ 교차 필터: 2건으로 축소

### 화이트리스트 적용 확인

ROOT, MOC, CONSTRAINTS, TYPES, DOMAINS, TOPICS → broken 제외 ✓

### lib/validate.py 247줄 / 250 한계 ✓

---

## §T-4 — wiki moc-build — 13 MOC placeholder + TOPIC 승격(N=3)

### dry-run 결과

```
13 MOC 인식:
- TYPES/REFERENCE.md → 4건 갱신 예정 (wiki/30_Constraints/ 노트들)
- 나머지 12 MOC → 0건 갱신 예정
- TOPIC 승격 예정: CONSTRAINTS (4건)
```

### 실제 실행 결과

```
12개 MOC 갱신 (marker 주입)
1개 변경 없음 (TOPICS/_README.md — 폴백 정적 링크 섹션 없음)
1개 TOPIC 승격: CONSTRAINTS → wiki/00_MOC/TOPICS/CONSTRAINTS.md
```

### idempotent 검증 (2회 실행)

```
python3 scripts/wiki/wiki.py moc-build (2회)
→ no changes (total=13, notes=5) ✓
```

### TOPIC 승격 결과

`wiki/00_MOC/TOPICS/CONSTRAINTS.md` 생성:
- frontmatter 11필드 (type=REFERENCE, index=ROOT, tags=[moc, topics/constraints])
- dataview 쿼리 + 폴백 정적 링크 섹션

### lib/moc.py 179줄 / 250 한계 ✓

---

## §T-5 — wiki toc-suggest — toc-recommendation 명세 구현

### toc-recommendation.md 자기 평가 (JSON)

```json
{
  "flatness": "ok",
  "max_depth_seen": 3,
  "suggestions": [... 20개 섹션 분석 ...]
}
```
출력 스키마 명세 100% 일치 ✓

### 빈 노트 검증

```json
{"flatness":"ok","max_depth_seen":0,"suggestions":[]} ✓
```

### frontmatter/code-block 제외 검증

```
---\ntitle: Test\n# 이 줄은 제외\n---\n\n# Real H1\n```python\n# 코드 내 제외\n```\n## Real H2
→ suggestions: [H1, H2] (frontmatter 내 # 및 코드블록 내 # 제외) ✓
```

### phase-1-4-plan.md markdown 출력

```
Flatness: ok, Max depth seen: 2 → 11개 섹션 분석 ✓
```

### lib/toc.py 200줄 / 200 한계 ✓

---

## §T-6 — Makefile + README.md

### Makefile 생성 결과

- 신규 작성 (기존 Makefile 없음)
- 4 타겟: wiki-new / wiki-link-check / wiki-moc-build / wiki-toc-suggest
- `.PHONY` 명시 ✓
- 인자 검증 (TYPE/SLUG/NOTE 누락 시 exit 2) ✓

### 4 make 타겟 smoke test

```
make wiki-link-check
→ FAIL (notes=19, violations=0, broken=2, orphans=0) [exit 1 = expected ✓]

make wiki-moc-build DRY_RUN=1
→ [dry-run] 총 13 MOC 인식, 실제 변경 없음 ✓

make wiki-new (인자 누락)
→ "Usage: make wiki-new TYPE=RESEARCH_NOTE SLUG=karpathy-llm-wiki" exit 2 ✓
```

### README.md

- `scripts/wiki/README.md` 138줄 / 250 한계 ✓
- 구성: 개요/의존성/디렉토리 구조/4 명령/트러블슈팅/SSOT 통합

---

## §HOTFIX — FIX-1/2/3 적용 (team-lead 지시)

### 변경 파일 및 라인 수

| 파일 | hotfix 전 | hotfix 후 | 한계 |
|---|---:|---:|---|
| `lib/validate.py` | 247 | 192 | 250 ✓ |
| `lib/moc.py` | 179 | 177 | 250 ✓ |

### FIX-1 (validate.py): 화이트리스트 `TOC` 추가

```python
# 변경 전
WIKILINK_WHITELIST = {"ROOT", "MOC", "CONSTRAINTS", "TYPES", "DOMAINS", "TOPICS"}
# 변경 후
WIKILINK_WHITELIST = {"ROOT", "MOC", "CONSTRAINTS", "TYPES", "DOMAINS", "TOPICS", "TOC"}
```

근거: toc-recommendation.md frontmatter topics의 `[[TOC]]`는 시스템 가상 앵커 (TOPIC 승격 N=3 미만 보존).

### FIX-2 (validate.py): 인라인 코드 + fenced code block 제외

`_extract_wikilink_targets(text)` 헬퍼 신규 추가:
- frontmatter(`---...---`) 제외
- fenced code block(```` ``` ...``` ````) 제외
- 인라인 코드(`` `...` ``) 제거 후 wikilink 추출

`find_unresolved_links_fallback` + obsidian 교차 필터 모두 동일 헬퍼 사용.

근거: linking-policy.md 147행 `` `[[wikilink]]` ``는 인라인 코드 예시 (false positive).

### FIX-3 (moc.py): TOPICS/_README.md 갱신 제외

```python
# 변경 전: _README.md를 _process_moc로 처리
# 변경 후: 주석으로 제외 처리 (Phase 1-3 산출물 보존 원칙)
# TOPICS/_README.md: placeholder 명세 노트 — 갱신 제외 (FIX-3)
```

### 재검증 결과

```
python3 scripts/wiki/wiki.py link-check
→ PASS (notes=19, violations=0, broken=0, orphans=0)  exit=0 ✓

python3 scripts/wiki/wiki.py --vault /tmp/empty-vault link-check
→ PASS (empty vault)  exit=0 ✓

python3 scripts/wiki/wiki.py moc-build --dry-run
→ [dry-run] 총 12 MOC 인식, 실제 변경 없음 (_README 제외) ✓

python3 scripts/wiki/wiki.py moc-build (1회)
→ no changes (total=12, notes=5) ✓

python3 scripts/wiki/wiki.py moc-build (2회)
→ no changes (total=12, notes=5) — idempotent ✓
```

---

## §HOTFIX2 — FIX-4/5/6 적용 (team-lead 지시, verifier PARTIAL → PASS)

### 라인 수

| 파일 | hotfix2 전 | hotfix2 후 | 한계 |
|---|---:|---:|---|
| `lib/validate.py` | 192 | 202 | 250 ✓ |
| `scripts/wiki/wiki.py` | 152 | 152 | 200 ✓ |
| `scripts/wiki/README.md` | 138 | 145 | 250 ✓ |

### FIX-4 (validate.py): fallback path-style wikilink basename 비교

```python
# 변경 전: target 전체를 stem과 비교 → [[00_MOC/TYPES/FOO]] false positive
return sorted(all_targets - all_stems - WIKILINK_WHITELIST)

# 변경 후: basename 추출 후 비교 (보고는 원본 그대로)
for target in sorted(all_targets):
    basename = target.split("/")[-1].split("|")[0].split("#")[0].strip()
    if basename not in all_stems and basename not in WIKILINK_WHITELIST:
        broken.append(target)
```

### FIX-5 (wiki.py + README.md): 12 MOC 표기 통일

- `wiki.py:107` help text: `"13 MOC"` → `"12 MOC"`
- `README.md:80` 설명: `"13 MOC(TYPES 6+DOMAINS 6+_README 1)"` → `"12 MOC(TYPES 6+DOMAINS 6, _README 제외)"`

### FIX-6 (README.md): DAILY → 99_Inbox 라우팅 명시

wiki new 섹션에 저장 디렉토리 매트릭스 테이블 추가:

| TYPE | 저장 위치 |
|---|---|
| RESEARCH_NOTE / CONCEPT / LESSON / PROJECT / REFERENCE | `wiki/10_Notes/` |
| DAILY | `wiki/99_Inbox/` |

### 재검증 결과

```
python3 scripts/wiki/wiki.py link-check
→ PASS (notes=19, violations=0, broken=0, orphans=0)  exit=0 ✓

fallback 단독 (obsidian 강제 None monkeypatch):
→ fallback broken count: 0 → broken=0 ✓

grep "13 MOC" scripts/wiki/wiki.py scripts/wiki/README.md
→ 잔존 0건 ✓
```

---

## 주요 이슈 보고 (Team Lead 확인 필요)

### ISSUE-1: wiki/30_Constraints/ 노트의 broken link 2건

| 링크 | 위치 | 유형 |
|---|---|---|
| `[[TOC]]` | `toc-recommendation.md` frontmatter `topics` | 실제 미생성 TOPIC (실제 이슈) |
| `[[wikilink]]` | `linking-policy.md` 인라인 코드 예시 | false positive |

`[[TOC]]` TOPIC MOC 생성 여부 결정 필요. Phase 1-6 시드 노트 작성 전에 moc-build로 승격 가능 (3건 이상 참조 시).

### ISSUE-2: obsidian unresolved 범위

`obsidian unresolved`는 전체 Obsidian vault(SSOT/ 포함)를 스캔. wiki/ 교차 필터로 보정했으나, 향후 vault 범위 설정 개선 권고.

### ISSUE-3: TOPICS/_README.md marker 섹션 없음

`wiki/00_MOC/TOPICS/_README.md`에 `## 폴백 정적 링크` 섹션이 없어 moc-build가 갱신 불가. Phase 1-3 결과물이므로 수정 불가 — Team Lead 결정 필요.
