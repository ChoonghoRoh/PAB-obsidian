"""기존 Document/KnowledgeChunk에 title + display_id 역추출 — Phase 32-3

사용법: python3 -m scripts.migrations.backfill_titles_display_ids
또는: python3 scripts/migrations/backfill_titles_display_ids.py
"""
import re
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy.orm import Session
from backend.models.database import SessionLocal
from backend.models.models import Document, KnowledgeChunk

HEADING_PATTERN = re.compile(r"^#{1,3}\s+(.+)$", re.MULTILINE)


def backfill_document_titles(db: Session) -> int:
    """Document.title 역추출 (file_name 기반)"""
    docs = db.query(Document).filter(Document.title.is_(None)).all()
    count = 0
    for doc in docs:
        name = doc.file_name
        if "." in name:
            name = name.rsplit(".", 1)[0]
        doc.title = name.replace("_", " ").replace("-", " ").strip()
        count += 1
    db.commit()
    return count


def backfill_document_display_ids(db: Session) -> int:
    """Document.display_id 역생성"""
    docs = db.query(Document).filter(Document.display_id.is_(None)).order_by(Document.id).all()
    count = 0
    # project_id별 시퀀스 추적
    seq_map = {}
    for doc in docs:
        pid = doc.project_id or 0
        if pid not in seq_map:
            # 이미 display_id가 있는 문서 수 카운트
            existing = db.query(Document).filter(
                Document.project_id == pid,
                Document.display_id.isnot(None)
            ).count()
            seq_map[pid] = existing
        seq_map[pid] += 1
        doc.display_id = f"DOC-{pid}-{seq_map[pid]:03d}"
        count += 1
    db.commit()
    return count


def backfill_chunk_titles(db: Session) -> int:
    """KnowledgeChunk.title 역추출 (content heading 기반)"""
    chunks = db.query(KnowledgeChunk).filter(KnowledgeChunk.title.is_(None)).all()
    count = 0
    for chunk in chunks:
        m = HEADING_PATTERN.search(chunk.content)
        if m:
            chunk.title = m.group(1).strip()
            chunk.title_source = "heading"
            count += 1
    db.commit()
    return count


def backfill_chunk_display_ids(db: Session) -> int:
    """KnowledgeChunk.display_id 역생성"""
    chunks = db.query(KnowledgeChunk).filter(
        KnowledgeChunk.display_id.is_(None)
    ).order_by(KnowledgeChunk.document_id, KnowledgeChunk.chunk_index).all()
    count = 0
    for chunk in chunks:
        chunk.display_id = f"CHK-{chunk.document_id}-{chunk.chunk_index:03d}"
        count += 1
    db.commit()
    return count


def main():
    db = SessionLocal()
    try:
        print("=== Phase 32-3: Title + Display ID Backfill ===")

        n = backfill_document_titles(db)
        print(f"Document titles: {n}건 역추출")

        n = backfill_document_display_ids(db)
        print(f"Document display_ids: {n}건 생성")

        n = backfill_chunk_titles(db)
        print(f"Chunk titles: {n}건 역추출")

        n = backfill_chunk_display_ids(db)
        print(f"Chunk display_ids: {n}건 생성")

        print("=== 완료 ===")
    finally:
        db.close()


if __name__ == "__main__":
    main()
