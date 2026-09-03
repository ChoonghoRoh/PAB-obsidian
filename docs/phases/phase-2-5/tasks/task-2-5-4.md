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

---

## 회전 절차서 (2026-09-04, backend-dev 조사 — 실행 전 초안)

> 작업 1 *"회전 절차서 + 롤백 절차 문서화 (반드시 선행)"* 의 산출물.
> **읽기 전용 조사로 작성했다. 회전·발급·probe 는 아직 하나도 실행하지 않았다.**
> 본 저장소는 PUBLIC 이므로 아래에는 키·계정 **이름**만 적는다. 값은 어디에도 남기지 않는다.

### A. 실측 현황 (2026-09-04)

| 항목 | 값 |
|---|---|
| CouchDB | **3.5.2** |
| `_users` 계정 | **`pabbridge` 1개뿐** |
| `pab-llmdata/_security` | `members.names=["pabbridge"]` · `members.roles=["_admin","bridge_ro"]` |
| VDU `_design/zz_bridge_readonly` | 194자 — `userCtx.name === 'pabbridge'` 일 때만 throw |
| `doc_count` | **3064** / `doc_del_count` **5** ← probe 후 원복 대조 기준 |
| 저장소 노출 | `bridge.env` 는 `.gitignore` 보호 + 커밋 이력 **0건**. 평문 `계정:비번` 패턴 **0건** |

### B. 🔴 발견 3건 — 절차의 전제

#### ⑴ `pabadmin` 은 `_users` 가 아니라 **config admin** 이다 — 회전 방법이 다르다

`_users` 에는 `pabbridge` 뿐이고 `pabadmin` 은 `/_node/_local/_config/admins` 에 있다.

| 계정 | 회전 엔드포인트 | 롤백 |
|---|---|---|
| `pabadmin` | `PUT /_node/_local/_config/admins/pabadmin` | ⚠️ **rev 없음 — "이전 값 재입력"뿐** |
| `pabbridge` | `PUT /_users/org.couchdb.user:pabbridge` | rev 기반 문서 복원 가능 |

⇒ **`pabadmin` 을 마지막에 회전한다.** 되돌리기가 가장 어렵고, 실패 시 전 기기 동기화와
Observer `#26`·`#32` 가 동시에 끊긴다.

#### ⑵ `_security.members` 가 접근 자체를 막는다

members 가 비어있지 않으므로 목록 밖 계정은 **읽기도 안 된다.** `pabprove` 는 VDU 통과
이전에 `_security` 에 먼저 올라가야 한다.

#### ⑶ `setup-readonly-account.sh` 가 `pabprove` 를 조용히 축출했다 — **수정 완료**

`_security` 에는 `_rev` 가 없어 **PUT 이 곧 전체 교체**다. 구 판본은
`"names":["${BRIDGE_USER}"]` 를 통째로 넣어 나중에 추가된 계정을 지웠고,
**`deploy.sh` 가 이 스크립트를 자동 호출**한다(line 88–91). 즉 `pabprove` 발급 후
아무 배포나 한 번 돌면 편입이 조용히 깨진다. 에러도 안 나고 멱등해 보인다.

> ⚠️ 더 나빴던 것은 **주석이 코드와 반대**였다는 점이다 — 주석은 *"기존 정책 유지 + 추가"*,
> 코드는 *교체*. **주석을 믿고 읽으면 이 결함은 보이지 않는다.**

⇒ 병합 로직을 `merge_security.py` 로 분리하고 주석을 정정했다. 회귀 시험 14종을 붙였고,
보존을 지우는 판본 4종을 주입해 시험이 잡는 것을 확인했다.

### C. 회전 순서 — 저위험 → 고위험

| # | 단계 | 상태 |
|:-:|---|---|
| 1 | `setup-readonly-account.sh` members 보존형 수정 + 주석 정정 + 회귀 시험 | ✅ **완료** (서버 무접촉) |
| 2 | `pabprove` 발급 → `_security` 병합 → probe 실증 → 문서 삭제 | ⬜ 보류 |
| 3 | `pabbridge` 회전 — `bridge.env` 갱신 → `deploy.sh` **+ Observer `.env` 동시 갱신** | ⬜ 보류 |
| 4 | `pabadmin` 회전 — config admin PUT → `observer/.netrc` + **전 기기 재설정**(사용자) | ⬜ 보류 |

