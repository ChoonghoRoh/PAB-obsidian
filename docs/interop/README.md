# Interop Hub — PAB-obsidian ↔ 외부 협업 공간

> **목적**: PAB-obsidian(wiki vault·LiveSync 전파 계약)과 외부 프로젝트 사이의 **계약 문서·조율 상태**를 한 곳에서 관리한다.
> **표준**: Khala `docs/interop/README.md` 허브 헌장의 SSOT 규약·배지 규약을 준용한다(PAB 프로젝트 간 형식 통일).
> **생성**: 2026-08-24 (PAB-Observer 발신 계약 수신으로 개설)

## 규약 (요지)

1. **SSOT 명시**: 협업 문서 상단에 authority 배지를 단다.
2. **무왜곡 사본**: 수신본은 수정하지 않는다. 갱신은 원본 authority가 수행 → 재전달.
3. **브레이킹 통지**: vault 구조·화이트리스트 범위·전파 경로 변경은 상대에 **사전 통지**.

## 파트너별 인덱스

| 파트너 | 인덱스 | 경계 | 상태 |
|---|---|---|---|
| PAB-Observer (관측 인프라) | [`pab-observer/README.md`](pab-observer/README.md) | obsidian=vault 정의·전파 계약 / Observer=4홉 체인 관측 | 활성 (2026-08-24 개설) |
| PAB-Prove (수집 파이프라인) | [`pab-prove/README.md`](pab-prove/README.md) | obsidian=vault 정의·정본 authority / Prove=capture UI·워커 코드 | 활성 (2026-08-25 개설 — **PAB-Prove 발신**) |

> **3자 연동 주의**: PAB-Prove의 3800X 디바이스 편입(PO1·PO2)은 **홉2 구조 변경**이라 PAB-Observer 사전 통지 대상이다(OB2-A §7.3, 리드타임 24h). 두 채널이 한 사안에 물리므로 **편입 실행 전 Observer 통지는 PAB-obsidian이 수행**한다.
