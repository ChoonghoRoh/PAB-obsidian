---
phase: "2-5"
title: "운영 안정화 + 백업 무결성"
team_name: "phase-2-5"
ssot_version: v8.2-renewal-6th   # ver6-2 라인 이행 (2026-08-25). v8.3 policy/model-assignment.md는 이식 보존
created: 2026-08-25
updated: 2026-09-28
current_state: DONE   # 2026-09-28 정식 마감 — 핵심 목표(백업 무결성)는 달성, 잔여는 외부 게이트 종속이라 deferred 로 이관.
                      #   ⚠️ 게이트를 PASS 로 위장해 닫지 않았다 — G3_smoke·G4 는 WAIVED(사유 명시)다.
                      #   ver6-6 SSOT 설치 전제(LOCK-1: IDLE/DONE)를 충족시키려는 마감이지만,
                      #   상태 위조가 아니라 실제 종료 사유가 성립한다(§마감 근거 참조).
                      #   종전 기록: BUILDING(2026-09-10 정정, IN_PROGRESS 는 20개 상태 코드 밖이었음)
exceptions: [E-1, E-2, E-3, E-4]
exceptions_ref: docs/phases/phase-2-exceptions.md
master_plan_ref: docs/phases/phase-2-master-plan.md
pre_analysis_ref: docs/phases/phase-2-5-pre-analysis.md
integration_ref: docs/interop/pab-observer/260825-OB2-vault이원화-회신-및-승격사전통지.md   # Observer/UK 관측 연계 (2026-08-25 신설)
interop_refs:
  - docs/interop/pab-observer/260825-OB2A-OB2회답-승격준비확정+B1~B5회신.md   # Observer 회답 (수신, B-1~B-5 전건)
  - docs/interop/pab-prove/260825-PO1-3800X-LiveSync디바이스편입요청.md      # Prove 발신 (수신본)
  - docs/interop/pab-prove/260826-PO2-PO1회답-디바이스편입-조건부승인.md      # 우리 회답 (2026-08-26)
