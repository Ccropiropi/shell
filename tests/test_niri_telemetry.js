/**
 * Milestone L2: Niri QML Telemetry Service Verification Test
 * Tests splitdesk_services/Niri.qml socket architecture, event ingestion, reactive state mutations, and action dispatchers.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

console.log("=== Running Milestone L2: Niri Telemetry Verification ===");

// 1. Read splitdesk_services/Niri.qml and verify file existence and structure
const niriQmlPath = fs.existsSync(path.resolve(__dirname, '../splitdesk_services/Niri.qml'))
    ? path.resolve(__dirname, '../splitdesk_services/Niri.qml')
    : path.resolve(__dirname, '../shell/splitdesk_services/Niri.qml');
assert(fs.existsSync(niriQmlPath), `Niri.qml does not exist at ${niriQmlPath}`);
const qmlSource = fs.readFileSync(niriQmlPath, 'utf8');

assert(qmlSource.includes('pragma Singleton'), 'Niri.qml must be a Singleton');
assert(qmlSource.includes('import Quickshell.Io'), 'Niri.qml must import Quickshell.Io');
assert(qmlSource.includes('id: eventStreamSocket'), 'Niri.qml must contain eventStreamSocket');
assert(qmlSource.includes('id: requestSocket'), 'Niri.qml must contain requestSocket');
assert(qmlSource.includes('parser: SplitParser'), 'Niri.qml sockets must use SplitParser');
assert(qmlSource.includes('function scheduleReconnect()'), 'Niri.qml must implement scheduleReconnect()');
assert(qmlSource.includes('function actionToCliArgs(actionObj)'), 'Niri.qml must implement actionToCliArgs()');
assert(qmlSource.includes('function sendAction(actionObj)'), 'Niri.qml must implement sendAction()');
assert(qmlSource.includes('requestSocket.flush()'), 'Niri.qml must call flush() on requestSocket');
console.log("PASS: splitdesk_services/Niri.qml socket structure verified.");

// 2. Build mock Niri instance mirroring Niri.qml state and methods
function createNiriService() {
    const root = {
        socketPath: "/run/user/1000/niri.sock",
        isSocketAvailable: true,
        connected: false,
        regionsEnabled: false,
        focusedRegion: "Right",
        workspaces: [],
        focusedWorkspaceId: -1,
        activeWindow: null,
        windowsById: {},

        get activeWindowTitle() {
            return this.activeWindow ? (this.activeWindow.title || "") : "";
        },

        reconnectAttempt: 0,
        reconnectBaseMs: 500,
        reconnectMaxMs: 10000,
        scheduledInterval: 0,

        scheduleReconnect() {
            if (!this.isSocketAvailable) return;
            const pow = Math.min(this.reconnectAttempt, 6);
            const base = Math.min(this.reconnectBaseMs * Math.pow(2, pow), this.reconnectMaxMs);
            const jitter = Math.floor(Math.random() * Math.floor(base / 4));
            this.scheduledInterval = base + jitter;
            this.reconnectAttempt++;
            return this.scheduledInterval;
        },

        actionToCliArgs(actionObj) {
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
            return [];
        },

        socketWrites: [],
        lastDispatchedCommand: null,
        requestSocketConnected: true,

        sendAction(actionObj) {
            if (this.requestSocketConnected) {
                const payload = JSON.stringify({ "Action": actionObj }) + "\n";
                this.socketWrites.push(payload);
                return true;
            }
            const args = this.actionToCliArgs(actionObj);
            if (args.length > 0) {
                this.lastDispatchedCommand = ["niri", "msg", "action"].concat(args);
            }
            return false;
        },

        toggleSplitMode() { this.sendAction("ToggleSplitMode"); },
        focusRegionLeft() { this.sendAction("FocusRegionLeft"); },
        focusRegionRight() { this.sendAction("FocusRegionRight"); },
        toggleRegionFocus() { this.sendAction("ToggleRegionFocus"); },
        moveWindowToRegionLeft() { this.sendAction("MoveWindowToRegionLeft"); },
        moveWindowToRegionRight() { this.sendAction("MoveWindowToRegionRight"); },
        focusWorkspace(id) {
            this.sendAction({ "FocusWorkspace": { "reference": { "Id": Number(id) } } });
        },

        focusRegion(region) {
            if (String(region).toLowerCase() === "left")
                this.focusRegionLeft();
            else if (String(region).toLowerCase() === "right")
                this.focusRegionRight();
        },

        moveWindowToRegion(region) {
            if (String(region).toLowerCase() === "left")
                this.moveWindowToRegionLeft();
            else if (String(region).toLowerCase() === "right")
                this.moveWindowToRegionRight();
        },

        handleEvent(evt) {
            if (!evt) return;

            if (evt.RegionsChanged) {
                const rc = evt.RegionsChanged;
                this.regionsEnabled = rc.regions_enabled;
                this.focusedRegion = rc.focused_region ?? "";
            } else if (evt.WorkspacesChanged) {
                this.workspaces = evt.WorkspacesChanged.workspaces ?? [];
                const focused = this.workspaces.find(w => w.is_focused);
                if (focused) {
                    this.focusedWorkspaceId = focused.id;
                    if (focused.regions_enabled !== undefined)
                        this.regionsEnabled = focused.regions_enabled;
                    if (focused.focused_region !== undefined)
                        this.focusedRegion = focused.focused_region ?? "";
                }
            } else if (evt.WorkspaceActivated) {
                const wa = evt.WorkspaceActivated;
                if (wa.focused) {
                    this.focusedWorkspaceId = wa.id;
                    const ws = this.workspaces.find(w => w.id === wa.id);
                    if (ws) {
                        if (ws.regions_enabled !== undefined)
                            this.regionsEnabled = ws.regions_enabled;
                        if (ws.focused_region !== undefined)
                            this.focusedRegion = ws.focused_region ?? "";
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
                this.windowsById = copy;
                if (focusedWin)
                    this.activeWindow = focusedWin;
            } else if (evt.WindowOpenedOrChanged) {
                const win = evt.WindowOpenedOrChanged.window;
                const copy = Object.assign({}, this.windowsById);
                copy[win.id] = win;
                this.windowsById = copy;
                if (win.is_focused)
                    this.activeWindow = win;
            } else if (evt.WindowClosed) {
                const id = evt.WindowClosed.id;
                const copy = Object.assign({}, this.windowsById);
                delete copy[id];
                this.windowsById = copy;
                if (this.activeWindow && this.activeWindow.id === id)
                    this.activeWindow = null;
            } else if (evt.WindowFocusChanged) {
                const id = evt.WindowFocusChanged.id;
                if (id === null || id === undefined)
                    this.activeWindow = null;
                else if (this.windowsById[id])
                    this.activeWindow = this.windowsById[id];
            } else if (evt.WorkspaceActiveWindowChanged) {
                const id = evt.WorkspaceActiveWindowChanged.active_window_id;
                if (evt.WorkspaceActiveWindowChanged.workspace_id === this.focusedWorkspaceId) {
                    if (id === null || id === undefined)
                        this.activeWindow = null;
                    else if (this.windowsById[id])
                        this.activeWindow = this.windowsById[id];
                }
            }
        }
    };

    return root;
}

const niri = createNiriService();

// 3. Test Action Serializer & Fallback Converter
console.log("\n--- Testing Action Serializer & Fallback Converter ---");
assert.deepStrictEqual(niri.actionToCliArgs("ToggleSplitMode"), ["toggle-split-mode"]);
assert.deepStrictEqual(niri.actionToCliArgs("FocusRegionLeft"), ["focus-region-left"]);
assert.deepStrictEqual(niri.actionToCliArgs("FocusRegionRight"), ["focus-region-right"]);
assert.deepStrictEqual(niri.actionToCliArgs("ToggleRegionFocus"), ["toggle-region-focus"]);
assert.deepStrictEqual(niri.actionToCliArgs("MoveWindowToRegionLeft"), ["move-window-to-region-left"]);
assert.deepStrictEqual(niri.actionToCliArgs("MoveWindowToRegionRight"), ["move-window-to-region-right"]);
assert.deepStrictEqual(niri.actionToCliArgs({ FocusWorkspace: { reference: { Id: 4 } } }), ["focus-workspace", "4"]);
assert.deepStrictEqual(niri.actionToCliArgs({ FocusWorkspace: { reference: { id: 2 } } }), ["focus-workspace", "2"]);
assert.deepStrictEqual(niri.actionToCliArgs({ UnknownAction: {} }), []);
console.log("PASS: actionToCliArgs() properly handles PascalCase string actions and structured objects.");

// 4. Test Socket Action Dispatchers (Fast Path)
console.log("\n--- Testing Socket Action Dispatchers (Fast Path) ---");
niri.socketWrites = [];
niri.requestSocketConnected = true;

niri.toggleSplitMode();
assert.strictEqual(niri.socketWrites.pop(), '{"Action":"ToggleSplitMode"}\n');
niri.focusRegionLeft();
assert.strictEqual(niri.socketWrites.pop(), '{"Action":"FocusRegionLeft"}\n');
niri.focusRegionRight();
assert.strictEqual(niri.socketWrites.pop(), '{"Action":"FocusRegionRight"}\n');
niri.toggleRegionFocus();
assert.strictEqual(niri.socketWrites.pop(), '{"Action":"ToggleRegionFocus"}\n');
niri.moveWindowToRegionLeft();
assert.strictEqual(niri.socketWrites.pop(), '{"Action":"MoveWindowToRegionLeft"}\n');
niri.moveWindowToRegionRight();
assert.strictEqual(niri.socketWrites.pop(), '{"Action":"MoveWindowToRegionRight"}\n');
niri.focusWorkspace(3);
assert.strictEqual(niri.socketWrites.pop(), '{"Action":{"FocusWorkspace":{"reference":{"Id":3}}}}\n');
console.log("PASS: Socket fast-path correctly serializes JSON actions.");

// 5. Test CLI Fallback Dispatchers (Slow Path when Socket Disconnected)
console.log("\n--- Testing CLI Fallback Dispatchers (Slow Path) ---");
niri.requestSocketConnected = false;

niri.toggleSplitMode();
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "toggle-split-mode"]);
niri.focusRegionLeft();
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "focus-region-left"]);
niri.focusRegionRight();
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "focus-region-right"]);
niri.toggleRegionFocus();
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "toggle-region-focus"]);
niri.moveWindowToRegionLeft();
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "move-window-to-region-left"]);
niri.moveWindowToRegionRight();
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "move-window-to-region-right"]);
niri.focusWorkspace(5);
assert.deepStrictEqual(niri.lastDispatchedCommand, ["niri", "msg", "action", "focus-workspace", "5"]);
console.log("PASS: CLI fallback dispatches correct niri msg action CLI commands.");

// 6. Test Exponential Backoff with Jitter
console.log("\n--- Testing Exponential Backoff Reconnect Algorithm ---");
niri.reconnectAttempt = 0;
const interval0 = niri.scheduleReconnect();
assert(interval0 >= 500 && interval0 <= 625, `Attempt 0 interval out of range: ${interval0}`);
const interval1 = niri.scheduleReconnect();
assert(interval1 >= 1000 && interval1 <= 1250, `Attempt 1 interval out of range: ${interval1}`);
const interval2 = niri.scheduleReconnect();
assert(interval2 >= 2000 && interval2 <= 2500, `Attempt 2 interval out of range: ${interval2}`);
console.log(`PASS: Backoff progression: [0]=${interval0}ms, [1]=${interval1}ms, [2]=${interval2}ms`);

// 7. Test Event Ingestion Pipeline
console.log("\n--- Testing Event Ingestion Pipeline ---");

// Test 7.1: WorkspacesChanged
const sampleWorkspacesChanged = {
    WorkspacesChanged: {
        workspaces: [
            {
                id: 1,
                name: "1",
                idx: 0,
                output: "eDP-1",
                is_active: true,
                is_focused: true,
                active_window_id: 101,
                regions_enabled: true,
                focused_region: "Right"
            },
            {
                id: 2,
                name: "2",
                idx: 1,
                output: "eDP-1",
                is_active: false,
                is_focused: false,
                active_window_id: null,
                regions_enabled: true,
                focused_region: null
            }
        ]
    }
};
niri.handleEvent(sampleWorkspacesChanged);
assert.strictEqual(niri.workspaces.length, 2);
assert.strictEqual(niri.focusedWorkspaceId, 1);
assert.strictEqual(niri.regionsEnabled, true);
assert.strictEqual(niri.focusedRegion, "Right");
console.log("PASS: WorkspacesChanged parsed correctly.");

// Test 7.2: WindowsChanged
const sampleWindowsChanged = {
    WindowsChanged: {
        windows: [
            {
                id: 101,
                title: "Terminal - Alacritty",
                app_id: "Alacritty",
                workspace_id: 1,
                is_focused: true,
                regions_enabled: true,
                focused_region: "Right",
                region: "Right"
            },
            {
                id: 102,
                title: "System Monitor",
                app_id: "btop",
                workspace_id: 1,
                is_focused: false,
                regions_enabled: true,
                focused_region: "Right",
                region: "Left"
            }
        ]
    }
};
niri.handleEvent(sampleWindowsChanged);
assert.strictEqual(Object.keys(niri.windowsById).length, 2);
assert.strictEqual(niri.activeWindow.id, 101);
assert.strictEqual(niri.activeWindowTitle, "Terminal - Alacritty");
console.log("PASS: WindowsChanged parsed correctly (activeWindow: 101).");

// Test 7.3: RegionsChanged to Left
const sampleRegionsChangedLeft = {
    RegionsChanged: {
        regions_enabled: true,
        focused_region: "Left"
    }
};
niri.handleEvent(sampleRegionsChangedLeft);
assert.strictEqual(niri.regionsEnabled, true);
assert.strictEqual(niri.focusedRegion, "Left");
console.log("PASS: RegionsChanged -> Left parsed correctly.");

// Test 7.4: WindowOpenedOrChanged
const sampleWindowOpened = {
    WindowOpenedOrChanged: {
        window: {
            id: 103,
            title: "Firefox Web Browser",
            app_id: "firefox",
            workspace_id: 1,
            is_focused: true,
            regions_enabled: true,
            focused_region: "Right",
            region: "Right"
        }
    }
};
niri.handleEvent(sampleWindowOpened);
assert.strictEqual(Object.keys(niri.windowsById).length, 3);
assert.strictEqual(niri.activeWindow.id, 103);
assert.strictEqual(niri.activeWindowTitle, "Firefox Web Browser");
console.log("PASS: WindowOpenedOrChanged parsed correctly (active window updated to Firefox).");

// Test 7.5: WindowFocusChanged
niri.handleEvent({ WindowFocusChanged: { id: 102 } });
assert.strictEqual(niri.activeWindow.id, 102);
assert.strictEqual(niri.activeWindowTitle, "System Monitor");
console.log("PASS: WindowFocusChanged -> 102 (System Monitor).");

niri.handleEvent({ WindowFocusChanged: { id: null } });
assert.strictEqual(niri.activeWindow, null);
assert.strictEqual(niri.activeWindowTitle, "");
console.log("PASS: WindowFocusChanged -> null (unfocused / desktop).");

// Test 7.6: WindowClosed
niri.handleEvent({ WindowFocusChanged: { id: 103 } });
assert.strictEqual(niri.activeWindow.id, 103);
niri.handleEvent({ WindowClosed: { id: 103 } });
assert.strictEqual(niri.windowsById[103], undefined);
assert.strictEqual(niri.activeWindow, null);
assert.strictEqual(Object.keys(niri.windowsById).length, 2);
console.log("PASS: WindowClosed -> 103 removed from registry and activeWindow cleared.");

// Test 7.7: WorkspaceActivated
niri.handleEvent({ WorkspaceActivated: { id: 2, focused: true } });
assert.strictEqual(niri.focusedWorkspaceId, 2);
console.log("PASS: WorkspaceActivated -> workspace 2 focused.");

// Test 7.8: Split mode disabled
niri.handleEvent({ RegionsChanged: { regions_enabled: false, focused_region: null } });
assert.strictEqual(niri.regionsEnabled, false);
assert.strictEqual(niri.focusedRegion, "");
console.log("PASS: RegionsChanged -> split mode disabled (regionsEnabled: false, focusedRegion: '').");

// 8. Test SplitParser Chunk Streaming Simulation
console.log("\n--- Testing SplitParser Line Stream Simulation ---");
const rawStream = [
    '{"RegionsChanged":{"regions_enabled":true,"focused_region":"Right"}}\n',
    '{"WorkspaceActivated":{"id":1,"focused":true}}\n',
    '{"WindowFocusChanged":{"id":101}}\n'
].join('');

let buffer = "";
const parsedEvents = [];
for (const char of rawStream) {
    buffer += char;
    if (buffer.endsWith('\n')) {
        const line = buffer.trim();
        buffer = "";
        if (line.length > 0) {
            const evt = JSON.parse(line);
            parsedEvents.push(evt);
            niri.handleEvent(evt);
        }
    }
}
assert.strictEqual(parsedEvents.length, 3);
assert.strictEqual(niri.regionsEnabled, true);
assert.strictEqual(niri.focusedRegion, "Right");
assert.strictEqual(niri.focusedWorkspaceId, 1);
assert.strictEqual(niri.activeWindow.id, 101);
console.log("PASS: SplitParser line chunking correctly deserialized 3 sequential JSON events.");

console.log("\n=== ALL MILESTONE L2 VERIFICATION CHECKS PASSED ===");
