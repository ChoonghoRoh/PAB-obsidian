---
title: "Obsidian 노트 구분·인덱싱 고도화 + Index/RAG/온톨로지 사례"
description: "MOC 3계층·_schema.json 기반 PAB vault의 노트 분류·인덱싱 진화 조사 — 리랭커·헤더청킹·Contextual Retrieval·SKOS·GraphRAG/HippoRAG/RAPTOR. 정본=사람용 SKOS, 소비=기계용 graph+vector 이원화."
created: "2026-07-20"
updated: "2026-07-21"
type: "[[RESEARCH_NOTE]]"
index: "[[KNOWLEDGE_MGMT]]"
topics: ["[[WIKI_ARCHITECTURE]]", "[[RAG]]", "[[LLM_WIKI]]", "[[ONTOLOGY]]"]
tags: [research-note, rag, embeddings, reranker, ontology, skos, knowledge-graph, indexing]
keywords: [노트 분류, MOC, 통제어휘, 포크소노미, SKOS, bge-m3, Qwen3-Embedding, 리랭커, 하이브리드 검색, Contextual Retrieval, 헤더 청킹, GraphRAG, LightRAG, HippoRAG, RAPTOR, TOPIC 거버넌스]
sources: ["works/PAB-Prove/docs/reports/R-03-obsidian-index-rag-ontology.md", "https://www.w3.org/TR/skos-primer/", "https://www.anthropic.com/engineering/contextual-retrieval", "https://github.com/QwenLM/Qwen3-Embedding", "https://arxiv.org/pdf/2502.14802"]
aliases: ["인덱싱 고도화", "RAG 온톨로지 사례", "R-03 인덱싱"]
---

# Obsidian 노트 구분·인덱싱 고도화 + Index/RAG/온톨로지

> **맥락**: PAB vault(MOC 3계층 TYPE 8/DOMAIN 7/TOPIC, `_schema.json` v1)의 노트 분류·인덱싱 진화 조사. 하위 소비 [[PAB-v4]]는 [[Qdrant]]+bge-m3+LV0 운용. 전문: `works/PAB-Prove/docs/reports/R-03-obsidian-index-rag-ontology.md`. 관련 접목검토: [[2026-07-01_hugrag_pab_knowledge_graft]].

---

## 1. 노트 구분 — 리스크는 TOPICS(포크소노미)

- TYPE(8)/DOMAIN(7)은 닫힌 **통제어휘**로 양호 → LLM few-shot + constrained 자동분류, `_schema.json` 검증 게이트.
- **진짜 리스크 = TOPICS 신규남발**(포크소노미). 완화:
  1. **TOPIC 레지스트리 = [[SKOS]] ConceptScheme**(`INDEX` MOC 또는 `_topics.json`에 prefLabel+altLabel+정의). 현행 `moc-build` 3건↑ 자동승격을 이 레지스트리로.
  2. **생성 전 대조(LLM)** + **임베딩 중복탐지**(코사인 >0.85 차단, bge-m3 재사용).
  3. UPPER_SNAKE 정규화, 동의어를 `altLabel` 흡수.

## 2. 인덱싱 고도화 (ROI 순)

- **bge-m3 유지 권장**: 단일 모델로 dense+sparse+multi-vector **하이브리드 내장** → 이미 유리.
- **최고 ROI = 리랭커 추가**: `bge-reranker-v2-m3`(MIT) 또는 `Qwen3-Reranker-0.6B/4B`(Apache) → 검색실패 대폭↓.
- **[[Contextual Retrieval]]**(Anthropic): 청크 앞 맥락 prepend → 실패 -35%→-49%(+BM25)→-67%(+리랭커). **PAB는 frontmatter(제목+MOC경로+TYPE+DOMAIN)가 그 맥락을 이미 보유 → 거의 공짜**.
- **헤더 기반 청킹**(고정크기 대비 +5~10%p): `[[wikilink]]` 비절단, frontmatter→[[Qdrant]] payload, 헤더 앵커를 청크 ID에.
- **임베딩 교체(선택)**: `Qwen3-Embedding-0.6B`(동일 1024-dim → 스키마 최소변경 + 32K context).

## 3. 외부 RAG/온톨로지 사례

| 사례 | 특징 | PAB 적용성 |
|---|---|---|
| [[GraphRAG]](MS) | LLM KG + 커뮤니티 요약 | 인덱싱 비용 큼 → LV3~4 거시요약 참고 |
| [[LightRAG]](HKU) | **증분 갱신**, 경량 | 지속수집과 정합 |
| [[HippoRAG]] 2(OSU) | OpenIE KG + PPR, multi-hop | **wikilink 그래프 보유 → 시드전파 유리**([[2026-07-01_hugrag_pab_knowledge_graft]]) |
| [[RAPTOR]](Stanford) | 재귀 클러스터+요약 트리 | **LV0~LV4 승격과 개념 정합** |

> 메타결론: 단일 아키텍처가 모든 질의를 이기지 못함 — Graph RAG 가치는 **질의 복잡도 비례**. 단순 팩트=벡터+리랭커, 다홉/종합=그래프로 [[Multi-Brain Router]] 라우팅.

## 4. PAB 진화 경로

```
현재:  TYPE·DOMAIN(enum) · TOPIC(wikilink 자유)   ← _schema.json v1
  ↓ (SKOS 형식화) 3× skos:ConceptScheme + altLabel/broader/related
  ↓ (typed edge + KG) 노트=노드, wikilink=typed edge(refines::/contradicts::)
목표:  [[Qdrant]](vector) + 경량 KG(PPR) 하이브리드 = PAB-v4 소비
```
- **역할 분담**: 정본([[PAB-obsidian]])=사람용 **SKOS/MOC**, 소비([[PAB-v4]])=기계용 **graph+vector**. `_schema.json`이 두 세계의 계약.
- **점진·비파괴**: SKOS는 frontmatter/JSON 표현 → Obsidian 정본 무손상. **풀 OWL 비권장**(유지비>편익).

## 5. 2차 고려

- 유지보수: LightRAG식 증분 갱신 + 자동분류로 수작업↓.
- 정합성: `_schema.json` CI + `altLabel` 정규화 + 콘텐츠 해시 재임베딩 트리거.
- 모델교체: 동일 dim(Qwen3-0.6B=1024) 우선 + 병렬 컬렉션 A/B 스왑.

## 연결

- 자료수집: [[2026-07-20_external_data_collection_tooling]] · 비용: [[2026-07-20_llm_api_cost_local_vs_external]]
- 그래프 접목: [[2026-07-01_hugrag_pab_knowledge_graft]] · [[WIKI_ARCHITECTURE]]
