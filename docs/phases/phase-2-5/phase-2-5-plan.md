# Phase 2-5 Plan — 운영 안정화 + 백업 무결성

- **master_plan**: [phase-2-master-plan.md §4 Phase 2-5](../phase-2-master-plan.md)
- **pre_analysis**: [phase-2-5-pre-analysis.md](../phase-2-5-pre-analysis.md) (ANALYSIS-1, APPROVED)
- **exceptions**: [phase-2-exceptions.md](../phase-2-exceptions.md) (E-1~E-4 상속, 신규 예외 없음)
- **status**: PLANNING
- **실행 순서**: 번호는 2-5이나 **2-1 직후 / 2-2 이전**에 실행

## 1. 목표

가동 중인 동기화 인프라에 **관측(모니터링·알림)** 과 **백업(오프사이트·볼륨)** 계층을 확립하고, Phase 2-1 잔여 인계사항을 해소한다.

**신설 근거**: 2026-08-21 서버 재부팅 → CouchDB 기동 실패 → 3일간 LiveSync 중단 미인지. 복구는 완료했으나 감지 수단이 0건이었다.

## 2. 결정 사항 (사용자 확정 2026-08-24)

| # | 항목 | 확정 | 잔여 위험 · 완화 |
|---|---|---|---|
| DP-2-5-1 | 모니터링 실행 위치 | **3800X crontab** | 서버 자체 다운 시 침묵 → T-1에 맥북발 주 1회 역방향 확인 포함 |
| DP-2-5-2 | git 자동 커밋 주체 | **맥북 로컬 cron** | 맥북 장기 off 시 공백 → T-1이 "마지막 커밋 경과 > 24h" 알림으로 커버 |
| DP-2-5-3 | CouchDB 백업 보존 | **일 1회 × 7세대** | DB 3.6MB, 용량 부담 없음 |

**결정 간 연동**: 서버 cron이 git 공백을 감시하고, 맥북 주 1회 점검이 서버 침묵을 감시하는 **상호 감시 구조**. 두 위험 동시 실현(서버·맥북 동시 장기 정지)은 본 Phase 범위 밖으로 수용.

## 3. 아키텍처

```
[3800X 서버 crontab]                          [맥북 로컬 cron]
  ├─ CouchDB /_up 헬스체크 ──┐                  ├─ git add/commit/push (병합 금지)
  ├─ bridge 컨테이너 상태 ────┤                  └─ 주 1회 역방향: 서버 침묵 감지
  ├─ git 마지막 커밋 경과(>24h)┤                         │
  └─ CouchDB 볼륨 덤프(일1회×7세대)                      ▼
                             │                   GitHub (오프사이트 백업)
                             ▼
              scripts/pmAuto/report_to_telegram.sh
              (연속 N회 실패 시에만 발송 + 복구 시 1회)

역할 분리: LiveSync = 복제(≠백업) / GitHub = 스냅샷 백업 / 볼륨 덤프 = 동기화 메타데이터
```

## 4. Task 구성 (T-1 ~ T-6, 사용자 지정 우선순위 순차)

| Task | 갭 | 내용 | 담당 | 우선 | 상태 |
|---|---|---|---|---|---|
| task-2-5-1 | G-1 | 헬스 모니터링 + Telegram 알림 (cron, 실패 시에만 발송) | backend-dev | 🔴 | ⬜ |
| task-2-5-2 | G-2 | GitHub 백업 정상화(미커밋 해소) + 자동 커밋·푸시 | backend-dev | 🔴 | ⬜ |
| task-2-5-3 | G-3 | CouchDB 볼륨 덤프 백업 자동화 + 세대 보존 | backend-dev | 🟡 | ⬜ |
| task-2-5-4 | G-4 | `pabadmin`·`pabbridge` 자격증명 회전 | backend-dev + 사용자(GUI) | 🟡 | ⬜ |
| task-2-5-5 | G-5 | `workspace.json` git 추적 해제 (R-2 해소) | backend-dev | 🟡 | ⬜ |
| task-2-5-6 | G-6 | iPhone LiveSync 연동 검증 (2-1 T-4 미완분) | 사용자(GUI) + Team Lead 검증 | 🟢 | ⬜ |
| task-2-5-7 | G-7 | `/wiki` 스킬 MOC 자동화 + link-check 게이트 강제 (PO1 §4.4 대응) | Team Lead(SKILL.md) + backend-dev(validate.py) | 🟡 | ⬜ |

**순차 제약**
- T-4(자격증명 회전)는 **T-1·T-2 완료 후** 착수한다 (PR-1 — 회전 중 동기화 일시 중단, 관측·백업 선행 필수)
- **T-2를 최우선으로 앞당긴다** (2026-08-26 결정) — PAB-Prove 3800X 디바이스 편입이 T-4에 물려 있고, T-4는 PR-1에 따라 T-2 완료가 선행이다

### 4.1 PAB-Prove 디바이스 편입 (2026-08-26 편성)

PO1 회답(PO2)으로 **3800X LiveSync 디바이스 편입을 조건부 승인**했다. 편입 실행은 **T-4와 동시**에 처리한다 — 신규 CouchDB 계정 `pabprove` 발급이 필요하고 T-4가 이미 `_users`·`bridge.env`를 다루기 때문이다.

