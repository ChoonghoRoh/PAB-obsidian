---
task: "2-5-3"
title: "CouchDB 볼륨 덤프 백업 + 세대 보존"
domain: "[INFRA]"
gap: "G-3 (🟡)"
assignee: backend-dev
status: pending
depends_on: []
---

# Task 2-5-3: CouchDB 볼륨 덤프 백업 자동화

## 목표
`pab_couchdb_data` 볼륨(3.6MB)의 덤프를 자동 생성하고 세대 보존한다.

## G-2와의 구분
- G-2(T-2) = **vault 내용**(md 파일) 스냅샷
- G-3(본 Task) = **동기화 메타데이터**(청크·리비전). 볼륨 손실 시 각 기기에서 재구축은 가능하나 동기화 이력 소실

## 작업
- 볼륨 덤프 스크립트 작성 (컨테이너 정지 없이 안전한 방식 선택)
- **세대 보존 — 일 1회 × 7세대** (DP-2-5-3), 초과분 자동 삭제
- 서버 crontab 등록
- 덤프 저장 위치 확정 (Tailnet 내부, 공개 노출 0)

## 산출물
- 덤프 백업 스크립트 + 보존 로직 + crontab 엔트리

## 검증 (G2_infra)
- 덤프 산출물 생성 확인
- **복원 리허설** — 덤프에서 실제 복구 가능함을 확인 (생성만으로 PASS 처리 금지)
- 8일째 실행 시 가장 오래된 세대가 정리되는지 확인

## 비고
- 검증되지 않은 백업은 백업이 아니다 — 복원 리허설이 본 Task의 핵심 산출물

---

## ⚠️ 범위 확정 (2026-08-26) — 논리 백업은 이미 존재한다

착수 후 **PAB-Observer `#32`가 CouchDB 논리 백업을 일 1회 × 7세대로 이미 수행 중**임이 확인됐다(사전 통지 규율 덕에 착수 직후 파악).

| | Observer `#32` (기존) | **T-3 (본 Task)** |
|---|---|---|
| 방식 | **논리** — `_all_docs?include_docs=true \| gzip` | **물리** — 볼륨 `pab_couchdb_data` 전체 tar |
| cron | `17 3 * * *` (03:17) | **`17 4 * * *` (04:17)** — I/O 분리 |
| 산출 | `/home/oceanui/backups/` | **별도 디렉토리** (그쪽 세대 정리 `ls -1d 20*-*`가 지우지 않게) |
| 대상 | `pab-llmdata` + `_users` (+ `_local` 추가 합의) | 볼륨 전체 |
| 관측 | UK `#32` (부분 실패도 down 보고) | 미정 |

### T-3의 고유 가치 (실측으로 좁힌 최종 범위)

> **리비전 트리 + 뷰 인덱스 + 볼륨 일관 복구 신뢰성**
>
> 특히 마지막 — *"문서를 재조립하는 것"과 "볼륨을 통째로 되돌리는 것"은 복구 신뢰성이 다르다.*

**논리 백업이 이미 커버하는 것** (T-3의 근거가 **아님** — 실측 확인):
- ✅ 문서 본문 3005건
- ✅ **`_design/zz_bridge_readonly`** — `_all_docs`에 design doc이 포함된다. `validate_doc_update` 함수 원문까지 보존됨
- ✅ `_users` 계정
- ✅ **`_local` 체크포인트 13건** — `_local_docs?include_docs=true`로 조회 가능(`last_seq`·`session_id`·`history` 포함). `#32`가 안 받고 있을 뿐 못 받는 게 아니다 → **Observer가 추가하기로 합의**

> ⚠️ **이 표를 지우지 말 것.** 근거 없이 보면 T-3은 중복으로 보인다. 실제로 조율 과정에서 양측이 각각 한 번씩 "이건 논리로 못 받는다"고 넘겨짚었다가 실측으로 정정했다.

### 정합성 방식: ⒜ 컨테이너 무정지 (확정)

| 안 | 판정 |
|---|---|
| ⒜ 무정지 + append-only + 무결성 검증 | ✅ **채택** |
| ⒝ 컨테이너 정지 | ❌ 4MB 볼륨에 `#25`·`#31`·`#26` 3종 동시 알림 + Observer pause 조율 비용이 과하다 |
| ⒞ FS 스냅샷 | ❌ 루트는 ext4 위 LVM — 루트 LV 전체 스냅샷이라 과함 |

- `_ensure_full_commit` 실측: CouchDB **3.5.2**에서 `{"ok":true}` 응답하나 **쓰기가 항상 동기 커밋이라 사실상 no-op**
- 볼륨 실측 **4.0MB** (`shards` 3.9M + `_dbs.couch` 36K + `_nodes.couch` 12K) → 7세대 ~28MB, 디스크 여유 550G
- tar는 "읽는 중 파일이 변했다"로 rc=1을 낼 수 있다(append-only라 정상) ⇒ **종료코드가 아니라 아카이브 무결성으로 판정**

