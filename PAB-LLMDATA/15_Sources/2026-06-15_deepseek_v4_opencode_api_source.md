---
title: "DeepSeek V4 API 가이드: 요금, 설정 및 코드 예제 (2026) — NxCode (원본)"
description: "NxCode (2026-03-12): DeepSeek V4 API 완전 가이드. 500만 무료 토큰, 캐시히트 $0.028/M 입력·$0.42/M 출력, deepseek-chat vs deepseek-reasoner, 100만 토큰 컨텍스트, OpenAI 호환 base_url 2줄 마이그레이션, OpenCode·Aider·Continue 연동. 원본 immutable 보존."
created: 2026-06-15 13:51
updated: 2026-06-15 13:51
type: "[[SOURCE]]"
index: "[[HARNESS]]"
topics: ["[[OPENCODE]]", "[[DEEPSEEK]]"]
tags: [source, deepseek, deepseek-v4, api, opencode, openai-compatible, pricing, context-caching, llm-provider, nxcode]
keywords: ["DeepSeek V4", "deepseek-chat", "deepseek-reasoner", "API 가격", "컨텍스트 캐싱", "base_url", "OpenAI 호환", "100만 토큰 컨텍스트", "OpenCode", "Aider", "Continue", "500만 무료 토큰", "prompt_cache_hit_tokens"]
sources:
  - "https://www.nxcode.io/ko/resources/news/deepseek-v4-api-guide-pricing-setup-2026"
aliases: ["DeepSeek V4 API 가이드 원본", "deepseek_v4_opencode_api_source", "NxCode DeepSeek V4 원문"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy 3계층의 SOURCE 계층)

# DeepSeek V4 API 가이드: 요금, 설정 및 코드 예제 (2026)

**출처:** NxCode (https://www.nxcode.io/ko/resources/news/deepseek-v4-api-guide-pricing-setup-2026)
**작성일:** 2026-03-12
**저자:** NxCode Team
**읽기시간:** 11 min read

## 메타데이터
- **제목**: DeepSeek V4 API 가이드: 요금, 설정 및 코드 예제 (2026)
- **출처**: NxCode
- **작성일**: 2026-03-12
- **저자**: NxCode Team
- **읽기시간**: 11 min read

## 1. 빠른 시작: 첫 번째 DeepSeek API 호출

### 1단계: 계정 생성
"[platform.deepseek.com](https://platform.deepseek.com)에 가입하세요. 신규 계정은 신용카드 없이 **500만 무료 토큰**을 받을 수 있어"

### 2단계: API Key 생성
- 대시보드에서 API Keys로 이동
- Create new API key 클릭
- 환경 변수 저장:
```
export DEEPSEEK_API_KEY="sk-your-key-here"
```

### 3단계: 첫 번째 요청 보내기
설치:
```
pip install openai
```

Python 코드:
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-your-key-here",
    base_url="https://api.deepseek.com"
)

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain Python decorators in three sentences."}
    ]
)

print(response.choices[0].message.content)
```

## 2. 요금 상세 분석

### DeepSeek API 요금 표

| 토큰 유형 | 백만 토큰당 비용 |
|---------|-----------------|
| 입력 (캐시 히트) | **$0.028** |
| 입력 (캐시 미스) | **$0.28** |
| 출력 | **$0.42** |

### 경쟁사 비교 표

| 제공업체 / 모델 | 입력 (백만당) | 출력 (백만당) |
|----------------|-------------|------------|
| **DeepSeek V4 (캐시 히트)** | $0.028 | $0.42 |
| **DeepSeek V4 (캐시 미스)** | $0.28 | $0.42 |
| OpenAI GPT-5.4 | $2.50 | $10.00 |
| Anthropic Claude Opus 4.6 | $15.00 | $75.00 |
| Google Gemini 3.1 Pro | $1.25 | $5.00 |

### 비용 분석
"캐시 히트 시 DeepSeek은 입력 토큰에서 OpenAI보다 약 **90배**, Claude Opus보다 **500배 저렴**합니다"

### 비용 예시
- 100개 요청 처리
- 각 요청: 2,000 토큰 시스템 프롬프트 + 500 토큰 사용자 쿼리 + 1,000 토큰 응답

결과:
- **캐싱 사용 (99회 캐시 히트)**: 총 약 $0.05
- **캐싱 미사용**: 총 약 $0.29
- **동일 작업량을 GPT-5.4로**: 총 약 $3.75

## 3. API 모드: deepseek-chat vs deepseek-reasoner

### deepseek-chat (범용 모드)

| 속성 | 값 |
|-----|-----|
| 최대 입력 토큰 | 1,000,000 |
| 최대 출력 토큰 | 8,192 |
| 적합한 용도 | 채팅, 요약, 코드 생성, 일반 Q&A |

### deepseek-reasoner (Chain-of-Thought 모드)

| 속성 | 값 |
|-----|-----|
| 최대 입력 토큰 | 1,000,000 |
| 최대 출력 토큰 | 64,000 |
| 적합한 용도 | 수학, 논리 퍼즐, 복잡한 디버깅, 다단계 추론 |

추론 모드 코드:
```python
response = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=[
        {"role": "user", "content": "Prove that the square root of 2 is irrational."}
    ]
)

