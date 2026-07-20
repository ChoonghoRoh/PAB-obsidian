---
title: "PAB-Khala Phase 6 페르소나 검증 — arbiter 적대 리뷰 (원문)"
description: "PAB-Khala 저장소 원본 문서 immutable 보존 — docs/analysis/20260629-phase6-persona-review.md"
created: 2026-06-30 07:58
updated: 2026-06-30 07:58
type: "[[SOURCE]]"
index: "[[ENGINEERING]]"
topics: ["[[KHALA]]", "[[API_GATEWAY]]"]
tags: ["source", "khala", "phase6"]
keywords: ["khala", "페르소나검증", "적대리뷰", "동시성", "보안", "blocker", "arbiter", "swap실패", "복귀트리거"]
sources: ["docs/analysis/20260629-phase6-persona-review.md"]
aliases: ["phase6페르소나검증", "arbiter적대리뷰"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (Karpathy sources 계층). 원본 위치: `PAB-Khala/docs/analysis/20260629-phase6-persona-review.md`

# Phase 6 통합 게이트웨이 — G0 다중 페르소나 적대 검증 기록

> 작성 2026-06-29 · 대상 `docs/phases/phase-6-master-plan.md` v1.0 §4.2 arbiter 스케치 + `docs/design/20260629-khala-unified-gateway-design.md`
> 페르소나: ①동시성/Race ②보안/신뢰경계 ③적대적 QA/장애모드 (각 독립 일반 에이전트, 실제 소스 정독)
> 위협모델(Phase 5 계승): 현재 **단독 Tailscale 내부망**(낮음) + 향후 외부. Track A=내부망에서도 실재(구현) / Track B=외부 진입 트리거(기록)

---

## 0. 판정 요약

v1.0 arbiter 스케치(§4.2)는 **G2 구현 불가** — 정상 운영 경로에 구조적 공백 2건(Blocker)이 입증됨. 둘 다 위협모델과 무관하게 **내부망 단독에서 "모든 LLM 트래픽 정지 / 수동 개입 필요"** 로 현실화된다. 설계 보강(arbiter v2, 마스터플랜 §4.5) 후 재승인 필요.

검증 환경 사실(추측 아님): 배포 = `uvicorn main:app --port 8765`(`--workers` 미지정 → **워커 1, 단일 프로세스 전제 현재 성립**). 모든 핸들러 `def`(sync) → FastAPI anyio threadpool(기본 40) 실행. `_state()`=`runtime_state.sh`는 다수 subprocess+curl(수십~수백 ms).

---

## 1. 발견 통합표 (3 페르소나 dedup + 검증 verdict)

| ID | 심각도 | 발견 | 근거 | verdict | 트랙 |
|---|---|---|---|---|---|
| **Q-1** | **Blocker** | swap 실패 중간상태: GPU 고아(ollama unload됨·vllm 미기동) + `_current` 미갱신 + ollama 복귀가 `vllm_stop already_off`(exit4→502)로 막힘 = 데드락 | `_swap_to` 비원자(§4.2) · `vllm_stop.sh:11-14` · `ops.py:_run` 비제로→502 | **인정** | A |
| **Q-2** | **Blocker** | 배치 종료→Ollama 복귀 **트리거 부재**. arbiter는 요청구동이라 "끝남"을 모르고, 복귀시킬 ollama 요청은 409로 거부 → vLLM 무기한 상주 | `tools.py:184-196`(복귀 콜백 0) · §4.2:135-137(active=vllm→ollama 409) · grep 복귀 0건 | **인정** | A |
| **C-1** | High | 락 보유 중 swap(최대 200s)이 threadpool 고갈 → health·대시보드 폴링(3s)까지 정지 | sync def 핸들러 + `with _lock` 안 `_swap_to` | **인정** | A |
| **C-2** | High | single-flight가 "양보(409)"가 아닌 "200s 블록 후 통과" → KPI(P6-04)가 줄서기를 PASS로 숨김 | §4.2:129-144, S5 미측정 | **인정** | A |
| **C-3** | Med→High | `_swap_to`가 `vllm_run.sh`의 가드 시퀀스(busy-wait·holdoff·open-webui-stop 후 busy 재검사)를 파이썬으로 재구현하며 **busy 가드 누락** → 진행 중 Ollama 추론 절단(R-41-04 회귀) | §4.2:146-153 vs `vllm_run.sh:15-74` | **인정** | A |
| **C-4** | High | (a) 락 밖 fast-path TOCTOU → 죽은 런타임에 curl(502). (b) `_active`가 `_current` lease 무시 → idle 직후 역방향 swap thrash | §4.2:106,123-144 | **인정** | A |
| **C-5** | High | arbiter `_lock` ↔ 기존 `/v1/admin/{ollama,vllm}/{run,stop,unload}`(대시보드 수동 swap, D34/D36 운영표준)이 **서로를 모르고** 동일 GPU 동시 조작 | `ops.py:122-191`(락 무관) | **인정** | A |
| **Q-3** | High | `_active`가 vLLM idle/busy 미구분 → idle vLLM이 ollama를 영구 차단. **설계(§2.3 "busy일 때만 양보") ↔ 스케치 불일치** | §4.2:106-112 vs design §2.3 · `_common.sh:vllm_is_busy` 미사용 | **인정** | A |
| **Q-4** | High | `starting`/unhealthy vLLM을 active로 판정 → 안 뜬 엔진에 라우팅(ready 미보장). fast-path는 polling 안 함 | `_common.sh:75-80`(starting 존재) · §4.2:126-127 | **인정** | A |
| **Q-8** | Med | 주간 `/v1/tools/run`(항상 `ensure(vllm)`)이 Ollama idle 시 swap → open-webui stop + unload → **주간 인터랙티브 차단**. 시간 분리 "코드 강제" 주장에 **시간창 가드가 실제로 없음** | §4.1:60, §4.2:138-143, §7-2(야간 "가정"만) | **인정** | A |
| **S-1** | Med | `pab:*`(일반 caller)가 generate/tools 경로로 admin 전용 GPU swap(=open-webui stop 포함) 간접 트리거 = **정책제약형 권한 상승** | `admin.py:40-51`(khala-self만) vs §4.2 swap이 owner 등급 미검사 | **인정(한정)** | A |
| **S-2/C-7** | Med | swap thrash/라이브락 — 순차 반복 swap 막는 cooldown·레이트리밋 부재. 409 herd(jitter·상한 없음) | §4.2:135-143, API rate limit 0건 | **인정** | A(악의분 B) |
| **S-3** | Med | `DIRECT_OLLAMA_FALLBACK`이 mutex 우회 백도어(특히 vLLM swap-hang 중 폴백이면 충돌 최대). **현재 미구현=제거/가드 적기** | design §7-1 자기시인 · grep 코드 0건 | **인정** | A |
| **Q-5** | Med | `_eta`가 읽는 `state["vllm"]["eta_sec"]`가 **`runtime_state.sh`에 미존재** → retry_after 항상 120 허수. arbiter엔 배치 진행 신호 채널 없음 | `runtime_state.sh:78-80` · §4.2:160 | **인정** | A |
| **Q-6** | High | 시나리오 매트릭스 S1~S5가 Q-1·Q-2 무커버. S3 "복귀" 테스트는 트리거 없어 **작성 불가/거짓 PASS** | master §5 · §6 KPI(실패/복구 지표 0) | **인정** | A |
| **S-5** | Med | `/v1/tools/lineage/{wid}` **조회 무인증**(`assert_allowed` 미적용) + prompt 평문 단일 DB 집적 + caller 자기신고 | `tools.py:199` · `db.py:131-139` · `auth.py:7-19` | **인정** | A(lineage)/B(집적) |
| **Q-7** | Med | PAB-v4 "큐잉" 미구현 = 409 단순 실패. 라벨링 배치 부분상태/중복 위험. 문서의 "큐잉" 표현 과장 | design §2.5:146-147(raise만) | **인정(표현 정정)** | B(+A 후속선결) |
| **C-6/S-6/Q-9** | Med/Low | in-process `_lock`은 `--workers 1` **묵시 의존**(고정/주석 없음). 증설 시 single-flight 붕괴 | §4.2:120 · 배포 커맨드 `--workers` 부재 | **인정** | A(부팅가드)/B(분산락) |
| **Q-10** | Low | resumable/lineage 기존 한계(resume_valid 표시만 등)는 게이트웨이로 **불변·전파**. 무인증 lineage 노출면만 확대 | `tools.py:184-196` · 보고서 §6 | **인정(허위개선 방지)** | A(lineage)/내부망 |
| ~~S-4~~ | ~~Low~~ | ~~명령 주입~~ | owner·`req.model` 모두 셸 인자 미도달 + 배열 subprocess | **반증/기각** — 입증 경로 없음. `vllm_run.sh:71` 비따옴표 위생만 저비용 보강 | A(위생) |

**과장 배제(Phase 5 교훈 적용)**: S-4 명령주입 = 경로 없음으로 기각. 메모리모델 결함 = GIL+락내갱신으로 없음. "단일 프로세스=동시성 OK" 서술은 **부정확**(C-1~C-5는 워커 1개에서도 발생) → 정정. S-1 권한상승은 "임의 admin 호출"이 아닌 "정책제약형"으로 한정.

---

## 2. 구조적 종합 — 근원 2개로 수렴

3 페르소나의 High+ 발견은 두 근원으로 묶인다:

### 근원 ① "요청구동 + 락내 장시간 swap" (C-1·C-2·C-4·C-5·Q-1)
요청이 직접 swap을 락 안에서 끝까지 수행하는 모델이 threadpool 고갈·줄서기·TOCTOU·admin 충돌·중간상태 데드락을 동시에 낳는다.
**해법(단일)**: **전용 직렬 swap 워커(큐)** — 모든 GPU 전환을 단일 백그라운드 워커가 소유. arbiter.ensure()와 admin ops 엔드포인트 둘 다 이 큐에 enqueue. 요청은 락을 길게 잡지 않고 ① 런타임이 이미 맞으면 즉시 통과, ② 전환 필요면 **블록이 아니라 409/503+retry**. swap 실패 시 워커가 **직전 안정 런타임으로 롤백**. 상태머신 `STABLE/SWAPPING/UNKNOWN` 도입, `SWAPPING` 중 불일치 요청은 503(=전환중, 409=정상 점유와 구분).

### 근원 ② "복귀/시간창 트리거 부재" (Q-2·Q-3·Q-8)
arbiter가 요청구동이라 "배치 끝"·"주간/야간"을 모른다.
**해법**: (a) **명시적 복귀 트리거** — swap 워커에 idle-TTL watcher(`vllm_is_busy()==false`가 RESTORE_TTL 지속 시 기본 상주 런타임=ollama로 자동 복귀) + `tools.py:finally`에서 배치 종료 release 신호. (b) **idle/busy 구분** — `_active`가 `_common.sh:vllm_is_busy/ollama_is_busy` 사용(idle vLLM은 swap 가능). (c) **시간창/caller 정책** — 파괴적 vLLM swap(open-webui stop)은 `khala-self:*`/지정 배치 owner 또는 배치 시간창에서만. 주간 `pab:*` tools 요청은 409("배치창에서 재시도").

이 둘을 반영하면 P6-02("mutex 자동·수동 0")가 비로소 실증 가능해진다(현재는 거짓).

---

## 3. G0 승인 조건 (필수 반영 → 마스터플랜 §4.5)

| # | 반영 항목 | 해소 |
|---|---|---|
| 1 | 직렬 swap 워커(큐) + 상태머신 + 블록금지(409/503) | C-1·C-2·C-4·C-5 |
| 2 | swap 원자성 + 실패 롤백 + `already_off`(exit4) 흡수 | Q-1 |
| 3 | 명시적 복귀 트리거(idle-TTL watcher + 배치 release) | Q-2 |
| 4 | `_active` idle/busy 구분(`_common.sh` 신호 배선) + ready-gating | Q-3·Q-4 |
| 5 | `_swap_to`는 `vllm_run.sh`/`ollama_run.sh` **한 줄 위임**(가드 재구현 금지) | C-3 |
| 6 | caller→target 권한 매트릭스 + 파괴적 swap은 admin 등급/배치창 | S-1·Q-8 |
| 7 | swap cooldown 게이트 + retry_after jitter/정직한 eta | S-2·Q-5·C-7 |
| 8 | `/v1/tools/lineage` 인증 추가(저비용·회귀성) | S-5·Q-10 |
| 9 | `DIRECT_OLLAMA_FALLBACK` 제거 또는 gpu/state 가드 | S-3 |
| 10 | 부팅 시 `--workers>1` fail-fast 가드 + systemd `--workers 1` 명시 | C-6·S-6·Q-9 |
| 11 | 시나리오 매트릭스 S6(swap실패→롤백)·S7(배치종료→복귀 latency) 추가 + KPI P6-07/08 | Q-6 |
| 12 | "큐잉" 표현 정정(shim 멱등 재시도는 T-6-2 선결조건으로 명문화) | Q-7 |

Track B 유지(외부 진입 트리거): API key 인증 전환, prompt 집적 마스킹/TTL, 분산 락 본구현, swap 악의적 증폭 방어.

---

## 4. 페르소나별 원본 산출물

3 에이전트 산출 전문은 본 세션 기록에 보존(C-1~C-7 / S-1~S-7 / Q-1~Q-10). 핵심 추궁 2건(Q-1 중간상태 데드락, Q-2 복귀 트리거 부재)은 코드·grep으로 입증됨.