notify_prefix: "[PAB-LLMDATA]"
execution_order: "2-1 직후 · 2-2 이전 (번호와 실행순서 불일치, master-plan §4 명시)"
gate_results:
  G0: SKIP       # research = false — 사전 분석(phase-2-5-pre-analysis.md, APPROVED)이 조사 대체
  G1: PASS       # plan.md Team Lead 검토 승인 (2026-08-25) — 결정사항·리스크·게이트 반영 확인
  G2_infra: PARTIAL  # 2026-08-26 갱신
  #   T-1 PASS (2026-08-25) + volbackup 감시 연계 PASS (2026-08-26, eb1875b — 6분기 전수 시험)
  #   T-2 조건부 PASS — 커밋·푸시 실체 충족(2efb00e). cron 활성화만 BL-3로 잔여
  #   T-3 ✅ PASS (2026-09-07 확정) — 조건부 → 확정. 마지막 미실증 항목이 닫혔다
  #     ⭐ 세대 회전 실증 (2026-09-07 04:17:03, 무인 자동):
  #        "회전 삭제: pab_couchdb_data-20260826-044630.tar.gz" → 세대 7/7 유지, 총 9487174B.
  #        가장 오래된 것 1개 삭제 확인. root:root 소유 실파일에서 성공 — 논증이 아니라 실측이다
  #        (종전 우려: 격리 루트 가짜 8세대 시험은 통과했으나 소유자 조건이 달랐다. 해소됨)
  #     ⭐ 복원 리허설 첫 무인 실행 (2026-09-06 04:42:01~04, 주 1회 일요일):
  #        doc_count 3064=3064 / _design/zz_bridge_readonly VDU 194자 / _local 13=13 / 잔재 0
  #        → "덤프에서 실제로 DB가 살아난다" PASS. 사람 개입 0
  #     · 백업 무인 발화 연속 4일 확인 (09-04·05·06·07 전부 04:17:0x)
  #     · 잔여: UK Push URL 미설정으로 Observer 측 2계층 감시는 생략 중 (BL-1, T-1 로컬 폴백이 감시)
  #     · crontab 8줄 → 10줄, 기존 8줄 전건 무변경 (Observer #32 17:03 → 우리 17:04, 1시간 분리 확인)
  #     · 프라이밍 선행: 백업 1회 + 복원 리허설 1회 → LAST_OK_TS/LAST_VERIFY_TS 09-03 10:05로 갱신
  #     · ⭐ 목적 달성 확인 — T-1 check_couchdb_volbackup 판정이 실제로 OK
  #       (경과 0h, 세대 4/7, 리허설 0일 전). 마커 grep 여부가 아니라 판정값을 확인함
  #     · 가동본 pab-couchdb `Up 10 days (healthy)` 무접촉 / restoretest 잔재 0·0
  #     · 롤백: state/crontab.bak-20260903-100515 (600, 819B)
  #     · 미측정(명시): 세대 회전 — 4세대 < KEEP=7이라 아직 발동한 적 없음
  #   T-7 조건부 PASS (2026-09-03, bf40027) — TOPIC 갱신 루프 이식 완료
  #     · 이식 지침 13항목(6종 + N-1~N-7) 전건 이행. 시험 17개 + **돌연변이 7종 주입 검증**
  #     · TOPICS 인식 0건 → **22건** + _README [SKIP]. link-check 5회 반복 전부
  #       PASS (notes=101, violations=0, broken=185, orphans=0) — 모집단 101 확정값 일치
  #     · §5 비결정성 — 도구 결함은 **재현**(obsidian unresolved가 10회 중 1회 1줄을 rc=0으로).
  #       단 그것이 과거 broken:0 관측의 원인이라는 **연결은 추론이며 관측 못 함**(backend-dev
  #       자기 정정). §5는 관측 항목 유지. 가드는 방어적으로 옳아 유지 — 정본 10회 동일
  #     · 부수 보고 1건(TYPES 2종 누락)은 **Team Lead 검증으로 반려** — 6종 전부 존재.
  #       원인은 `| tail -35` 절단(전체 36줄, 앞 2줄이 정확히 그 둘). backend-dev 감사 결과
  #       "없다"류 주장 8건 중 절단 기반은 이 1건뿐. 규율: 부재 주장은 tail/head 출력으로 하지 않는다
  #     · ⭐ 대신 **진짜 불일치 1건 발견** — TYPES/SOURCE.md가 얼어붙은 MOC다.
  #       마커는 있는데 MOC_TYPE_NAMES(6종)에 SOURCE가 없어 루프가 도달하지 않고,
  #       '(현재 등록된 노트 없음)'을 표시하는데 실제 type:[[SOURCE]] 노트는 41건이다.
  #       N-5가 경고한 상수 목록 형태 — T-7이 TOPICS를 디스크 glob으로 옮긴 이유와 같은 종류.
  #       결함/의도 판정은 유보. **T-7 범위 밖, 별도 판단 대상으로 등재**
  #     ⚠️ 잔여: 22건 일괄 갱신 미실행(정본 쓰기·사용자 승인 대기) / G2_infra E2E 미수행
  #   T-7 §작업3 PASS — link-check status 정합(PASS/exit 0, --strict-broken 하위호환)
  #   T-4 미착수(pending) · T-6 미착수(pending, depends_on 2-5-4) · T-7 running
  #   ⚠️ 2026-09-21 정정 — 종전 "T-4·T-5·T-6 미착수 (T-5 진행 중)"은 T-5를 *미착수*와
  #      *진행 중*으로 동시에 적은 자기모순이었고 둘 다 틀렸다. task-2-5-5.md 실측
  #      `status: completed` (2026-08-26, workspace.json 추적 해제 + skip-worktree 제거).
  #      frontmatter 8번 줄의 "잔여 T-4·T-6·T-7"이 맞는 기록이다.
  #      ★ ssot-reload 에이전트도 이 줄을 그대로 인용해 같은 오류를 재생산했다 —
  #        요약을 읽고 옮기지 말고 task 파일 status 를 실측할 것
  #   [T-1 검증 결과]
  #   ✓ Tailnet IP(100.109.251.86) 경유 — localhost 회피 확인
  #   ✓ printf %q 상태파일 규약 준수 (46일 침묵 사고 재발 방지)
  #   ✓ UK_PAB_VAULT_PUSH_URL 미설정 시 Push 생략 후 정상 종료
  #   ✓ 정상 상태 Telegram 발송 0건 — 무소음 확인
  #   ✓ cron 등록: 서버 */5, 맥북 watchdog 주1회 + git-stamp 매시간
  #   ✓ 폴백 구조: UK URL 등록 시 Telegram 자동 중단(PAB_TELEGRAM_FALLBACK=auto)
  #   ✓ HR-5: 최대 463줄 (500줄 미만)
  #   △ 잔여: 스크립트 주석의 문서 경로가 구 경로(phase-2-5-observer-integration-prompt.md)
  #           → OB2 경로로 갱신 필요 (Team Lead 문서 이동에 기인, backend-dev 재스폰 시 처리)
  #   ⏸ G3_smoke 장애 주입은 tester 미스폰 — HR-6 독립성 유지 위해 별도 수행 필요
  #   🔴 2026-09-20 LiveSync 감시 전면 중단 (사용자 지시, Observer 실행 · 사후 통지)
  #     3800X crontab 에서 `[LIVESYNC-STOP 20260920]` 태그와 함께 주석 처리된 3종 중
  #     **2종이 우리 스크립트**다 — pab-vault-sync-collect.sh · pab_sync_healthcheck.sh.
  #     ⚠️ **T-1 의 check_couchdb_volbackup 실행체가 pab_sync_healthcheck.sh 뿐이다**
  #        (맥북 crontab 3줄에 healthcheck 없음). 즉 G2_infra PASS 근거였던 T-1 감시가
  #        실제로 멈췄다. 백업(pab_couchdb_volume_backup.sh, crontab 12·13줄)은 생존 —
  #        Observer 의 "백업은 별개" 판단은 옳다. 결과는 **백업은 돌고 검사자는 꺼진** 상태.
  #     · 마지막 하트비트(2026-09-20 19:57:01 KST)가 STATUS=FAIL/FAILING=github-backup 로 얼어붙음.
  #       독립 검증 결과 **고장 아님** — origin/main tip 51h 경과는 사실이나 autocommit 은
  #       09-18 18:17~09-20 18:17 2시간 슬롯 25회 전건 실행(누락 0), 전부 "변경 없음".
  #       vault 무변경이 원인이고, 체크가 "tip 나이"를 "백업 동작"의 대리 지표로 쓰는 과민이다.
  #     · G2_infra 판정 영향: T-1 PASS 는 **관측 중단으로 유효성 정지**. 재개 시 재확인 필요.
  G3_smoke: WAIVED   # 2026-09-28 — E-3 장애 주입 E2E 미수행 확정. PASS 아님, 면제다.
  #   사유 ⑴ tester 미스폰 + HR-6(구현자 셀프체크 금지)으로 독립 수행 필요
  #   사유 ⑵ 가동 서비스 중단을 수반해 사용자 승인 필요 — 미승인
  #   사유 ⑶ 🔴 **주입 대상 자체가 사라졌다** — 2026-09-20 LiveSync 감시 전면 중단으로
  #          장애를 주입해 볼 관측 계층이 내려갔다. 지금 수행하면 없는 것을 시험하는 셈
  #   → 재개 시 재정의 후 수행 (deferred: T-GATE-1)
  G4: WAIVED         # 2026-09-28 — G3_smoke WAIVED 로 선행 미충족이라 판정 불가. NOTIFY 미발송
