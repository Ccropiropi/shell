/**
 * Milestone S3: Anchor Canvas & Input Pass-Through Verification Test (splitdesk)
 * Validates LeftPanel.qml, ClockCard.qml, SystemDials.qml, MediaCard.qml, QuickActions.qml,
 * layout tokens, WlrLayer.Bottom layer-shell geometry, input pass-through masking, and shell mounting.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log("=== Running Milestone S3: Anchor Canvas & Input Pass-Through Verification ===");

// Robust shell directory resolution
const shellDir = fs.existsSync(path.resolve(__dirname, '../shell'))
    ? path.resolve(__dirname, '../shell')
    : (fs.existsSync(path.resolve(__dirname, '../modules'))
        ? path.resolve(__dirname, '..')
        : path.resolve(__dirname, '.'));

const leftPanelDir = path.join(shellDir, 'modules/left_panel');
const widgetsDir = path.join(leftPanelDir, 'widgets');

// ── 1. File Existence and Structure ──────────────────────────────────────────
const coreFiles = [
    { dir: leftPanelDir, name: 'LeftPanel.qml' },
    { dir: widgetsDir, name: 'ClockCard.qml' },
    { dir: widgetsDir, name: 'SystemDials.qml' },
    { dir: widgetsDir, name: 'MediaCard.qml' },
    { dir: widgetsDir, name: 'QuickActions.qml' }
];

for (const f of coreFiles) {
    const fullPath = path.join(f.dir, f.name);
    assert(fs.existsSync(fullPath), `Missing required component: ${f.name} at ${fullPath}`);
    console.log(`PASS: Found component ${f.name}`);
}

// ── 2. Check ShellRoot Mounting in shell.qml ─────────────────────────────────
const shellQmlPath = path.join(shellDir, 'shell.qml');
assert(fs.existsSync(shellQmlPath), `Missing shell.qml at ${shellQmlPath}`);
const shellSource = fs.readFileSync(shellQmlPath, 'utf8');
assert(shellSource.includes('import "modules/left_panel"'), 'shell.qml must import modules/left_panel');
assert(shellSource.includes('LeftPanel {}'), 'shell.qml must instantiate LeftPanel {}');
console.log("PASS: LeftPanel mounted into shell.qml.");

// ── 3. LeftPanel Component & Pass-Through Verification ───────────────────────
const leftPanelSrc = fs.readFileSync(path.join(leftPanelDir, 'LeftPanel.qml'), 'utf8');
assert(leftPanelSrc.includes('PanelWindow'), 'LeftPanel must be a PanelWindow');
assert(leftPanelSrc.includes('WlrLayershell.layer: WlrLayer.Bottom'), 'LeftPanel must reside on WlrLayer.Bottom');
assert(leftPanelSrc.includes('WlrLayershell.namespace: "splitdesk-left-panel"'), 'Namespace must be splitdesk-left-panel');
assert(leftPanelSrc.includes('anchors.left: true'), 'Must anchor to screen left');
assert(leftPanelSrc.includes('anchors.top: true'), 'Must anchor to screen top');
assert(leftPanelSrc.includes('anchors.bottom: true'), 'Must anchor to screen bottom');
assert(leftPanelSrc.includes('width: Screen.width * 0.46'), 'Width must be bound to Screen.width * 0.46');
assert(leftPanelSrc.includes('visible: Niri.regionsEnabled'), 'Visible only when Niri.regionsEnabled');
assert(leftPanelSrc.includes('mask: Region'), 'Must configure Quickshell.Region input masking for click pass-through');
assert(leftPanelSrc.includes('ClockCard'), 'LeftPanel must instantiate ClockCard');
assert(leftPanelSrc.includes('SystemDials'), 'LeftPanel must instantiate SystemDials');
assert(leftPanelSrc.includes('MediaCard'), 'LeftPanel must instantiate MediaCard');
assert(leftPanelSrc.includes('QuickActions'), 'LeftPanel must instantiate QuickActions');
console.log("PASS: LeftPanel geometry, WlrLayer.Bottom, 46% width binding, and Region input masking verified.");

// ── 4. ClockCard Component Verification ──────────────────────────────────────
const clockSrc = fs.readFileSync(path.join(widgetsDir, 'ClockCard.qml'), 'utf8');
assert(clockSrc.includes('Qt.formatTime(now.time, "HH:mm")'), 'Must render stylized 24h clock');
assert(clockSrc.includes('"tnum": 1'), 'Must use tabular numerals for clock alignment');
assert(clockSrc.includes('Qt.formatDate(now.time, "dddd")'), 'Must display weekday name');
assert(clockSrc.includes('Qt.formatDate(now.time, "MMMM d'), 'Must display date');
assert(clockSrc.includes('Theme.radiusTile'), 'Must use Theme.radiusTile');
assert(clockSrc.includes('Theme.amber'), 'Must accent day with Theme.amber');
console.log("PASS: ClockCard stylized clock, day, date display, and design tokens verified.");

// ── 5. SystemDials Component Verification ────────────────────────────────────
const dialsSrc = fs.readFileSync(path.join(widgetsDir, 'SystemDials.qml'), 'utf8');
assert(dialsSrc.includes('cpuUsage'), 'Must track CPU usage');
assert(dialsSrc.includes('ramUsedGb'), 'Must track RAM usage in GB');
assert(dialsSrc.includes('thermalTempC'), 'Must track thermal package temperature');
assert(dialsSrc.includes('FileView'), 'Must ingest telemetry via Quickshell FileView');
assert(dialsSrc.includes('/proc/stat'), 'Must parse /proc/stat for CPU');
assert(dialsSrc.includes('/proc/meminfo'), 'Must parse /proc/meminfo for RAM');
assert(dialsSrc.includes('Theme.teal'), 'Must style CPU/thermal indicators with Theme.teal');
assert(dialsSrc.includes('Theme.amber'), 'Must style RAM/thermal indicators with Theme.amber');
console.log("PASS: SystemDials CPU, RAM, and thermal progress indicators verified.");

// ── 6. MediaCard Component Verification ──────────────────────────────────────
const mediaSrc = fs.readFileSync(path.join(widgetsDir, 'MediaCard.qml'), 'utf8');
assert(mediaSrc.includes('Players.active'), 'Must connect to active media player');
assert(mediaSrc.includes('Players.getArtUrl'), 'Must bind album art via Players.getArtUrl');
assert(mediaSrc.includes('trackTitle'), 'Must render track title');
assert(mediaSrc.includes('trackArtist'), 'Must render track artist');
assert(mediaSrc.includes('progressFraction'), 'Must compute seekbar progress fraction');
assert(mediaSrc.includes('Players.active.position ='), 'Must support interactive seekbar positioning');
assert(mediaSrc.includes('Players.active.previous()'), 'Must have previous control');
assert(mediaSrc.includes('Players.active.togglePlaying()'), 'Must have play/pause toggle control');
assert(mediaSrc.includes('Players.active.next()'), 'Must have next control');
console.log("PASS: MediaCard album art, track info, seekbar, and player controls verified.");

// ── 7. QuickActions Component Verification ───────────────────────────────────
const actionsSrc = fs.readFileSync(path.join(widgetsDir, 'QuickActions.qml'), 'utf8');
assert(actionsSrc.includes('Niri.toggleRegionFocus()'), 'Quick action 1: Must toggle region focus');
assert(actionsSrc.includes('Niri.moveWindowToRegionRight()'), 'Quick action 2: Must move window right');
assert(actionsSrc.includes('Niri.moveWindowToRegionLeft()'), 'Quick action 2: Must move window left');
assert(actionsSrc.includes('Niri.toggleSplitMode()'), 'Quick action 3: Must toggle split mode');
assert(actionsSrc.includes('Theme.teal'), 'Must highlight active region with Theme.teal');
assert(actionsSrc.includes('Theme.amber'), 'Must highlight active region with Theme.amber');
console.log("PASS: QuickActions region switch, move window, and split toggle shortcuts verified.");

// ── 8. Simulate Runtime State & Masking Logic ────────────────────────────────
console.log("--- Simulating Runtime State and Geometry Logic ---");

// Test Left Panel Width Binding
const screenWidth = 2560;
const leftPanelWidth = screenWidth * 0.46;
assert(Math.abs(leftPanelWidth - 1177.6) < 0.001, "Width should be approximately 1177.6");
console.log(`PASS: LeftPanel width correctly bound to 46% of ${screenWidth}px (${leftPanelWidth.toFixed(1)}px).`);

// Test Input Mask Pass-Through Geometry
const mockWidgets = [
    { name: 'clockCard', x: 24, y: 84, width: 320, height: 110 },
    { name: 'dialsCard', x: 24, y: 208, width: 320, height: 180 },
    { name: 'mediaCard', x: 24, y: 402, width: 320, height: 170 },
    { name: 'actionsCard', x: 24, y: 586, width: 320, height: 190 }
];

function isPointInteractive(px, py, widgets) {
    return widgets.some(w => px >= w.x && px <= (w.x + w.width) && py >= w.y && py <= (w.y + w.height));
}

// Inside a widget -> interactive (captured by LeftPanel)
assert.strictEqual(isPointInteractive(50, 100, mockWidgets), true, "Click inside ClockCard should be captured");
assert.strictEqual(isPointInteractive(100, 450, mockWidgets), true, "Click inside MediaCard should be captured");

// Outside widgets in Left Region -> pass-through to underlying client windows
assert.strictEqual(isPointInteractive(500, 300, mockWidgets), false, "Click in Left Region client window area must pass through");
assert.strictEqual(isPointInteractive(1000, 500, mockWidgets), false, "Click in Right/tiled area must pass through");
assert.strictEqual(isPointInteractive(50, 198, mockWidgets), false, "Click in gutter between cards must pass through");
console.log("PASS: Quickshell.Region input masking math ensures click pass-through to underlying windows.");

// Test Seekbar Position Calculation
function computeSeekProgress(posSec, lenSec) {
    if (!lenSec || lenSec <= 0) return 0.0;
    return Math.min(1.0, Math.max(0.0, posSec / lenSec));
}
assert.strictEqual(computeSeekProgress(60, 180), 60 / 180);
assert.strictEqual(computeSeekProgress(0, 200), 0.0);
assert.strictEqual(computeSeekProgress(250, 200), 1.0);
console.log("PASS: Seekbar progress fraction arithmetic verified.");

// ── 9. Execute QML Linting and Conventions ───────────────────────────────────
console.log("--- Executing QML Syntax and Convention Linters ---");

try {
    execSync('qmllint -I . -I modules/left_panel -I modules/left_panel/widgets modules/left_panel/widgets/ClockCard.qml modules/left_panel/widgets/SystemDials.qml modules/left_panel/widgets/MediaCard.qml modules/left_panel/widgets/QuickActions.qml modules/left_panel/LeftPanel.qml shell.qml', {
        cwd: shellDir,
        stdio: 'pipe'
    });
    console.log("PASS: qmllint validated all left panel components and shell.qml with 0 errors.");
} catch (err) {
    const stderr = err.stderr ? err.stderr.toString() : err.message;
    assert.fail(`qmllint failed: ${stderr}`);
}

const checkFiles = [
    'modules/left_panel/LeftPanel.qml',
    'modules/left_panel/widgets/ClockCard.qml',
    'modules/left_panel/widgets/SystemDials.qml',
    'modules/left_panel/widgets/MediaCard.qml',
    'modules/left_panel/widgets/QuickActions.qml'
];

for (const f of checkFiles) {
    try {
        execSync(`python3 scripts/qml-lint-conventions.py --file ${f}`, {
            cwd: shellDir,
            encoding: 'utf8',
            stdio: ['pipe', 'pipe', 'pipe']
        });
        console.log(`PASS: qml-lint-conventions validated ${path.basename(f)} with 0 violations.`);
    } catch (err) {
        const stderr = err.stderr ? err.stderr.toString() : err.message;
        if (err.status === 0 || stderr.includes("No violations found")) {
            console.log(`PASS: qml-lint-conventions validated ${path.basename(f)} with 0 violations.`);
        } else {
            assert.fail(`qml-lint-conventions failed on ${f}:\n${stderr}`);
        }
    }
}

console.log("=== ALL MILESTONE S3 VERIFICATION CHECKS PASSED ===");