# The reasoning chain
print(response.choices[0].message.reasoning_content)

# The final answer
print(response.choices[0].message.content)
```

**사용 지침**: "다단계 논리, 수학적 증명 또는 복잡한 코드 디버깅이 필요한 작업에는 `deepseek-reasoner`를 사용하세요"

## 4. 코드 예제

### Python: 기본 채팅 완성

```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url="https://api.deepseek.com"
)

def ask_deepseek(prompt, system_prompt="You are a helpful assistant."):
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        max_tokens=2048
    )
    return response.choices[0].message.content

answer = ask_deepseek("Write a Python function to merge two sorted lists.")
print(answer)
```

### Python: 스트리밍

```python
stream = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "system", "content": "You are a senior software engineer."},
        {"role": "user", "content": "Review this code and suggest improvements:\n\ndef fib(n):\n  if n <= 1: return n\n  return fib(n-1) + fib(n-2)"}
    ],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### Python: 추론 모드

```python
response = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=[
        {"role": "user", "content": "Find all bugs in this code and explain why each is a bug:\n\ndef quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n    pivot = arr[0]\n    left = [x for x in arr if x < pivot]\n    right = [x for x in arr if x > pivot]\n    return quicksort(left) + [pivot] + quicksort(right)"}
    ]
)

print("Reasoning:", response.choices[0].message.reasoning_content)
print("Answer:", response.choices[0].message.content)
```

### JavaScript / Node.js: 기본 채팅

```javascript
import OpenAI from "openai";

const client = new OpenAI({
  apiKey: process.env.DEEPSEEK_API_KEY,
  baseURL: "https://api.deepseek.com",
});

async function askDeepSeek(prompt) {
  const response = await client.chat.completions.create({
    model: "deepseek-chat",
    messages: [
      { role: "system", content: "You are a helpful assistant." },
      { role: "user", content: prompt },
    ],
  });

  return response.choices[0].message.content;
}

const answer = await askDeepSeek("Explain closures in JavaScript.");
console.log(answer);
```

### JavaScript / Node.js: 스트리밍

```javascript
const stream = await client.chat.completions.create({
  model: "deepseek-chat",
  messages: [
    { role: "user", content: "Write a REST API in Express.js with CRUD routes for a todo app." },
  ],
  stream: true,
});

for await (const chunk of stream) {
  const content = chunk.choices[0]?.delta?.content;
  if (content) {
    process.stdout.write(content);
  }
}
```

## 5. 컨텍스트 캐싱: 반복 프롬프트 90% 절감

### 작동 방식
"요청을 보내면 DeepSeek은 프롬프트의 시작 부분이 이전에 캐시된 접두사와 일치하는지 확인합니다"

캐싱 요금: 캐시된 토큰 $0.028/M vs 일반 입력 $0.28/M

### 캐싱이 활성화되는 경우
- "모든 요청이 'You are a senior Python developer...'로 시작하면, 해당 접두사는 첫 번째 호출 후 캐시됩니다"
- 다중 턴 대화의 누적 기록
- 일관된 템플릿을 사용한 배치 처리

### 캐시 히트 최대화 전략
1. 정적 콘텐츠를 먼저 배치
2. 시스템 프롬프트를 동일하게 유지
3. 유사한 요청을 함께 배치
4. 긴 시스템 프롬프트를 자신있게 사용

## 6. OpenAI에서 마이그레이션

### 마이그레이션 전 (OpenAI)
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-openai-key-here"
    # base_url defaults to https://api.openai.com/v1
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Hello"}]
)
```

### 마이그레이션 후 (DeepSeek)
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-deepseek-key-here",
    base_url="https://api.deepseek.com"  # <-- add this line
)

response = client.chat.completions.create(
    model="deepseek-chat",              # <-- change the model name
    messages=[{"role": "user", "content": "Hello"}]
)
```

