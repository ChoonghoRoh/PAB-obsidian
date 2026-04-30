-- ============================================
-- Phase 15-1-1: 시스템 설정 테이블 생성
-- ============================================
-- 목적: Key-Value 방식으로 시스템 전역 설정 저장
-- 환경변수 기본값을 DB에서 오버라이드 가능
--
-- 실행 방법:
--   docker exec -i pab-postgres-ver3 psql -U brain -d knowledge < scripts/migrations/003_create_system_settings.sql
--   또는
--   psql -h localhost -p 5433 -U brain -d knowledge -f scripts/migrations/003_create_system_settings.sql
-- ============================================

CREATE TABLE IF NOT EXISTS system_settings (
    id              SERIAL PRIMARY KEY,
    key             VARCHAR(100) UNIQUE NOT NULL,
    value           TEXT NOT NULL,
    description     TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 유니크 인덱스
CREATE UNIQUE INDEX IF NOT EXISTS idx_system_settings_key
    ON system_settings (key);

-- ============================================
-- 검증 쿼리
-- ============================================
-- SELECT * FROM system_settings;
-- SELECT key, value FROM system_settings WHERE key = 'knowledge.folder_path';
