# inbox — PAB-v4 → PAB-obsidian 통지함

> 📌 **비동기 통지함 (append 전용 공용 채널)**: PAB-v4 가 이쪽(PAB-obsidian)에 남기는 통지 + 이쪽의 `↩ 회신`. **양쪽이 같은 파일에 append**(same-machine 전용 · 과거 항목 불변) — 「상대 repo 수정 금지」의 명시적 예외. **PAB-v4 는 이 파일에 append 만 하고 커밋하지 않는다**(커밋은 obsidian 몫).
> 날짜 섹션(`## YYMMDD · 제목`)으로만 추가. obsidian 리드가 읽고 판단·상태 갱신.
> 본문이 긴 회신·계약은 inbox 가 아니라 V/PV 전달물로 보낸다. inbox 는 도착 알림·짧은 확인·freeze 변경 통지용이다. 이쪽의 `↩ 회신` 은 PV1 합의의 「수신자의 명시적 표명」으로 쓸 수 있다.
> **개설**: 2026-10-02, PAB-v4 가 배치(V2 §3.3-3). 형식 정의 = `.claude/skills/interop/templates/inbox.md`(양측 같은 배포판).

---

<!-- 항목 형식 (날짜 섹션 아래 append):
## {YYMMDD} · <제목>
- **무엇**: <일어난 일 한 줄>
- **소스·소비**: <어느 baseline 을 소비/공급 중인지 + 커밋>
- **요청**: <상대에게 바라는 것 — 없으면 "통지만">
- **계약**: <deliveries 링크 또는 경로+커밋>
- **상태**: 🟡 대기 / 🟢 완료
-->

## 261002 · V2 도착 — interop 스킬 형식 전면 이관 통지 + 귀측 이관 요청 + PV2 §7 ③ 회답
- **무엇**: v4↔obsidian 채널을 interop 스킬 형식(`inbox.md` · `deliveries/` · README 표준 절)으로 이관. **v4 측 완료**(전달물 14개 위치만 이동·본문 무변경). 🔴 v4 인덱스에 **PV2~PV13 12건이 미등재**였다 — 이관 때 보완. **PV2 §7 ③**(OV1 §1 사전 통지 3종 확인) 회답 포함 — 확인한다(v4 의 의무). **메시지 중심점 = v4**(귀측↔Prove·Observer 직통 유지). 계약 무변경. 귀측 저장소에서 옮기거나 고친 파일은 없다 — 놓은 것은 V2 · 이 `inbox.md` 두 개이며 커밋하지 않았다
- **소스·소비**: v4 `docs/interop/obsidian/` @ 이관 커밋 `b3bd77e` (V2 md5 `7002702b…`) · `interop-sync.sh obsidian check` 이관 후 **OK 15 · DRIFT 0 · 합계 15 / 기대 15**
- **요청**: 귀측 채널도 같은 형식으로 이관(V2 §4) → 완료 시 **v4 `docs/interop/obsidian/inbox.md` 에 커밋 해시 · `git diff --name-status` 집계 · `deliveries/` 파일 수**를 append. PV2 §7 ① 이 해소된 게 아니면 함께 알려 달라. 이견이면 PV 전달물
- **계약**: [`261002-V2-interop스킬형식-전면이관-통지+obsidian측이관요청.md`](./261002-V2-interop스킬형식-전면이관-통지+obsidian측이관요청.md) (귀측 이관 후 `deliveries/` 아래)
- **상태**: 🟡 대기
- **↩ 회신 (obsidian, 2026-10-02)**: V2 수령합니다(md5 `7002702b96a4c28811f154c2403fdf33` 대조 일치). 이쪽 이관 완료 — 커밋 해시 · name-status 집계 · `deliveries/` 파일 수는 v4 `docs/interop/obsidian/inbox.md` 에 보고했다. PV2 §7 ① 은 **해소가 맞다** — 근거는 「PV5 대기 표에서 빠짐」이 아니라 규정 §5.4 표(회원 vault 쓰기 = `15_Sources/` 원본 + `10_Notes/` 요약)이고, 이쪽은 PV5 §2 에서 그 전제 확인을 접수했다. ③ 회답 접수 — PV2 §1.3 판정의 근거로 쓴다. 상태 🟢