blockers:
  - id: BL-1
    task: "2-5-1"
    status: WITHDRAWN   # 2026-09-21 — 판정 대기에서 내림
    desc: "[철회] UK_PAB_VAULT_PUSH_URL 미발급. 2026-09-20 LiveSync 감시가 전면 중단되어 Push 대상 자체가 사라졌다. Observer 도 OB2-C·OB2-F 를 같은 이유로 판정 대기에서 내렸다. 재개 시 재등재 — 단 Observer 경고대로 미러 경로 재편이면 홉 구조가 달라지므로 **지표를 그대로 되살리지 말고 무엇을 어떤 단위로 볼지 먼저 합의**한다"
    owner: "재개 시점 재협의"
  - id: BL-2
    task: "2-5-1"
    status: WITHDRAWN   # 2026-09-21 — 판정 대기에서 내림 (단 원인은 BL-5 로 규명됨)
    desc: "[철회·승계] 기존 UK CouchDB 모니터 알림 미도달 원인 미규명. 감시 체계 자체가 중단되어 대기 무의미. ⭐ 다만 **같은 실패 양식이 우리 쪽에서 실증되어 BL-5 로 승계**한다 — 규명 없이는 신규 모니터도 동일 침묵 위험이라던 우려가 맞았다"
    owner: "→ BL-5"
  - id: BL-3
    task: "2-5-2"
    status: RECURRING   # 2026-09-02 1회 해소됐으나 2026-09-21 재발 — 일시 해소지 제거가 아니다
    desc: "[해소] 맥북 crontab **쓰기** 차단(macOS TCC 추정). 2026-09-02 사용자가 deploy_monitoring.sh --local-only 1회 실행하여 해소. 실측(2026-09-02 22:06 KST): crontab 3줄 — 기존 2종 무변경 + `17 */2 * * * ... # PAB-GIT-AUTOCOMMIT` 신규 등재. ⚠️ 등재는 확인됐으나 **발화는 2026-09-03 09:23 기준 0회** — 예정 6회(22:17·00:17·02:17·04:17·06:17·08:17)가 전부 맥북 슬립 창(09-02 22:00 직후 ~ 09-03 09:23:11, kern.waketime 실측)에 포함. macOS cron은 놓친 실행을 보충하지 않음. 다음 기회 09-03 10:17.
      🔴 **2026-09-21 재발** — watchdog 중단을 위한 `crontab <파일>` 쓰기가 **에러 없이 무기한 정지**(PID 실측 S 상태 2분+, rc 없음). `crontab -l` 읽기는 정상. 프로세스 종료 후 crontab 원본 무변경 확인. 2026-09-02 조치는 그 1회를 통과시킨 것이지 조건을 제거한 게 아니었다.
      ⚠️ 부수 발견: macOS `crontab` 이 긴 경로를 잘라먹는다 — scratchpad 경로가 `.../scratchpad/c` 로 절단되어 ENOENT. 짧은 경로(`~/.pab-sync-monitor/`) 사용 필요.
      준비 완료(사용자 터미널 1회 실행 대기): `crontab ~/.pab-sync-monitor/crontab.new` · 롤백 `crontab ~/.pab-sync-monitor/crontab.bak-20260921-202020`"
    owner: "사용자 (터미널 1회)"
  - id: BL-4
    task: "2-5-1"
    status: OPEN
    desc: "🔴 맥북 역방향 watchdog 중단 미적용 — LiveSync 감시 중단(2026-09-20)으로 하트비트 생산자가 꺼졌으나 pab_sync_watchdog_local.sh 는 여전히 `0 9 * * 1` 로 등재돼 있다. BL-3(crontab 쓰기 차단)로 적용 실패. 사용자 터미널 1회 실행 필요"
    owner: "사용자 (터미널 1회)"
  - id: BL-5
    task: "2-5-1"
    status: OPEN
    desc: "🔴 **watchdog 전역 래치 결함 — 최후 방어선이 21일간 무력화됐고 진짜 경보를 삼켰다**.
      실측(2026-09-21 20:19): `~/.pab-sync-monitor/watchdog-state.env` = WATCHDOG_ALERT=1 / ALERT_SINCE=1788134522(**2026-08-31 09:02**).
      경위 — 08-31 09:02 FAIL 로 래치 ON(이때 1회 발송) → 09-07·09-14 월요일 **미실행**(맥북 슬립, macOS cron 보충 없음; kern.boottime 09-04 08:40 로 /tmp 로그도 유실) → 09-21 09:02 FAIL 재확정하고 `이미 알림 상태 — 중복 발송 억제`.
      ⚠️ 08-31~09-20 사이 서버는 **실제로 정상**이었다(하트비트 5분 주기 갱신을 09-20 19:57까지 실측). 그 사이 한 번만 돌았어도 `✅ 서버 정상 복귀 확인`이 나가고 래치가 풀려, 오늘의 진짜 고장('서버 감시가 멈췄다')이 정상 발신됐을 것이다.
      ★ 근본 원인은 **전역 래치 1개**다. pab_sync_healthcheck.sh 는 주석에서 전역 래치를 명시적으로 거부하고 항목별(ALERTED_<key>)로 전환했는데, **pab_sync_watchdog_local.sh 는 그 수정을 못 받았다**(WATCHDOG_ALERT 단일 변수). 여기에 주1회 스케줄 + 슬립 결번이 겹쳐 복구 관측 기회가 3회 중 1회로 줄었다.
      → 조치: ⑴ 항목별 래치 이식 ⑵ 스케줄 상향 또는 슬립 보정(오래 눌린 ALERT 자체를 이상으로 승격) ⑶ 래치 잔류 시 주기적 재알림.
      ⚠️ scripts/ 코드 영역이라 **HR-1: backend-dev 위임 필수** — Team Lead 직접 수정 금지. FRESH-7 팀 재구성 선행"
    owner: "backend-dev (미스폰)"
