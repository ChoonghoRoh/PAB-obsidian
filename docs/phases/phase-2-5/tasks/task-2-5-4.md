---
task: "2-5-4"
title: "자격증명 회전 (pabadmin · pabbridge)"
domain: "[INFRA]"
gap: "G-4 (🟡)"
assignee: "backend-dev (스크립트·서버) + 사용자 (기기 GUI 재설정)"
status: pending
depends_on: ["2-5-1", "2-5-2"]
---

# Task 2-5-4: 자격증명 회전

## 목표
세션 중 노출된 CouchDB 자격증명을 회전하고 전 기기를 재설정한다.

## 대상
| 계정 | 성격 | 노출 경위 |
|---|---|---|
| `pabadmin` | 관리자 | Phase 2-1 PoC 세션 노출 (잔여 인계사항) |
| `pabbridge` | bridge 읽기전용 | 2026-08-24 조사 중 마스킹 미적용 재노출 |

둘 다 Tailnet 내부 한정이나 정식 운영 전 회전 필요.

## 선행 조건 (PR-1)
**T-1(모니터링)·T-2(백업) 완료 후 착수한다.** 회전 중 동기화가 일시 중단되므로 관측·백업 계층이 먼저 서 있어야 한다.

- T-1 ✅ (2026-08-25) · T-2 ◐ (2026-08-26 커밋·푸시 실체 충족, **cron 활성화만 BL-3로 잔여**)
- ⚠️ **편입 실행은 추가 게이트 2개**를 더 통과해야 한다 (PO2 §7 / OB2-B §3.6):
  - **P-1**: PAB-Prove 측 검증 시점 이동(write 전 검증) 완료 통지 수신 (PO2 R-5)
  - **P-2**: PAB-Observer 사전 통지 후 **24h 리드타임** 경과 (홉2 구조 변경)

## 작업
1. **회전 절차서 + 롤백 절차 문서화 (반드시 선행)**
2. `pabadmin` 비밀번호 회전 (`.env` + 서버 반영)
3. `pabbridge` 비밀번호 회전 + bridge 설정 반영
4. 전 기기 LiveSync 재설정 — 맥북 / 레노버 / iPhone(T-6과 연계)
5. 평문 노출 지점 정리 — 스크립트·로그·커밋 이력
6. ⭐ **`pabprove` 신규 계정 발급 + 쓰기 통과 실증** (2026-08-26 추가 — PAB-Prove 디바이스 편입 전제)

## ⭐ 추가 범위: `pabprove` 발급 + N-2 실증 (2026-08-26)

PAB-Prove 3800X LiveSync 디바이스 편입(PO2 §3, DP-2-5-5)의 전제 조건이다. 계정 작업을 두 번 하지 않으려고 T-4에 합류시켰다.

**왜 신규 계정이 필요한가**: `_design/zz_bridge_readonly`의 `validate_doc_update`가 **`userCtx.name === 'pabbridge'`일 때만** throw하고 그 외엔 no-op(허용)이다. 따라서 `pabbridge`로 편입하면 forbidden → uncaught `LiveSyncError` → **컨테이너 크래시**, 신규 계정이면 통과한다.

**⚠️ probe 설계 제약 (PAB-Observer 실측 전달, 2026-08-26)**

Observer가 자기 probe에서 겪은 false-monitor를 공유했다 — 페이로드가 `_` 접두 필드를 써서 **VDU에 도달하기 전에** 400 `doc_validation`으로 반려되고 있었다. 즉 **"통과/차단"을 시험한 것이 아니라 아무것도 시험하지 못한 상태**였다. PO1이 겪은 `illegal_docid`도 동류다.

> `_` 접두는 **doc id에도 적용된다.** VDU까지 실제로 도달하려면 **⑴ 밑줄로 시작하지 않는 doc id**(Observer 사례: `zz_probe_<ts>`) **⑵ 밑줄 접두 필드 없음** — **두 조건을 모두** 만족해야 한다.

⇒ `pabprove` 쓰기 실증 시 **유효문서로 시험할 것.** 400이 뜨면 그것은 "차단됨"이 아니라 **"시험 실패"**다.

**probe 역할 분담** (PO2 §3.4 / OB2-B §3.5로 3자 합의):

| 주체 | 담당 | 상태 |
|---|---|---|
| PAB-Observer | `pabbridge` forbidden 확인 | ✅ 완료 — 유효문서 PUT → **403 forbidden**, 원본 오염 0 |
| **PAB-obsidian (본 Task)** | **`pabprove` 통과 실증** | ⬜ 본 Task |
| PAB-Prove | **금지** | PO2 R-4로 요청 완료 |

**검증 항목 추가**
- `pabprove`로 유효문서 PUT → **201 통과** 확인 (400이면 payload 재설계)
- 실증 후 **테스트 문서 즉시 삭제** + `doc_count` 원복 확인
- 구 `pabbridge` 자격증명으로 접근 실패(401) 확인 — 회전 검증과 동일 요령

## 산출물
- 자격증명 회전 절차서 (롤백 포함)

## 검증 (G2_infra)
- 회전 후 전 기기 양방향 동기화 정상
- 구 자격증명으로 접근 실패(401) 확인
- 평문 자격증명 노출 0

## 비고
- 회전 중 마스킹 규율 유지 — 이 Task 자체가 재노출 경로가 되지 않도록 주의
