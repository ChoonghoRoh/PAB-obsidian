# PAB-obsidian ↔ PAB-Observer 협업 인덱스

> **상위**: [`docs/interop/README.md`](../README.md)
> **목적**: wiki vault 이원화(정보 vs 개발 데이터)와 4홉 전파 체인의 **관측 계약** 집약·조율 상태.
> **생성**: 2026-08-24 (PAB-Observer 발신)

---

## 1. 역할 경계 (한 줄)

**PAB-obsidian = vault 정의·전파 계약(무엇이 정보이고 무엇이 개발 데이터인가)** / **PAB-Observer = 4홉 체인 관측·임계·알림**. Observer는 vault에 **쓰지 않는다**(R-1 단일 writer 원칙 준수 — 미러·CouchDB 직접 쓰기 금지).

## 2. 관측 중인 체인

```
PAB-LLMDATA(정보) → LiveSync → CouchDB pab-llmdata(홉1) → livesync-bridge(홉2)
  → 미러 /home/oceanui/pab-vault-mirror(홉3) → PAB-v4 /vault-mirror + Qdrant(홉4)
```

2026-08-24 실측: 화이트리스트 **미러 102 == 컨테이너 vault 102 == Qdrant distinct doc 102**, 게이트 ON.

UK 모니터: `#25`(CouchDB `/_up`) · `#26`(VaultChain 4홉 복합 Push) · `#31`(bridge 등 컨테이너 running).

## 3. 계약 문서 (SSOT 소유권)

> 범례 — **수신본**: PAB-Observer=SSOT, 여기엔 읽기전용 사본 · **회신본**: PAB-obsidian=SSOT.

| # | 문서 | SSOT | 성격 | 링크 |
|---|---|---|---|---|
| OB1 | vault 이원화 크로스 체크 점검 요청 (O-1~O-5) | **PAB-Observer** | 수신본(읽기전용) | [`260824-OB1-vault이원화-크로스체크-점검요청.md`](260824-OB1-vault이원화-크로스체크-점검요청.md) |
| OB2 | O-1~O-5 회신 + **O-3 승격 사전 통지** | **PAB-obsidian** | 회신본 | [`260825-OB2-vault이원화-회신-및-승격사전통지.md`](260825-OB2-vault이원화-회신-및-승격사전통지.md) |
| OB2-A | B-1~B-5 전건 회답 + 승격 준비 확정(리드타임 OB3+24h) + 자발 통지 2건 | **PAB-Observer** | 수신본(읽기전용) | [`260825-OB2A-OB2회답-승격준비확정+B1~B5회신.md`](260825-OB2A-OB2회답-승격준비확정+B1~B5회신.md) |
| OB2-B | OB2-A §8 ①~⑤ 전건 회답 + **기기 재연결 실증**(§7.1 정정) + PAB-Prove 편입 사전 통지 | **PAB-obsidian** | 회신본 | [`260826-OB2B-OB2A회답-기기재연결실증+편입사전통지.md`](260826-OB2B-OB2A회답-기기재연결실증+편입사전통지.md) |
| OB2-C | OB2-B **C-1~C-6 전건 회답** — §7.1 "미재연결 확정" **철회** · **`client_idle` 정정 완료 실증** + user축 확정안 · **P-1 실측 회답**(호스트 발은 게이트웨이 아님)·P-2·P-3 · N-2 역할 3분할 수용 · **T-3 정식 판정**(보완 승인·⒜·cron 2줄·`#31` 조치 불요·리허설 Push 발급 제안) · **회신 요청 R-1~R-4** | **PAB-Observer** | 수신본(읽기전용) | [`260827-OB2C-OB2B회답-client_idle정정완료+T3판정+편입회답.md`](260827-OB2C-OB2B회답-client_idle정정완료+T3판정+편입회답.md) |
| **OB2-D** | OB2-C **R-1~R-4 전건 회답** — ⭐ **`BL-3` 해소 통지**(R-2 발효, 단 활성화 후 25h 발화 0회) · `git-gap` **3중 종속** 실측 제시 · bridge#2 **`pab-vault-net` 소속 확약**(R-1) · `UK_COUCHDB_VERIFY_PUSH_URL` 설계 확인 + **실번호 요청**(R-3) · bridge#2 예정명 통지 + **선등재 금지 요청**(R-4) · T-3 판정 접수 · **회신 요청 D-1~D-4** | **PAB-obsidian** | 회신본 | [`260902-OB2D-OB2C회답-R1~R4전건+BL3해소통지.md`](260902-OB2D-OB2C회답-R1~R4전건+BL3해소통지.md) |
| OB3 | (예정 — obsidian) 승격 실행 통지 | **PAB-obsidian** | 회신본 | 대기 |

