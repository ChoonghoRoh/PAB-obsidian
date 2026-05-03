---
task_id: "1-5-6"
title: "기존 노트 재생성 — Karpathy 글 원본+요약 한 쌍"
domain: WIKI-SKILL
owner: backend-dev
priority: P0
estimate_min: 25
status: pending
depends_on: ["1-5-2", "1-5-5"]
blocks: ["1-5-3"]
intent_ref: docs/phases/phase-1-5/phase-1-5-intent.md
---

# Task 1-5-6 (NEW) — 기존 노트 재생성

> **본질 (잃지 말 것)**:
> 1. 원본 immutable 보존
> 2. LLM 요약본
> 3. TOC 양방향 링크
> 4. 두 산출물 동시 생성
> 5. Karpathy 3계층 충족

## 목적

T-2 v2 SKILL.md + T-5 vault 확장이 완료된 상태에서, 기존 v1 노트(`wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md`)를 *백업하고*, 신규 SKILL.md 절차대로 **원본 + 요약본 한 쌍**으로 재생성한다.

## 입력
- v1 노트: `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` (3.3 KB, 87줄)
- 원본 입력 (재실행): `https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f 내용을 읽고 정리해줘.`
- T-2 산출: `skills/wiki/SKILL.md` v2
- T-5 산출: SOURCE TYPE 인프라

## 산출물

### 신규
1. `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md` — 원본 (immutable, 원문 그대로)
2. `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` — 요약본 v2 (TOC 링크 포함, v1 덮어쓰기)

### 백업
3. `wiki/10_Notes/_old/2026-05-02_karpathy_llm_wiki_v1_backup.md` — v1 백업 (보존)

## 실행 절차

### Step 1 — v1 노트 백업
```bash
mkdir -p wiki/10_Notes/_old
cp wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md \
   wiki/10_Notes/_old/2026-05-02_karpathy_llm_wiki_v1_backup.md
```

### Step 2 — SKILL.md v2 절차 *직접 실행*

backend-dev이 본인이 작성한 SKILL.md v2의 §3 처리 절차 12 step을 그대로 수행:

1. WebFetch로 gist URL 페치 (원문 텍스트 *전체 보존* — 사용자 vault 개인 보관)
2. TYPE 판별 (요약본=RESEARCH_NOTE, 원본=SOURCE 자동)
3. DOMAIN 매핑 (KNOWLEDGE_MGMT — 양 파일 동일)
4. TOPIC 후보 (LLM_WIKI 신규 마중물 — v1과 동일)
5. 메타데이터 (slug=`karpathy_llm_wiki`, title=v1 그대로 또는 보강)
6. **본문 생성 (요약본)** — 각 H2 섹션 헤더 직후에 원본 anchor 링크 자동 삽입:
   ```
   ## 핵심 주장
   [원본 §핵심 아이디어 →](2026-05-02_karpathy_llm_wiki_source.md#핵심-아이디어)
   ...
   ```
7. frontmatter 11필드 — 양 파일 각각:
   - 요약본: `sources: ["[[15_Sources/2026-05-02_karpathy_llm_wiki_source]]", "<URL>"]`
   - 원본: `sources: ["<URL>"]`, `type: "[[SOURCE]]"`, `tags: [source, ...]`
8a. **원본 저장**: `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md`
   - 본문 = WebFetch로 받은 원문 텍스트 그대로 (개인 vault 보관)
   - frontmatter 첫 줄에 "⚠️ 변경 금지 — 원본 immutable 보존" 주석
8b. **요약본 저장**: `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md` (v1 덮어쓰기)
9. 검증:
   - `python3 scripts/wiki/wiki.py link-check` (양 파일)
   - violations=0 확인 (Critical PASS)
   - TOC 링크 anchor가 원본 실제 헤더와 일치 확인 (정규화 후 비교)

### Step 3 — 산출물 사이즈 확인
```bash
wc -lc wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md
wc -lc wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md
```

원본 분량이 v1 검증에서 측정된 원문 분량(약 9,000~10,000자)의 80% 이상이어야 STAGE A 본질 #1 PASS.

## 완료 기준

- [ ] v1 백업 존재: `wiki/10_Notes/_old/2026-05-02_karpathy_llm_wiki_v1_backup.md`
- [ ] 원본 신규: `wiki/15_Sources/2026-05-02_karpathy_llm_wiki_source.md`
  - frontmatter type=`"[[SOURCE]]"`, tags 첫 항목=`source`
  - 본문 분량 ≥ 80% 원문 보존
  - "변경 금지" 헤더 명시
- [ ] 요약본 갱신: `wiki/10_Notes/2026-05-02_karpathy_llm_wiki.md`
  - frontmatter sources에 원본 wikilink 포함
  - 각 H2 섹션 직후 `[원본 §... →](..._source.md#anchor)` 패턴
  - 모든 anchor가 원본 실제 헤더와 일치 (정규화 후)
- [ ] `wiki link-check` violations=0 (양 파일)
- [ ] 두 파일 `created` 같은 분 안에 (동시 생성 증빙)

## 보고

`reports/report-backend-dev-v2.md` §T-6 섹션:
- v1 백업 경로 + 백업 시 분량
- 원본 파일 경로 + 분량 (원문 대비 보존률)
- 요약본 파일 경로 + 분량 + 섹션 수 + TOC 링크 개수
- 양 파일 created 타임스탬프
- link-check 결과 (violations + broken)
- TOC 링크 anchor 일치 확인 결과 (예시 3건 이상)

## 위험

- **L-1**: WebFetch로 받은 원문이 시간이 지나 cache 만료된 형태일 수 있음 — verifier 검증 시 baseline에 적힌 원문 핵심 인용 ("compounding artifact" 등)이 원본 파일에 포함되어 있는지 확인
- **L-2**: 원본 분량이 너무 클 경우(R-3 500줄 초과) — 자료 보존 파일이므로 R-3 적용 제외 (코드 ≠ 자료). 단 매우 긴 자료는 청크 분할 검토 (본 case는 해당 없음)
- **L-3**: TOC anchor 매칭 — 한글 anchor 처리. 옵시디언 실제 동작과 차이 시 보고서에 명시
- **L-4**: v1 백업 누락 시 v1 검증 자료 손실 — Step 1 반드시 선행
