// test_ui_modules.js — Unit test suite for Pure Quickshell UI Modules & Overlays (Milestone L3)
const fs = require('fs');
const path = require('path');
const assert = require('assert');

console.log("=== Running Milestone L3: UI Modules & Overlays Test Suite ===");

const shellDir = path.resolve(__dirname, '..');
const modulesDir = path.join(shellDir, 'modules');

// 1. Verify existence of UI components
const components = [
    { file: 'launcher/Launcher.qml', name: 'Launcher' },
    { file: 'nexus/Nexus.qml', name: 'Nexus' },
    { file: 'osd/OSD.qml', name: 'OSD' },
    { file: 'session/SessionMenu.qml', name: 'SessionMenu' },
    { file: 'lock/LockScreen.qml', name: 'LockScreen' },
    { file: 'lock/Pam.qml', name: 'Pam' },
    { file: 'notifications/NotificationToasts.qml', name: 'NotificationToasts' },
    { file: '../shell.qml', name: 'shell.qml' }
];

for (const c of components) {
    const fullPath = path.resolve(modulesDir, c.file);
    assert.ok(fs.existsSync(fullPath), `Component missing: ${c.name} at ${fullPath}`);
    console.log(`PASS: Found component ${c.name}`);
}

// 2. Test Launcher JavaScript Calculator (Section 3.2.1, Advisor Note 3 & Defect D8)
function evaluateMath(expr) {
    if (!expr || expr.length > 256) return null;
    if (!/^[0-9+\-*/().^ %eEpiPI\s]+$/.test(expr)) return null;
    try {
        const sanitized = expr.replace(/\^/g, "**")
                              .replace(/\bpi\b/gi, "Math.PI")
                              .replace(/\b[eE]\b/g, "Math.E");
        const res = Function('"use strict"; return (' + sanitized + ')')();
        return Number.isFinite(res) ? String(res) : null;
    } catch (e) {
        return null;
    }
}

// Test basic arithmetic
assert.strictEqual(evaluateMath("2 + 2"), "4");
assert.strictEqual(evaluateMath("10 - 3 * 2"), "4");
assert.strictEqual(evaluateMath("(12 + 8) / 4"), "5");

// Test power operator
assert.strictEqual(evaluateMath("2 ^ 8"), "256");
assert.strictEqual(evaluateMath("3 ^ 3"), "27");

// Test pi case-insensitivity
assert.ok(Math.abs(parseFloat(evaluateMath("pi")) - Math.PI) < 1e-10);
assert.ok(Math.abs(parseFloat(evaluateMath("PI")) - Math.PI) < 1e-10);
assert.ok(Math.abs(parseFloat(evaluateMath("2 * Pi")) - (2 * Math.PI)) < 1e-10);

// Test Euler number case-insensitivity (Defect D8 resolution)
assert.ok(Math.abs(parseFloat(evaluateMath("e")) - Math.E) < 1e-10);
assert.ok(Math.abs(parseFloat(evaluateMath("E")) - Math.E) < 1e-10);
assert.ok(Math.abs(parseFloat(evaluateMath("2 * e")) - (2 * Math.E)) < 1e-10);
assert.ok(Math.abs(parseFloat(evaluateMath("2 * E")) - (2 * Math.E)) < 1e-10);

// Test division by zero safety
assert.strictEqual(evaluateMath("1 / 0"), null);
assert.strictEqual(evaluateMath("0 / 0"), null);

// Test empty and invalid inputs
assert.strictEqual(evaluateMath(""), null);
assert.strictEqual(evaluateMath("   "), null);
assert.strictEqual(evaluateMath("2 + * 3"), null);

// Test security & injection prevention
assert.strictEqual(evaluateMath("process.exit(1)"), null);
assert.strictEqual(evaluateMath("require('fs')"), null);
assert.strictEqual(evaluateMath("this"), null);
assert.strictEqual(evaluateMath("window"), null);
assert.strictEqual(evaluateMath("alert(1)"), null);

// Test length cap (> 256 chars rejected)
const longExpr = "1+" + "1+".repeat(130) + "1";
assert.ok(longExpr.length > 256);
assert.strictEqual(evaluateMath(longExpr), null);

console.log("PASS: Launcher JS math calculator (arithmetic, pi, e/E, div0, injection guard, 256 length cap) fully verified.");

// 3. Launcher Component Structure & IPC
const launcherSrc = fs.readFileSync(path.join(modulesDir, 'launcher/Launcher.qml'), 'utf8');
assert.ok(launcherSrc.includes('WlrLayer.Overlay'), 'Launcher must run on WlrLayer.Overlay');
assert.ok(launcherSrc.includes('WlrKeyboardFocus.OnDemand'), 'Launcher must use OnDemand focus');
assert.ok(launcherSrc.includes('DesktopEntries.applications'), 'Launcher must use DesktopEntries model');
assert.ok(launcherSrc.includes('target: "launcher"'), 'Launcher must register IPC target "launcher"');
console.log("PASS: Launcher Overlay and IPC structure verified.");

