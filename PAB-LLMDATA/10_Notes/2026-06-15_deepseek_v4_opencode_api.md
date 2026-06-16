---
title: "DeepSeek V4를 OpenCode에 이식하기 — OpenAI 호환 base_url로 provider 연결 + oh-my-opencode 프레임워크 활용"
description: "NxCode의 DeepSeek V4 API 가이드를 'opencode + oh-my-opencode' 활용 관점으로 재정리. DeepSeek은 OpenAI 호환 API(base_url 교체)라 opencode provider 설정 한 블록으로 이식 가능. deepseek-chat/reasoner 모델 선택, 100만 토큰 컨텍스트, 캐시히트 $0.028/M 기반의 코딩 에이전트 운영 비용 전략까지 정리."
created: 2026-06-15 13:51
updated: 2026-06-15 13:51
type: "[[RESEARCH_NOTE]]"
index: "[[HARNESS]]"
topics: ["[[OPENCODE]]", "[[DEEPSEEK]]"]
tags: [research-note, opencode, deepseek, deepseek-v4, oh-my-opencode, openai-compatible, llm-provider, coding-agent, context-caching, api]
keywords: ["OpenCode", "oh-my-opencode", "DeepSeek V4", "deepseek-chat", "deepseek-reasoner", "base_url", "OpenAI 호환", "provider 설정", "100만 토큰 컨텍스트", "컨텍스트 캐싱", "DEEPSEEK_API_KEY", "코딩 에이전트 비용"]
sources:
  - "[[15_Sources/2026-06-15_deepseek_v4_opencode_api_source]]"
  - "https://www.nxcode.io/ko/resources/news/deepseek-v4-api-guide-pricing-setup-2026"
aliases: ["DeepSeek OpenCode 이식", "deepseek_v4_opencode_api", "opencode DeepSeek provider 설정"]
---

# DeepSeek V4를 OpenCode에 이식하기

> 📌 RESEARCH_NOTE — NxCode 'DeepSeek V4 API 가이드'(2026-03-12)를 **opencode + oh-my-opencode 활용** 관점으로 재구성. 가격·코드 수치는 원본 시점 기준. 원문 보존: [[15_Sources/2026-06-15_deepseek_v4_opencode_api_source|SOURCE]].