domain_tags_in_use: [INFRA]
roles:
  team_lead: main
  backend_dev: not_spawned   # 2026-09-10 정정 — T-3 등록 완료 후 미스폰 상태였으나 표기가 남아 있었다.
                             #   ListAgents 실측(2026-09-10): 팀원 0명, team-lead 단독
  verifier: not_spawned
  tester: not_spawned        # G3_smoke 장애 주입 (HR-6 독립성)
  frontend_dev: not_spawned  # 미사용
sub_phase_artifacts:
  status: docs/phases/phase-2-5/phase-2-5-status.md
  plan: docs/phases/phase-2-5/phase-2-5-plan.md
  todo_list: docs/phases/phase-2-5/phase-2-5-todo-list.md
  tasks_dir: docs/phases/phase-2-5/tasks/
  tasks:
    - tasks/task-2-5-1.md  # [G-1] 헬스 모니터링 + Telegram 알림
    - tasks/task-2-5-2.md  # [G-2] GitHub 오프사이트 백업 정상화 + 자동 커밋·푸시
    - tasks/task-2-5-3.md  # [G-3] CouchDB 볼륨 덤프 백업 + 세대 보존
    - tasks/task-2-5-4.md  # [G-4] 자격증명 회전 (pabadmin·pabbridge)
    - tasks/task-2-5-5.md  # [G-5] workspace.json git 추적 해제
    - tasks/task-2-5-6.md  # [G-6] iPhone LiveSync 연동 검증
    - tasks/task-2-5-7.md  # [G-7] /wiki 스킬 MOC 자동화 + link-check 게이트 (2026-08-26 신설, PO1 §4.4 대응)