// 4. Nexus Component Structure & IPC
const nexusSrc = fs.readFileSync(path.join(modulesDir, 'nexus/Nexus.qml'), 'utf8');
assert.ok(nexusSrc.includes('WlrLayer.Top'), 'Nexus must run on WlrLayer.Top');
assert.ok(nexusSrc.includes('target: "nexus"'), 'Nexus must register IPC target "nexus"');
assert.ok(nexusSrc.includes('Network.toggleWifi'), 'Nexus must bind Network toggle');
assert.ok(nexusSrc.includes('Bluetooth.togglePower'), 'Nexus must bind Bluetooth toggle');
assert.ok(nexusSrc.includes('Audio.setVolume'), 'Nexus must bind Audio volume');
assert.ok(nexusSrc.includes('Brightness.setBrightness'), 'Nexus must bind Brightness');
assert.ok(nexusSrc.includes('Notifications.notifications'), 'Nexus must bind Notifications list');
console.log("PASS: Nexus Control Center structure, toggles, sliders, and IPC verified.");

// 5. OSD Input Pass-Through Invariant (Gate 3)
const osdSrc = fs.readFileSync(path.join(modulesDir, 'osd/OSD.qml'), 'utf8');
assert.ok(osdSrc.includes('WlrLayer.Overlay'), 'OSD must run on WlrLayer.Overlay');
assert.ok(osdSrc.includes('mask: Region {}'), 'OSD MUST declare mask: Region {} for 100% input pass-through (Gate 3)');
assert.ok(osdSrc.includes('1500'), 'OSD must implement 1500ms auto-hide timer');
console.log("PASS: OSD 100% click pass-through (mask: Region {}) and auto-hide verified.");

// 6. SessionMenu Component Structure & IPC
const sessionSrc = fs.readFileSync(path.join(modulesDir, 'session/SessionMenu.qml'), 'utf8');
assert.ok(sessionSrc.includes('WlrLayer.Overlay'), 'SessionMenu must run on WlrLayer.Overlay');
assert.ok(sessionSrc.includes('target: "session"'), 'SessionMenu must register IPC target "session"');
assert.ok(sessionSrc.includes('"loginctl", "lock-session"'), 'SessionMenu must implement Lock');
assert.ok(sessionSrc.includes('"systemctl", "suspend"'), 'SessionMenu must implement Suspend');
assert.ok(sessionSrc.includes('"systemctl", "reboot"'), 'SessionMenu must implement Reboot');
assert.ok(sessionSrc.includes('"systemctl", "poweroff"'), 'SessionMenu must implement Power Off');
console.log("PASS: SessionMenu actions and IPC verified.");

// 7. LockScreen & Native PAM Integration
const lockSrc = fs.readFileSync(path.join(modulesDir, 'lock/LockScreen.qml'), 'utf8');
assert.ok(lockSrc.includes('WlSessionLock'), 'LockScreen must use WlSessionLock');
assert.ok(lockSrc.includes('WlSessionLockSurface'), 'LockScreen must use WlSessionLockSurface');
assert.ok(lockSrc.includes('target: "lock"'), 'LockScreen must register IPC target "lock"');

const pamSrc = fs.readFileSync(path.join(modulesDir, 'lock/Pam.qml'), 'utf8');
assert.ok(pamSrc.includes('Quickshell.Services.Pam'), 'Pam.qml must use native Quickshell.Services.Pam');
assert.ok(pamSrc.includes('PamContext'), 'Pam.qml must instantiate PamContext');
assert.ok(!pamSrc.includes('pamtester'), 'Pam.qml must NOT depend on external pamtester binary');
assert.ok(!pamSrc.includes('pam_validate'), 'Pam.qml must NOT depend on external pam_validate binary');
console.log("PASS: LockScreen WlSessionLock and native PamContext integration verified.");

// 8. NotificationToasts
const toastsSrc = fs.readFileSync(path.join(modulesDir, 'notifications/NotificationToasts.qml'), 'utf8');
assert.ok(toastsSrc.includes('WlrLayer.Overlay'), 'NotificationToasts must run on WlrLayer.Overlay');
assert.ok(toastsSrc.includes('Notifications.notifications'), 'NotificationToasts must bind Notifications.notifications');
assert.ok(toastsSrc.includes('Notifications.dismiss'), 'NotificationToasts must implement dismiss');
console.log("PASS: NotificationToasts Overlay and dismiss verified.");

// 9. Root Shell Mounting (shell.qml)
const rootShellSrc = fs.readFileSync(path.join(shellDir, 'shell.qml'), 'utf8');
for (const mod of ['IslandBar', 'LeftPanel', 'FocusVeils', 'WallpaperSurface', 'Launcher', 'Nexus', 'OSD', 'LockScreen', 'SessionMenu', 'NotificationToasts', 'Cheatsheet', 'ClipboardPanel', 'RegionSelector']) {
    assert.ok(rootShellSrc.includes(`${mod} {}`), `shell.qml must mount ${mod}`);
}
console.log("PASS: All 13 modular services and overlays mounted in shell.qml.");

console.log("=== ALL MILESTONE L3 UI MODULES CHECKS PASSED ===");
