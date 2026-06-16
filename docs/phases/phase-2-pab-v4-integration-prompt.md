---
title: "PAB-v4 ↔ wiki vault 단방향 읽기 연동 설계 + 전달 프롬프트 (방법 A: livesync-bridge)"
phase: "2 (외부 연계 사전 설계)"
created: 2026-06-16
status: DRAFT   # 다음 세션 외부 연계에서 실행
related: docs/phases/phase-2-master-plan.md
---

# PAB-v4 외부 연계 설계 — 방법 A (livesync-bridge 파일 미러)

다음 세션 "외부 연계" 작업의 사전 설계 + PAB-v4 전달 프롬프트. PoC(Phase 2-1 CouchDB LiveSync 동기화) 완료 후 이어지는 단계.

## 조사 결과 (2026-06-16, 3800X 서버)

PAB-v4 = `personal-ai-brain-v4` (컨테이너 `pab-backend-ver4`, :8001)
- FastAPI, 286 REST API, 헬스 정상. PostgreSQL `knowledge_v4` + Qdrant `brain_documents_v4` + Ollama(로컬) 기반 RAG. CouchDB 미사용.
- `obsidian_intake_service`: `.md` frontmatter 11필드 + 본문 파싱, 수집 화이트리스트 `10_Notes/15_Sources/20_Lessons`. `scan_vault()`/`filter_collected()`/`ingest_note()`/`parse_note()` 보유 — 단 sync 파이프라인과 미연결.
- `document_sync_service.sync_document_paths()`: 현재 `PROJECT_ROOT/brain`·`PROJECT_ROOT/docs`만 스캔(하드코딩). `get_file_hash`(MD5)+`find_document_by_hash`로 증분·경로이동 감지는 이미 구현.
- 현재 `PAB_PROJECT_ROOT=.` → 자기 docs/만 인덱싱 중. **wiki vault 미연동.**
- vault 데이터 현 위치: CouchDB `pab-llmdata`(청크 바이너리, 직접 읽기 부적합) / GitHub 백업(폴더형 .md) / 맥북·레노버 로컬.

## 아키텍처 (방법 A)

```
[맥북/레노버 Obsidian]
      │ LiveSync
      ▼
[CouchDB pab-llmdata] ──livesync-bridge(단방향 CouchDB→파일)──▶ [/vault-mirror/*.md]
   (PAB-Obsidian 소유)                                              │ read-only
                                                                    ▼
                                                       [PAB-v4 backend] ──▶ Postgres + Qdrant
                                                       (scan→ingest→embed)
```

## 인터페이스 계약 (양 프로젝트 경계 — 동일하게 준수)

| 항목 | 값 |
|------|-----|
| 미러 폴더 | 호스트 `/home/oceanui/pab-vault-mirror/`, PAB-v4 컨테이너 `/vault-mirror` (read-only) |
| 포맷 | 평문 `.md`, frontmatter 11필드 + 본문, vault 폴더구조 보존 |
| 수집 대상 | `10_Notes/`, `15_Sources/`, `20_Lessons/` |
| 제외 | `.obsidian/`, `99_Inbox/`, `_attachments/`, per-machine 파일 |
| 방향 | **단방향**: CouchDB → 파일 → PAB-v4 (PAB-v4 쓰기 금지, R-1) |
| 갱신 신호 | 파일 mtime 변동(bridge 실시간 기록) |
| 삭제 | 미러에서 사라진 노트 = PAB-v4 인덱스에서도 제거 |

## PAB-Obsidian 측 작업 (이쪽 구현)

1. `pab-vault-cloud/docker-compose.yml`에 **livesync-bridge**(`vrtmrz/livesync-bridge`) 컨테이너 추가.
2. bridge config: couchdb peer(`pab-llmdata`) → storage peer(`/home/oceanui/pab-vault-mirror`), **CouchDB→파일 단방향만** 활성(역방향 비활성 = R-1).
3. CouchDB **읽기 전용 계정** 생성(bridge 전용, admin 노출 최소화).
4. 미러 출력 필터: `.obsidian/`·per-machine·`99_Inbox` 제외.
5. 미러 폴더를 PAB-v4가 read-only 마운트할 공유 경로로 배치.
6. E2E 검증: 맥북 노트 편집 → bridge 미러 `.md` 갱신 → PAB-v4 재인덱싱.

---

## PAB-v4 전달 프롬프트 (복사용)

