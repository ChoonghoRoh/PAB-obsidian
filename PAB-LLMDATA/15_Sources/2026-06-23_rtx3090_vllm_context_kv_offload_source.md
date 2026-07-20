---
title: "RTX 3090 환경 NVMe·RAM 컨텍스트 한계 극복 전략 보고서 (원본)"
description: "RTX 3090 24GB에서 NVMe·RAM을 외부 기억으로 활용하는 3전략(Letta/CrewAI/Custom Loop) 원본 보고서."
created: 2026-06-23 22:49
updated: 2026-06-23 22:49
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[VLLM]]", "[[KV_CACHE]]", "[[CONTEXT_WINDOW]]"]
tags: [source, vllm, context-window, kv-cache, rtx3090, memgpt, letta, crewai]
keywords: [RTX 3090, NVMe, System RAM, MemGPT, Letta, AutoGen, CrewAI, Custom Python Loop, context window, VRAM paging]
sources: ["PAB-Khala/docs/analysis/20260633-RTX3090_컨텍스트_확장_전략_보고서.md"]
aliases: ["RTX3090 컨텍스트 보고서 원본", "NVMe RAM 컨텍스트 전략 원본"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존

# RTX 3090 환경에서 NVMe·RAM을 활용한 컨텍스트 한계 극복 전략 보고서

## 개요

RTX 3090의 24GB VRAM은 대규모 컨텍스트를 한 번에 적재하기에는 부족하다. 그러나 초고속 NVMe SSD와 넉넉한 System RAM을 **외부 기억 장치(File I/O 및 Paging)** 로 활용하면, 물리적 VRAM 한계를 넘어서는 사실상 무한한 컨텍스트 작업 환경을 구축할 수 있다.

본 보고서는 이를 구현하는 대표적인 세 가지 전략을 정리한다.

| # | 전략 | 핵심 메커니즘 | 적합한 상황 |
|---|------|--------------|------------|
| 1 | MemGPT / Letta | OS 메모리 페이징 차용 (Core ↔ Archival Memory) | 장기 기억이 필요한 자율 에이전트 |
| 2 | AutoGen · CrewAi | 파일 기반 에이전트 순차 릴레이 | 역할 분담형 다단계 협업 |
| 3 | Custom Python Loop | 직접 작성한 워크스페이스 루프 | 오버헤드 없는 경량·견고한 처리 |

---

## 1. MemGPT(현 Letta) — OS 메모리 페이징 기법 차용

MemGPT는 최근 **Letta**라는 이름으로 개편되며, AI 에이전트의 장기 기억(Memory)을 관리하는 독립 서비스(Platform)로 진화했다.

- **공식 GitHub:** https://github.com/letta-ai/letta (기존 MemGPT 통합)

### 핵심 원리

Letta 에이전트는 두 종류의 메모리를 분리해서 관리한다.

- **Core Memory:** VRAM에 항상 상주하는 핵심 컨텍스트(시스템 프롬프트 등)
- **Archival Memory:** NVMe 디스크나 로컬 DB에 저장되는 과거 대화·문서

3090 서버에 로컬 LLM(vLLM 또는 Ollama)을 띄우고, Letta 프레임워크가 모델에게 **Function Calling** 능력을 부여한다. 컨텍스트 윈도우가 가득 찰 것 같으면 모델이 스스로 `core_memory_append` 또는 `archival_memory_search` 함수를 호출해 필요한 정보만 VRAM으로 불러온다. 마치 인간의 해마처럼 NVMe 폴더를 활용하는 방식이다.

### 구축 방법 (3090 서버 기준)

**1) 로컬 모델 서빙 (vLLM 권장)** — Letta는 OpenAI API 규격을 사용한다.

```bash
vllm serve "Qwen/Qwen2.5-14B-Instruct" --port 8000 --max-model-len 8192
```

**2) Letta 설치**

```bash
npm install -g @letta-ai/letta-code
# 또는 구버전: pip install pymemgpt
```

**3) 연결 및 세팅** — `letta configure` 명령으로 LLM 백엔드를 `http://localhost:8000/v1` 로 지정한 뒤 에이전트와 대화를 시작한다.

---

## 2. AutoGen · CrewAi — 파일 시스템 기반 에이전트 릴레이 협업

여러 에이전트가 공통의 `.md` 파일을 VRAM에 스왑(Swap)하며 릴레이로 작업을 이어가도록 구성하는 데 특화된 프레임워크다.

- **CrewAi:** https://github.com/crewaiinc/crewai
- **Microsoft AutoGen (v0.4):** https://github.com/microsoft/autogen

### 핵심 원리

3090 한 장의 24GB VRAM으로는 여러 에이전트를 동시에 적재할 수 없다. 따라서 에이전트를 **순차 실행(Sequential Flow)** 한다.

