# Database Migrations

이 프로젝트는 Alembic을 사용하지 않으며, SQL 마이그레이션 스크립트를 수동 실행합니다.

## 실행 방법

### Docker 환경 (권장)

```bash
# 컨테이너 내부에서 실행
docker exec -i pab-postgres-ver3 psql -U brain -d knowledge < scripts/migrations/001_add_gin_indexes.sql
```

### 로컬 환경

```bash
# 호스트에서 직접 실행 (포트 5433)
psql -h localhost -p 5433 -U brain -d knowledge -f scripts/migrations/001_add_gin_indexes.sql
```

## 마이그레이션 목록 (SQL, 순차 실행)

| 번호 | 파일명 | 설명 | Phase |
|------|--------|------|-------|
| 001 | `001_add_gin_indexes.sql` | GIN 인덱스 4개 추가 (knowledge_chunks, conversations, memories) | 12-2-3 |
| 002 | `002_create_page_access_log.sql` | page_access_logs 테이블 생성 + 인덱스 (path, accessed_at) | 13-4 |
| 003 | `003_create_system_settings.sql` | system_settings 테이블 생성 (시스템 설정 저장소) | — |
| 004 | `004_create_users_table.sql` | users 테이블 생성 (인증·사용자 관리) | — |

## 일회성 백필 스크립트 (Python, `_applied/`)

`_applied/` 에 보관된 Python 스크립트는 **특정 Phase 한정 1회성 백필**로, 이미 적용되어 재실행 대상이 아니다.

| 파일 | 출처 Phase | 목적 |
|------|-----------|------|
| `_applied/backfill_titles_display_ids.py` | Phase 32-3 | 기존 Document/KnowledgeChunk 에 title 역추출 + display_id 역생성 |
| `_applied/update_qdrant_payload.py` | Phase 32-3 | 기존 Qdrant 포인트에 title + display_id payload 사후 추가 |

> 신규 데이터는 애플리케이션 레벨에서 title·display_id 를 기록하므로 재실행 불필요. 동일 맥락의 후속 백필이 필요할 때 참조.

## 주의사항

- `CREATE INDEX CONCURRENTLY`는 트랜잭션 블록 안에서 실행 불가
- psql의 autocommit 모드에서 실행해야 함 (`-f` 플래그 사용 시 자동)
- 대용량 테이블에서는 인덱스 생성에 수 분 소요될 수 있음