```markdown
# 작업 요청: PAB-Obsidian wiki vault 단방향 읽기 연동 (livesync-bridge 미러)

## 배경
별도 프로젝트 PAB-Obsidian의 wiki vault(PAB-LLMDATA)를, 서버(3800X)에서 livesync-bridge가
CouchDB → 파일시스템으로 실시간 복제한 미러 폴더로 제공한다. PAB-v4는 이 미러를
**단방향 읽기 전용**으로 스캔하여 자체 지식베이스(Postgres knowledge_v4 + Qdrant
brain_documents_v4)에 ingest/임베딩한다. vault에 쓰기는 절대 하지 않는다(원본 무결성, R-1).

## 인터페이스 계약 (PAB-Obsidian 측이 보장)
- 미러 폴더(컨테이너 마운트 예정): `/vault-mirror` (호스트 `/home/oceanui/pab-vault-mirror`, read-only)
- 포맷: 평문 .md, frontmatter 11필드(title/description/created/updated/type/index/topics/
  tags/keywords/sources/aliases) + 본문, vault 폴더구조 보존
- 수집 대상 폴더: 10_Notes/, 15_Sources/, 20_Lessons/  (그 외 .obsidian/·99_Inbox/·_attachments/ 제외)
- 갱신 신호: 파일 mtime 변동(bridge가 실시간 기록). 삭제 시 파일이 미러에서 사라짐.

## 현재 코드 상태 (조사 결과)
- backend/services/search/document_sync_service.py
  - sync_document_paths(): 현재 PROJECT_ROOT/"brain", PROJECT_ROOT/"docs" 만 스캔(하드코딩)
  - get_file_hash()(MD5) + find_document_by_hash(): 증분 동기화·경로이동 감지 이미 구현됨
  - sync_single_document(): brain/docs 에서만 탐색
- backend/services/obsidian/obsidian_intake_service.py
  - scan_vault(), filter_collected()(10_Notes/15_Sources/20_Lessons 화이트리스트),
    ingest_note(), parse_note()(frontmatter 11필드 정규화) 보유 — 단 sync 파이프라인과 미연결
- backend/config.py: PROJECT_ROOT 정의
- 컨테이너(pab-backend-ver4)는 현재 /app 만 마운트(vault 미러 미마운트)

## 요구 작업 (단방향 읽기 동기화)
1. [설정] 미러 폴더 경로를 환경변수로 분리
   - config.py 에 VAULT_MIRROR_ROOT(기본 /vault-mirror) 추가, .env / .env.server.example 반영
   - docker-compose.server.yml 의 pab-backend-ver4 서비스에
     `- /home/oceanui/pab-vault-mirror:/vault-mirror:ro` (read-only) 볼륨 추가

2. [스캔 확장] vault 미러를 동기화 대상에 포함
   - sync_document_paths()가 brain/docs 외에 VAULT_MIRROR_ROOT 하위
     10_Notes/15_Sources/20_Lessons 도 스캔하도록 확장
   - obsidian_intake.scan_vault()+filter_collected()를 sync 파이프라인에 통합
     (frontmatter 11필드 파싱은 parse_note()/ingest_note() 재사용)

3. [증분·이동] 기존 해시 매칭 재사용
   - get_file_hash()/find_document_by_hash()로 변경분만 재임베딩, 경로 이동은 갱신 처리
     (vault 미러는 read-only이므로 PAB-v4가 쓰지 않음 — 해시는 읽기 전용 계산)

4. [삭제 전파] 미러에서 사라진 노트 정리
   - 스캔 시 DB에 있으나 미러에 없는 vault 출처 문서를 Postgres + Qdrant에서 제거
   - 단, brain/docs 출처 문서는 영향 없도록 vault 출처를 source 필드 등으로 구분

5. [트리거] 미러 변경 → 재인덱싱 자동화 (택1, 권장 a)
   a. watchdog로 /vault-mirror 파일 watch → 디바운스 후 sync_document_paths() 호출
   b. cron/주기 작업으로 POST /api/documents/sync 주기 호출
   - 기존 POST /api/documents/sync, POST /api/automation/trigger-ingest 재사용 가능

6. [읽기 전용 가드] vault 미러에 쓰기 금지
   - 마운트를 :ro 로 강제, 코드 경로에서도 미러 경로 쓰기 시도 차단/검증

## 제약 (절대 준수)
- 단방향: PAB-v4 → vault 미러 쓰기 금지 (원본은 LiveSync CouchDB가 유일 권위, R-1)
- 추론은 로컬(Ollama) 사용 유지, 외부 LLM API로 vault 내용 전송 금지(데이터 주권)
- 기존 brain/docs 인덱싱 동작 회귀 없도록 보장(테스트)

## 검증 기준 (DoD)
- /vault-mirror/10_Notes 의 .md N개가 GET /api/documents 에 출처 구분되어 노출
- 노트 1건 mtime 변경 → 변경분만 재임베딩(해시 불변 파일은 skip 로그)
- 노트 1건 미러에서 삭제 → Postgres + Qdrant(brain_documents_v4)에서도 제거 확인
- vault 미러 쓰기 시도 → 차단(:ro). brain/docs 기존 인덱싱 회귀 없음
- 외부 API 호출 0 (로컬 Ollama 임베딩만)

## 산출물
- config/env/compose 변경분, sync 파이프라인 확장 코드, 삭제 전파 로직,
  watch/cron 트리거, 회귀·신규 테스트, 연동 결과 요약 보고
```

## 대안 (참고)
- 방법 B(git clone + cron pull): 가장 단순, 준실시간. PoC용.
- 방법 C(PAB-v4 REST API push): Conductor가 `/api/documents/sync`·`/api/automation/trigger-ingest` 호출. 이벤트 기반.

## 정리 메모
- orphan 컨테이너 `hopeful_kirch`(익명 CouchDB) 다음에 `docker rm -f` 정리 권장.