## TL;DR — 왜 opencode + DeepSeek인가
[원본 §10 →](2026-06-15_deepseek_v4_opencode_api_source.md#10-마무리)

DeepSeek V4는 **OpenAI 호환 API**라서 [[OpenCode]] 같은 OpenAI-스펙 기반 도구에 **provider 설정 블록 하나**로 꽂힌다. 코드 변경 없이 `base_url`만 `https://api.deepseek.com`으로 바꾸면 끝. 여기에 **캐시히트 $0.028/M 입력 · $0.42/M 출력**이라는 공격적 가격과 **100만 토큰 컨텍스트**가 더해져, 터미널 코딩 에이전트를 저비용으로 상시 돌리기에 유리하다. 사용자 계획은 opencode 위에 **[[oh-my-opencode]]** 프레임워크 레이어를 얹어 운용하는 것 — 그 provider 슬롯에 DeepSeek을 채우는 구도다.

## 0단계 — 이식의 핵심 전제: OpenAI 호환
[원본 §6 →](2026-06-15_deepseek_v4_opencode_api_source.md#6-openai에서-마이그레이션)

opencode 이식이 쉬운 이유는 DeepSeek이 OpenAI Chat Completions 스펙을 그대로 따르기 때문이다. 순수 OpenAI 클라이언트 기준 **딱 2줄**만 바뀐다:

```python
client = OpenAI(
    api_key="sk-deepseek-key-here",
    base_url="https://api.deepseek.com"  # ← 추가
)
response = client.chat.completions.create(
    model="deepseek-chat",               # ← 모델명 교체
    messages=[{"role": "user", "content": "Hello"}]
)
```

→ opencode/oh-my-opencode 입장에서는 "OpenAI 호환 provider 하나 추가"와 동일한 작업으로 환원된다.

## OpenCode provider 연결
[원본 §7 →](2026-06-15_deepseek_v4_opencode_api_source.md#7-오픈소스-도구와-deepseek-사용하기)

원본이 제시한 opencode provider 설정 블록 (DeepSeek 지정):

```json
{
  "provider": {
    "name": "deepseek",
    "apiKey": "sk-your-key",
    "baseURL": "https://api.deepseek.com",
    "model": "deepseek-chat"
  }
}
```

- `apiKey`는 하드코딩 대신 **`DEEPSEEK_API_KEY` 환경변수** 주입 권장 (`export DEEPSEEK_API_KEY="sk-..."`).
- `baseURL`은 OpenAI 호환 엔드포인트 `https://api.deepseek.com` 고정.
- **oh-my-opencode 활용 시**: 이 provider 블록을 프레임워크의 모델/프로파일 설정에 매핑해, 작업 성격별로 `deepseek-chat`(기본)과 `deepseek-reasoner`(추론) 프로파일을 분리 운용하는 것이 핵심 패턴. (※ oh-my-opencode의 구체적 키 스키마는 해당 프레임워크 설정 규약을 따라야 하며, 위 블록은 opencode 표준 provider 형태다.)
- 동일 패턴으로 Aider(`OPENAI_API_BASE` + `--model openai/deepseek-chat`), Continue(`apiBase`/`apiKey`)도 연결 가능 — 모두 OpenAI 호환 슬롯에 끼우는 방식.

## 모델 선택 — deepseek-chat vs deepseek-reasoner
[원본 §3 →](2026-06-15_deepseek_v4_opencode_api_source.md#3-api-모드-deepseek-chat-vs-deepseek-reasoner)

opencode 에이전트의 작업 유형에 따라 모델을 갈라 쓰는 게 비용·품질의 핵심.

| 모델 | 최대 입력 | 최대 출력 | 코딩 에이전트 용도 |
|---|---|---|---|
| `deepseek-chat` | 1,000,000 | 8,192 | 기본값 — 코드 생성, 편집, 요약, 일반 Q&A |
| `deepseek-reasoner` | 1,000,000 | 64,000 | 복잡한 디버깅, 다단계 추론, 수학/논리 증명 |

- **기본은 `deepseek-chat`**. `deepseek-reasoner`는 "진짜 다단계 추론"이 필요할 때만 (비용·지연 더 큼).
- `deepseek-reasoner`는 `reasoning_content`(사고 체인)와 `content`(최종 답)를 분리 반환 — opencode UI에서 추론 과정 노출 여부를 결정할 포인트.

## 100만 토큰 컨텍스트 — 코드베이스 통째로 투입
[원본 §8 →](2026-06-15_deepseek_v4_opencode_api_source.md#8-100만-토큰-컨텍스트-윈도우-활용하기)

- 50,000줄(중간 규모 프로젝트) ≈ 50만 토큰 → **프로젝트 전체를 한 컨텍스트에** 넣고 아키텍처 리뷰·교차 파일 리팩토링·보안 감사 가능.
- opencode 운용 팁: ① 파일 트리 먼저 제공 ② `--- FILE: src/auth.py ---` 식 명확한 구분자 ③ 집중된 질문 ④ 캐싱과 결합.

## 비용 구조와 캐싱 전략
[원본 §2 →](2026-06-15_deepseek_v4_opencode_api_source.md#2-요금-상세-분석)

| 토큰 유형 | 백만 토큰당 |
|---|---|
| 입력 (캐시 히트) | **$0.028** |
| 입력 (캐시 미스) | **$0.28** |
| 출력 | **$0.42** |

- 캐시 히트 시 입력 단가가 OpenAI 대비 약 **90배**, Claude Opus 대비 **500배** 저렴 (원본 주장).
- **컨텍스트 캐싱**([원본 §5 →](2026-06-15_deepseek_v4_opencode_api_source.md#5-컨텍스트-캐싱-반복-프롬프트-90-절감)): 프롬프트 **앞부분(prefix)**이 이전 호출과 일치하면 자동 캐시. opencode에서 시스템 프롬프트/프로젝트 컨텍스트를 **고정·선두 배치**하면 반복 호출이 캐시 히트로 떨어져 비용 급감.
- 캐시 효과 측정: 응답의 `usage.prompt_cache_hit_tokens` / `prompt_cache_miss_tokens`로 모니터링.

## OpenCode 운용 비용 최적화 체크리스트
[원본 §9 →](2026-06-15_deepseek_v4_opencode_api_source.md#9-비용-최적화-모범-사례)

1. **고정 콘텐츠를 메시지 선두에** — 시스템 프롬프트/프로젝트 컨텍스트를 앞에 두어 캐시 히트 극대화.
2. **기본 모델 = deepseek-chat**, `reasoner`는 선별 사용.
3. `max_tokens`는 작업에 맞게 (실제 생성량만 과금되므로 상한은 넉넉히 둬도 무방).
4. 같은 시스템 프롬프트를 쓰는 요청은 **연속 배치** 처리.
5. 토큰 사용량 상시 모니터링.
6. 긴 출력엔 스트리밍 — 비용 절감은 아니지만 체감 지연 개선.

## 시작 절차 요약
[원본 §1 →](2026-06-15_deepseek_v4_opencode_api_source.md#1-빠른-시작-첫-번째-deepseek-api-호출)

1. `platform.deepseek.com` 가입 → 신규 계정 **500만 무료 토큰** (신용카드 불필요).
2. 대시보드 → API Keys → Create new API key → `export DEEPSEEK_API_KEY="sk-..."`.
3. opencode provider 블록에 `baseURL: https://api.deepseek.com`, `model: deepseek-chat` 설정.
4. oh-my-opencode 프로파일에서 chat/reasoner 분리 → 무료 토큰으로 벤치마크 후 본격 전환.

---

## PAB 관점 메모
- DeepSeek은 외부 클라우드 API이므로, PAB의 **로컬 LLM(`/v1/` ollama)·데이터 주권 기조**와는 트레이드오프 관계 — 관련: [[2026-05-27_pab_mcp_model_sizing|PAB × MCP × 모델 사이즈]]의 "엔터프라이즈/외부 모델은 데이터 주권·비용 때문에 기본 선택지가 아니다" 논점과 같은 축에서 검토 필요.
- 다만 **코딩 에이전트(opencode) 보조 도구**로서는 비용·컨텍스트 이점이 커, 민감 데이터가 닿지 않는 작업(공개 OSS 리뷰, 보일러플레이트 생성 등)에 한정 투입하는 분리 운용이 현실적.

## 참고
- 원본(immutable): [[15_Sources/2026-06-15_deepseek_v4_opencode_api_source]]
- 외부 출처: https://www.nxcode.io/ko/resources/news/deepseek-v4-api-guide-pricing-setup-2026
