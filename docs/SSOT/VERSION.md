# SSOT 버전 관리 (6th iteration)

**통합 릴리스**: `v8.2-renewal-6th`
**릴리스 날짜**: 2026-04-13 (v8.0) / 2026-04-15 (v8.0.1) / 2026-04-16 (v8.1) / 2026-04-16 (v8.2 — AutoCycle v1.1 Phase-I) / 2026-07-08 (v8.2 유지 — 이식성 잔재 정리) / 2026-05-22 (ver6-1 PoC — LIFECYCLE-5 도입) / 2026-08-07 (ver6-2 라인 신설 — Phase 8-1) / 2026-08-08 (LIFECYCLE-6 도입, Phase 8-3 + 신호원 정비, Phase 8-5) / **최신 갱신: 2026-08-09 (ver6-2 PoC — 검증 매트릭스 + 결함 수정, Phase 8-6)**
**라인**: **ver6-2 (PoC, LIFECYCLE-6 도입)** — 정본(`docs/SSOT/docs/`, v8.2-renewal-6th)과 분리된 검증 전용 세대. 원본은 PAB-claude 번들 v1.5-260710
**전략**: **5th 기반 확장** — 5th 단독 사용 구조 유지 + SUB-SSOT 모듈형 로딩 아키텍처 + **AutoCycle 15단계 자동 handoff (사용자 주도 Step 0 Pre-draft 포함)**

**최근 변경 (2026-08-14 — ver6-2 PoC, Phase 9-4, 훅 파서 보강 + 수칙·절차 명문화 + 이식 문서 2종 + 라인 마감, 버전 번호 유지 v8.2)**: TR-01(BookKeep API) 시운전 피드백 4건(FB-01-1·FB-01-3·FB-01-5 + 훅 파서 결함)을 반영하고 `ver6-2` 라인을 마감했다(신규 기능 개발 종료 — 배포본 폐기 아님, 상세는 README.md §10.1). 변경 파일: ① `.claude/hooks/state-transition-guard.sh`(193→200줄, 순증 7) — read_counter/NEW_STATE/OLD_STATE 3지점에 `#` 이후 주석 절단 로직 삽입(카운터 행·current_state 행 인라인 주석 오파싱 해소, FB-01-3ⓑ) + AUTO_FIX DEF-2(단일 인용부호 제거·선행 `+` 제거로 차단 약화 경로 봉쇄). **md5 전 `3c191ca33f91c14bfdd59945843ff1b0`(기준 커밋 `932b2fc`) → 후 `205770a6bf463e2c6866129f22f4108f`** ② `3-workflow.md`(1283→1284줄) — §2.2 카운터 행 인라인 주석 금지 수칙 1행 신설(FB-01-3ⓐ) + §AGENT-LIFECYCLE LIFECYCLE-6 행 arm 시점 재정의(인플레이스, 순증 0) ③ `.claude/skills/phase-init/SKILL.md`(189→190줄) — status 템플릿에 카운터 주석 금지 안내 1행(FB-01-3ⓐ) ④ `SUB-SSOT/TEAM-LEAD/2-lifecycle-procedure.md`(380→403줄) — §LIFECYCLE-5 모델 전환 조건부 승격(장애 신호 529/overload 동반 시 옵션 B 1순위, FB-01-1) + §LIFECYCLE-6 arm 시점 재정의(TEAM_SETUP 완료 직후, BUILDING 게이트=2차 방어선)·arm/회수 체크리스트·`--stop` 조건부 강등 신설(FB-01-5) ⑤ `0-entrypoint.md`(651줄, 순증 0 — 각주 인플레이스 확장) — 모델 승격 예외 각주에 장애 시 즉시 전환 조항 추가 ⑥ `ver6-2/INSTALL.md` 신설(134줄) — 설치 가이드 정본 8절(§0 문서 위치~§7 다음 단계, 번들 루트·미배포) ⑦ `MIGRATION-6-1-to-6-2.md`(185→256줄) — 6-x(ver6-0/구v8.2·ver6-1·ver6-2 구버전) 통합 확장: §0 출발점 판별표·§2 9-1~9-4 변경분·§3.6 훅 갱신 확인·§4 귀속 갱신(D8-1·T-5·V-2 ver7-0 이관 태그)·§7 줄수 현행화·§8 라인 종료 선언 신설 ⑧ `ver6-2/README.md` — §3.2 절차 원문 제거(INSTALL.md로 정본 이관) + §10 v1.6 changelog 행·§10.1 종료 선언 신설 ⑨ `.claude/README.md` §2 — 정본은 INSTALL.md(미배포) 1행 ⑩ `UPGRADE.md` §1.1 — MIGRATION 행 "6-x→ver6-2" 갱신 + 신규 설치 안내 각주 ⑪ `docs/guide/index.html`(1164줄, 순증 0) — LIFECYCLE-6 설명의 arm 시점을 3-workflow:469 신 문안으로 축약 반영(1차 verifier 라운드 누락분 DEF-5). **회귀**: H표 17/17 · M표(무변경 계약·배포 실증) 6/6 · D표(문서 기계 검증) 6/6 — self-test `zombie_check.sh` 21/21 · `zombie_watch.sh` 29/29, 무변경 계약 16/16 MATCH(타 훅 8종·zombiecheck 7종 기준선 `932b2fc` 동일) · `core/6-rules-index.md` md5 불변(104건 불변 확정). **게이트**: G2 PASS(3차 최종, Critical 0·High 0·Medium 0) · G3 PASS(29/29, FAIL 0). **이월(ver7-0)**: V-5·V-2·T-5·D8-1·FB-01-2·FB-01-4·FB-01-6·`core/6-rules-index.md` L180·L466 arm 문구 동기화(무변경 계약으로 9-4 미수정)·`zombie_watch.sh --help`의 `--stop` 무조건 안내·`3-workflow.md` 상대링크 BROKEN 4건(9-2 LINK-2·LINK-3 기이월 계열, 신규 아님). **근거**: `docs/phases/phase-9-4/phase-9-4-plan.md` · `docs/phases/phase-9-4/reports/report-verifier.md` · `docs/phases/phase-9-4/reports/report-tester.md` · `docs/phases/phase-9-4/reports/report-tester-baseline.md`.