1. Research Agent가 로드 → 웹 검색 후 결과를 `nvme_drive/research.md`에 기록 → 종료(VRAM 반환)
2. Coding Agent가 VRAM에 로드 → 방금 저장된 `research.md`를 읽어 코드 작성 → `nvme_drive/code.py`에 저장

### 구축 방법 (CrewAi 기준)

**설치** (최신 버전은 `uv` 패키지 매니저 권장)

```bash
uv pip install crewai[tools]
```

**파일 I/O 툴 부여 및 파이프라인 구성** — `FileReadTool`, `FileWriterTool`을 에이전트에 할당한다.

```python
from crewai_tools import FileReadTool, FileWriterTool

# 파일 읽기/쓰기 도구 인스턴스화
file_read_tool = FileReadTool(file_path='workspace/draft.md')
file_write_tool = FileWriterTool(file_path='workspace/final_code.md')

# 에이전트 정의 시 도구 주입
coder = Agent(
    role='Senior Coder',
    goal='Read the draft.md and write final code to final_code.md',
    tools=[file_read_tool, file_write_tool],
    llm=local_llm  # vLLM이나 Ollama 로컬 엔드포인트
)
```

---

## 3. Custom Python Loop — 가장 빠르고 직관적인 워크스페이스 패턴

복잡한 프레임워크의 오버헤드를 피하려는 엔지니어들이 3090 서버에서 가장 선호하는, 원시적이면서도 강력한 방법이다.

### 핵심 원리

Python 내장 함수 `open()`으로 NVMe에 저장된 마크다운 파일을 System RAM으로 즉시 읽고 쓴다. VRAM에는 매 턴마다 **'시스템 프롬프트 + 현재 작업 파일 내용 + 최근 지시사항 1건'** 만 올라가므로 24GB VRAM을 절대 초과하지 않는다.

### 구축 방법 (Python 스크립트)

```python
from openai import OpenAI
import os

# 3090에서 돌아가고 있는 로컬 Ollama 또는 vLLM 서버
client = OpenAI(base_url="http://localhost:8000/v1", api_key="not-needed")
WORKSPACE_FILE = "/path/to/nvme/workspace.md"  # NVMe 경로 지정

def read_workspace():
    if os.path.exists(WORKSPACE_FILE):
        with open(WORKSPACE_FILE, 'r', encoding='utf-8') as f:
            return f.read()
    return "현재 워크스페이스가 비어있습니다."

def write_workspace(content):
    with open(WORKSPACE_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

def run_agent_loop(user_task):
    while True:
        current_state = read_workspace()

        # 컨텍스트 조립: 이전 작업 내역을 프롬프트로 주입
        system_prompt = f"""당신은 자율 에이전트입니다.
        [현재 workspace.md 내용]
        {current_state}

        [지시사항]
        작업을 이어가고, 반드시 전체 내용을 <WORKSPACE> 태그 안에 감싸서 출력하세요. 작업이 끝나면 <DONE>을 출력하세요.
        """

        response = client.chat.completions.create(
            model="Qwen/Qwen2.5-Coder-32B-Instruct",  # 4비트 양자화 시 24GB VRAM 안착 가능
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_task}
            ]
        )

        reply = response.choices[0].message.content

        # 파싱 및 NVMe 덮어쓰기 로직
        if "<WORKSPACE>" in reply:
            new_content = reply.split("<WORKSPACE>")[1].split("</WORKSPACE>")[0]
            write_workspace(new_content.strip())  # VRAM 밖인 NVMe에 저장
            print("NVMe 워크스페이스가 업데이트 되었습니다.")

        if "<DONE>" in reply:
            print("작업 완료!")
            break

        user_task = "계속 진행하세요."  # 루프 지속
```

### 장점

OOM(메모리 초과 에러)으로 서버가 꺼지더라도 `workspace.md` 파일에 이전까지의 **Chain of Thought(사고 과정)** 와 결과물이 그대로 남아 있다. 스크립트만 재실행하면 거의 손실 없이 작업을 재개할 수 있다.

---

## 결론 및 권장 사항

세 전략 모두 "VRAM은 작업 캐시, NVMe·RAM은 영속 기억"이라는 동일한 철학을 공유한다. 선택 기준은 다음과 같다.

- **자율성·장기 기억이 핵심이라면 → Letta**: 모델이 스스로 기억을 페이징하는 가장 정교한 방식.
- **역할 분담형 멀티 에이전트 협업이라면 → CrewAi / AutoGen**: 순차 실행으로 단일 GPU에서도 여러 역할을 구현.
- **최소 오버헤드와 장애 복원력이 우선이라면 → Custom Python Loop**: 가장 가볍고, OOM에도 강한 견고함을 제공.

> 단일 3090 운영 환경에서는 **Custom Python Loop로 시작해 패턴을 검증한 뒤**, 기억 관리가 복잡해지는 시점에 Letta를 도입하는 단계적 접근이 실용적이다.