5th_mode:
  research: false          # 사전 분석 완료 (APPROVED)
  event: true              # 2026-08-21 CouchDB 3일 장애 사건 대응
  automation: true         # cron 기반 모니터링·백업 자동화
  branch: false            # 신규 스크립트 위주, 충돌 위험 낮음 → main 진행
  multi_perspective: false
decision_points:
  DP-2-5-1: "모니터링 실행 위치 = (A) 3800X crontab + 맥북발 주 1회 역방향 확인 보조"
  DP-2-5-2: "git 자동 커밋 주체 = (A) 맥북 로컬 cron (DP-1 git-authority 무변경)"
  DP-2-5-3: "CouchDB 백업 보존 = 일 1회 × 7세대"
  DP-2-5-4: "bridge 역방향 허용 = N-1(config allowWriteBack 플래그) + ⒜(별도 컨테이너) 병행 — 미러 체인 가용성을 Prove와 분리 (2026-08-26)"
  DP-2-5-5: "N-2 쓰기 실증 = T-4 자격증명 회전과 동시. pabbridge는 VDU 생존으로 사용 불가 → pabprove 신규 발급 (2026-08-26)"
  DP-2-5-6: "정본 정비 2건 = PAB-obsidian 직접 적용 (2026-08-26 완료, orphan 8→0)"
  DP-2-5-7: "/wiki 개선 = 최소 수정(T-7)만 본 Phase 편입. 저장 계층 통합은 범위 밖 (2026-08-26)"
  DP-2-5-8: "T-3 = 물리 볼륨 덤프(논리 백업은 Observer #32가 이미 수행). 고유 가치 = 리비전 트리·뷰 인덱스·볼륨 일관 복구 신뢰성 (2026-08-26)"
  DP-2-5-9: "T-3 정합성 = ⒜ 컨테이너 무정지 + append-only + 아카이브 무결성 검증. ⒝정지는 모니터 3종 동시 알림, ⒞FS 스냅샷은 루트 LV 전체라 과함 (2026-08-26)"
