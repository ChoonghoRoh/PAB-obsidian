---
title: "HugRAG↔PAB 지식체계 비교 · 외부 brain 접목 검토"
description: "HugRAG(계층모듈·인과게이트·허위상관억제)를 PAB의 빈 상위레이어에 대응시키되 LV0 결정성은 지키고 khala 생성축 검색 백엔드로만 접목 — Phase A(저자그래프 백필)부터"
created: 2026-07-01 12:25
updated: 2026-07-01 12:25
type: "[[RESEARCH_NOTE]]"
index: "[[AI]]"
topics: ["[[KHALA]]", "[[HUGRAG]]", "[[LINEAGE]]"]
tags: ["research-note", "hugrag", "rag", "khala", "knowledge-graph"]
keywords: ["hugrag", "causal knowledge graph", "graphrag", "인과게이트", "계층모듈", "허위상관", "khala", "lv0", "knowledge_relations", "결정성", "저자링크", "raptor", "leiden"]
sources: ["[[15_Sources/2026-07-01_hugrag_pab_knowledge_graft_source]]", "works/PAB-v4/docs/overview/260701-HugRAG-PAB지식체계-비교-외부brain접목-검토.md", "https://arxiv.org/abs/2602.05143"]
aliases: ["HugRAG접목검토", "HugRAG-PAB비교", "인과게이트접목"]
---

# HugRAG↔PAB 지식체계 비교 · 외부 brain 접목 검토

> [[HUGRAG]]의 3대 기법(계층 모듈 · 인과 게이트 · 허위상관 억제)은 PAB의 **비어 있는 상위 레이어**(LV1~LV4·`knowledge_relations`·미구현 MOC)에 정확히 대응한다. 단 **LV0(결정적·저자작성)에는 넣지 않고** [[KHALA]] 플래너의 **생성·라우팅축 검색 백엔드**로만 접목해야 결정성 SLA가 보존된다. 원문 전문: [[15_Sources/2026-07-01_hugrag_pab_knowledge_graft_source|SOURCE]].