### 복원 리허설 — 양 프로젝트 공용 절차로 정리할 것

⚠️ **PAB-Observer `#32`는 신설 이후 복원 검증이 0건**이다(자기 진단). 백업 실패 경로만 검증했고 복구 경로는 한 번도 시험하지 않았다. **우리 리허설 절차를 공유하기로 합의**했으므로 재사용 가능한 형태로 정리한다.

검증 항목:
- 격리: **임시 컨테이너 + 임시 볼륨**. ⚠️ 가동 중 `pab-couchdb` 미접촉 (손상은 전 기기로 전파된다)
- `doc_count` 일치 (기준 3005)
- **`_design/zz_bridge_readonly` 존재 + `validate_doc_update` 함수 원문 보유**
- `_local` 체크포인트 복원 여부 (13건)
- 리허설 후 임시 자원 정리

> *"백업했다"는 사실과 "복구된다"는 사실은 다르다.* 2026-08-21에 3자 일치가 생존을 뜻하지 않았던 것과 같은 구조다.

### 외부 통지 상태

- **사전 통지 발신 완료** (2026-08-26) — 물리 방식·04:17·경로 분리·7세대 명시
- Observer **전건 수용 가능** 회신, 정식 판정은 **OB2-C**에서
- ⚠️ **cron 등록은 OB2-C 판정 후** — `docs/interop/pab-observer/` §3.3 사전 통지 규율(2026-08-26 합의)

### Team Lead 독립 검증 — 아카이브 무결성 (2026-08-26, HR-6)

backend-dev 산출물을 Team Lead가 별도로 열어 확인했다(읽기 전용).

대상: `pab_couchdb_data-20260826-044750.tar.gz` (1,488,261B)

```
총 15 엔트리
./shards/00000000-7fffffff/pab-llmdata.1781570471.couch    ← q=2 shard 1
./shards/80000000-ffffffff/pab-llmdata.1781570471.couch    ← q=2 shard 2
./shards/*/                _users · _replicator · _global_changes
./_dbs.couch  ./_nodes.couch  ./.delete/
```

| 검증 | 결과 |
|---|---|
| 아카이브 읽힘 (`tar tzf`) | ✅ |
| `_dbs.couch` · `_nodes.couch` · `shards/` | ✅ 전부 존재 |
| `pab-llmdata` **양 shard 모두** 포함 | ✅ (한쪽만 있으면 복구 불가) |
| `_users` DB 포함 | ✅ — 물리 덤프는 계정도 함께 담는다 |
| CouchDB 무정지 | ✅ `RestartCount=0`, `StartedAt` 불변 |
| 세대 2건 생성·회전 동작 | ✅ 각 1.49MB → 7세대 ≈ 10.5MB |

⚠️ **여기까지는 "백업이 만들어진다"의 증명이다. "복구된다"는 아직 미증명** — `--verify` 복원 리허설이 남아 있다.

### 복원 리허설 — **PASS** (2026-08-26, backend-dev 실행 / Team Lead 검토)

```
pab_couchdb_data-20260826-044750.tar.gz → 격리 컨테이너 (127.0.0.1:15984)
복원본 pab-llmdata doc_count=3064 / 가동본=3064
복원본 DB 목록: ["_global_changes","_replicator","_users","pab-llmdata"]
복원본 _design/zz_bridge_readonly: validate-doc-update 194자
복원본 _local 체크포인트=13 / 가동본=13
✅ PASS
```

| 요구 항목 | 결과 |
|---|---|
| ⑴ `doc_count` 일치 | **3064 = 3064** ✅ (⚠️ 대조 기준은 **가동본 3064**. 3005는 `#32` 덤프 시점(03:17) 값이라 혼동 주의) |
| ⑵ `_design/zz_bridge_readonly` + `validate_doc_update` | **본문 194자 보유** ✅ — *존재*가 아니라 *함수 본문 길이*로 확인해 **껍데기 복원을 배제** |
| ⑶ `_local` 체크포인트 | **13 = 13** ✅ (Observer 논리덤프는 0건) |
| ⑷ 임시자원 정리 | 컨테이너 0 / 볼륨 0 잔재, 가동본 `Up 45h (healthy)` 불변 ✅ |

- **⑵⑶은 로그가 아니라 중단 게이트**(`verify-nodesign`/`verify-nolocal`) — 통과 여부를 로그로만 남기면 다음에 조용히 깨져도 모른다
- 격리: 이름·볼륨·포트 전부 분리, **`127.0.0.1` 바인딩만**(DP-4). 임시 관리자 비번은 매회 난수·미기록
- 대조 방향은 **"복원본 ≤ 가동본"** — 가동본은 덤프 이후에도 늘어나므로 복원본이 적은 것은 정상이고 **많으면 이상**

### ⒟ 무정지 채택 — 최종 근거 (실측으로 갱신)

