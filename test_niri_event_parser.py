#!/usr/bin/env python3
"""
test_niri_event_parser.py — standalone mock test for Niri.qml event ingestion logic.

Mirrors the JS handleEvent logic in pure Python to verify JSON schema parsing.
Run: python3 test_niri_event_parser.py
Exit 0 = PASS, non-zero = FAIL
"""

import json, sys

# ── State mirrors Niri.qml reactive properties ────────────────────────────────
state = {
    "connected": False,
    "regionsEnabled": False,
    "focusedRegion": "Right",
    "workspaces": [],
    "focusedWorkspaceId": -1,
    "activeWindow": None,
    "windowsById": {},
}

def handle_event(evt: dict) -> None:
    if "RegionsChanged" in evt:
        rc = evt["RegionsChanged"]
        state["regionsEnabled"] = rc["regions_enabled"]
        state["focusedRegion"] = rc.get("focused_region") or ""
        state["connected"] = True
    elif "WorkspacesChanged" in evt:
        state["workspaces"] = evt["WorkspacesChanged"]["workspaces"]
        focused = next((w for w in state["workspaces"] if w.get("is_focused")), None)
        if focused:
            state["focusedWorkspaceId"] = focused["id"]
        state["connected"] = True
    elif "WorkspaceActivated" in evt:
        wa = evt["WorkspaceActivated"]
        if wa.get("focused"):
            state["focusedWorkspaceId"] = wa["id"]
        state["connected"] = True
    elif "WindowsChanged" in evt:
        wins = evt["WindowsChanged"].get("windows", [])
        state["windowsById"] = {w["id"]: w for w in wins}
        focused_win = next((w for w in wins if w.get("is_focused")), None)
        if focused_win:
            state["activeWindow"] = focused_win
        state["connected"] = True
    elif "WorkspaceActiveWindowChanged" in evt:
        wid = evt["WorkspaceActiveWindowChanged"].get("active_window_id")
        if evt["WorkspaceActiveWindowChanged"].get("workspace_id") == state["focusedWorkspaceId"]:
            state["activeWindow"] = state["windowsById"].get(wid) if wid is not None else None
        state["connected"] = True
    elif "WindowOpenedOrChanged" in evt:
        win = evt["WindowOpenedOrChanged"]["window"]
        state["windowsById"][win["id"]] = win
        if win.get("is_focused"):
            state["activeWindow"] = win
        state["connected"] = True
    elif "WindowClosed" in evt:
        wid = evt["WindowClosed"]["id"]
        state["windowsById"].pop(wid, None)
        if state["activeWindow"] and state["activeWindow"]["id"] == wid:
            state["activeWindow"] = None
        state["connected"] = True
    elif "WindowFocusChanged" in evt:
        wid = evt["WindowFocusChanged"].get("id")
        if wid is None:
            state["activeWindow"] = None
        elif wid in state["windowsById"]:
            state["activeWindow"] = state["windowsById"][wid]
        state["connected"] = True

# ── Mock event stream ─────────────────────────────────────────────────────────
MOCK_STREAM = [
    '{"RegionsChanged": {"regions_enabled": true, "focused_region": "Right"}}',
    '{"WorkspacesChanged": {"workspaces": [{"id": 1, "name": "1", "idx": 0, "output": "eDP-1", "is_active": true, "is_focused": true, "active_window_id": 42, "regions_enabled": true, "focused_region": "Right"}, {"id": 2, "name": "2", "idx": 1, "output": "eDP-1", "is_active": false, "is_focused": false, "active_window_id": null, "regions_enabled": true, "focused_region": null}]}}',
    '{"WorkspaceActivated": {"id": 1, "focused": true}}',
    '{"WindowOpenedOrChanged": {"window": {"id": 42, "title": "alacritty", "app_id": "Alacritty", "workspace_id": 1, "is_focused": true, "regions_enabled": true, "focused_region": "Right", "region": "Right"}}}',
    '{"WindowFocusChanged": {"id": 42}}',
    '{"WindowOpenedOrChanged": {"window": {"id": 99, "title": "Firefox", "app_id": "firefox", "workspace_id": 1, "is_focused": false, "regions_enabled": true, "focused_region": "Right", "region": "Left"}}}',
    '{"WindowFocusChanged": {"id": 99}}',
    '{"WindowClosed": {"id": 42}}',
    '{"RegionsChanged": {"regions_enabled": true, "focused_region": "Left"}}',
    '{"WindowFocusChanged": {"id": null}}',
]

for line in MOCK_STREAM:
    evt = json.loads(line)
    handle_event(evt)

# ── Assertions ────────────────────────────────────────────────────────────────
failures = []

def check(desc, got, expected):
    if got != expected:
        failures.append(f"FAIL [{desc}]: got {got!r}, expected {expected!r}")
    else:
        print(f"  PASS [{desc}]")

check("connected after first event", state["connected"], True)
check("regionsEnabled", state["regionsEnabled"], True)
check("focusedRegion after Left switch", state["focusedRegion"], "Left")
check("focusedWorkspaceId", state["focusedWorkspaceId"], 1)
check("workspace count", len(state["workspaces"]), 2)
check("window 42 closed → removed from windowsById", 42 in state["windowsById"], False)
check("window 99 present in windowsById", 99 in state["windowsById"], True)
check("window 99 title", state["windowsById"][99]["title"], "Firefox")
check("activeWindow None after null WindowFocusChanged", state["activeWindow"], None)

if failures:
    print("\n" + "\n".join(failures))
    print(f"\n{len(failures)} test(s) FAILED.")
    sys.exit(1)
else:
    print(f"\nAll {len(MOCK_STREAM)} events processed. All assertions PASSED.")
    sys.exit(0)
