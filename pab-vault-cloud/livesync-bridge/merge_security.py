#!/usr/bin/env python3
"""CouchDB `_security` 병합 — 기존 멤버를 보존하면서 bridge 계정만 추가한다.

⚠️ 이 파일이 존재하는 이유:
`_security` 에는 `_rev` 가 없다. 즉 **PUT 이 곧 전체 교체**다. 그래서 예전 판본은
`{"members":{"names":["pabbridge"]}}` 를 통째로 PUT 했고, 나중에 추가된 계정
(`pabprove` 등)을 **조용히 축출**했다. 스크립트는 멱등해 보였고 에러도 안 났다 —
없어진 것은 다음 번 접근이 401 로 막힐 때까지 드러나지 않는다.

더 나빴던 것은 주석이 코드와 반대였다는 점이다:
    # 기존 _admin 멤버 정책 유지 + bridge 사용자/롤 추가   ← 주석은 "유지+추가"
    -d '{... "names":["'"$BRIDGE_USER"'"] ...}'            ← 코드는 "교체"
**주석을 믿고 읽으면 이 결함은 보이지 않는다.**

⇒ 읽어서 합치는 수밖에 없다. 이 모듈이 그 병합이고, 시험이 붙어 있다.

사용: 현재 _security 를 stdin 으로, 추가할 계정을 BRIDGE_USER 환경변수로 넘긴다.
    curl -sf ".../_security" | BRIDGE_USER=pabbridge python3 merge_security.py
"""
from __future__ import annotations

import json
import os
import sys
from typing import Any

# 이 스크립트가 보장하는 최소 권한. 기존 값에 **더하기만** 하고 빼지 않는다.
REQUIRED_ADMIN_ROLES = ["_admin"]
REQUIRED_MEMBER_ROLES = ["_admin", "bridge_ro"]


def _extend_unique(section: dict[str, Any], key: str, wanted: list[str]) -> None:
    """기존 목록 순서를 보존하면서 없는 값만 뒤에 덧붙인다."""
    current = list(section.get(key) or [])
    for w in wanted:
        if w not in current:
            current.append(w)
    section[key] = current


def merge_security(current: Any, bridge_user: str) -> dict[str, Any]:
    """기존 `_security` 에 bridge 계정을 더한 새 `_security` 를 만든다.

    - 기존 `members.names` 는 **한 건도 지우지 않는다** (pabprove 축출 방지)
    - 기존 `admins.names` / 추가 role 도 보존한다
    - 입력이 비었거나 깨졌으면 최소 정책으로 시작한다
    """
    if not isinstance(current, dict):
        current = {}
    admins = current.get("admins")
    members = current.get("members")
    admins = dict(admins) if isinstance(admins, dict) else {}
    members = dict(members) if isinstance(members, dict) else {}

    _extend_unique(admins, "roles", REQUIRED_ADMIN_ROLES)
    _extend_unique(members, "names", [bridge_user])
    _extend_unique(members, "roles", REQUIRED_MEMBER_ROLES)
    return {"admins": admins, "members": members}


def main() -> int:
    bridge_user = os.environ.get("BRIDGE_USER", "").strip()
    if not bridge_user:
        print("merge_security: BRIDGE_USER 가 비었다", file=sys.stderr)
        return 2
    raw = sys.stdin.read().strip()
    try:
        current = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        # 조회 실패(빈 응답·에러 JSON)를 "기존 멤버 없음"으로 오해하면 그 순간
        # 기존 계정이 날아간다. 판단이 서지 않으면 **쓰지 않고 멈춘다.**
        print(f"merge_security: _security 응답을 파싱할 수 없다 — 중단 (len={len(raw)})",
              file=sys.stderr)
        return 3
    if isinstance(current, dict) and "error" in current and "members" not in current:
        print(f"merge_security: _security 조회가 에러를 반환했다 — 중단 ({current.get('error')})",
              file=sys.stderr)
        return 4
    json.dump(merge_security(current, bridge_user), sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
