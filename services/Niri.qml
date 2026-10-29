pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Reactive public state
    property bool connected: false
    property bool regionsEnabled: false
    property string focusedRegion: "Right" // "Left", "Right", or ""
    property var workspaces: []
    property int focusedWorkspaceId: -1
    property var activeWindow: null
    property var windowsById: ({})

    readonly property string activeWindowTitle: activeWindow ? (activeWindow.title || "") : ""

    // ── Action dispatch ──────────────────────────────────────────────────────

    function dispatch(args) {
        if (actionProc.running)
            actionProc.running = false;
        actionProc.command = ["niri", "msg", "action"].concat(args);
        actionProc.running = true;
    }

    function toggleSplitMode() { dispatch(["toggle-split-mode"]); }
    function focusRegionLeft() { dispatch(["focus-region-left"]); }
    function focusRegionRight() { dispatch(["focus-region-right"]); }
    function toggleRegionFocus() { dispatch(["toggle-region-focus"]); }
    function moveWindowToRegionLeft() { dispatch(["move-window-to-region-left"]); }
    function moveWindowToRegionRight() { dispatch(["move-window-to-region-right"]); }
    function focusWorkspace(id) { dispatch(["focus-workspace", String(id)]); }

    function focusRegion(region) {
        if (String(region).toLowerCase() === "left")
            focusRegionLeft();
        else if (String(region).toLowerCase() === "right")
            focusRegionRight();
    }

    function moveWindowToRegion(region) {
        if (String(region).toLowerCase() === "left")
            moveWindowToRegionLeft();
        else if (String(region).toLowerCase() === "right")
            moveWindowToRegionRight();
    }

    // ── Event ingestion ──────────────────────────────────────────────────────

    function handleEvent(evt) {
        if (!evt) return;

        if (evt.RegionsChanged) {
            const rc = evt.RegionsChanged;
            root.regionsEnabled = rc.regions_enabled;
            root.focusedRegion = rc.focused_region ?? "";
        } else if (evt.WorkspacesChanged) {
            root.workspaces = evt.WorkspacesChanged.workspaces ?? [];
            const focused = root.workspaces.find(w => w.is_focused);
            if (focused) {
                root.focusedWorkspaceId = focused.id;
                if (focused.regions_enabled !== undefined)
                    root.regionsEnabled = focused.regions_enabled;
                if (focused.focused_region !== undefined)
                    root.focusedRegion = focused.focused_region ?? "";
            }
        } else if (evt.WorkspaceActivated) {
            const wa = evt.WorkspaceActivated;
            if (wa.focused) {
                root.focusedWorkspaceId = wa.id;
                const ws = root.workspaces.find(w => w.id === wa.id);
                if (ws) {
                    if (ws.regions_enabled !== undefined)
                        root.regionsEnabled = ws.regions_enabled;
                    if (ws.focused_region !== undefined)
                        root.focusedRegion = ws.focused_region ?? "";
                }
            }
        } else if (evt.WindowsChanged) {
            const wins = evt.WindowsChanged.windows ?? [];
            const copy = {};
            let focusedWin = null;
            for (let i = 0; i < wins.length; ++i) {
                copy[wins[i].id] = wins[i];
                if (wins[i].is_focused)
                    focusedWin = wins[i];
            }
            root.windowsById = copy;
            if (focusedWin)
                root.activeWindow = focusedWin;
        } else if (evt.WindowOpenedOrChanged) {
            const win = evt.WindowOpenedOrChanged.window;
            const copy = Object.assign({}, root.windowsById);
            copy[win.id] = win;
            root.windowsById = copy;
            if (win.is_focused)
                root.activeWindow = win;
        } else if (evt.WindowClosed) {
            const id = evt.WindowClosed.id;
            const copy = Object.assign({}, root.windowsById);
            delete copy[id];
            root.windowsById = copy;
            if (root.activeWindow && root.activeWindow.id === id)
                root.activeWindow = null;
        } else if (evt.WindowFocusChanged) {
            const id = evt.WindowFocusChanged.id;
            if (id === null || id === undefined)
                root.activeWindow = null;
            else if (root.windowsById[id])
                root.activeWindow = root.windowsById[id];
        } else if (evt.WorkspaceActiveWindowChanged) {
            const id = evt.WorkspaceActiveWindowChanged.active_window_id;
            if (evt.WorkspaceActiveWindowChanged.workspace_id === root.focusedWorkspaceId) {
                if (id === null || id === undefined)
                    root.activeWindow = null;
                else if (root.windowsById[id])
                    root.activeWindow = root.windowsById[id];
            }
        }
    }

    function _handleEvent(evt) {
        handleEvent(evt);
    }

    // ── Inbound event stream ─────────────────────────────────────────────────

    Process {
        id: eventStreamProc

        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const line = data.trim();
                if (line.length === 0) return;
                try {
                    const evt = JSON.parse(line);
                    root.handleEvent(evt);
                    root.connected = true;
                } catch (err) {
                    console.warn("[Niri.qml] JSON parse error:", err, "raw line:", line);
                }
            }
        }

        onExited: (code, status) => {
            root.connected = false;
            console.warn(`[Niri.qml] Event stream exited (code ${code}). Reconnecting in 1000ms...`);
            reconnectTimer.start();
        }
    }

    // ── One-shot action invoker ──────────────────────────────────────────────

    Process {
        id: actionProc

        running: false
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("[Niri.qml] Action dispatch failed, exit code:", code);
        }
    }

    // ── Fault-tolerant reconnect ─────────────────────────────────────────────

    Timer {
        id: reconnectTimer

        interval: 1000
        repeat: false
        onTriggered: {
            if (!eventStreamProc.running)
                eventStreamProc.running = true;
        }
    }
}