### D. 🔴 Observer 조율은 예의가 아니라 **실행 전제**다

두 계정 모두 Observer 의 **가동 중 수집기가 직접 사용**한다:

| 자격증명 | 보관 | 사용하는 Observer 자산 |
|---|---|---|
| `pabadmin` | `observer/.netrc` (600) | **`#32` `backup-datastores.sh`** · **`#26` `vault-chain-collect.sh`** (+ 우리 T-3 볼륨백업) |
| `pabbridge` | `observer/.env` `BRIDGE_RO_*` | **`#26` `vault-chain-collect.sh`** |

회전 순간 그쪽이 인증 실패하고, Observer 가 자기 파일을 갱신하지 않으면 복구되지 않는다.
**양측 동시 작업이 필요한 회전**이다.

### E. probe 설계 — `201` 을 통과의 증거로 쓰지 않는다

`200/201` 은 VDU **통과**의 증거가 아니다 — VDU 에 닿기 전에 성공했을 수도 있다
(Observer 가 반대 방향으로 같은 함정에 빠졌다: `_` 접두 필드 때문에 400 으로 반려되어
*"차단됐다"* 고 읽었으나 **VDU 는 한 번도 시험되지 않았다**).

```
페이로드: doc id = zz_probe_<ts>   (밑줄로 시작하지 않는다)
          본문 필드에 밑줄 접두 없음
 ① 같은 페이로드를 pabbridge 로 PUT → 403 기대
      ⇒ "이 페이로드는 VDU 까지 도달한다" 가 증명된다. 400 이면 차단이 아니라 시험 실패
 ② 같은 페이로드를 pabprove 로 PUT  → 201 기대
      ⇒ ①로 도달성이 증명됐으므로 201 은 "도달했고 이름으로 갈려 통과했다" 를 뜻한다
 ③ 즉시 삭제 → doc_count 3064 원복 확인
```

①이 없으면 ②의 201 은 *"VDU 에 닿지도 않았는데 성공"* 과 구분되지 않는다.
⚠️ ①은 역할 3분할(PO2 §3.4)상 Observer 몫과 겹친다 — **합의 후 실행**한다.

### F. 롤백

| 대상 | 방법 | 비고 |
|---|---|---|
| `_security` | 변경 전 원문을 그대로 PUT | 현재 값 확보 완료(§A) |
| `pabbridge` | `_users` 문서 rev 기반 복원 + `bridge.env` 원복 + `deploy.sh` | 재기동 필요 |
| **`pabadmin`** | ⚠️ **rev 없음 — 이전 비밀번호를 사용자가 보관해야만 복원 가능** | 보관 실패 시 복구 불가 |
| VDU | 변경하지 않는다 (rev 보존) | |
| probe 문서 | 삭제 후 `doc_count` **3064** 대조 | 생성 실패해도 삭제 시도 |

### G. 미측정 — 추정치를 적지 않는다

- **`pabadmin` 회전 시 클라이언트가 언제부터 끊기는지 모른다.**
  `couch_httpd_auth/timeout` 은 **미설정**(404)이라 빌트인 기본값이 적용된다 — 문서상 600초이나
  **우리 인스턴스에서 실측하지 않았다.** 또한 LiveSync 클라이언트가 쿠키 세션을 쓰는지
  Basic 인증을 쓰는지 **확인하지 못했다.** 전자면 유예 구간이 있고 후자면 즉시 끊긴다.
  ⇒ ⚠️ **역으로, 회전 직후 "아직 동기화된다"는 것은 성공의 증거가 아니다** — 세션이
  남아 있을 뿐일 수 있다. 회전 검증은 **새 세션으로** 해야 한다.
- **끊김의 길이는 시스템 속성이 아니다.** 자동 복구 경로가 없어 사람이 각 기기에서
  재입력할 때까지 지속된다 — 기기 수와 사용자 대응 속도가 결정한다.
- 기기 측 재설정 절차(맥북·레노버·iPhone GUI)는 조사하지 않았다. 사용자 영역이며 T-6 과 연계.