## 한 줄 결론 · 요지
[[2026-07-01_hugrag_pab_knowledge_graft_source#0. 요지 (TL;DR)|원문 §0 →]]

- **HugRAG = [[GraphRAG]]의 다음 세대**: (a) 계층 모듈(Leiden 분할+요약), (b) 원거리 모듈을 잇는 **인과 게이트**(LLM 인과 판정), (c) 온라인 **허위상관 인지 프롬프팅**. 재현율↔정밀도를 계층+인과로 동시에 푼다.
- **PAB 세 체계는 서로 다른 축**: LV0 wiki=결정적 저자링크, 미구현 MOC=계층 인덱스, v3 RAG=유사도 벡터. **아무도 인과·계층·모듈을 안 가졌다.**
- **접목 자리는 이미 비어 있다**: v3 `knowledge_relations`는 `auto_similar`(유사도)·순서뿐 — HugRAG가 진단한 실패("표면 매칭, 인과 부재")를 그대로 재현.
- **PAB만의 자산 — 저자 링크 = 공짜 인과 프라이어**: 사람이 그은 `[[링크]]`·`topics`·`type`을 인과 게이트 시드로 쓰면 순수-LLM HugRAG보다 정밀·저렴·출처보존.
- **오프라인 절반은 이미 돈다**: LV0 인테이크가 이미 `SemanticChunker` 청킹 + 384d 벡터를 Qdrant에 적재 중(LV0 API가 노출만 거부).

## HugRAG 핵심 3기법
[[2026-07-01_hugrag_pab_knowledge_graft_source#1. HugRAG 핵심 메커니즘|원문 §1 →]]

- **고치는 것**: 기존 graph-RAG의 ① 전역 정보 고립(재현율 갭 — 그룹핑이 경계를 강화해 먼 근거를 놓침), ② 로컬 허위 노이즈(정밀도 갭), ③ 엔티티 적중 위주 QA 평가 편향.
- **계층 지식그래프**: H₀=IE 세립 엔티티, H_ℓ>0=[[Leiden]] 반복 분할 모듈 + 모듈별 자연어 요약(RAPTOR식 요약 앵커, 단 그래프 모듈 단위).
- **인과 게이트 𝒢_c**(핵심 혁신): 위상적으로 먼 모듈 쌍의 요약을 LLM에 주고 인과성 판정(≥τ면 게이트). O(N²)는 Top-Down 프루닝으로 완화. 통합 엣지 **ℰ_uni = 구조 ∪ 계층 ∪ 인과게이트**.
- **온라인 3단**: A. 다입도 하이브리드 시딩(레벨별 top-K+MMR) → B. 게이트 우선 확장(Gain=s·γ^t·w, 인과·계층 우대) → C. LLM-CausalExpert가 유효 인과경로 S⋆만 남겨 허위상관 저항, S⋆에만 조건화하여 답 생성.
- **결과**: HolisQA 신규 벤치 포함, HotpotQA F1 64.83(vs LeanRAG 48.68), 1.5M자에서도 유지. 주비용은 인과 게이트 LLM 평가(프루닝으로 완화).

## PAB 지식 3체계 현황 (실코드 근거)
[[2026-07-01_hugrag_pab_knowledge_graft_source#2. PAB 지식 기록 3체계 — 현황 (실코드 근거)|원문 §2 →]]

- ⚠️ **레벨 번호 2체계 공존**: 성장 스킴(2026-04, Lv1~Lv4, LV0 없음) vs 신뢰 스킴(2026-06, LV0~LV4, LV0=옵시디언 인테이크). 본 문서는 **신뢰 스킴** 기준.
- **LV0 obsidian-wiki (구현됨)**: 11필드 frontmatter, `/ext/lv0/v1` 8엔드포인트, `source="author"`·`confidence=1.0` 하드코딩, 검색=부분문자열 매칭, 링크=저자링크+facet 실시간 계산(영속 0). **결정성 계약: 동일요청=바이트 동일.** 단 인테이크는 이미 청킹·384d 벡터 적재 중 → HugRAG 오프라인 입력 존재.
- **MOC/Wiki 레이어 (미구현/옵시디언 거주)**: 설계상 `wiki_pages`·`wiki_links`는 백엔드 grep 0건. 실제 MOC는 옵시디언 `00_MOC/{TYPES,DOMAINS,TOPICS}`(사람 작성)에만 있고, **인테이크 화이트리스트 밖 → PAB LV0는 이 계층을 못 본다.**
- **v3 RAG (레거시)**: 1500자 청킹, 384d multilingual-MiniLM+Qdrant COSINE, 하이브리드(RRF k=60). `knowledge_relations`는 `auto_similar`(cosine≥0.85)·순서뿐 — **인과/is-a/part-of 전무**. multi-hop은 희소 관계표 의존 → 비면 single-hop 퇴화. (한국어 형태소검색 부재, 영어 ms-marco 리랭커 오용 등 명시적 한계 다수.)

## 정면 비교 — 비어 있는 칸
[[2026-07-01_hugrag_pab_knowledge_graft_source#3. 정면 비교|원문 §3 →]]

- **읽는 법**: LV0·MOC는 결정성·출처가 강하나 재현율·인과가 0. v3·HugRAG는 그 반대. HugRAG는 v3가 "유사도"로만 갖던 그래프를 **계층+인과**로 끌어올린 것 = **PAB에 결여된 정확히 그 칸들**을 채운다.
- **한 장 통찰** — 세 줄이 같은 테이블(`knowledge_relations`)의 과거·미래·자산:
  - v3가 채우려던 것 = `auto_similar`(유사도, 표면 매칭, 인과 부재)
  - HugRAG가 채우는 것 = 𝒢_c(LLM 인과판정, 원거리 모듈)
  - LV0가 가진 것 = 저자 `[[링크]]`·topics·type(사람이 그은 고신뢰 엣지 = **공짜 인과 프라이어**)
- 즉 **v3의 실패 = HugRAG의 문제정의**, **LV0 저자링크 = HugRAG가 LLM으로 추론하려는 것을 사람이 이미 만들어 둔 것.**

## 접목 지점 — 결정성 경계를 넘지 않는다
[[2026-07-01_hugrag_pab_knowledge_graft_source#4. 접목 — 어디에, 어떻게|원문 §4 →]]

- **대원칙**: 조회축(결정적 LV0, `source=author`/conf=1.0)과 생성축(LLM khala)을 분리. Khala는 "무엇을 조회할지만 선택, 생성 0".
- ❌ **LV0에 넣지 않는다** — HugRAG 그래프를 섞으면 conf=1.0 SLA가 즉시 깨짐.
- ✅ **생성·라우팅축(LV1~LV4 = khala 플래너 검색 백엔드)에만** — HugRAG는 *어떤 LV0을 왜 고를지* + 인과경로를 만들고, 반환 `items`는 여전히 **저자 원문 바이트 동일**.
- **plan 승격**: 현재 plan="호출한 도구 목록" → HugRAG 얹으면 plan=**인과경로 S⋆**("이 문서들을 왜·어떤 논리로 골랐나"). §5 규약("plan은 답이 아니라 근거")과 정합.
- **부품→레벨 매핑**: H₀+임베딩→LV1(절반 존재) · Leiden 모듈+요약→미구현 MOC · 인과게이트→LV2 `knowledge_relations`(빈칸) · 다입도 시딩→LV3 · 모듈요약→LV4 routing_hints · 허위상관 접지→(신규) items 밖 필터.

## 단계별 로드맵 (A→D, 결정성 보존 순서)
[[2026-07-01_hugrag_pab_knowledge_graft_source#5. 단계별 접목 로드맵 (결정성 보존 순서)|원문 §5 →]]

- **Phase A — 저자 그래프 백필** (LLM 0, 완전 결정적) ★최우선: 옵시디언 MOC를 *읽어* 저자링크·topics·type을 `knowledge_relations`(또는 `lv0_links`)에 영속. → 결정적 multi-hop 가능, 출처 100%. HugRAG의 *구조*만 취하고 LLM 인과추론은 뺀 형태.
- **Phase B — 다입도 의미 시딩** (LV3 경량, 동결로 준결정적): 이미 적재된 384d 벡터 위에 top-K+MMR 시딩을 플래너 도구로 노출. 동의어 공백 메움(LV3 풀 재적재 없이). `source=ai_seed`·conf<1로 분리 표기.
- **Phase C — 인과 게이트** (LLM 오프라인, 동결·버전드): 원거리 모듈 간 인과 엣지 추가(`relation_type="causal"`·`source="ai"`·conf<1). **저자링크(Phase A)를 프라이어로 우선**, LLM은 빈 곳만 → 순수 HugRAG보다 정밀·저비용.
- **Phase D — 허위상관 인지 접지** (온라인, items 밖): LLM-CausalExpert로 *어떤 LV0을 반환할지* 랭킹 + 인과경로 생성. **`items` 내용은 저자 원문 바이트 동일**(재서술 0), synthesis=null 유지.

## 리스크 · 결론
[[2026-07-01_hugrag_pab_knowledge_graft_source#6. 리스크 · 유의|원문 §6 →]]

- **주요 리스크**: ① 결정성 오염(→레벨 태깅·별 테이블) · ② [[GPU_MUTEX]](khala vLLM GPU 경합 →야간 배치·경량 백본) · ③ 재현 불가(→그래프 동결·버전 스냅샷+[[LINEAGE]]) · ④ O(N²)(→프루닝+저자링크 프라이어) · ⑤ 한국어(임베딩·qwen 모두 OK, v3 실수 반복 금지).
- **결론**: 접목은 타당하고 자리도 비어 있으며, **LV0는 신성불가침**. PAB 비교우위 = 저자링크 인과 프라이어("HugRAG-lite"). **권고 착수 = Phase A(저자 그래프 백필)** — LLM 0·완전 결정적, 즉시 가치(결정적 multi-hop·MOC 가시화), Phase B~D의 토대. 선행 의존: `/ext/lv0/v1` + khala `pab_lv0_*` 도구 등록.

---

**연계**: [[project_khala_pab_v4_integration]] · [[reference_pab_ecosystem_repos]] · [[feedback_sequential_dev]]
