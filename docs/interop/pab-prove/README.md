# PAB-obsidian ↔ PAB-Prove 협업 인덱스

> **상위**: [`docs/interop/README.md`](../README.md)
> **목적**: PAB-Prove 산출물의 **정본 vault 편입 경로** 조율 — write 대상 전환 · 3800X의 LiveSync 디바이스 편입 · 정본 정비.
> **생성**: 2026-08-25 (**PAB-Prove 발신**)

---

## 1. 역할 경계 (한 줄)

**PAB-obsidian = vault 정의·전파 계약·정본 authority** / **PAB-Prove = 수집 파이프라인(capture UI → 워커 → 노트 2파일 생성) 코드·Phase 운영**.

PAB-Prove는 `PAB-LLMDATA`의 authority가 **PAB-obsidian**임을 인정한다. 정본에 대해 **⑴ 읽기 ⑵ 워커 write(편입 승인 후)** 두 가지만 수행하며, **저장소 조작·정비 적용·병합은 하지 않는다** — 전부 본 채널로 **요청**한다.

## 2. 관련 체인

```
[편입 전 — 현재]
PAB-Prove 워커 → 서버 pab-wiki-vault (262 md) → ✖ 전파 없음 (격리)

[편입 후 — PO2에서 조건부 승인한 구조]
Mac      Obsidian + LiveSync  ─┐
Lenovo   Obsidian + LiveSync  ─┼─→ CouchDB pab-llmdata ─┬─ bridge#1(단방향) → 미러 → v4
3800X    PAB-LLMDATA 사본     ─┘   (pabprove 계정)      └─ bridge#2(양방향, 신설)
         ↑ PAB-Prove 워커가 여기 write
```

> ⚠️ bridge를 **두 컨테이너로 분리**한다(PO2 §2.2) — 단일 인스턴스에 얹으면 Prove peer 권한 오류가 **미러 전파까지 함께 죽인다**(크래시가 프로세스 단위).

## 3. 문서 목록

> 범례 — **수신본**: PAB-Prove=SSOT, 여기엔 읽기전용 사본 · **회답본**: PAB-obsidian=SSOT.

| 문서 | SSOT | 성격 | 상태 |
|---|---|---|---|
| [`260825-PO1-3800X-LiveSync디바이스편입요청.md`](260825-PO1-3800X-LiveSync디바이스편입요청.md) | **PAB-Prove** | 수신본(읽기전용) — OB2 §2 미확정 항목 회답 + 인프라 조치 요청 3건 + 정비 판단 요청 | **PO2로 회답 완료 (2026-08-26)** |
| [`260826-PO2-PO1회답-디바이스편입-조건부승인.md`](260826-PO2-PO1회답-디바이스편입-조건부승인.md) | **PAB-obsidian** | 회답본 — PO1 §7 전건 회답 + 정비 적용 보고 + 사실관계 정정 2건 + 요청 6건 | **회답 대기** |
| PO3 | (예정 — obsidian) 편입 실행 일시 통지 | 회답본 | 대기 (T-2 완료 후) |

> PO1은 `PAB-obsidian/docs/interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md` 를 선행 문서로 한다.
> PO2는 위에 더해 [`OB2-A`](../pab-observer/260825-OB2A-OB2회답-승격준비확정+B1~B5회신.md)(SSOT=PAB-Observer)를 선행 문서로 한다 — Observer가 PO1을 읽고 **N-1을 홉2 구조 변경으로 판정, 편입 실행 전 사전 통지를 요구**했다(OB2-A §7.3).

## 4. 회답 대기 항목

### 4.1 PO1 §7 (PAB-Prove → obsidian) — **PO2로 전건 회답 완료 (2026-08-26)**

| # | 항목 | PO2 회답 |
|:-:|---|---|
| ⑴ | `livesync-bridge` **단방향 패치 조건부화** 가부 (`/app/Hub.ts:50-53`) | **조건부 승인** — N-1(config 플래그) + ⒜(별도 컨테이너) **병행** (§2) |
| ⑵ | **CouchDB 쓰기 경로 실증** — 실패 시 bridge 컨테이너 크래시 위험 | ⚠️ **VDU 살아 있음**(`_design/zz_bridge_readonly` 실측). `pabbridge`로는 크래시 → **신규 `pabprove` 발급 필요**, T-4에서 실증 (§3) |
| ⑶ | **충돌 정책** 합의 (특히 `00_MOC/` 갱신) | **C-1~C-5 제시**. C-2 idempotent가 핵심 (§6.3) |
| ⑷ | **정본 정비 2건** 적용 여부·주체 (link-check 현재 FAIL) | **PAB-obsidian이 직접 적용 완료** — orphan 8→0 (§4) |
| ⑸ | **AC-3 판정 이견** 유무 | **이견 없음** — R-1 정본이 오히려 피어 기기 경유를 지시 (§1) |
| ⑹ | 두 생성 경로(`/wiki` 스킬 ↔ Prove 워커) **비대칭**에 대한 의견 | 문제 **인정** / "가드 우회"는 **정정 요청**(그 가드는 우리에게 없다) / **Phase 2-5 T-7** 최소 수정 편입 (§5) |
| ⑺ | 승격 확정(OB3) 시 **편입 경계 시점** 합의 | **T-4와 동시**. 경계 = 편입 실행 완료 시각. 일시는 PO3로 통지 (§6.1·§6.2) |

### 4.2 PO2 §8 (obsidian → PAB-Prove) — **회답 대기**

| # | 요청 | 기한 |
|:-:|---|---|
| **R-1** | link-check 판정 근거를 `status` → `counts.violations==0 && counts.orphans==0`으로 정렬 | 편입 전 |
| **R-2** | PO1 §4.4 비교표·§2 경로 귀속 정정 ("가드 4겹 우회" → "write 가드 계층 미보유") | 무기한(조기 권장) |
| **R-3** | `moc.py` 출력 동일성 확인 — vendor 판본 ↔ 원본 | 편입 전 |
| **R-4** | 정본 CouchDB에 probe 금지 (역할 분담: Observer=`pabbridge` / 우리=`pabprove`) | 즉시 |
| **R-5** | P-1 검증 시점 이동(write 전 검증) 완료 통지 — **편입 게이트** | 편입 전 |
| **R-6** | `00_MOC/` 충돌 정책 C-1~C-5 수용 여부 | 편입 전 |

## 5. 규약

- 본 디렉토리의 PAB-Prove 발신 문서는 **읽기전용 수신본**이다. 원본은 `PAB-Prove/docs/interop/pab-obsidian/` 에 있고, 갱신은 PAB-Prove가 재전달한다.
- PAB-obsidian 발신 회답은 본 디렉토리에 배치하면 PAB-Prove가 수신한다.
- PAB-Prove는 interop 문서를 **커밋하지 않는다**(파일 배치까지가 전달이다).
