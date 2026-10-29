// splitdesk_services/Niri.qml — Native IPC Telemetry Service
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET")
    readonly property bool isSocketAvailable: socketPath !== ""

    // Reactive public state
    property bool connected: false
    property bool regionsEnabled: false
    property string focusedRegion: "Right" // "Left", "Right", or ""
    property var workspaces: []
    property int focusedWorkspaceId: -1
    property var activeWindow: null
    property var windowsById: ({})

    readonly property string activeWindowTitle: activeWindow ? (activeWindow.title || "") : ""

    // ── Reconnection Lifecycle (Exponential Backoff with Jitter) ─────────────
    property int reconnectAttempt: 0
    property int reconnectBaseMs: 500
    property int reconnectMaxMs: 10000

    function scheduleReconnect() {
        if (!root.isSocketAvailable) return;
        const pow = Math.min(reconnectAttempt, 6);
        const base = Math.min(reconnectBaseMs * Math.pow(2, pow), reconnectMaxMs);
        const jitter = Math.floor(Math.random() * Math.floor(base / 4));
        reconnectTimer.interval = base + jitter;
        reconnectTimer.restart();
        reconnectAttempt++;
    }

    function actionToCliArgs(actionObj) {
        if (typeof actionObj === "string") {
            const kebab = actionObj.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
            return [kebab];
        }
        if (typeof actionObj === "object" && actionObj !== null) {
            if (actionObj.FocusWorkspace && actionObj.FocusWorkspace.reference) {
                const ref = actionObj.FocusWorkspace.reference;
                const id = ref.Id ?? ref.id;
                if (id !== undefined) return ["focus-workspace", String(id)];
            }
        }
        console.warn("[Niri.qml] Could not convert action to CLI args:", JSON.stringify(actionObj));
        return [];
    }

    function sendAction(actionObj) {
        if (requestSocket.connected) {
            const payload = JSON.stringify({ "Action": actionObj }) + "\n";
            requestSocket.write(payload);
            requestSocket.flush();
            return true;
        }
        // Fallback: spawn CLI process if socket is detached
        const args = actionToCliArgs(actionObj);
        if (args.length > 0) {
            if (fallbackActionProc.running) fallbackActionProc.running = false;
            fallbackActionProc.command = ["niri", "msg", "action"].concat(args);
            fallbackActionProc.running = true;
        }
        return false;
    }

    function toggleSplitMode() { sendAction("ToggleSplitMode"); }

    function focusRegionLeft() { sendAction("FocusRegionLeft"); }

    function focusRegionRight() { sendAction("FocusRegionRight"); }

    function toggleRegionFocus() { sendAction("ToggleRegionFocus"); }

    function moveWindowToRegionLeft() { sendAction("MoveWindowToRegionLeft"); }

    function moveWindowToRegionRight() { sendAction("MoveWindowToRegionRight"); }

    function focusWorkspace(id) {
        sendAction({ "FocusWorkspace": { "reference": { "Id": Number(id) } } });
    }

    function focusRegion(region) {
        if (String(region).toLowerCase() === "left") focusRegionLeft();
        else if (String(region).toLowerCase() === "right") focusRegionRight();
    }

    function moveWindowToRegion(region) {
        if (String(region).toLowerCase() === "left") moveWindowToRegionLeft();
        else if (String(region).toLowerCase() === "right") moveWindowToRegionRight();
    }

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
                if (wins[i].is_focused) focusedWin = wins[i];
            }
            root.windowsById = copy;
            if (focusedWin) root.activeWindow = focusedWin;
        } else if (evt.WindowOpenedOrChanged) {
            const win = evt.WindowOpenedOrChanged.window;
            const copy = Object.assign({}, root.windowsById);
            copy[win.id] = win;
            root.windowsById = copy;
            if (win.is_focused) root.activeWindow = win;
        } else if (evt.WindowClosed) {
            const id = evt.WindowClosed.id;
            const copy = Object.assign({}, root.windowsById);
            delete copy[id];
            root.windowsById = copy;
            if (root.activeWindow && root.activeWindow.id === id)
                root.activeWindow = null;
        } else if (evt.WindowFocusChanged) {
            const id = evt.WindowFocusChanged.id;
            if (id === null || id === undefined) root.activeWindow = null;
            else if (root.windowsById[id]) root.activeWindow = root.windowsById[id];
        } else if (evt.WorkspaceActiveWindowChanged) {
            const id = evt.WorkspaceActiveWindowChanged.active_window_id;
            if (evt.WorkspaceActiveWindowChanged.workspace_id === root.focusedWorkspaceId) {
                if (id === null || id === undefined) root.activeWindow = null;
                else if (root.windowsById[id]) root.activeWindow = root.windowsById[id];
            }
        }
    }

    Timer {
        id: reconnectTimer

        repeat: false
        onTriggered: {
            if (root.isSocketAvailable) {
                if (!eventStreamSocket.connected) {
                    eventStreamSocket.connected = false;
                    Qt.callLater(() => { eventStreamSocket.connected = true; });
                }
                if (!requestSocket.connected) {
                    requestSocket.connected = false;
                    Qt.callLater(() => { requestSocket.connected = true; });
                }
            }
        }
    }

    Socket {
        id: eventStreamSocket

        path: root.socketPath
        connected: root.isSocketAvailable

        onConnectionStateChanged: {
            root.connected = connected;
            if (connected) {
                root.reconnectAttempt = 0;
                write('"EventStream"\n');
                flush();
            } else {
                // Clear stale cache on disconnect
                root.workspaces = [];
                root.windowsById = ({});
                root.activeWindow = null;
                root.scheduleReconnect();
            }
        }

        parser: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const line = data.trim();
                if (line.length === 0) return;
                try {
                    const evt = JSON.parse(line);
                    root.handleEvent(evt);
                } catch (err) {
                    console.warn("[Niri.qml] Socket JSON parse error:", err);
                }
            }
        }
    }

    Socket {
        id: requestSocket

        path: root.socketPath
        connected: root.isSocketAvailable

        onConnectionStateChanged: {
            if (!connected && root.isSocketAvailable) {
                root.scheduleReconnect();
            }
        }

        // Drain Niri JSON replies ({"Ok":"Handled"}\n) to prevent buffer exhaustion
        parser: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                // Drained successfully from kernel SO_RCVBUF
            }
        }
    }

    Process {
        id: fallbackActionProc

        running: false
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("[Niri.qml] Fallback action failed, exit code:", code);
        }
    }
}
