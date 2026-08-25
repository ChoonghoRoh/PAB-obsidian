"""Frontmatter 11필드 자동 채움 + parse/dump 유틸.

T-2에서 본격 구현.
"""
from __future__ import annotations

import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any

import frontmatter as fm_lib

DRY_RUN_PREFIX = "[dry-run]"

REQUIRED_FIELDS = [
    "title", "description", "created", "updated",
    "type", "index", "topics", "tags",
    "keywords", "sources", "aliases",
]

# TYPE → 기본 tags 매핑 (schema v1.1 pattern: ^[a-z0-9-]+(/[a-z0-9-]+)*$)
TYPE_DEFAULT_TAGS: dict[str, list[str]] = {
    "RESEARCH_NOTE": ["research-note"],
    "CONCEPT": ["concept"],
    "LESSON": ["lesson"],
    "PROJECT": ["project"],
    "DAILY": ["daily"],
    "REFERENCE": ["reference"],
}

# TYPE → 노트 저장 디렉토리 (vault 내부 상대)
TYPE_DIR_MAP: dict[str, str] = {
    "RESEARCH_NOTE": "10_Notes",
    "CONCEPT": "10_Notes",
    "LESSON": "10_Notes",
    "REFERENCE": "10_Notes",
    "PROJECT": "10_Notes",
    "DAILY": "99_Inbox",
}


def build_default_frontmatter(type_: str, slug: str) -> dict[str, Any]:
    """11필드 default 값 생성.

    schema v1.1 규칙:
    - type: [[TYPE]] 형식
    - index: [[ROOT]] (사용자가 편집 시 변경)
    - tags: TYPE별 lowercase-hyphen 1개
    - created/updated: YYYY-MM-DD HH:MM
    """
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    title = slug.replace("-", " ").replace("_", " ").title()
    return {
        "title": title,
        "description": "",
        "created": now,
        "updated": now,
        "type": f"[[{type_}]]",
        "index": "[[ROOT]]",
        "topics": [],
        "tags": list(TYPE_DEFAULT_TAGS.get(type_, [type_.lower()])),
        "keywords": [],
        "sources": [],
        "aliases": [],
    }


def load_note(path: Path) -> fm_lib.Post:
    """python-frontmatter로 노트 파싱."""
    return fm_lib.load(str(path))


def render_note(fm_data: dict[str, Any], vault: Path, type_: str) -> str:
    """템플릿 본문 + frontmatter를 합쳐 최종 노트 문자열 반환.

    절차:
    1. {vault}/40_Templates/<TYPE>.md 읽기
    2. python-frontmatter로 본문 분리 (현재 템플릿은 placeholder 미사용)
    3. 새 frontmatter + 템플릿 본문 결합
    """
    template_path = vault / f"40_Templates/{type_}.md"
    body = ""
    if template_path.exists():
        post = fm_lib.load(str(template_path))
        body = post.content.strip()

    post = fm_lib.Post(body, **fm_data)
    return fm_lib.dumps(post)


def write_note(
    out_path: Path,
    fm_data: dict[str, Any],
    content: str,
    vault: Path,
    type_: str,
) -> int:
    """노트 파일을 디스크에 기록하고 obsidian create 호출.

    Returns:
        0 — 성공
        1 — 파일 충돌 (이미 존재)
    """
    if out_path.exists():
        print(f"[ERROR] 파일이 이미 존재합니다: {out_path}")
        return 1

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    print(f"[OK] 노트 생성: {out_path}")

    # obsidian create 호출 (best-effort)
    _try_obsidian_create(out_path)
    return 0


def _try_obsidian_create(path: Path) -> None:
    """obsidian create CLI 호출 (실패해도 파일은 유지)."""
    try:
        result = subprocess.run(
            ["obsidian", "create", str(path)],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            print(f"[obsidian] create 성공: {result.stdout.strip()}")
        else:
            print(f"[obsidian] create 실패 (exit {result.returncode}): {result.stderr.strip()}")
    except FileNotFoundError:
        print("[obsidian] CLI 미설치 — 폴백: 직접 파일 작성 완료")
    except subprocess.TimeoutExpired:
        print("[obsidian] create 타임아웃 — 파일은 정상 생성됨")
