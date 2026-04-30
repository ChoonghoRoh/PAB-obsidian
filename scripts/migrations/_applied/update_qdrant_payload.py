"""기존 Qdrant 포인트에 title + display_id payload 추가 — Phase 32-3

사용법: python3 scripts/migrations/update_qdrant_payload.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy.orm import Session
from backend.models.database import SessionLocal
from backend.models.models import KnowledgeChunk
from backend.config import QDRANT_HOST, QDRANT_PORT, COLLECTION_NAME


def _get_qdrant_client():
    """Qdrant 클라이언트 생성 (연결 실패 시 None 반환)"""
    try:
        from qdrant_client import QdrantClient
        client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
        return client
    except Exception as e:
        print(f"Qdrant 클라이언트 초기화 실패: {e}")
        return None


def update_qdrant_payloads(db: Session) -> int:
    """기존 Qdrant 포인트에 title + display_id payload 추가"""
    qdrant = _get_qdrant_client()
    if not qdrant:
        print("Qdrant 클라이언트를 가져올 수 없습니다.")
        return 0

    chunks = db.query(KnowledgeChunk).filter(
        KnowledgeChunk.qdrant_point_id.isnot(None)
    ).all()

    count = 0
    for chunk in chunks:
        try:
            qdrant.set_payload(
                collection_name=COLLECTION_NAME,
                payload={
                    "title": chunk.title,
                    "display_id": chunk.display_id,
                },
                points=[chunk.qdrant_point_id],
            )
            count += 1
        except Exception as e:
            print(f"  경고: chunk {chunk.id} (point {chunk.qdrant_point_id}) 업데이트 실패: {e}")

    return count


def main():
    db = SessionLocal()
    try:
        print("=== Phase 32-3: Qdrant Payload Update ===")
        n = update_qdrant_payloads(db)
        print(f"Qdrant 포인트: {n}건 업데이트")
        print("=== 완료 ===")
    finally:
        db.close()


if __name__ == "__main__":
    main()
