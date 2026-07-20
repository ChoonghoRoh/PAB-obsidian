---
title: "PAB-Khala tools/run 빈 응답·버그·개선점 조사 (원본)"
description: "khala /v1/tools/run의 max_iter 빈 final_response·status=ok 오염(제어토큰·CoT 누출) 버그와 개선점(FIX-A~F)·자동 loop 설계 검토 원문"
created: 2026-07-02 14:24
updated: 2026-07-02 14:24
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]", "[[VLLM]]"]
tags: ["source", "khala", "tools-run", "bug", "max-iter", "issue"]
keywords: ["khala", "tools-run", "max_iter", "final_response", "제어토큰누출", "degeneration", "cot누출", "no-data-exit", "적응형종료", "qwen3.6"]
sources: ["docs/overview/260702-Khala-toolsrun-빈응답-버그·개선점.md"]
aliases: ["tools-run 이슈 원본", "khala 빈응답 버그 원본"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 출처: PAB-v4 리포 `docs/overview/260702-Khala-toolsrun-빈응답-버그·개선점.md`

> **검증환경**: khala `100.109.251.86:8765` (Khala API Gateway v0.2) · PAB-v4 `:8001` · 3800x · **분류**: 버그/개선 기록 (외부조회 khala 연동)

# Khala `/v1/tools/run` 빈 응답(max_iter) 버그 · 개선점

## TL;DR

- 없는(또는 찾기 어려운) 내용을 물으면 `/v1/tools/run`이 **`status="max_iter"` + `final_response=""`(빈 문자열)** 로 종료 → 클라이언트가 `final_response`만 읽으면 **조용한 실패**.
- 브라우저 콘솔의 `undefined`는 **`console.log()`의 반환값**일 뿐, 데이터 값이 아님(오해 주의).
- 실제로는 "내용이 없어서"가 아니라 **`max_iter`가 낮아 요약 단계 진입 전 컷** 된 경우가 많음(SSOT 문서 #11은 존재했음).
- 해결: ① 클라이언트가 `status` 확인 ② `max_iter≥8` + system에 수렴/포기 지시 ③ (선택) khala 서버측 max_iter 종료 시 best-effort 요약 강제.
- **(2026-07-02 보강)** `status="ok"`라도 `final_response`가 **깨질 수 있음** — 없는 내용 질의 시 모델이 `<tool_call>`/`</think>` **제어토큰을 누출·반복**(사례1)하거나 **사고과정을 그대로 출력**(사례2). ⇒ status 확인만으론 부족, **출력 내용 검증 필요**. (상세 §5)

---

## 1. 증상 / 재현

브라우저 콘솔에서 `/v1/tools/run` 호출 후 `console.log(d.final_response)` → 화면엔 빈 줄 + `undefined`만.

재현 요청(유저 실제 입력):
```json
{
  "prompt": "SSOT 관련 내용 중 필수 사항에 대해서 설명해줘. 한글로 알려줘",
  "system": "사고 과정을 출력하지 마라. pab_lv0 도구로 근거 조회 후 최종 답을 요약해줘. 요약해서 얘기해줘, 각 줄 끝에 (#id).",
  "tools": ["pab_lv0_search_text","pab_lv0_get_document"],
  "max_iter": 5, "max_tokens": 1800, "temperature": 0,
  "metadata": { "caller":"manual:hoseong", "request_id":"run-clean-2" }
}
```

전체 응답(재현 결과):

| 필드 | 값 |
|---|---|
| HTTP | `200` (정상) |
| `status` | **`max_iter`** |
| `error` | **`"max_iter (5) reached without final response"`** |
| `final_response` | `""` (빈 문자열) |
| `iterations` | 5 (상한 도달) |
| `tool_calls_log` | 6건 — 검색 3 + 문서읽기 3 (그중 doc#11 full 14,436B) |

---

## 2. 버그/오해 목록

### BUG-1 (DX, 중간) — max_iter 종료 시 빈 `final_response` = 조용한 실패
- `/v1/tools/run`은 tool-loop가 `max_iter`에 도달하면 최종 답 생성 없이 **`final_response=""`** 로 반환한다.
- `status`/`error`에는 정보가 실려 있으나, 클라이언트가 관습적으로 `final_response`만 읽으면 **아무 신호 없이 빈 답**이 된다.
- 위치(추정): `scripts/api/handlers/tools.py`의 `run_tools()` → `openai_chat.tool_loop_openai`의 반복 종료 분기.

### NOTE-2 (오해, 버그 아님) — 콘솔 `undefined`의 정체
- DevTools는 실행 스니펫의 **마지막 표현식 완료값**을 echo한다. 스니펫이 `console.log(...)`로 끝나면 그 **반환값 `undefined`** 가 찍힌다.
- 즉 `VM….:NN` 뒤 빈 줄 = 실제 `final_response`(빈 문자열), 그 아래 `undefined` = `console.log` 반환값.
- 데이터가 `undefined`인 게 아니다 → 이걸 에러로 오해하지 말 것.

### ROOT-3 — "없는 내용"이 아니라 "못 끝냄"
- `pab_lv0_search_text(q="SSOT")` 는 **5건** 반환, 그중 **doc #11이 SSOT 정본 문서**. 내용은 존재했다.
- 그런데 결정적 텍스트검색 특성상 `"SSOT 필수 사항"` 같은 **다중어 구는 거의 0매치**(result_size 116·305) → 모델이 `SSOT 필수사항→SSOT→SSOT 필수`로 **쿼리를 바꿔가며 재검색** → 반복 낭비.
- `max_iter=5` + full 문서(14KB) 읽기로 반복 소진 → **요약 단계 진입 전 컷**.
- system에 "근거 모이면 즉시 답 / 없으면 없다고 하라"는 **종료 조건이 없어** 수렴 실패.

### BUG-4 (심각) — 제어토큰 누출·반복: `status=ok`인데 출력이 쓰레기
- 없는 내용(예: '아시아나 IDT' — `q=아시아나` 검색 **0건**)을 물으면, 모델이 근거를 못 찾고 **`<tool_call>`/`</think>` 챗템플릿 제어토큰을 텍스트로 누출하며 무한 반복**(사례1).
- 재현: `status="ok"`·iter=4, 정상 tool 3회(`아시아나 IDT→IDT→아시아나` 검색, 전부 무의미) 후 `final_response`(7,389자)가 `<tool_call>\nIDT\n</think>` × 수십 회.
- **위험도 상**: `status="ok"` + `final_response` 非빈값이라 **FIX-A(status 확인)로도 안 걸러진다.** 클라이언트엔 '성공'으로 보이나 내용은 쓰레기. system의 '자료 없으면 없다고 해'도 **무시됨**. 상세 §5.

### BUG-5 (중간) — 사고과정 누출 + 도구 미호출: `status=ok`인데 답이 아님
- 전용 문서 없는 주제('Karpathy LLM Wiki' — 언급 수준 5건)에서 모델이 **도구를 한 번도 안 부르고**(`tool_calls_log=[]`) 1턴에 **사고과정을 그대로 텍스트로 출력**하고 종료(사례2).
- 재현: `status="ok"`·iter=1·tools=[], `final_response`(6,229자)=`"Here's a thinking process: 1. Understand User Request..."`.
- system '사고 과정 출력 금지'가 **지켜지지 않음.** '금지'+'최대한 자세히' **상충**이 악화. 역시 status로 안 걸림. 상세 §5.

---

## 3. 개선점

### FIX-A (클라이언트) — `status` 확인 필수 ★
`final_response`만 보지 말고 `status`를 먼저 분기한다.
```js
const d = await r.json();
if (d.status === 'ok') {
  console.log(d.final_response);
} else {
  console.warn(`⚠ [${d.status}] ${d.error}`);
  console.log('찾은 근거:', d.tool_calls_log?.map(c => `${c.name}(${JSON.stringify(c.arguments)})`));
}
// ※ 스니펫을 console.log로 끝내면 콘솔이 undefined를 echo함 — 마지막 줄을 `d`로 두면 깔끔
```
**FIX-A2 (보강) — `status="ok"`도 못 믿음(BUG-4/5): 출력 내용까지 검증** ★
```js
function looksBroken(t){
  if(!t) return true;
  if(/<\/?(tool_call|think)>/.test(t)) return true;                              // 제어토큰 누출(BUG-4)
  if(/Here's a thinking process|Understand User Request/i.test(t)) return true;  // CoT 누출(BUG-5)
  const s=t.slice(0,60); if(s && t.split(s).length>4) return true;               // 반복 degeneration
  return false;
}
const usable = d.status==='ok' && !looksBroken(d.final_response);
```

### FIX-B (프롬프트/파라미터) — 수렴 강제
- `max_iter` **≥ 8** (기본값 8. 5로 낮춘 게 화근).
- system에 종료 조건 명시: **"도구는 최대 N회, 근거 모이면 즉시 답, 없으면 추측 말고 '해당 LV0 근거 없음'이라고 답하라."**
- 큰 문서는 `detail=summary` 우선, `full`은 꼭 필요할 때만 → 반복·토큰 절약.

### FIX-C (khala 서버, 선택) — max_iter 종료 시 best-effort 요약 강제
- `scripts/api/handlers/tools.py`(→ `openai_chat.tool_loop_openai`)에서 **max_iter 도달 시, 지금까지 모은 tool 결과를 컨텍스트로 tools 없이 LLM 1회 호출** 하여 `final_response`를 채운다.
- 효과: 빈 문자열 반환 자체가 사라지고, 최소한 "모은 근거 요약 + 불충분 고지"가 나온다.
- (참고: caller 화이트리스트 `scripts/api/auth.py` 주석 — "PoC. 운영 단계에 API key로 진화". tool-loop도 PoC 성격.)

### FIX-D (외부 caller) — 전용 prefix 등록
- 외부 프로그램 연동 시 대시보드 caller(`khala-self:`) 재사용 대신 `scripts/api/auth.py`의 `ALLOWED_CALLERS`에 전용 prefix 추가 후 재시작:
```python
ALLOWED_CALLERS = [ ..., re.compile(r"^myapp:[\w\-]+$") ]
```
- 개인/수동 테스트는 기존 `manual:<이름>` prefix로 충분(등록 불필요, 검증됨).

### FIX-E (khala 서버, 권장) — 출력 정화로 오염을 `status`에 반영 ★
- tool-loop 최종 반환 직전(`openai_chat.tool_loop_openai`)에서 `final_response`의 **제어토큰(`<tool_call>`,`</think>`,`<think>`) 누출·반복 degeneration을 탐지**해, 있으면 `status`를 `ok`가 아닌 `degenerate`/`invalid`로 세팅(또는 tools 없이 1회 재생성).
- 목적: BUG-4/5처럼 `status=ok`로 새어나가는 오염 출력을 **클라이언트가 status만 보고 걸러낼 수 있게** (지금은 FIX-A2처럼 클라가 내용검증을 떠안아야 함).

### FIX-F (모델/디코딩) — degeneration 억제
- 제어토큰 누출·반복은 quantized 27B(`qwen3.6-27b-autoround`)의 tool-calling/stop-token 취약성 신호.
- 대책: (a) 디코딩 `repetition_penalty`/`no_repeat_ngram`, (b) `</think>`·`<tool_call>`를 stop 토큰으로 정확히 설정(템플릿 정합), (c) tool-calling 신뢰도 높은 모델 검토, (d) `tools` 지정 시 **1턴째 tool 미호출 텍스트는 최종답으로 수용 금지** → '도구 먼저 호출' 재프롬프트(BUG-5 방지).

---

## 4. 검증 — 고친 버전은 수렴함 (before/after)

FIX-B 적용(`max_iter:8` + system에 "도구 최대 3회 후 즉시 답, 없으면 없음 선언"):

```
status = ok | iterations = 4 | error = None
호출도구 = search(SSOT) → get_document(11,summary) → get_document(11,full)
```
```
SSOT(Single Source of Truth)는 Claude Code Agent Teams 운영 정본으로 Core(0~5)·Common·SUB-SSOT 3계층으로 구성된다 (#11).
필수 사항으로 세션 시작 시 Team Lead의 Core 풀로드(FRESH-1)와 공통 레이어 동반 로딩(FRESH-11)이 강제된다 (#11).
Phase 진입 시 상태파일 읽기(ENTRY)·실행 중 SSOT 변경 차단(LOCK)을 준수하고, 역할별 SUB-SSOT로 토큰 60%를 절감한다 (#11).
```
→ **같은 질문, 파라미터·system만 바꿔 4회 만에 수렴.** 빈 답 재발 없음.

---

## 5. 추가 사례 상세 (2026-07-02 보강) — status=ok인데 오염된 출력

콘텐츠 존재 확인(deterministic search): `q=아시아나`→**0건** · `q=IDT`→2건(무관: Qwen 서빙 글) · `q=Karpathy`→5건(전용문서 아님·언급 수준).

### 사례 1 — "아시아나 IDT 설명" (없는 내용 → 제어토큰 누출·반복)
- 입력: `max_iter:5`, system에 '자료 없으면 없다고 해' 포함. 브라우저 콘솔 출력:
```
<tool_call>
IDT
</think>
   … (위 4줄이 수십 회 반복) …
```
- 재현 envelope: `status=ok · iter=4 · tools=[search('아시아나 IDT'), search('IDT'), search('아시아나')] · final_response 7,389자(제어토큰 반복)`.
- 진단: 근거 0건 → 모델이 '없음' 선언 대신 **템플릿 제어토큰을 누출하며 degeneration**. `status=ok`라 status 확인으로 못 걸림 → **BUG-4**.

### 사례 2 — "Karpathy LLM Wiki 핵심주장" (전용문서 없음 → 사고과정 누출)
- 입력: `max_iter:5`, system '사고 과정 출력 금지'+'최대한 자세히'. 콘솔 출력:
```
Here's a thinking process:
1.  Understand User Request: … (사고 독백이 그대로) …
```
- 재현 envelope: `status=ok · iter=1 · tools=[] (도구 미호출) · final_response 6,229자(CoT 텍스트)`.
- 진단: 모델이 도구를 안 부르고 **사고과정을 최종답으로 출력**. '사고과정 금지' 지시 무시 + 지시 상충 → **BUG-5**.

### 공통 결론
`status="ok"`는 **정상 출력을 보장하지 않는다.** 위 두 유형은 status로 안 걸리므로 **출력 내용 검증(FIX-A2) + 서버측 정화(FIX-E) + 디코딩/모델 보강(FIX-F)** 이 함께 필요. 근본 원인은 quantized 소형 모델(`qwen3.6-27b-autoround`)의 **tool-call 포맷·CoT 억제·'없음' 선언 신뢰성 부족**.

---

## 6. 설계 검토 — 자동 loop 제어 · no-data exit · 사용자 옵션 (개발방향 미정)

> 배경: BUG-1/4/5의 근본은 "loop 제어·종료 조건 부재". 사용자가 `max_iter`·exit 조건을 손으로 박지 않고 **시스템이 알아서** 판단·안내하게 하는 설계를 검토한다. **개발 착수 여부·순서는 추후 결정** (본 절은 타당성·설계안 기록용).

### 6.0 현재 loop는 순수 reactive (코드 근거)

`tool_loop_openai` — `scripts/run-on-3800x-v5/lib/openai_chat.py`:
```python
for i in range(max_iter):
    tool_calls = msg.get("tool_calls") or []
    if not tool_calls:
        final = msg.get("content") or msg.get("reasoning") or ""   # ← BUG-5 누출 지점
        return { "status":"ok", "final_response": final, ... }      # 모델이 뭘 뱉든 최종답 확정
return { "status":"max_iter", "final_response":"", ... }            # 소진 시 빈 답
```
- 종료 조건 = "모델이 tool_call을 안 하면 끝" 하나뿐. **planner·수렴감지·no-data exit 전무.**
- `final = content or reasoning` → 도구 없이 **reasoning(CoT)만 뱉으면 그게 final_response** (BUG-5 코드 근거 확정).
- 웹'검색' 도구 없음 (`fetch_url` = 지정 URL fetch만).

### 6.1 Q1 — 질문에서 필요한 loop 횟수 산정: **가능** (현재 없음)

| 방식 | 내용 | 비용 | 삽입점 |
|---|---|---|---|
| A. Planner 사전패스 | loop 전 값싼 LLM 1콜로 질문 분류 → 예상 iter(단순조회 2~3 / 다문서종합 5~6 / 전체조사 8~10 / 희박 3후 포기) | vLLM 짧은 1콜 | `run_tools` 진입부 |
| B. 휴리스틱(LLM 0) | 질문 토큰으로 즉석 산정("비교/전체/목록"↑, "설명/뭐야"↓) | 0 | 동일 |
| **C. 적응형 종료 ★** | `max_iter`는 **상한**으로만, loop 내부에서 **수렴 감지**로 조기 종료 | 0 | `for` 루프 내부 |

- 권장 **C (+선택 A)**. 미리 횟수를 맞히기보다 **실제 신호로 멈춤**: 최근 2회 tool 결과가 (a) 0건 또는 (b) 직전과 동일(중복 검색)이면 "충분히 탐색" 판정 → 모델에 *"이제 답하거나 '없다'고 하라"* 강제.
- 효과: **사용자가 `max_iter`를 손댈 필요 소멸** (요구의 핵심).

### 6.2 Q2 — 산정 결과를 시스템에 유동 지정: **가능** (2층위)

API가 이미 `max_iter/tools/max_tokens`를 요청별로 받음.
- **클라이언트 오케스트레이션** (khala 무변경, 지금 당장): 래퍼가 Q1을 돌려 값 정하고 `/v1/tools/run` 호출.
- **서버 `auto` 모드 ★** (khala 변경, 더 깔끔): `ToolsRunRequest`에 `max_iter: "auto"` 허용 → 서버가 planner/적응형으로 자동 산정. **클라·사용자 모두 값 미지정 가능** → "제어 필요 없음" 요구에 정확히 부합.

### 6.3 Q3 — exit 시 사용자 옵션 제시(없음/빈약 → 다음 행동): **가능**

핵심 = 종료를 자유 텍스트가 아니라 **구조화된 outcome**으로:
```
outcome ∈ { answered, no_data, thin_data, ambiguous, degenerate }
```

| outcome | 트리거 | 사용자에게 제시 |
|---|---|---|
| no_data | `search_text` 0건 | "요청 데이터가 LV0에 없습니다" + **`pab_lv0_list_keywords`로 vault 실존 저자 키워드/태그를 뽑아 '가까운 검색어' 추천** → "다른 검색어로 진행할까요?" |
| thin_data | 결과 1~2건 | "자료가 적습니다 → (a) 요약만 (b) `pab_lv0_get_links` 연결 확장 (c) 웹 검색 조합?" |
| degenerate | 제어토큰/반복 감지(FIX-E) | 재생성 or "다시 시도할까요?" |

- **추천이 진짜인 근거**: `list_keywords`·`catalog`는 vault의 실제 index(AI/ENGINEERING/…)·키워드를 반환 → "없음"일 때 **실존 인접어만** 제안(결정성 유지, 환각 없음).
- **웹 조합 주의 (두 축 분리)**: 웹'검색' 도구는 **신설 필요**. 웹 결과는 **LV0(저자only·confidence 1.0)에 절대 혼입 금지** — **생성축의 별도·명시적 opt-in**으로 "저자지식"과 "웹조합"을 라벨 분리 (조회/생성 두 축 원칙).
- **응답 형태**: `final_response` + `outcome` + `suggestions:[{action,label,payload}]` → 클라가 버튼 렌더:
```json
{ "outcome":"no_data",
  "message":"요청하신 데이터가 없습니다. 다른 검색어로 진행할까요?",
  "suggestions":[
    {"action":"search","label":"Khala","q":"Khala"},
    {"action":"search","label":"게이트웨이","q":"게이트웨이"},
    {"action":"web_combine","label":"웹에서 찾아 조합"}
  ] }
```

### 6.4 종합 — 하나의 패치로 묶임

Q1~Q3 + BUG-1/4/5가 **같은 지점(`tool_loop_openai`)**에서 함께 해결:
```
run_tools
 └ (A) planner: max_iter="auto"면 질문 분류로 예산 산정          ← Q1·Q2
 └ tool_loop_openai
     ├ 매 iter: (C) 수렴 감지 — 0건/중복 2회 → 조기 종료 유도    ← Q1
     ├ 종료 시: 출력 검증 — 제어토큰/CoT/반복이면 degenerate      ← BUG-4/5·FIX-E
     └ outcome 판정 + suggestions 생성 (no_data→list_keywords)    ← Q3
```
- **가성비 1순위 = C** (적응형 종료 + `outcome`/`suggestions` 구조화): 추가 LLM 콜 0, `for` 루프 내 ~30–40줄로 Q1 실효 · Q3 no_data 안내 · BUG-1/4/5까지 일괄 해소.
- 변경 파일(예상): `scripts/run-on-3800x-v5/lib/openai_chat.py`(루프·outcome), `scripts/api/handlers/tools.py`(planner·응답조립), `scripts/api/models.py`(`ToolsRunResponse`에 `outcome`/`suggestions`, `ToolsRunRequest`에 `max_iter:"auto"`).

### 6.5 결정 필요 (추후)

- 개발 착수 여부·순서 (C 우선 vs A/B 우선).
- `auto` 모드 위치: 클라 래퍼 vs 서버 스키마.
- 웹검색 도구 신설 여부 (두 축 분리 준수 전제).

---

## 7. 레퍼런스

- 엔드포인트: `POST http://100.109.251.86:8765/v1/tools/run` (LLM 자율) · `/v1/tools/invoke` (도구 1회) · `/docs` (Swagger)
- 응답 모델 `ToolsRunResponse`: `status·final_response·tool_calls_log·iterations·wall_sec·workflow_id·error` (khala `scripts/api/models.py`)
- khala PAB 툴 7종: `pab_lv0_catalog·list_brains·get_brain·search_text·get_document·get_links·list_keywords`
- 관련 소스(khala, macbook `~/WORKS/PAB-Khala`): `scripts/api/handlers/tools.py` · `scripts/api/auth.py` · `scripts/api/models.py` · `openai_chat.py`
