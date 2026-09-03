"""`_security` 병합 회귀 시험 (T-4 발견⑶).

⚠️ 이 시험이 지키는 것은 **"지우지 않았다"** 이다 — 부작위 요구라 리뷰에서 안 보인다.
구 판본은 members.names 를 통째로 교체했고, 에러도 안 나고 멱등해 보였다. 없어진
계정은 **다음 접근이 401 로 막힐 때까지** 드러나지 않는다. 그래서 관측 가능한
형태로 바꾼다: 남의 계정을 하나 넣어 두고, 그것이 살아남는지 본다.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

_HERE = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from merge_security import merge_security  # noqa: E402

SCRIPT = _HERE / "merge_security.py"

# 정본 실측값 (2026-09-04). 이 모양이 실제로 서버에 들어 있다.
LIVE = {
    "admins": {"roles": ["_admin"]},
    "members": {"names": ["pabbridge"], "roles": ["_admin", "bridge_ro"]},
}


def _run(stdin: str, user: str = "pabbridge") -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCRIPT)], input=stdin, capture_output=True, text=True,
        env={"BRIDGE_USER": user, "PATH": "/usr/bin:/bin"},
    )


# ── 핵심 — 남의 계정이 살아남는가 ────────────────────────────────────────────
def test_existing_other_account_is_preserved():
    """`pabprove` 가 이미 있으면 **보존**돼야 한다. 이것이 발견⑶의 회귀 시험이다."""
    cur = {
        "admins": {"roles": ["_admin"]},
        "members": {"names": ["pabbridge", "pabprove"], "roles": ["_admin", "bridge_ro"]},
    }
    out = merge_security(cur, "pabbridge")
    assert "pabprove" in out["members"]["names"], (
        "pabprove 가 축출됐다 — deploy.sh 한 번에 편입이 조용히 깨진다"
    )
    assert out["members"]["names"] == ["pabbridge", "pabprove"], "기존 순서까지 보존해야 한다"


def test_preserves_account_added_by_someone_else():
    """우리가 모르는 계정이라도 지우지 않는다 — 공유 자원이다."""
    cur = {"admins": {"roles": ["_admin"]},
           "members": {"names": ["someone_elses_account"], "roles": []}}
    out = merge_security(cur, "pabbridge")
    assert set(out["members"]["names"]) == {"someone_elses_account", "pabbridge"}


def test_preserves_admins_names():
    """admins.names 도 보존한다 — 구 판본은 admins 를 roles 만으로 덮었다."""
    cur = {"admins": {"names": ["superuser"], "roles": ["_admin"]}, "members": {}}
    out = merge_security(cur, "pabbridge")
    assert out["admins"]["names"] == ["superuser"]
    assert "_admin" in out["admins"]["roles"]


def test_preserves_extra_member_roles():
    cur = {"admins": {}, "members": {"names": [], "roles": ["custom_role"]}}
    out = merge_security(cur, "pabbridge")
    assert "custom_role" in out["members"]["roles"]
    assert {"_admin", "bridge_ro"} <= set(out["members"]["roles"])


# ── 멱등 ─────────────────────────────────────────────────────────────────────
def test_idempotent_on_live_shape():
    once = merge_security(LIVE, "pabbridge")
    twice = merge_security(once, "pabbridge")
    assert once == twice
    assert once["members"]["names"] == ["pabbridge"], "중복 추가되면 안 된다"


def test_bootstrap_from_empty():
    """최초 설치(빈 _security)에서도 최소 정책이 선다."""
    out = merge_security({}, "pabbridge")
    assert out["members"]["names"] == ["pabbridge"]
    assert out["admins"]["roles"] == ["_admin"]


# ── 실패 시 쓰지 않는다 ──────────────────────────────────────────────────────
# 조회 실패를 "기존 멤버 없음"으로 오해하면 **그 순간 기존 계정이 날아간다.**
# 판단이 서지 않으면 멈추는 쪽이 맞다.
def test_broken_json_aborts_without_output():
    r = _run("<html>502 Bad Gateway</html>")
    assert r.returncode != 0, "깨진 응답인데 계속 진행했다 — 기존 멤버를 잃는다"
    assert r.stdout.strip() == "", "중단해야 하는데 출력을 냈다"


def test_couchdb_error_response_aborts():
    r = _run(json.dumps({"error": "unauthorized", "reason": "Authentication required."}))
    assert r.returncode != 0, "에러 JSON 을 정상 _security 로 읽었다"
    assert r.stdout.strip() == ""


def test_missing_bridge_user_aborts():
    r = subprocess.run([sys.executable, str(SCRIPT)], input=json.dumps(LIVE),
                       capture_output=True, text=True, env={"PATH": "/usr/bin:/bin"})
    assert r.returncode != 0
    assert r.stdout.strip() == ""


# ── CLI 통합 (셸이 실제로 부르는 경로) ───────────────────────────────────────
def test_cli_roundtrip_on_live_shape():
    r = _run(json.dumps(LIVE))
    assert r.returncode == 0, r.stderr
    out = json.loads(r.stdout)
    assert out["members"]["names"] == ["pabbridge"]


def test_cli_preserves_pabprove_end_to_end():
    cur = dict(LIVE)
    cur["members"] = {"names": ["pabbridge", "pabprove"], "roles": ["_admin", "bridge_ro"]}
    r = _run(json.dumps(cur))
    assert r.returncode == 0, r.stderr
    assert "pabprove" in json.loads(r.stdout)["members"]["names"]


@pytest.mark.parametrize("empty", ["", "   ", "{}"])
def test_empty_input_bootstraps(empty):
    """빈 입력은 '최초 설치'로 본다 — 파싱 실패와 구분한다."""
    r = _run(empty)
    assert r.returncode == 0, r.stderr
    assert json.loads(r.stdout)["members"]["names"] == ["pabbridge"]