## 4. 회신 대기 항목 (OB1 §2) — **OB2로 회신 완료 (2026-08-25)**

> ⚠️ **O-2 = 승격 임박(이번 Phase 내)** → OB2 §3으로 **O-3 사전 통지 발효**. Observer 측 임계 완화·baseline 재동결 준비 요청 중(B-1).
> PAB-obsidian → Observer 역방향 대기 항목 B-1~B-5는 OB2 §8 참조 → **OB2-A로 전건 회답 (2026-08-25)**. 현재 대기(Observer → obsidian): OB2-A §8 ①~⑤ (OB3 내용 · 3회 통지 · Telegram 직접 발송 중단 · B-3 조건 확인 · 기기 재연결 확인).

### ✅ 통지 이행 완료 (2026-08-26, OB2-B §3)

**OB2-A §7.3**이 PAB-Prove 3800X 디바이스 편입(N-1 bridge 조건부화)을 **홉2 구조 변경**으로 판정하고 **편입 실행 전 사전 통지**를 요구했다. 2026-08-26 [`PO2`](../pab-prove/260826-PO2-PO1회답-디바이스편입-조건부승인.md)로 편입을 **조건부 승인**했으므로 통지 의무가 발생했다.

| 항목 | 상태 |
|---|---|
| 통지 대상 | bridge 컨테이너 분리(미러 단방향 유지 + Prove용 양방향 신설) · `pabprove` 계정 신설 · 3800X를 LiveSync 디바이스로 편입 |
| 리드타임 | **24시간** (OB2-A §1.3) |
| 시점 | 편입 실행 = T-4와 동시. **사전 통지는 OB2-B §3으로 발효**. 일시 확정 시 24h 리드타임으로 재통지 |
| 수행 주체 | **PAB-obsidian** (관측 계약상 우리 의무 — PAB-Prove가 별도로 하지 않는다) |
| 함께 전달 | `pabbridge` forbidden probe는 Observer 담당 / `pabprove` 통과 실증은 우리 backend-dev 담당 — **중복 write 방지** (PO2 §3.4) |

> 별건: Observer가 자기 고지한 `client_idle` 지표 결함(OB2-A §7.2)으로 **2026-08-26 02:45 KST 오경보 🟠 예정**. 편입과 무관한 경보다.


| # | 질의 | 시급도 |
|---|---|---|
| **O-1** | vault 2종 authority 확정 — `PAB-LLMDATA`=정보(운영 SSOT) / `PAB-LLMDATA-prove`=개발용 데이터 | 중간 |
| **O-2** | PAB-Prove 산출물 승격 경로 — 현재 `pab-wiki-vault`에만 쌓이고 운영 전파 0(`WIKI_ENV=dev` 격리). 의도된 PoC인가, 승격 시점은? | 높음 |
| **O-3** | 승격 시 관측 임계 재산정 — 화이트리스트 102 → 200+ 급증 시 대량 오경보. **승격 전 통지 필수** | **높음 — 승격 실행 전** |
| **O-4** | 서버 증분 60건 회수 정책 — 개발 vault 서버본에만 존재, 로컬 미회수 | 중간 |
| **O-5** | 운영 vault 7일 무갱신(미러 mtime 2026-08-17)이 정상 리듬인가 — 현재 **정체와 정지를 구분 못 한다** | 중간 |

## 5. 함께 확인 필요 (문서–실태 불일치)

Khala `docs/interop/pab-prove/README.md` §1이 PAB-Prove를 *"vault(`PAB-LLMDATA`)에 생성 → LiveSync 전파"*로 기술하나, **실태는 `pab-wiki-vault`(= `PAB-LLMDATA-prove` 복제본) write이며 전파는 일어나지 않는다**. authority는 PAB-Prove이므로 정정은 그쪽 소관이나, vault 정의의 SSOT인 obsidian 측 인지가 필요하다. (OB1 §1.4)

## 6. 관측 규격 SSOT

4홉 지표·임계·게이트·화이트리스트 정의는 PAB-Observer `observer/3800x/notes/vault-chain-metrics.md`(현행 v1.2)가 단일 진실 공급원이다.

- §5.4 **경로 케이싱 상이** — 미러/컨테이너 `10_Notes`(대문자) / CouchDB `_id` `10_notes/`(소문자). 통일하면 0 doc 오산.
- §8.2 **정합 ≠ 생존** — 홉1이 3일간 죽은 동안에도 3자 일치는 정상이었다.
