# Phase 1-3 Plan — TOC/MOC 시스템 (3중 인덱스)

## 목표

PAB Wiki의 **3중 인덱스 시스템**(TYPES / DOMAINS / TOPICS)을 구축한다.
Phase 1-2에서 정의된 frontmatter 필드(`type`, `index`, `topics`)를 입구로, 노트가 자동으로 알맞은 MOC에 수집되는 메커니즘을 만든다.

## 범위

- **TYPES MOC** (6종): 노트의 `type` 필드 기준 자동 수집. `[[RESEARCH_NOTE]]`/`[[CONCEPT]]`/`[[LESSON]]`/`[[PROJECT]]`/`[[DAILY]]`/`[[REFERENCE]]`
- **DOMAINS MOC** (6종): 노트의 `index` 필드 기준 자동 수집. `[[AI]]`/`[[HARNESS]]`/`[[ENGINEERING]]`/`[[PRODUCT]]`/`[[KNOWLEDGE_MGMT]]`/`[[MISC]]` (ROOT는 _INDEX.md 자체)
- **TOPICS placeholder**: 동적 생성 디렉토리 + 자동 승격 규칙(노트 N건 이상 등장 시)
- **_INDEX.md 갱신**: 3중 인덱스 진입점 + dataview 폴백 정적 링크
- **TOC 알고리즘 명세**: Phase 1-4 T-5 구현 시 참조할 휴리스틱(heading depth + 길이) + LLM 보강 기준

## 산출물

| Task | 경로 | 설명 |
|---|---|---|
| T-1 | `wiki/00_MOC/TYPES/{6}.md` | 6 TYPE MOC |
| T-2 | `wiki/00_MOC/DOMAINS/{6}.md` | 6 DOMAIN MOC |
| T-3 | `wiki/00_MOC/TOPICS/_README.md` | placeholder + 자동 생성 규칙 |
| T-4 | `wiki/_INDEX.md` (갱신) | 3중 인덱스 진입점 |
| T-5 | `wiki/30_Constraints/toc-recommendation.md` | TOC 추천 알고리즘 명세 |

## Task 목록

| Task | 도메인 | 담당 | 의존 |
|---|---|---|---|
| T-1: TYPES MOC 6종 | WIKI-CONTENT | backend-dev | - |
| T-2: DOMAINS MOC 6종 | WIKI-CONTENT | backend-dev | - |
| T-3: TOPICS placeholder | WIKI-META | backend-dev | - |
| T-4: _INDEX.md 갱신 | WIKI-META | backend-dev | T-1, T-2, T-3 |
| T-5: TOC 알고리즘 명세 | WIKI-META | backend-dev | - |
| T-6: Schema strict 정렬 (사용자 결정 옵션 a) | WIKI-META | backend-dev | T-1~T-5 |

## G2_wiki 게이트

- **Critical**: MOC 간 broken `[[wikilink]]` 0건 / frontmatter 필수필드(`title`/`type`/`created`) 100% / 파일명 규약 준수
- **High**: dataview 쿼리 syntax valid (Phase 1-1 plugin 설치 가정 기반 검증) / 모든 MOC가 _INDEX.md에서 도달 가능
- **Low**: `keywords`/`sources` 누락 허용 (MOC는 구조 노트라 외부 참조 적음)

## 의존 관계

- 입력: Phase 1-2 산출물 (`_schema.json`, 6 템플릿, 3 constraints) — type/index enum 일치 확인
- 출력: Phase 1-4 (`wiki moc-build` CLI가 본 MOC 구조를 자동 갱신), Phase 1-6 (시드 노트가 본 MOC에 자동 등록)

## 예외 (E-1 ~ E-5 적용)

- E-1 (G2 → G2_wiki): 본 Phase에서 적용
- E-3 (G3 → wiki-validation): T-4 완료 후 verifier가 link-check 1회 수행
- E-4 (tester 미스폰): MOC는 구조 노트로 단위 테스트 불필요
- E-5 (frontend-dev 미스폰): UI 코드 없음

## 소요 추정

5 task / 90~120분