**이전 변경 (2026-08-11 — ver6-2 PoC, Phase 9-2, SUB-SSOT 문서 Lv1 분리 + 참조 갱신, 버전 번호 유지 v8.2)**: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md`가 671/700(여유 29)에 도달해 REFACTOR-2 Lv1 분리를 수행. **기능·규칙 변경 0건 — 문서 위치만 이동한다.** 변경 파일: ① `SUB-SSOT/TEAM-LEAD/2-lifecycle-procedure.md` 신규(210줄) — 본체 L291~490의 §LIFECYCLE-5 RESPAWN·§LIFECYCLE-6 SCHEDULER 200줄을 **무수정 이관**. 이관 무결성은 `git show 18a5024:…/1-orchestration-procedure.md | sed -n '291,490p'` 와 신규 파일 추출분의 **바이트 대조 diff(exit 0, md5 `ae5efb0a41d5ab6634d99d4647160ee7` 양쪽 동일)** 로 입증했다(🔴 **기준을 `HEAD` 로 쓰면 안 된다** — 분리 커밋이 들어가는 순간 기준선이 산출물 자신으로 바뀌어 거짓 FAIL이 난다. 기준 커밋 고정 + md5 병기가 최종 방어선이다)(9-1의 `declare -f` 27/27 바이트 동일과 동형의 닫힌 증명). 역방향 재구성 대조로 본체 잔여 669줄의 손실 0도 확인 ② `1-orchestration-procedure.md`(671→474줄, 여유 226 확보) — LIFECYCLE-1~6 요약표는 잔류, LIFECYCLE-5·6 행의 "상세 하단" 자기참조를 신규 파일 경로로 교체 + 분리 인덱스 블록 2행 삽입 ③ 참조 갱신 10파일 — `0-lead-entrypoint.md`(로딩 체크리스트 +1행, **미등재 시 Team Lead가 신규 문서를 영영 로딩하지 않는다**) · `SUB-SSOT/0-sub-ssot-index.md` · `GUIDE.md`(트리·SUB-SSOT 표 + **거짓 진술 제거** — "1-orchestration … LIFECYCLE-5·6 상세 포함"은 분리 후 거짓) · `STRUCTURE.md` · `3-workflow.md`(5행 교체, 1282 불변) · `core/6-rules-index.md`(2행 교체, 485 불변) · `MIGRATION-6-1-to-6-2.md` · `zombie_check.sh`(330 불변) · `zombie_watch.sh`(220 불변) ④ **HR-5 규정 링크 3행 정정** — `3-workflow.md` L1114·L1115가 `../../../../docs/refactoring/`(저장소 밖) 을, `core/6-rules-index.md` L369가 번들 기준 미해석 경로를 가리키던 결함. 전수 감사 결과 ver6-2 SSOT 상대링크 **294건 중 BROKEN 18건**이며, 그중 대상이 실재하는 그룹 1(3건)만 본 Phase에서 닫는다. 그룹 2(`poc/worktree-gate-design`, 7건 — 배포 정책 결정 선행 필요)·그룹 3(`tests/index.md`, 8건 — 대상 자체가 저장소에 부재)은 **carry-over(LINK-2·LINK-3)** ⑤ `docs/refactoring/refactoring-registry.md` — 본표 stale 2행 정정. **배포 실증**: `install.sh --force` → `--upgrade` → `cmp` 로 신규 문서가 배포본에 실제로 포함됨을 확인(`docs/SSOT/` 전수 순회이므로 install.sh 개별 등재 불요 — 선언이 아니라 실행으로 확인). **회귀**: `zombie_watch.sh --self-test` 29/29. **근거**: `docs/phases/phase-9-2/tasks/task-9-2-1.md` · `task-9-2-3.md` · `docs/phases/phase-9-2/reports/phase-9-2-link-audit.md`.

**이전 변경 (2026-08-09 — ver6-2 PoC, Phase 8-6, 검증 매트릭스 + tester 적발 결함 수정, 버전 번호 유지 v8.2)**: tester(8-6-1~4)가 실측한 결함을 backend-dev가 수정(8-6-5, HR-6에 따라 tester는 수정하지 않음). **필수 순서 준수**(8-5 verifier 인계) — D8-2(T-2, 케이스[18]이 `_zw_check_one`을 스텁했다가 미복원해 이후 전 케이스가 no-op으로 무조건 통과하던 결함) 복원을 최우선 처리하고 반증(임시 실패 케이스 삽입→FAIL 확인→제거) 후에야 신규 케이스를 추가했다. 변경 파일: ① `scripts/zombiecheck/zombie_watch.sh`(498줄, 순증 0) — **T-2**(케이스[18] 종료 시 `declare -f`로 저장해둔 원함수를 `eval`로 복원) + **T-1**(Linux systemd `/tmp/systemd-private-*` 권한 거부 디렉터리에서 `find`가 exit 1을 반환해 `pipefail`+`set -e`로 self-test가 무설명 중단되던 결함 — `|| true`로 종료코드만 무시, 매치 카운트 값은 그대로 보존됨을 실측 확인) + **D8-5**(D-2의 팀명 대조가 부분일치라 `foo`가 `foobar` 루프를 arm으로 오인하던 결함 — 단어 경계 정규식 `(^|[[:space:]])team($|[[:space:]])`로 교체, 순증 0줄) ② `zombie_watch_selftest.sh`(404→498줄) — R-14 대조군 4종(S3~S6, R2-5가 `OK→SKIP` 단일 방향임을 marker+SUSPECT/ZOMBIE/SKIP 조합으로 보강, **S5가 핵심**: marker 존재+raw ZOMBIE 에도 rc=1 유지 확인 — ZOMBIE 를 절대 덮지 않음을 보증) + T-1 회귀 1종, `expected_cases` 24→29 ③ `zombie_check.sh`(329→330줄) — D8-7(L268 주석이 TTL 판정을 "#4+#5"로 기술하던 것을 8-5 문서 정정(F-2)에 맞춰 "#4"로 정합화) ④ `install.sh` — D-6(`chmod +x` 8파일 일괄 실행을 `2>/dev/null || true`로 무음 처리하던 것을, 파일별 개별 실행 + 실패 시 CONFLICTS 배열로 가시화하도록 교체 — 부재 파일 chmod가 exit=0으로 위장되던 결함 해소) ⑤ `PROJECT.md`·`VERSION.md` — T-4(G3 커버리지 케이스 수 18→29 정정, Phase 8-5 이력 항목 신설로 버전 로그 공백 해소). **이월(예산/검증 부족으로 8-7 이관, 명시적 보고 — 전부 밀어넣지 않음)**: D8-1(`--arm` 폴링 루프가 rc를 폐기해 자동 에스컬레이션 채널이 없음 — 설계 필요, `zombie_watch.sh` 여유 2줄로 불가) · T-3(억제 게이트 pane 해시가 형제 pane 종료/생성에도 반응 — 실 tmux 재검증 필요) · T-5(시그널#2 정규식 오탐 확정되었으나 tester 자신의 e2e 검증도 노이즈로 미확정이라, 단독 확정→ZOMBIE→respawn 고위험 경로에 미검증 정규식을 배포하지 않음) · D8-9(state 격리, env 오버라이드 부재) · D8-3(억제 게이트 발동 시 낡은 wake marker 1회 미소거 — 자가치유형, Low) · D8-8(케이스화 권고 — 코드 결함이 아니라 SOP 절차 누락이라 self-test 프레임워크로 표현 불가) · D8-4(verifier 확인대로 규약 위반 아님, 수정 불필요). **회귀**: `zombie_check.sh --self-test` 21/21 · `zombie_watch.sh --self-test` 29/29, 각 3회 반복 flaky 0. **근거**: `docs/phases/phase-8-6/tasks/task-8-6-5.md` · `docs/phases/phase-8-6/reports/report-tester.md` · `docs/phases/phase-8-6/reports/report-backend-dev.md`.

**이전 변경 (2026-08-08 — ver6-2 PoC, Phase 8-5, 신호원 정비 + status 스키마 확장, 버전 번호 유지 v8.2)**: 8-3 verifier 라운드 2가 지적한 신호원 결함(R2-5/R2-1/D-2/D-7)과 F-2(시그널 표-코드 불일치)를 해소. **핵심 조치 R2-5**: `inboxes/{agent}.json`이 수신 시에도 갱신되므로 LIFECYCLE-1의 "무응답→wake-up→재확인" 절차가 wake-up 발신 자체로 판정 근거를 리셋하는 결함(진단 행위가 신호를 리셋) — `zombie_watch.sh`에 wake_marker(직전 SUSPECT 확정 시각 기록) 도입, 재확인 시 inbox mtime이 그 시각 이후면 `OK`가 아니라 `SKIP(3)` 반환(자기발신 리셋 의심, 1회 소비). 변경 파일: ① `scripts/zombiecheck/zombie_watch.sh`(450→498줄) — R2-5 SKIP 반환 + R2-1(D-1 필터 제외 가시화, 대상 0명 시 SKIP+rc=3) + D-2(arm 3단 판정에 `--_loop-internal`+팀명 대조 추가, 부분일치 오판정 방지) + D-7(`--stop` 시 해당 팀 state 디렉토리 정리, 타 팀 보존) ② `zombie_watch_selftest.sh`(291→404줄) — 신규 6종(R2-5 2·R2-1 2·D-2/D-7 각 1) + `expected_cases` 정확 일치 검사(R2-2, P-2 계열 재발 방지) + 케이스[5] 무출력+rc=0 동시 단언(R2-4) ③ `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md`(667→671줄) — F-2 조합 규칙 문서를 코드 실측에 맞춰 정정(#2 단독 확정 복구, #3은 검증 보류이므로 AND 조건에서 제외), 시그널 #3 검출 방법 문구 정정(drain 큐 — `.[].read` 표현식은 실 포맷과 불일치), R2-5 한계 명시 ④ `3-workflow.md`(1274→1282줄) — status.md `agents:` 블록(LIFECYCLE-6 스케줄러 연계, name/spawned_at/last_report_at/next_check_at/respawn_count) 신설 ⑤ `.claude/skills/phase-init/SKILL.md` — status 템플릿에 `agents: []` 반영(`TEMPLATES/`에는 status 템플릿 자체가 없어 대상 부재 확인). **G2 PASS**(Critical 0·High 0, 14/14 기준 통과, 8-5 verifier). **근거**: `docs/phases/phase-8-5/phase-8-5-plan.md` · `docs/phases/phase-8-5/reports/report-verifier.md`.

**이전 변경 (2026-08-08 — ver6-2 PoC, Phase 8-3, LIFECYCLE-6 도입, 버전 번호 유지 v8.2)**: LIFECYCLE-1·5에 **체크 스케줄러 실행체**를 부여하는 LIFECYCLE-6 규칙 신설. Phase 8-1에서 확인된 결함 A(시간 기반 실행체 부재)로 spawn+30초 체크와 3분 정기 체크가 실제로는 한 번도 발동하지 않던 문제를 해소. **확정 결정값**: 3분 폴링 주기 / spawn+30초 1차 체크(3분 루프와 다른 경로) / arm 판정 3단(마커 존재+PID 생존+명령줄 대조 — 마커 존재만으로는 판정 근거 불인정) / emit edge-triggered(상태 변화 시 1줄, ZOMBIE는 상시, 기동 시 1회 무조건) / 억제 게이트(inbox mtime stale + pane 콘텐츠 해시 변화 → SUSPECT 취소, 해시는 워처 프로세스 **메모리**에만 보관, 상태 키는 `(agent_name, pane_id)` 쌍 — respawn으로 pane_id가 바뀌면 낡은 해시 자동 무효화). 변경 파일: ① `scripts/zombiecheck/zombie_watch.sh` 신규(체크 스케줄러 본체 403줄, `zombie_check.sh`를 **subprocess로만** 호출 — source 절대 금지) + `zombie_watch_selftest.sh` 신규(내장 단위 테스트 12케이스, 204줄) ② `zombie_check.sh` — P-1(8-4 verifier 지적) 가드를 `declare -p EXIT_OK`(이름 충돌 취약) → `declare -F zombie_check`(함수는 export 안 되고 exec를 못 넘어 이름 충돌·환경 오염 양쪽에 면역)로 교체, `zombie_check_selftest.sh`에 회귀-P1 케이스 추가(20→21케이스, MIN_CASES 18→19) ③ `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` — **§LIFECYCLE-6 SCHEDULER** 신설(인터페이스/수단 2층 기술, R-1 하네스 종속 완화, 582→666줄) ④ `3-workflow.md` — §AGENT-LIFECYCLE 규칙 표 LIFECYCLE-6 행 + §3.1 BUILDING 행에 진입 차단 조건 인라인 추가(1272→1274줄, KPI-07 상한 1287 이내) ⑤ `core/6-rules-index.md` — LIFECYCLE 카테고리 5→6개, **총 규칙 수 103 → 104**(하위 포함 137→138), **심각도 CRITICAL 43 → 44**(HR-7 매핑 LIFECYCLE-1~6로 확장, §6 CRITICAL Quick Reference 40 → 41) ⑥ `SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md`·`PROJECT.md`·`README.md`·`docs/guide/index.html`·`.claude/skills/abort/SKILL.md` — LIFECYCLE-1~6/규칙 수 표기 정합화. **커버리지 한계 명시(과장 금지)**: 좀비 유형 (c) 살아있으나 유휴 정지·(d) 턴 진행 중 교착은 본 스케줄러로 감지 불가 — (d)는 결함 E 총 대기 상한 30분이 별도 종결(자동 복구 아님). **근거**: `docs/phases/phase-8-3/phase-8-3-plan.md` · `docs/phases/pre/phase-8-progress-signal-decision.md`(rev.2) · `docs/analysis/260807-lifecycle-scheduler-gap-from-Dabeeo-Changes.md`.

**이전 변경 (2026-08-07 — ver6-2 라인 신설, Phase 8-1, 버전 번호 유지 v8.2)**: `ver6-1/`을 `ver6-2/`로 전량 복제(148 파일, 심볼릭 링크 0건)하고 자체지칭을 갱신했다. **라인 계보**: ver6-2(LIFECYCLE-6 실행체 도입) — ver6-1(2026-05-22 LIFECYCLE-5) 기반. **목적**: LIFECYCLE 규칙에 시간 기반 실행 계층을 부여하고 `zombie_check.sh` 플랫폼 결함을 해소하기 위한 신규 작업 라인 확보. **근거**: `docs/analysis/260807-lifecycle-scheduler-gap-from-Dabeeo-Changes.md`(Dabeeo-Changes 수신 보고서, 결함 A~F) + `docs/phases/pre/phase-8-pre-analysis.md`(결함 G 신규 발견). **상태(당시 기록)**: 본 항목은 8-1(라인 신설) 완료 시점 기록이며, LIFECYCLE-6 규칙 신설은 8-3에서 반영 완료(위 최근 변경 참조). `ver6-1/`은 본 시점부터 동결(수정 금지, `ver6-1/README.md` 상단 선언 참조). **규칙·버전 번호 변경 없음** (라인 신설만, 규칙 총수 103건 유지 — 당시 기록).

**이전 변경 (2026-05-22 — ver6-1 PoC, LIFECYCLE-5 도입, 버전 번호 유지 v8.2)**: 에이전트 **좀비 감지 + Respawn** 규칙 신설. tmux pane 환경에서 claude.exe가 spawn 직후 silent fail 하는 현상(관측 좀비율 60%, 5건 중 3건)에 대해 근본 원인 회피 대신 **감지 + 복구** 메커니즘을 채택. ① `core/6-rules-index.md` — LIFECYCLE 카테고리 4개 → 5개, **총 규칙 수 102 → 103**, **심각도 CRITICAL 42 → 43**(LIFECYCLE-5는 CRITICAL, HR-7 매핑을 LIFECYCLE-1~5로 확장, §6 CRITICAL Quick Reference 39 → 40) ② `3-workflow.md` §AGENT-LIFECYCLE — LIFECYCLE-5 행 + Team Lead 절차에 "좀비 의심 → LIFECYCLE-5 진입" 분기 추가 ③ `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` — **§LIFECYCLE-5 RESPAWN 상세 절차** 신설(감지 시그널 5종 + 조합 규칙 + Step 1~5 절차 + zombie_check.sh 호출 예시) ④ `SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md` — HR-7 표기 LIFECYCLE-1~5로 갱신 ⑤ `UPGRADE.md` §1.1 — `scripts/zombiecheck/`를 프레임워크 파일로 등록 ⑥ `scripts/zombiecheck/zombie_check.sh` 신규(단위 테스트 3종 `--self-test` 전건 PASS, 종료 코드 계약 `0`=정상 / `1`=좀비 확정 / `2`=추정 좀비) ⑦ `docs/guide/index.html`·`README.md` 규칙 수·HR-7 표기 정합화. **확정 결정값**: 1차 check 30초 / 정기 check 3분 / respawn 상한 5회 / suffix `_r1`~`_r5`. **근거**: `docs/analysis/260522-zombie-detection-proposal.md` · `docs/handoff/260522-ver6-1-fork-checkpoint.md` §5.

**이전 변경 (2026-07-08 — 이식성 잔재 정리, 버전 번호 유지 v8.2)**: 원본 프로젝트(Personal AI Brain v3) 잔재 정리 (LOCK-5 기록). ① `0-entrypoint.md` §빠른 시작 실행 환경 표 프로젝트 중립화 — 프로젝트→루트 PROJECT.md §1 참조, 현재 Phase→`docs/phases/*/status.md` 참조(ENTRY-1)로 교체 ② 번들 미포함 `_backup/GUIDES/` 참조를 SUB-SSOT 정본 참조로 교체 (0-entrypoint·3-workflow·GUIDE·1-project·ROLES/planner), 설명성 언급에는 "번들 미포함" 명시 (STRUCTURE·SUB-SSOT DEV/RESEARCH) ③ §8 트리를 실제 구조(docs/SSOT/)로 재작성, 존재하지 않는 `project/` 참조 제거 — 분류 정본은 UPGRADE.md §1로 일원화 ④ `refactoring/refactoring-registry.md` 원본 프로젝트 데이터 제거·빈 템플릿화 ⑤ `1-project.md` §1에 예시 표기, GUIDE 카탈로그·Telegram 예시 중립화 ⑥ ROLES(backend/frontend/tester/verifier)·PERSONA 8종·TEMPLATES/defect-report·SUB-SSOT 진입점 3종의 레거시 가이드 참조 정리, 원본 저장소 경로 잔재(`iterations/5th`·`ver6-0/`·`renewal/...`·`personal-ai-brain-v3`) 제거 (infra/git-subtree·mcp-design·refactoring-rules·STRUCTURE·GUIDE §13). **규칙·버전 번호 변경 없음** (문서 정리만).

**이전 변경 (2026-04-16 — Phase-I, v8.2 AutoCycle v1.1)**: 사용자 주도 마스터 플랜 진입 전 **Step 0 Pre-draft 게이트** 신설. PROMPT-QUALITY 규칙(HIGH) 등록 (완전성·명료성·실행 가능성·범위 적정성·트리아지 5항목 판정). `/plan` 스킬(.claude/skills/plan/SKILL.md, Plan Mode 유사, Team Lead 단독, 온디맨드 팀원 호출). master-plan YAML `initiator`·`prompt_quality`·`pre_draft_ref` 3필드 표준. `orchestration-procedure §Step-0 Branch` + 플로우차트 + 체크리스트. `master-final-report §7.3 initiator_hint` 필드. `docs/phases/pre/` 평탄 폴더 신설 (pre-analysis + pre-draft). **AI handoff는 14단계 유지 (Step 0 자동 스킵 + CHAIN-13 자동 로딩)**. 15단계 시뮬레이션 3 시나리오 커버리지 100%.

**이전 변경 (2026-04-16 — Phase-G+H, v8.1 AutoCycle v1.0)**: 14단계 개발 요청 자동 사이클(handoff) 지원. Phase-G(Foundation): TEMPLATES 5종 신설 + ITER-PRE/POST 규칙 2건 + TESTER KPI-driven. Phase-H(Hardening): G-Pre 수렴 게이트 + ITERATION-BUDGET 500K + CHAIN-12(Tech Debt 자동 로딩) + CHAIN-13(직전 3 Phase 기억 전달) + verifier 승인 훅 + 사용자 피드백 필드. 14단계 커버리지 14/14 (100%).

**이전 변경 (2026-04-15 — Phase-E, v8.0.1)**: ver6-0 개선 과제 — DEV SUB-SSOT 3분할 (CODER 전용 축소 + REVIEWER → VERIFIER + VALIDATOR → TESTER 이관) + RESEARCH SUB-SSOT 신설 (Lead/Architect/Analyst 3역할 분리). 역할별 SUB-SSOT 비대칭 해소, Research 역할 독립 주입 가능.

**이전 변경 (2026-04-13 — v8.0)**: 6세대 SUB-SSOT 모듈형 로딩 도입 — 역할별 SUB-SSOT(DEV/PLANNER/VERIFIER/TESTER/TEAM-LEAD) 분리, 공통 레이어(core/7-shared-definitions.md) 신설, FRESH-10~12 규칙 추가, 토큰 약 60% 절감.

---

## 릴리스 정보

| 항목 | 내용 |
|------|------|
| **버전** | 8.2-renewal-6th (6th iteration, AutoCycle v1.1) |
| **이전 버전** | 8.1-renewal-6th (AutoCycle v1.0) / 7.0-renewal-5th (5th) |
| **변경 사유** | AutoCycle 15단계 사용자 주도 Step 0 Pre-draft 게이트 신설 (v8.1→v8.2) + 역할별 모듈형 로딩 (v7→v8) |
| **핵심 원칙** | **5th 호환성 유지** — 5th 콘텐츠 전량 보존 + 6th SUB-SSOT 확장 레이어 + AutoCycle Pre-draft Gate |

---

## 5th → 6th 변경 요약

| 변경 항목 | 내용 |
|----------|------------|
| **+SUB-SSOT 아키텍처** | 역할별 독립 로딩 집합 (DEV/PLANNER/VERIFIER/TESTER/TEAM-LEAD) |
| **+공통 레이어** | `core/7-shared-definitions.md` — GATE, 역할, 승인, VUL 공통 포맷 |
| **+FRESH 규칙 3개** | FRESH-10(모듈형 로딩), FRESH-11(공통 레이어 필수), FRESH-12(독립 검증) |
| **+SUB-SSOT 인덱스** | `SUB-SSOT/0-sub-ssot-index.md` — 라우팅 테이블 |
| **+§7.5 라우팅** | 0-entrypoint.md에 SUB-SSOT 라우팅 섹션 추가 |
| **ssot_version** | `7.0-renewal-5th` → `8.0-renewal-6th` |

---

## Breaking Changes (5th → 6th)

| 변경 항목 | 변경 내용 |
|----------|----------|
| **ssot_version** | `7.0-renewal-5th` → `8.0-renewal-6th` — 기존 Phase status.md에서 버전 불일치 발생 |
| **SUB-SSOT 참조** | 각 역할 체크리스트에 SUB-SSOT 경로 참조 추가 — 기존 SSOT 사용자에게는 무영향 |
| **FRESH-10~12** | 신규 규칙 — SUB-SSOT 로딩 시에만 적용, 기존 전체 SSOT 로딩에는 무영향 |

---

## 6th 신규 파일 목록

| 경로 | 용도 |
|------|------|
| `core/7-shared-definitions.md` | 공통 포맷 정의 (GATE, 역할, 승인, VUL 체크리스트) |
| `SUB-SSOT/0-sub-ssot-index.md` | SUB-SSOT 라우팅 테이블·인덱스 |
| `SUB-SSOT/DEV/0-dev-entrypoint.md` | DEV 진입점 |
| `SUB-SSOT/DEV/1-fn-procedure.md` | fn 개발 절차 |
| `SUB-SSOT/DEV/2-ai-execution-rules.md` | AI 실행 규칙 |
| `SUB-SSOT/DEV/3-failure-modes.md` | 실패 모드 |
| `SUB-SSOT/PLANNER/0-planner-entrypoint.md` | Planner 진입점 |
| `SUB-SSOT/PLANNER/1-planning-procedure.md` | 계획 절차 |
| `SUB-SSOT/VERIFIER/0-verifier-entrypoint.md` | Verifier 진입점 |
| `SUB-SSOT/VERIFIER/1-verification-procedure.md` | 검증 절차 |
| `SUB-SSOT/TESTER/0-tester-entrypoint.md` | Tester 진입점 |
| `SUB-SSOT/TESTER/1-testing-procedure.md` | 테스트 절차 |
| `SUB-SSOT/TEAM-LEAD/0-lead-entrypoint.md` | Team Lead 진입점 |
| `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` | 오케스트레이션 절차 |
| `SUB-SSOT/RESEARCH/0-research-entrypoint.md` | Research 3역할 공용 진입점 (2026-04-15 Phase-E 신설) |
| `SUB-SSOT/RESEARCH/1-lead-procedure.md` | research-lead 절차 (2026-04-15 Phase-E 신설) |
| `SUB-SSOT/RESEARCH/2-architect-procedure.md` | research-architect 절차 (2026-04-15 Phase-E 신설) |
| `SUB-SSOT/RESEARCH/3-analyst-procedure.md` | research-analyst 절차 (2026-04-15 Phase-E 신설) |

---

## 5th 유지 파일 목록

| 경로 | 용도 |
|------|------|
| `0-entrypoint.md` | 진입점 (**수정**: §7.5 SUB-SSOT 라우팅, FRESH-10~12 추가) |
| `1-project.md` | 프로젝트·팀 구성·역할 |
| `2-architecture.md` | 인프라·BE/FE 구조·DB |
| `3-workflow.md` | 상태 머신(20개), 품질 게이트(G0~G4) |
| `4-event-protocol.md` | 이벤트 인프라 프로토콜 |
| `5-automation.md` | 자동화 파이프라인 |
| `PERSONA/` | 역할 페르소나 (9개 파일) |
| `ROLES/` | 역할 상세 규칙 (8개 파일) |
| `_backup/GUIDES/` | 작업지시 가이드 (2026-04-15 Phase-F에서 SUB-SSOT로 완전 이관, 6파일 backup 보존) |
| `QUALITY/` | 11명 Verification Council |
| `TEMPLATES/` | 문서 템플릿 |
| `core/6-rules-index.md` | 규칙 통합 인덱스 |
| `VERSION.md` | 본 문서 |

---

## 토큰 효율성 비교

| 시나리오 | 5th (현행) | 6th v8.0 (SUB-SSOT) | 6th v8.0.1 (Phase-E) | 절감율 (v8.0.1 기준) |
|----------|-----------|----------------------|----------------------|---------------------|
| fn 기본 개발 (CODER 전용) | ~61K | ~20K | **~18K** | **70%** |
| fn 풀 (CODER 전용) | ~61K | ~33K | **~27K** | **56%** |
| Planner | ~37K | ~13K | ~13K | 65% |
| Verifier (REVIEWER 통합) | ~44K | ~14K | **~17K** | 61% |
| Tester (VALIDATOR 통합) | ~38K | ~14K | **~16.5K** | 57% |
| Research Lead (신규 분리) | ~30K | — (GUIDES 공유) | **~14K** | **53%** |
| Research Architect (신규 분리) | ~30K | — (GUIDES 공유) | **~14K** | **53%** |
| Research Analyst (신규 분리) | ~30K | — (GUIDES 공유) | **~14K** | **53%** |
| Team Lead | ~35K | ~38K | ~38K | (허브) |

---

## 권장 사용

- **기본 진입점**: `0-entrypoint.md`
- **SUB-SSOT 사용**: [SUB-SSOT/0-sub-ssot-index.md](SUB-SSOT/0-sub-ssot-index.md) 라우팅 테이블 참조
- **SSOT 갱신 시**: 기존 0~5·ROLES·GUIDES·QUALITY 정답 유지 + SUB-SSOT 동기화

---

## 변경 이력

### v8.2 (AutoCycle Phase-I, 2026-04-16) — AutoCycle v1.1 (15단계 사용자 주도 확장)

- **신규**: `TEMPLATES/pre-draft-topics.md` — §1~§8 (원본·토픽·수집 자료·Pre-test·5항목 판정·마스터 플랜 진입 준비·Next Step·사용 지침)
- **신규**: `.claude/skills/plan/SKILL.md` — `/plan` 스킬 (Plan Mode 유사, Team Lead 단독, 온디맨드 팀원 호출)
- **신규**: `phase-chain-autocycle-v1.1.md` — v1.1 체인 마스터 (v1.0 `phase-chain-autocycle.md` 스냅샷 보존)
- **신규**: `docs/phases/pre/` 평탄 폴더 — `phase-{N}-pre-analysis.md` / `phase-{N}-pre-draft.md` 파일명 강제
- **변경**: `core/6-rules-index.md` v1.2 → v1.3 — §1.20 PROMPT-QUALITY (HIGH) 신설 (5항목: 완전성·명료성·실행 가능성·범위 적정성·트리아지), §1.18 ANALYSIS-1/2 경로 업데이트 (총 95 → 96건)
- **변경**: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` v1.2 → v1.3 — §Step-0 Branch 신설 (사용자/AI 분기 플로우차트 + 체크리스트)
- **변경**: `TEMPLATES/master-final-report.md` — §7.3 `initiator_hint` 필드 (다음 마스터 플랜 진입 경로 추천)
- **변경**: `STRUCTURE.md` v1.1 → v1.2 — §2.8 `pre/` 블록 확장, SSOT 버전 표기 갱신
- **변경**: `3-workflow.md` §8.7 / §11 / §12 — pre-analysis·pre-draft 경로 개정
- **신규 규칙**: PROMPT-QUALITY (HIGH)
- **15단계 시뮬레이션**: 사용자 주도 / AI handoff / Fast-path 3 시나리오 전부 커버리지 100% (verifier #1 PASS)
- **진입 분기**: 사용자 주도(`initiator: user`) = 15단계 / AI handoff(`initiator: ai-handoff`) = 14단계 (Step 0 자동 스킵 + CHAIN-13 대체)
- **ssot_version**: `8.1` → `8.2` (minor upgrade, AutoCycle v1.0 → v1.1)
- **Phase 산출물**: `ver6-0/docs/phases/phase-I/` (status · plan · todo-list · 5 task specs) + `phase-I-master-plan.md` + `phase-I-final-summary-report.md` + `phases/pre/phase-I-pre-analysis.md`

### v8.1 (AutoCycle Phase-G+H, 2026-04-16) — 14단계 자동 handoff v1.0

- **신규**: `TEMPLATES/development-plan-template.md` — KPI 수치화·사용자/개발자 관점 2분법 (Step 3)
- **신규**: `TEMPLATES/prompt-alignment-check.md` — 원본 프롬프트 vs 계획/구현 diff 분석 (Step 5)
- **신규**: `TEMPLATES/phase-achievement-report.md` — KPI 달성 대조·수정계획 (Step 8)
- **신규**: `TEMPLATES/tech-debt-report.md` — 수정 불가 항목 문서화·carryover_to (Step 12)
- **신규**: `TEMPLATES/master-final-report.md` — 6섹션 최종 보고서 + Next Prompt + verifier 승인 (Step 13~14)
- **변경**: `SUB-SSOT/TEAM-LEAD/1-orchestration-procedure.md` v1.0 → v1.2 — §ITER-PRE(3회 반복 + G-Pre 수렴 게이트), §ITER-POST(2회 재계획), CHAIN-12(Tech Debt 자동 로딩), CHAIN-13(직전 3 Phase 기억 전달), G4 verifier 승인 훅
- **변경**: `SUB-SSOT/TESTER/1-testing-procedure.md` — §KPI-driven Test Plan 추가 (Step 10)
- **변경**: `core/7-shared-definitions.md` v1.0 → v1.1 — §8 ITERATION-BUDGET (사이클 토큰 상한 500K)
- **변경**: `core/6-rules-index.md` v1.1 → v1.2 — ITER-PRE, ITER-POST, ITERATION-BUDGET, CHAIN-12, CHAIN-13 (신규 5건, 총 95개 규칙)
- **신규 규칙**: ITER-PRE(CRITICAL), ITER-POST(CRITICAL), ITERATION-BUDGET(CRITICAL), CHAIN-12(HIGH), CHAIN-13(HIGH)
- **14단계 커버리지**: 14/14 (100%) — 가상 시뮬레이션 dry-run PASS
- **ssot_version**: `8.0.1` → `8.1` (minor upgrade, AutoCycle runtime 동작 영향)

### v8.0.1 (Phase-E, 2026-04-15) — ver6-0 개선 과제

- **신규**: `SUB-SSOT/RESEARCH/` 디렉토리 4파일 (`0-research-entrypoint.md`, `1-lead-procedure.md`, `2-architect-procedure.md`, `3-analyst-procedure.md`) — 3역할(research-lead/architect/analyst) 독립 주입 가능
- **변경**: `SUB-SSOT/DEV/` v1.0 → v1.1 — CODER 전용으로 축소. REVIEWER 페르소나·plan-first review·컨텍스트 분리는 VERIFIER로, VALIDATOR 페르소나·VAL 포맷·FAIL_COUNTER는 TESTER로 이관
- **변경**: `SUB-SSOT/VERIFIER/` v1.0 → v1.1 — REVIEWER 페르소나 Scope/Rules/Forbidden 확장, plan-first review·컨텍스트 분리 신규 섹션, REVIEWER 실패 모드 대응(PROBLEM-BE-04, DB-03, PROC-06) 통합
- **변경**: `SUB-SSOT/TESTER/` v1.0 → v1.1 — VALIDATOR 페르소나 확장, 증거 기반 감사·VAL 포맷·FAIL_COUNTER 신규 섹션, VALIDATOR 실패 모드 대응(PROBLEM-PROC-05, CTX-07) 통합
- **변경**: `SUB-SSOT/DEV/3-failure-modes.md` — REVIEWER/VALIDATOR 소관 Fix 4건을 참조 축약 (MULTI 원칙: DEV는 CODER 인식용 유지 + VERIFIER/TESTER에 완화 관점 신규)
- **변경**: `0-entrypoint.md §역할별 스폰 주입 표` + `§7.5 라우팅` — DEV CODER 전용·VERIFIER REVIEWER 통합·TESTER VALIDATOR 통합·Research 3역할 분리 반영
- **변경**: `SUB-SSOT/0-sub-ssot-index.md` v1.0 → v1.1 — DEV/VERIFIER/TESTER 대상 갱신, RESEARCH 신규 행, 토큰 효율 표 갱신
- **변경**: `ROLES/README.md` — verifier/tester에 REVIEWER/VALIDATOR 책임 명시, research-* 역할에 SUB-SSOT 경로 추가
- **출처**: `docs/analysis/260414-ver6-0-audit-followup.md §6.5 #17, #19` 사용자 결정
- **Phase 산출물**: `ver6-0/docs/phases/phase-E/` — status, plan, todo-list, 8 checkpoints, 7 task specs, scratchpad
- **ssot_version**: `8.0-renewal-6th` 유지 (sub-version 8.0.1)

### v8.0-renewal-6th (2026-04-13)
- **신규**: SUB-SSOT 모듈형 로딩 아키텍처 (5개 역할 SUB-SSOT)
- **신규**: `core/7-shared-definitions.md` (공통 포맷 레이어)
- **신규**: `SUB-SSOT/0-sub-ssot-index.md` (라우팅 인덱스)
- **신규**: FRESH-10, FRESH-11, FRESH-12 규칙
- **변경**: `0-entrypoint.md` (§7.5 SUB-SSOT 라우팅, 역할별 SUB-SSOT 참조)
- **변경**: ssot_version `7.0-renewal-5th` → `8.0-renewal-6th`
- **유지**: 5th 전체 콘텐츠 보존 (하위 호환)

### v7.0-renewal-5th (2026-02-28)
- **신규**: 상태 머신 6개 상태 추가 (RESEARCH, RESEARCH_REVIEW, BRANCH_CREATION, AUTO_FIX, AB_COMPARISON, DESIGN_REVIEW)
- **신규**: G0 Research Review 게이트
- **신규**: Research Team 3역할
- **신규**: `4-event-protocol.md`, `5-automation.md`
- **신규**: `QUALITY/10-persona-qc.md` (11명 Verification Council)
- **신규**: `TEMPLATES/`
- **변경**: status.md 스키마에 `5th_mode` 필드 추가
- **변경**: ssot_version `6.0-renewal-4th` → `7.0-renewal-5th`
- **유지**: 4th 전체 콘텐츠 보존

### v6.0-renewal-4th (2026-02-17)
- **신규**: iterations/4th 폴더, 0-entrypoint·1-project·2-architecture·3-workflow
- **신규**: ROLES/planner.md, _backup/GUIDES/planner-work-guide.md
- **신규**: 3-workflow.md §8 Phase Chain
- **신규**: PERSONA/ 5종
- **변경**: 팀 라이프사이클 §3.9 루프 명시
- **변경**: Charter 링크 PERSONA/*.md 변경
- **제거**: 모든 claude/ 참조

---

**문서 관리**: 버전 8.2-renewal-6th (AutoCycle v1.1), 단독 사용(6th 세트만으로 SSOT 완결, 5th 전량 보존+SUB-SSOT 확장+AutoCycle Pre-draft Gate)