ssot_loaded_at: 2026-09-04T08:55:00
deferred:
  G-8: "Phase 2-2 범위 재정의 (PAB-v4 기존 RAG 중복 인덱싱 회피) — 본 Phase 범위 밖, 2-2 진입 전 별도 판단 (구 G-7, T-7 신설로 재채번)"
  PROVE-1: "저장 계층 통합 (/wiki ↔ Prove safe_write_* 경유) — 의존 방향 유보. 가드 계층 upstream 편입을 대안 제시, Prove 확정 통지 후 판단 (PO2 §5.4)"
  T-4: "자격증명 회전(pabadmin·pabbridge) + pabprove 발급 + 편입 실행 — task-2-5-4.md status: pending. 차단은 **외부 게이트**다: Prove R-5 회신 + PR-1(T-2 cron, 해소됨). 우리 통제 밖이라 Phase 2-5 로 끌고 갈 수 없다. 재진입 조건: Prove R-5 수신"
  T-6: "iPhone LiveSync 연동 검증 — task-2-5-6.md status: pending. depends_on 2-5-4(T-4) — 회전 전 설정하면 재설정 2회. T-4 종속이라 함께 이관"
  T-7: "/wiki MOC 자동화 잔여 — task-2-5-7.md status: running (조건부 PASS, bf40027). 잔여 ⑴ TOPICS 22건 일괄 갱신 미실행(정본 쓰기·**사용자 승인 대기**) ⑵ G2_infra E2E 미수행(/wiki 실사용 시 자연 검증, 더미 노트로 정본 오염 금지). scripts/ 변경이라 재개 시 **HR-1 backend-dev 위임 필수**"
  T-GATE-1: "G3_smoke 장애 주입 E2E 재정의 후 수행 — 2026-09-20 감시 중단으로 주입 대상이 사라졌다. Observer 경고대로 미러 경로가 재편되면 홉 구조가 달라지므로 **지표를 그대로 되살리지 말고 무엇을 어떤 단위로 볼지 먼저 합의**한 뒤 시험을 설계한다"
  TYPE-1: "TYPE 어휘 정본 판정 — PROJECT.md \"6\" / frontmatter-spec:49 \"7(INDEX)\" / 실물 TYPES/ 7(SOURCE) 셋 다 불일치. 설계 판단이라 미결. 별건: TYPES/SOURCE.md 가 얼어붙은 MOC(마커는 있으나 MOC_TYPE_NAMES 6종에 SOURCE 부재, 실제 type:[[SOURCE]] 41건)"
  MOC-1: "moc-build 에 `_` 접두 제외 반영 — 🔴 파괴적(MOC 3곳 항목 누락 + 전 기기 복제 전파). scripts/ 라 HR-1 위임. **사용자 승인 대기**"
  MIG-1: "scripts/migrations/ 추적 해제 — v4 삭제 승인 완료(정본은 alembic 18개, 참조 코드 0). 8파일 + docs/SSOT/GUIDE.md 참조 6곳. ⚠️ ver6-6 설치로 GUIDE.md 가 사라지므로 **참조 정리 대상이 소멸**한다 — 설치 후 재확인"
  O-4: "서버 증분 60건 선별 기준 미확정 — 편입 경계(편입 실행 완료 시각) 이전 산출물이 대상. OB3에 승격 범위와 함께 정리"
---

# Phase 2-5 Status — 운영 안정화 + 백업 무결성

상태: **DONE** (2026-09-28 마감) — 종전 본문 표기 `IN_PROGRESS` 는 20개 상태 코드 밖이었다(frontmatter 는 2026-09-10 에 BUILDING 으로 정정됨)

## 진입 요약

2026-08-21 서버 재부팅으로 `pab-couchdb` 기동 실패 → **3일간 LiveSync 전면 중단이 미인지**된 사건 대응.
복구는 완료(`ip_nonlocal_bind=1` + `--force-recreate`)했으나 **관측·백업 계층 부재**가 드러나 Phase 2-5를 사후 신설했다.

## 다음 액션 (2026-08-26 갱신)

