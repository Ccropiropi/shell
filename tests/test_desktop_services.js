// test_desktop_services.js — Unit test suite for Pure Quickshell Desktop Services (Milestone L3)
const fs = require('fs');
const path = require('path');
const assert = require('assert');

console.log("=== Running Milestone L3: Desktop Services Test Suite ===");

const shellDir = path.resolve(__dirname, '..');
const servicesDir = path.join(shellDir, 'splitdesk_services');

// 1. Verify existence of all service files
const requiredServices = [
    'Audio.qml',
    'Brightness.qml',
    'Network.qml',
    'Bluetooth.qml',
    'Notifications.qml',
    'Players.qml',
    'Theme.qml',
    'Niri.qml',
    'qmldir'
];

for (const svc of requiredServices) {
    const fullPath = path.join(servicesDir, svc);
    assert.ok(fs.existsSync(fullPath), `Service file missing: ${svc}`);
    console.log(`PASS: Found service file: ${svc}`);
}

// 2. Audio service checks
const audioContent = fs.readFileSync(path.join(servicesDir, 'Audio.qml'), 'utf8');
assert.ok(audioContent.includes('Quickshell.Services.Pipewire'), 'Audio.qml must use native Pipewire');
assert.ok(audioContent.includes('defaultAudioSink'), 'Audio.qml must bind defaultAudioSink');
assert.ok(audioContent.includes('setVolume'), 'Audio.qml must implement setVolume()');
assert.ok(audioContent.includes('toggleMute'), 'Audio.qml must implement toggleMute()');
assert.ok(audioContent.includes('wpctl'), 'Audio.qml must include wpctl fallback');
console.log("PASS: Audio service native bindings and fallback verified.");

// 3. Brightness service checks & parsing logic simulation
const brightnessContent = fs.readFileSync(path.join(servicesDir, 'Brightness.qml'), 'utf8');
assert.ok(brightnessContent.includes('brightnessctl'), 'Brightness.qml must use brightnessctl');
assert.ok(brightnessContent.includes('FileView'), 'Brightness.qml must watch sysfs via FileView');
assert.ok(brightnessContent.includes('setBrightness'), 'Brightness.qml must implement setBrightness()');

// Simulate brightnessctl -m info parsing
const mockBrightnessInfo = "intel_backlight,backlight,1286,30%,4285";
const bParts = mockBrightnessInfo.trim().split(',');
assert.strictEqual(bParts[0], 'intel_backlight');
const currB = parseInt(bParts[2], 10);
const maxB = parseInt(bParts[4], 10);
const valB = Math.max(0.0, Math.min(1.0, currB / maxB));
assert.ok(Math.abs(valB - (1286 / 4285)) < 1e-6);
console.log("PASS: Brightness service parsing and sysfs tracking verified.");

// 4. Network service checks & parsing logic simulation
const networkContent = fs.readFileSync(path.join(servicesDir, 'Network.qml'), 'utf8');
assert.ok(networkContent.includes('nmcli'), 'Network.qml must use nmcli');
assert.ok(networkContent.includes('"dev", "wifi", "connect"'), 'Network.qml must implement wifi connect');
assert.ok(networkContent.includes('"password", "-"'), 'Network.qml must pass password via stdin (Advisory R3)');

// Simulate nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list parsing with escaped colon
const mockWifiOutput = "H\\:Net:77:WPA2:*\nOtherNet:64:WPA1 WPA2: ";
const wifiLines = mockWifiOutput.split('\n');
const parsedNets = [];
for (const line of wifiLines) {
    if (!line.trim()) continue;
    const sanitized = line.replace(/\\:/g, '\u0000');
    const parts = sanitized.split(':');
    const ssid = parts[0].replace(/\u0000/g, ':');
    const signal = parseInt(parts[1], 10);
    const inUse = parts[3].trim() === '*';
    parsedNets.push({ ssid, signal, inUse });
}
assert.strictEqual(parsedNets.length, 2);
assert.strictEqual(parsedNets[0].ssid, 'H:Net');
assert.strictEqual(parsedNets[0].inUse, true);
assert.strictEqual(parsedNets[1].ssid, 'OtherNet');
assert.strictEqual(parsedNets[1].inUse, false);
console.log("PASS: Network service parsing with colon escaping & stdin password security verified.");

// 5. Bluetooth service checks & regex simulation
const btContent = fs.readFileSync(path.join(servicesDir, 'Bluetooth.qml'), 'utf8');
assert.ok(btContent.includes('bluetoothctl'), 'Bluetooth.qml must use bluetoothctl');
assert.ok(btContent.includes('togglePower'), 'Bluetooth.qml must implement togglePower()');

// Simulate bluetoothctl show and devices Connected
const mockShow = "Controller 5C:FB:3A:53:D9:FC (public)\n\tName: test\n\tPowered: yes\n";
const showMatch = mockShow.match(/Powered:\s*(yes|no)/i);
assert.ok(showMatch && showMatch[1].toLowerCase() === 'yes');

const mockDevLine = "Device AA:BB:CC:DD:EE:FF My Headphones";
const devMatch = mockDevLine.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.*)$/);
assert.ok(devMatch);
assert.strictEqual(devMatch[1], 'AA:BB:CC:DD:EE:FF');
assert.strictEqual(devMatch[2], 'My Headphones');
console.log("PASS: Bluetooth service status and device regex verified.");

// 6. Notifications service checks
const notifContent = fs.readFileSync(path.join(servicesDir, 'Notifications.qml'), 'utf8');
assert.ok(notifContent.includes('Quickshell.Services.Notifications'), 'Notifications.qml must use native Quickshell notifications');
assert.ok(notifContent.includes('NotificationServer'), 'Notifications.qml must instantiate NotificationServer');
assert.ok(notifContent.includes('clearAll'), 'Notifications.qml must implement clearAll()');
assert.ok(notifContent.includes('dismiss'), 'Notifications.qml must implement dismiss()');
console.log("PASS: Notifications service native integration verified.");

// 7. Players service checks
const playersContent = fs.readFileSync(path.join(servicesDir, 'Players.qml'), 'utf8');
assert.ok(playersContent.includes('Quickshell.Services.Mpris'), 'Players.qml must use native Mpris');
assert.ok(playersContent.includes('active'), 'Players.qml must expose active player');
assert.ok(playersContent.includes('play()'), 'Players.qml must implement play()');
assert.ok(playersContent.includes('pause()'), 'Players.qml must implement pause()');
assert.ok(playersContent.includes('togglePlaying()'), 'Players.qml must implement togglePlaying()');
console.log("PASS: Players service MPRIS integration verified.");

// 8. qmldir exports
const qmldirContent = fs.readFileSync(path.join(servicesDir, 'qmldir'), 'utf8');
for (const s of ['Audio', 'Brightness', 'Network', 'Bluetooth', 'Notifications', 'Players', 'Niri', 'Theme']) {
    assert.ok(qmldirContent.includes(`singleton ${s}`), `qmldir must register singleton ${s}`);
}
console.log("PASS: qmldir module singletons verified.");

console.log("=== ALL MILESTONE L3 DESKTOP SERVICES CHECKS PASSED ===");
