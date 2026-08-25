-- ============================================
-- Phase 13-4: 페이지 접근 로그 테이블 생성
-- ============================================
-- 목적: HTML 페이지 접근 이력 수집 (메뉴 사용 패턴 분석)
-- API/정적 파일 요청은 제외하고 페이지 라우트만 기록
--
-- 실행 방법:
--   docker exec -i pab-postgres-ver3 psql -U brain -d knowledge < scripts/migrations/002_create_page_access_log.sql
--   또는
--   psql -h localhost -p 5433 -U brain -d knowledge -f scripts/migrations/002_create_page_access_log.sql
-- ============================================

CREATE TABLE IF NOT EXISTS page_access_logs (
    id              SERIAL PRIMARY KEY,
    path            VARCHAR(255) NOT NULL,
    method          VARCHAR(10) NOT NULL DEFAULT 'GET',
    status_code     INTEGER NOT NULL,
    response_time_ms INTEGER,
    user_agent      TEXT,
    ip_address      VARCHAR(45),
    accessed_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_page_access_logs_path
    ON page_access_logs (path);

CREATE INDEX IF NOT EXISTS idx_page_access_logs_date
    ON page_access_logs (accessed_at);

-- ============================================
-- 검증 쿼리
-- ============================================
-- SELECT count(*) FROM page_access_logs;
-- SELECT path, count(*) as cnt FROM page_access_logs
--   GROUP BY path ORDER BY cnt DESC LIMIT 10;