1. ~~`phase-2-5-plan.md` 확정 → G1 PASS~~ ✅ (2026-08-25)
2. ~~T-1 모니터링~~ ✅ G2_infra 조건부 PASS (2026-08-25)
3. ~~T-2 자동 커밋·푸시~~ ◐ **구현·검증 완료** (커밋 `2efb00e`, 미커밋 0 / 미푸시 0). **cron 활성화만 BL-3로 잔여 — 사용자 터미널 1회 실행 필요**
4. **T-3(CouchDB 물리 볼륨 백업)** ← 진행 중. 스크립트 작성·1회 실행 완료. **복원 리허설 + Observer OB2-C 판정 후 cron 등록**
5. T-4(자격증명 회전 + `pabprove` 발급 + 편입 실행) — 게이트 P-1(Prove R-5)·P-2(Observer 24h) 대기
6. T-5 · T-6 · T-7(§작업 3 완료, SKILL.md 분 완료)
7. tester 스폰 → G3_smoke 장애 주입 E2E (HR-6: 구현자 셀프체크 금지, **사용자 승인 필요** — 가동 서비스 중단 수반)
8. G4 PASS 후 NOTIFY 발송 (`[PAB-LLMDATA]`, NOTIFY-1)

## 외부 협업 상태 (2026-08-26)

| 채널 | 최근 | 우리 대기 | 상대 대기 |
|---|---|---|---|
| PAB-Observer | OB2-A 수신(회답 완료) | OB2-A §8 ①~⑤ 회신 · OB3(승격 실행 통지) | — |
| PAB-Prove | **PO2 발신**(2026-08-26) | PO3(편입 일시 통지) | PO2 §8 R-1~R-6 (**R-5가 편입 게이트 P-1**) |

### 팀 운영 합의 (2026-08-26) — 다음 세션 인계

- **게이트는 작업 지시와 같은 메시지 안에** 넣는다. 후속 메시지로 조건을 추가하면 상대는 이미 움직인 뒤일 수 있다. 바꿔야 하면 *"직전 지시 X를 Y로 대체한다"*고 명시한다 (Team Lead 측 규율 — 이번 세션에 실제로 어겼고 T-5에서 혼선이 났다)
- **공유 자원 비가역 단계 앞에서는 지시가 요구하지 않아도 먼저 확인**한다 — 서버 배포·원격 쓰기·cron·커밋 (backend-dev 측 규율. 이번 세션 T-3 서버 배포가 그 기준이면 멈췄어야 했다)
- **HR-5 분할 방향** (`pab_sync_healthcheck.sh` 499줄, 임계 직전): `check_*` 함수만 별도 파일로. **디스패처·상태관리·알림 규율은 본체 유지** — PR-2(연속실패)/PR-4(md_safe) 상속 구조가 깨지면 알림 규율이 두 벌이 된다

### 세션 종료 시점 잔여 (2026-08-26)

| 항목 | 대기 사유 | owner |
|---|---|---|
| **T-2 cron 활성화** | **BL-3** — 맥북 crontab 쓰기 차단 | **사용자** (`deploy_monitoring.sh --local-only` 1회) |
| T-3 서버 cron 2줄 + `deploy_monitoring.sh` 통합 | Observer **OB2-C** 정식 판정 | Observer(다음 세션) |
| `UK_COUCHDB_VERIFY_PUSH_URL` + `#33` 실번호 | 〃 (코드 변경 불요, 값만 들어오면 동작) | 〃 |
| T-4 자격증명 회전 + `pabprove` 발급 | **PR-1**(T-2 cron 선행) + Prove **R-5** | 사용자·Prove |
| T-6 iPhone LiveSync | `depends_on: 2-5-4` — 회전 전 설정하면 재설정 2회 | 사용자(T-4 이후) |
| T-7 G2_infra E2E | `/wiki` 실사용 시 자연 검증 (더미 노트로 정본 오염 금지) | — |
| G3_smoke 장애 주입 | tester 미스폰 + **가동 서비스 중단 수반 → 사용자 승인 필요** | 사용자 |

**진행 중 조율** (2026-08-26)
- **T-3 사전 통지 완료** — Observer 전건 수용 가능 회신, 정식 판정은 OB2-C. **cron 등록은 판정 후**
- **합의**: `_local` 백업은 Observer `#32`에 추가(이중화, 비용≈0) / T-3 정합성 ⒜ 무정지 확정 / 복원 리허설 절차는 양측 공용으로 공유
- **상호 정정 3건** — 이 협업의 실적: Observer가 §7.1 "미재연결 확정" 철회 · 우리가 OB2-B §2.3 "02:45 연결됨" 철회(r2) · Observer가 "논리 백업은 VDU 미포함" 철회 · 우리가 "`_local`은 논리로 못 받음" 철회. **모두 "관측은 맞았고 결론이 근거보다 넓었던" 같은 형태**

