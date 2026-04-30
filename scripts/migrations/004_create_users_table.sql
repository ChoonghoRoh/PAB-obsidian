-- Phase 15-5-1: users 테이블 생성 마이그레이션
-- 실행: docker compose exec backend psql -U brain -d knowledge -f scripts/migrations/004_create_users_table.sql
--
-- 주의: Phase 14-5-2에서 ORM으로 이미 생성된 경우 IF NOT EXISTS로 안전하게 처리

-- users 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    display_name VARCHAR(200),
    email VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users (is_active);

-- 코멘트
COMMENT ON TABLE users IS 'Phase 14-5-2/15-5-1: 사용자 인증·역할 관리';
COMMENT ON COLUMN users.role IS 'user | admin_knowledge | admin_system';
COMMENT ON COLUMN users.is_active IS 'soft delete용 활성 상태';
