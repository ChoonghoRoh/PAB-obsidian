---
phase: "1"
type: exceptions
created: 2026-05-01
ssot_version: 8.2-renewal-6th
scope: "Phase 1 (Obsidian Wiki 구축) 한정"
ssot_modified: false
---

# Phase 1 SSOT 예외 등록

> **원칙**: SSOT 본체는 무수정. 본 프로젝트(Obsidian wiki 구축)에 한해 아래 5건의 예외를 등록·적용한다. 다른 Phase·다른 프로젝트에는 자동 승계되지 않는다. 예외 종료 시(Phase 1 DONE) 본 문서는 보존하되 효력은 정지된다.

## 등록 예외 (E-1 ~ E-5)

### E-1: G2_be / G2_fe 검증 비적용

| 항목 | 내용 |
|---|---|
| **대체** | **G2_wiki** 신설 (frontmatter 필수필드 검증, broken `[[wikilink]]` 검출, 파일명 규약 `YYYY-MM-DD_*` 검증, 날짜 형식 일관성, 필수 MOC 링크 존재) |
| **사유** | 본 프로젝트는 `.md` 파일 wiki 구축. backend/web 코드 없음 → ORM/Pydantic/CDN/ESM 검증 적용 불가 |
| **적용 범위** | Phase 1-1 ~ Phase 1-6 전 sub-phase |
| **검증 도구** | `obsidian unresolved` (broken link) + 자체 Python 스크립트 (`scripts/wiki/validate.py`) |
| **판정 기준** | Critical: broken link 1건 이상 → FAIL / 필수 frontmatter 필드 누락 1건 이상 → FAIL |

### E-2: HR-5 (코드 500/700줄) 비적용 → 노트 400줄 권장 기준으로 대체

| 항목 | 내용 |
|---|---|
| **대체** | **wiki 노트 단일 파일 400줄 초과 시 분할 권장** (강제 아님). 분할 시 wikilink로 후속 노트 연결. |
| **사유** | `.md` 노트는 가독성 단위가 코드와 다름. Karpathy 방식은 짧은 노트 다수 + 강한 링크 |
| **적용 범위** | `wiki/` 하위 모든 `.md` |
| **검증 도구** | `scripts/wiki/validate.py --line-check` (warning만, FAIL 아님) |
| **레지스트리** | 본 프로젝트는 `SSOT/refactoring/refactoring-registry.md`에 등록하지 **않음** (코드 아님) |

### E-3: HR-8 Telegram prefix `[PAB-v3]` → `[PAB-Wiki]` 변경

| 항목 | 내용 |
|---|---|
| **대체** | 알림 메시지 prefix를 **`[PAB-Wiki]`** 로 변경. 그 외 형식·발송 의무는 동일 |
| **사유** | 본 프로젝트는 PAB-v3 코드가 아닌 별도 wiki 구축 프로젝트. 알림 그룹 분리 필요 |
| **적용 범위** | Phase 1-1 ~ Phase 1-6 모든 DONE 전이 |
| **스크립트** | `scripts/pmAuto/report_to_telegram.sh` 호출 시 `--prefix "[PAB-Wiki]"` 인자 또는 환경변수 `PAB_PREFIX="[PAB-Wiki]"` |
| **메시지 예시** | `[PAB-Wiki] ✅ Phase 1-1 완료: Obsidian CLI + Vault 초기화\n📊 결과: CLI 동작 확인, vault 초기화 완료\n📁 보고서: docs/phases/phase-1-1/reports/` |

### E-4: G3(pytest 테스트 게이트) → wiki-validation으로 대체

| 항목 | 내용 |
|---|---|
| **대체** | **wiki-validation** (Python 스크립트 기반): frontmatter 파싱 성공률, broken link 0, 고아 노트(orphan) 검출, MOC 일관성, 파일명 규약 |
| **사유** | 테스트 대상 코드 없음. pytest·E2E 적용 불가 |
| **적용 범위** | Phase 1-3 ~ Phase 1-6 (TOC/MOC가 존재하는 Phase부터) |
| **검증 도구** | `scripts/wiki/validate.py --full` (Phase 1-4 산출물) |
| **G3 PASS 기준** | broken link 0, frontmatter 파싱 성공률 100%, 고아 노트 0, MOC 미포함 노트 0 |
| **tester 역할** | 본 프로젝트는 tester 스폰하지 **않음**. verifier가 wiki-validation 검증 겸임 (HR-6 분리 원칙 일시 완화 — 검증자 ≠ 구현자는 유지) |

### E-5: 도메인 태그 `[BE]/[FE]/[DB]/[INFRA]` → wiki-* 4종으로 재정의

| 항목 | 내용 |
|---|---|
| **신규 도메인 태그** | `[WIKI-CONTENT]` (노트 작성·시드) / `[WIKI-INFRA]` (vault·CLI 설정) / `[WIKI-CLI]` (자동화 스크립트) / `[WIKI-META]` (템플릿·MOC·스키마) |
| **사유** | 기존 4종은 코드 도메인. wiki 작업과 매핑 불가 |
| **역할 매핑** | 4개 도메인 모두 → backend-dev (단일 implementer), verifier (검증). frontend-dev·tester 비스폰 |
| **사유 (역할 단일화)** | 본 프로젝트는 코드 BE/FE 분리 없음. 단일 implementer로 충분. 검증·구현 분리는 verifier 별도 스폰으로 유지 (HR-6 핵심 원칙 보존) |
| **적용 범위** | 모든 Phase 1-* tasks의 `domain:` 필드 |

## 예외 적용·기록 절차

### 1. Phase status.md 필드

각 sub-phase의 `phase-1-X-status.md` YAML에 다음 필드 필수 포함:

```yaml
exceptions: [E-1, E-2, E-3, E-4, E-5]
exceptions_ref: docs/phases/phase-1-exceptions.md
```

### 2. Task 파일 도메인

`tasks/task-1-X-N.md`의 `domain:` 필드는 위 4종(`WIKI-CONTENT`/`WIKI-INFRA`/`WIKI-CLI`/`WIKI-META`) 중 1개 사용.

### 3. G2 게이트 호출

`gate-check` skill 호출 시 본 프로젝트는 `G2_wiki` 게이트로 자동 매핑. (Phase 1-4에서 skill 어댑터 구현 시 분기 추가)

### 4. NOTIFY 발송

`scripts/pmAuto/report_to_telegram.sh` 호출 시 `[PAB-Wiki]` prefix 강제. (Phase 1-1에서 스크립트 옵션 확인 후 wrapper 작성 여부 결정)

## 효력 종료 조건

- Phase 1 마스터 플랜의 모든 sub-phase가 DONE 도달
- master-final-report.md 작성 완료
- 본 문서는 **보존**(이력용), `status: ARCHIVED`로 변경

## 변경 이력

| 일시 | 변경 | 작성자 |
|---|---|---|
| 2026-05-01 | 초안 작성 (E-1 ~ E-5) | Team Lead (사용자 승인 기반) |