| 안 | 판정 | 근거 |
|---|---|---|
| ⒜ `_ensure_full_commit` 선행 | 불채택 | **CouchDB 3.5.2는 `delayed_commits` 제거** — 모든 쓰기가 이미 durable. 호출해도 `{"ok":true}` 껍데기 |
| ⒝ 컨테이너 정지 | 불채택 | 실질 위험은 알림이 아니라 **LiveSync 복제 순단**. append-only로 이미 성립하는 보장에 치를 값이 아님 |
| ⒞ LVM 스냅샷 | **불가능** | ⚠️ `ubuntu-vg` **VG 여유 `0`** — 스냅샷 LV를 만들 공간 자체가 없다 (당초 "과함"으로 적었으나 실은 불가) |
| **⒟ 무정지 tar + 다층 검증** | **채택** | **compaction은 별도 `.compact`에 쓰고 원자적 rename** → 원본 `.couch`는 늘 유효. compaction 중 복사가 오히려 안전한 쪽 |

### 서버 cron — **2줄** (등록 보류 중)

```
17 4 * * *  ... pab_couchdb_volume_backup.sh                  # PAB-COUCHDB-VOLBACKUP
42 4 * * 0  ... pab_couchdb_volume_backup.sh --verify-restore  # PAB-COUCHDB-VOLVERIFY
```

- **04:17** 백업 — Observer `#32`(03:17)와 1시간 분리
- **일요일 04:42 복원 리허설 상설화** — *"한 번 성공한 복원은 다음 주의 보증이 아니다"*
- ⚠️ **2줄째는 `#31` 감시 대상에 걸린다** — 리허설마다 `pab-couchdb-restoretest-*` 컨테이너·볼륨이 생겼다 사라진다. **보충 통지 발신 완료**(2026-08-26). 역으로 *"나타나야 할 때 안 나타나는 것"*을 신호로 쓸 수도 있다
- **등록은 Observer OB2-C 정식 판정 후.** 합의 당일에 우리가 앞질러 등록하면 §3.3 규율이 죽는다

### T-1 헬스체크 연계 (승인, 진행 중)

상태파일 `state/couchdb-volbackup.env`(644)를 T-1이 읽는다.

| 판정 | 임계 |
|---|---|
| 백업 정지 | `LAST_OK_TS` 경과 > **36h** (일 1회 주기 + 12h 여유) |
| 세대 미달 | `GENERATIONS < 7` — **정보만**, 초기 7일은 정상적으로 미달 |
| 용량 추이 | `TOTAL_SIZE` |
| ⭐ **리허설 만료** | `LAST_VERIFY_TS` 경과 > **10일** — 주 1회 리허설이 조용히 멈추면 *"복구된다"는 보증이 만료된 채 백업만 도는* 가장 위험한 조합이 된다 |

#### 리허설 부재 감시 — 2계층 (Observer 합의, 2026-08-26)

*"안 나타나면 신호"* 를 `#31`에 넣자는 최초 발상은 **반려**됐다. `#31`은 매분 폴링이라 **주 1회 수십 초만 존재하는 컨테이너를 목록에 넣으면 나머지 시간 전부 down**이 된다. 방향은 맞았고 도구가 틀렸다.

| 계층 | 역할 |
|---|---|
| **UK Push** (`UK_COUCHDB_VERIFY_PUSH_URL`, Observer 발급 예정) | **주 감시** — `--verify-restore` 종료 시 1회 Push(성공=`up`/실패=`down`+사유). 모니터 interval **주 1회 + 여유**(`648000s`) → 리허설이 멈추면 **heartbeat 부재로 UK가 스스로 down 판정** |
| **T-1 로컬 `LAST_VERIFY_TS` > 10일** | **폴백** — URL 미발급 구간 + UK 자체 침묵 대비 |

- 기존 `PAB_TELEGRAM_FALLBACK=auto`와 **같은 구조** — URL 등록 시 로컬 알림이 자동으로 물러난다. 이중 발송 없음
- **URL 미설정 시 Push 생략 후 정상 종료** (T-1에서 검증된 방식) → 발급 전에도 배포 지장 없음
- `#32`가 이미 같은 패턴이다 (interval `93600s` = 일 1회 + 2h 여유)

> ✅ **`#31` 조치 불요 확인** — `container-health-collect.sh`는 전체 스캔이 아니라 화이트리스트(`CONTAINER_WATCH`)라 `pab-couchdb-restoretest-*`는 `docker inspect` 대상 자체가 아니다. 오탐 0.

> **자체 결함 1건 수정 이력**: 초기 판본은 `--verify-restore`가 상태파일의 백업 메타(`LAST_FILE`/`LAST_SIZE`/`TOTAL_SIZE`)를 덮어써 지웠다. 상태파일은 T-1이 읽는 단일 창구라, **리허설 한 번이 "마지막 백업이 언제였는지"를 지우면 감시자가 백업 공백을 못 본다.** `carry()`로 상호 보존하도록 수정. — 감시 대상이 감시자를 눈멀게 하는 구조였다.
