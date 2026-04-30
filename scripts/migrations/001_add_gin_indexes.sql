-- ============================================
-- Phase 12-2-3: PostgreSQL GIN 인덱스 추가
-- ============================================
-- 목적: 텍스트 검색 성능 개선 (to_tsvector 기반 full-text search)
-- 파서: 'simple' (한국어 콘텐츠 호환 — 'english' 대신 범용 토크나이저)
-- 옵션: CONCURRENTLY (테이블 잠금 없이 인덱스 생성)
--
-- 실행 방법:
--   psql -h localhost -p 5433 -U brain -d knowledge -f scripts/migrations/001_add_gin_indexes.sql
--
-- 주의: CONCURRENTLY는 트랜잭션 블록 안에서 실행 불가.
--       이 파일은 반드시 autocommit 모드로 실행해야 함.
-- ============================================

-- 1. knowledge_chunks.content — 청크 내용 전문 검색
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_chunks_content_gin
    ON knowledge_chunks USING gin (to_tsvector('simple', content));

-- 2. conversations.question — 대화 질문 전문 검색
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversations_question_gin
    ON conversations USING gin (to_tsvector('simple', question));

-- 3. conversations.answer — 대화 답변 전문 검색
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversations_answer_gin
    ON conversations USING gin (to_tsvector('simple', answer));

-- 4. memories.content — 기억 내용 전문 검색
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_memories_content_gin
    ON memories USING gin (to_tsvector('simple', content));

-- ============================================
-- 검증 쿼리 (인덱스 생성 후 실행)
-- ============================================
-- SELECT indexname, tablename FROM pg_indexes
-- WHERE indexname LIKE 'idx_%_gin' ORDER BY tablename;
--
-- EXPLAIN ANALYZE
-- SELECT id, left(content, 50) FROM knowledge_chunks
-- WHERE to_tsvector('simple', content) @@ to_tsquery('simple', 'test');