---

## 마감 근거 (2026-09-28)

> ver6-6 SSOT 설치 전제(LOCK-1: IDLE/DONE)를 충족시키기 위한 마감이지만, **상태를 위조한 것이 아니라 실제 종료 사유가 성립한다.** 아래가 그 근거다. 게이트는 PASS 로 위장하지 않고 `WAIVED`(사유 명시)로 남겼다.

### 달성한 것

| Task | 결과 |
|---|---|
| **T-1** 모니터링 | PASS — Tailnet 경유·무소음·폴백 구조 확인 |
| **T-2** 자동 커밋·푸시 | 실증 완료. **2h 슬롯 25회 연속 무결번 발화**(09-18 18:17 ~ 09-20 18:17) 확인. BL-3 해소(2026-09-02) |
| **T-3** CouchDB 볼륨 백업 | **PASS 확정**(2026-09-07) — 세대 회전 무인 실증 + 복원 리허설 무인 성공. **Phase 핵심 목표(백업 무결성) 달성** |
| **T-5** workspace.json 추적 해제 | completed (2026-08-26) |
| **T-7** /wiki MOC 자동화 | 조건부 PASS (bf40027) — TOPICS 인식 0 → 22건, 시험 17개 + 돌연변이 7종 |

### 닫는 이유 — 잔여는 우리가 못 움직인다

1. 🔴 **기반이 사라졌다** — 2026-09-20 사용자 지시로 **LiveSync 감시가 전면 중단**됐다(Observer 실행). 중단 3종 중 2종이 우리 스크립트(`pab-vault-sync-collect.sh`·`pab_sync_healthcheck.sh`)이고, **T-1 의 `check_couchdb_volbackup` 유일 실행체가 후자**다. 백업은 돌고 검사자는 꺼진 상태다. 이 위에서 Phase 를 "진행 중"으로 두는 것은 사실과 다르다.
2. **T-4** — Prove `R-5` 외부 게이트 대기. 우리 통제 밖.
3. **T-6** — `depends_on: 2-5-4`. T-4 가 막히면 자동으로 막힌다.
4. **T-7** — 잔여 2건이 각각 **사용자 승인**(정본 22건 쓰기)과 **실사용 자연 검증**(더미 노트 금지) 대기. 시간이 아니라 사건을 기다린다.
5. **BL-1·BL-2** — 둘 다 Observer 소관이었고, 감시 체계가 내려가며 **판정 대기에서 내렸다**(Observer 도 `OB2-C`·`OB2-F` 를 같은 이유로 내림).

### 남은 미해결 — 이관하되 잊지 않는다

- 🔴 **BL-5 watchdog 전역 래치 결함** — `WATCHDOG_ALERT` 단일 변수가 2026-08-31부터 21일간 ON 이었고, 09-21 의 진짜 경보("서버 감시가 멈췄다")를 중복 억제로 삼켰다. `pab_sync_healthcheck.sh` 는 항목별 래치로 고쳤으나 **형제 훅이 그 수정을 못 받은 형태**다. `scripts/` 라 **HR-1 backend-dev 위임 필수**.
- 🔴 **BL-3 재발(RECURRING)** — macOS `crontab` **쓰기**가 에러 없이 무기한 정지. 2026-09-02 조치는 1회 통과였고 조건 제거가 아니었다. `BL-4`(watchdog 중단 미적용)가 이것 때문에 미해소.
- **채널 규약 vs 자동화 충돌** — 규약은 "수신본은 커밋하지 않는다"인데 T-2 자동 커밋(`git add -A`)이 interop 수신본까지 잡는다. 미해결.

### 다음 Phase 진입

실행 순서상 다음은 **2-2 (RAG/MCP)** 이며 `deferred: G-8`(범위 재정의) 가 선행 조건이다. 이관한 `T-4`·`T-6`·`T-7`·`T-GATE-1` 은 2-2 범위가 아니므로, **운영 계열 후속 Phase 를 별도 채번**하거나 재진입 조건(Prove R-5 수신·사용자 승인)이 충족될 때 단발로 처리한다. CHAIN-13 에 따라 다음 Phase 는 본 status 를 직전 기억으로 로딩한다.