"이것이 전체 마이그레이션입니다. `base_url`과 `model` 두 줄만 변경했습니다"

### 환경 변수 방식 (프로바이더 전환용)

```python
import os
from openai import OpenAI

provider = os.getenv("LLM_PROVIDER", "deepseek")

config = {
    "deepseek": {
        "api_key": os.getenv("DEEPSEEK_API_KEY"),
        "base_url": "https://api.deepseek.com",
        "model": "deepseek-chat"
    },
    "openai": {
        "api_key": os.getenv("OPENAI_API_KEY"),
        "base_url": "https://api.openai.com/v1",
        "model": "gpt-4o"
    }
}

client = OpenAI(
    api_key=config[provider]["api_key"],
    base_url=config[provider]["base_url"]
)
```

## 7. 오픈소스 도구와 DeepSeek 사용하기

### OpenCode
"오픈소스 터미널 기반 AI 코딩 어시스턴트입니다. 설정에서 프로바이더를 지정하여 DeepSeek을 사용하세요"

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

### Aider
"명령줄 AI 페어 프로그래밍 도구입니다"

```bash
export OPENAI_API_BASE="https://api.deepseek.com"
export OPENAI_API_KEY="sk-your-deepseek-key"
aider --model openai/deepseek-chat
```

### Continue (VS Code 확장)
"VS Code와 JetBrains용 오픈소스 AI 코드 어시스턴트입니다"

`~/.continue/config.json`에 추가:
```json
{
  "models": [
    {
      "title": "DeepSeek V4",
      "provider": "openai",
      "model": "deepseek-chat",
      "apiBase": "https://api.deepseek.com",
      "apiKey": "sk-your-key"
    }
  ]
}
```

## 8. 100만 토큰 컨텍스트 윈도우 활용하기

### 전체 코드베이스 분석
"일반적인 중간 규모 프로젝트(50,000줄 코드)는 약 500,000 토큰입니다"

가능한 작업:
- **아키텍처 리뷰**: 순환 의존성, 누락된 추상화, 일관성 없는 패턴 식별
- **교차 파일 리팩토링**: 여러 파일에 걸쳐 조율된 편집 생성
- **보안 감사**: SQL 인젝션, XSS 및 기타 취약점 스캔

### 대규모 컨텍스트를 위한 팁
1. 파일 트리를 먼저 제공
2. 명확한 구분자 사용 (예: `--- FILE: src/auth.py ---`)
3. 집중된 질문 작성
4. 캐싱과 결합하여 사용

## 9. 비용 최적화 모범 사례

### 1. 캐시 히트 최대화
"가장 길고 안정적인 콘텐츠를 메시지 배열의 시작 부분에 배치하세요"

### 2. 기본적으로 deepseek-chat 사용
"`deepseek-reasoner`는 진정으로 다단계 추론이 필요한 작업에만 사용하세요"

### 3. 적절한 max_tokens 설정
"200 토큰 응답을 예상한다면 `max_tokens: 8192`로 설정해도 비용이 더 들지는 않지만"

### 4. 유사한 요청 배치 처리
"동일한 시스템 프롬프트를 공유하는 요청을 그룹화하고 빠르게 연속 전송하세요"

### 5. 토큰 사용량 모니터링

```python
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "Hello"}]
)

print(f"Input tokens: {response.usage.prompt_tokens}")
print(f"Output tokens: {response.usage.completion_tokens}")
print(f"Cache hit tokens: {response.usage.prompt_cache_hit_tokens}")
print(f"Cache miss tokens: {response.usage.prompt_cache_miss_tokens}")
```

### 6. 긴 출력에 스트리밍 사용
"스트리밍은 비용을 절감하지 않지만 체감 지연 시간을 개선합니다"

## 10. 마무리

"DeepSeek의 API는 공격적인 가격, OpenAI 호환성, 100만 토큰 컨텍스트 윈도우를 하나의 패키지로 결합하여 무시하기 어렵습니다"

핵심 이점:
- OpenAI에서 코드 2줄만 변경으로 마이그레이션
- 컨텍스트 캐싱으로 자동 비용 절감
- 오픈소스 도구 생태계 지원

"500만 무료 토큰으로 시작하여 현재 프로바이더와 벤치마크를 비교하고 숫자가 결정을 이끌도록 하세요"

---

**© 2026 NxCode. All rights reserved.**