| 항목 | 내용 |
|---|---|
| bridge 구조 | **N-1(config `allowWriteBack` 플래그) + ⒜(별도 컨테이너) 병행** — 미러 bridge는 현행 단방향 유지, Prove용 bridge 신설 |
| 계정 | **`pabprove` 신규 발급** — `pabbridge`는 `_design/zz_bridge_readonly` VDU가 살아 있어 쓰기 시 컨테이너 크래시 |
| 대상 파일 | `pab-vault-cloud/livesync-bridge/Hub.patched.ts` · `config.json.template` · `docker-compose.yml` · `setup-readonly-account.sh` (전부 backend-dev 위임, HR-1) |
| 선행 게이트 | **P-1** — Prove 측 검증 시점 이동(write 전 검증) 완료 통지(R-5) 수신 후에만 실행 |
| 외부 통지 | **Observer 사전 통지 24h**(OB2-A §1.3·§7.3 — 홉2 구조 변경). PAB-obsidian이 수행 |
| 일시 통지 | 확정 시 **PO3** 발신 |

정본 정비 2건(anchor 수선 + `moc-build`)은 **2026-08-26 적용 완료** — orphan 8→0.

## 5. 산출물

- 헬스 모니터링 스크립트 + cron 등록 (서버·맥북 양측)
- git 자동 커밋·푸시 스크립트 + cron 등록
- CouchDB 볼륨 덤프 백업 스크립트 + 세대 보존 로직
- 자격증명 회전 절차서 (전 기기 재설정·롤백 포함)
- 운영 런북 (장애 진단 순서 — 08-21 사건 교훈 반영)
- 검증 보고서 (G2_infra + G3_smoke)

## 6. 검증

**G2_infra (E-1 — Team Lead/verifier 독립 검증, HR-6)**
1. 모니터링 알림 수신 확인 (Telegram 도달)
2. 백업 산출물 생성 확인 + **복원 검증** (덤프 → 복구 리허설)
3. 자격증명 회전 후 전 기기 동기화 정상 동작
4. per-machine 파일 git 미추적 확인 (`workspace.json`)
5. cron 등록 상태 확인 (서버 crontab + 맥북 cron)
6. 평문 자격증명 노출 0 (스크립트·로그·커밋 이력)

**G3_smoke (E-3 — tester 담당, 구현자 셀프체크 금지)**
- **장애 주입 테스트**: 컨테이너 강제 정지 → 알림 수신 → 복구 → 복구 알림 수신 E2E
- git 공백 알림: 마지막 커밋 24h 초과 상황 재현 → 알림 수신

## 7. 리스크

| # | 리스크 | 완화 |
|---|---|---|
| PR-1 | T-4 자격증명 회전 시 전 기기 LiveSync 재설정 → 동기화 일시 중단 | T-1·T-2 완료 후 착수. 절차·롤백 문서화 선행 |
| PR-2 | 알림 과다 발송(플래핑) → 알림 피로 | 연속 N회 실패 시에만 발송 + 복구 시 1회 |
| PR-3 | 자동 커밋이 충돌·불완전 상태를 커밋 | DP-1 git-authority 유지. 자동화는 커밋·푸시만, **병합 금지** |
| PR-4 | Telegram `_` 토큰 parse_mode 충돌 | 기존 회피책 적용 (하이픈 치환·escape) |
| PR-5 | (구조적) Docker가 tailscaled보다 선행 기동 | `net.ipv4.ip_nonlocal_bind=1` 적용 완료. T-1 모니터링이 재발 시 즉시 감지 |
| PR-6 | **bridge 양방향 전환 시 미러 체인 동반 크래시** — `forbidden` uncaught는 peer가 아니라 **프로세스 단위**로 죽는다 | 컨테이너 분리(⒜). Prove bridge가 죽어도 미러(홉2~4)는 생존 |
| PR-7 | **정본 CouchDB probe 중복** — Prove·Observer·우리가 각자 쓰기 시도를 계획 | 역할 분담 고정: `pabbridge` forbidden 확인=**Observer**, `pabprove` 통과 실증=**우리 backend-dev**, Prove는 **금지**(PO2 R-4) |
| PR-8 | **MOC 진동** — 편입 후 `/wiki`와 Prove 워커가 둘 다 `moc-build` 호출 | `moc.py` idempotent + 출력 동일성 확인(PO2 R-3). T-7이 우리 측 담당 |

## 8. SSOT 예외 적용 (E-1~E-4 상속)

| 예외 | 본 Phase 적용 |
|---|---|
| E-1 G2_infra | 적용 — 코드가 아닌 운영 인프라 산출물 |
| E-2 리팩토링 비대상 | 설정파일 비대상. **단 신규 bash 스크립트는 HR-5 정상 적용** (500줄 스캔) |
| E-3 G3_smoke | 적용 — 장애 주입 후 알림 수신 검증 |
| E-4 외부 API 금지 | 해당 없음 (추론 없음) |

## 9. 범위 밖 (이월)

- **G-7**: Phase 2-2 범위 재정의 — PAB-v4가 이미 vault 미러를 인덱싱 중(`brain_documents_v4` 1,661 points). 2-2를 원안대로 착수하면 **동일 vault 2중 인덱싱**. 2-2 진입 전 별도 판단.

## 10. 소요 추정

6 task / 90~150분
