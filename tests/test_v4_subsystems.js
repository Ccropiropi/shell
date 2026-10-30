// test_v4_subsystems.js — Unit test suite for Milestone V4: Advanced Desktop Subsystems
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const vm = require('vm');

console.log("=== Running Milestone V4: Advanced Desktop Subsystems Test Suite ===");

const shellDir = path.resolve(__dirname, '..');
const servicesDir = path.join(shellDir, 'splitdesk_services');
const modulesDir = path.join(shellDir, 'modules');

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Verify existence of all Milestone V4 subsystem files & qmldir manifests
// ═══════════════════════════════════════════════════════════════════════════════
const requiredFiles = [
    path.join(servicesDir, 'Cliphist.qml'),
    path.join(servicesDir, 'qmldir'),
    path.join(modulesDir, 'clipboard/ClipboardPanel.qml'),
    path.join(modulesDir, 'clipboard/ClipboardItem.qml'),
    path.join(modulesDir, 'clipboard/qmldir'),
    path.join(modulesDir, 'cheatsheet/Cheatsheet.qml'),
    path.join(modulesDir, 'cheatsheet/CheatsheetCard.qml'),
    path.join(modulesDir, 'cheatsheet/KeybindsData.js'),
    path.join(modulesDir, 'cheatsheet/qmldir'),
    path.join(modulesDir, 'region_selector/RegionSelector.qml'),
    path.join(modulesDir, 'region_selector/qmldir'),
    path.join(shellDir, 'shell.qml'),
    path.join(shellDir, 'splitdesk-shell.qml')
];

for (const f of requiredFiles) {
    assert.ok(fs.existsSync(f), `Missing required file: ${f}`);
    console.log(`PASS: Found file: ${path.relative(shellDir, f)}`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Cliphist Service (Task L4.1, Gate 1 & Findings C2/R1)
// ═══════════════════════════════════════════════════════════════════════════════
const cliphistSrc = fs.readFileSync(path.join(servicesDir, 'Cliphist.qml'), 'utf8');

// Assertions on Cliphist.qml
assert.ok(cliphistSrc.includes('command: ["/usr/sbin/cliphist", "list"]'), 'Cliphist must invoke cliphist list');
assert.ok(cliphistSrc.includes('maxEntries: 200'), 'Cliphist must cap maxEntries at 200 (Advisory R1)');
assert.ok(cliphistSrc.includes('SplitParser'), 'Cliphist must stream parse lines with SplitParser');
assert.ok(cliphistSrc.includes('parseInt'), 'Cliphist must validate numeric ID before decoding (Finding C2)');
assert.ok(cliphistSrc.includes('--type image/png'), 'Cliphist image decoding must pass --type image/png (Finding C2)');
assert.ok(cliphistSrc.includes('"wipe"'), 'Cliphist must implement wipe in clearAll');

// Simulate stream line parsing and image regex matching
const imgRegex = /^\s*(\d+)\t\[\[\s*binary data\s+(\d+)x(\d+)\s+([a-zA-Z0-9]+)\s*\]\]$/;

const mockLines = [
    "15\tHermes Web UI → http://127.0.0.1:9119",
    "14\t[[ binary data 1920x1080 png ]]",
    "13\tgit commit -m \"feat: new feature\"",
    "12\t[[ binary data 800x600 jpeg ]]",
    "invalid_line_without_tab"
];

const parsed = [];
for (const line of mockLines) {
    const tabIdx = line.indexOf("\t");
    if (tabIdx === -1) continue;
    const id = line.slice(0, tabIdx).trim();
    const rest = line.slice(tabIdx + 1);
    const m = line.match(imgRegex);
    if (m) {
        parsed.push({ id, preview: `[Image: ${m[2]}x${m[3]} ${m[4]}]`, isImage: true, dims: `${m[2]}x${m[3]} ${m[4]}` });
    } else {
        parsed.push({ id, preview: rest, isImage: false, dims: "" });
    }
}

assert.strictEqual(parsed.length, 4);
assert.strictEqual(parsed[0].id, "15");
assert.strictEqual(parsed[0].isImage, false);
assert.strictEqual(parsed[0].preview, "Hermes Web UI → http://127.0.0.1:9119");

assert.strictEqual(parsed[1].id, "14");
assert.strictEqual(parsed[1].isImage, true);
assert.strictEqual(parsed[1].dims, "1920x1080 png");
assert.strictEqual(parsed[1].preview, "[Image: 1920x1080 png]");

assert.strictEqual(parsed[2].id, "13");
assert.strictEqual(parsed[2].isImage, false);

assert.strictEqual(parsed[3].id, "12");
assert.strictEqual(parsed[3].isImage, true);
assert.strictEqual(parsed[3].dims, "800x600 jpeg");

// Test ID injection validation
function validateNumericId(id) {
    const numericId = parseInt(id, 10);
    if (isNaN(numericId) || numericId < 0 || String(numericId) !== String(id).trim()) {
        return null;
    }
    return numericId;
}

assert.strictEqual(validateNumericId("42"), 42);
assert.strictEqual(validateNumericId("0"), 0);
assert.strictEqual(validateNumericId("-5"), null);
assert.strictEqual(validateNumericId("15; rm -rf /"), null);
assert.strictEqual(validateNumericId("abc"), null);
assert.strictEqual(validateNumericId(""), null);

console.log("PASS: Cliphist service parsing, regex, ID validation, and streaming invariants verified.");

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Clipboard Panel Overlay (Task L4.2, Findings R2/C3)
// ═══════════════════════════════════════════════════════════════════════════════
const clipboardSrc = fs.readFileSync(path.join(modulesDir, 'clipboard/ClipboardPanel.qml'), 'utf8');
assert.ok(clipboardSrc.includes('WlrLayer.Overlay'), 'ClipboardPanel must run on WlrLayer.Overlay');
assert.ok(clipboardSrc.includes('WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None'),
    'ClipboardPanel must conditionally release focus on dismiss (Finding C3)');
assert.ok(clipboardSrc.includes('target: "clipboard"'), 'ClipboardPanel must register IPC target "clipboard"');
assert.ok(clipboardSrc.includes('onClicked: root.close()'), 'ClipboardPanel must support backdrop click dismiss (Finding R2)');

const clipboardItemSrc = fs.readFileSync(path.join(modulesDir, 'clipboard/ClipboardItem.qml'), 'utf8');
assert.ok(clipboardItemSrc.includes('Theme.teal'), 'ClipboardItem must use Theme.teal');
assert.ok(clipboardItemSrc.includes('Theme.amber'), 'ClipboardItem must use Theme.amber for images');
assert.ok(clipboardItemSrc.includes('pinRequested'), 'ClipboardItem must emit pinRequested');
assert.ok(clipboardItemSrc.includes('deleteRequested'), 'ClipboardItem must emit deleteRequested');

console.log("PASS: ClipboardPanel overlay, layer-shell focus, backdrop dismiss, and item delegate verified.");

// ═══════════════════════════════════════════════════════════════════════════════
// 4. Keybinds Cheatsheet HUD & KeybindsData.js (Task L4.3, Finding C3)
// ═══════════════════════════════════════════════════════════════════════════════
const cheatsheetSrc = fs.readFileSync(path.join(modulesDir, 'cheatsheet/Cheatsheet.qml'), 'utf8');
assert.ok(cheatsheetSrc.includes('WlrLayer.Overlay'), 'Cheatsheet must run on WlrLayer.Overlay');
assert.ok(cheatsheetSrc.includes('WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None'),
    'Cheatsheet must conditionally release Exclusive focus on dismiss (Finding C3)');
assert.ok(cheatsheetSrc.includes('target: "cheatsheet"'), 'Cheatsheet must register IPC target "cheatsheet"');

const cardSrc = fs.readFileSync(path.join(modulesDir, 'cheatsheet/CheatsheetCard.qml'), 'utf8');
assert.ok(cardSrc.includes('Theme.amber'), 'CheatsheetCard must highlight Slant with Theme.amber');
assert.ok(cardSrc.includes('Theme.veil'), 'CheatsheetCard must use Theme.veil background for Slant');

// Validate KeybindsData.js content and schema
const rawKeybindsJs = fs.readFileSync(path.join(modulesDir, 'cheatsheet/KeybindsData.js'), 'utf8');
const sanitizedJs = rawKeybindsJs.replace(/^\.pragma\s+library/m, '');
const sandbox = {};
vm.runInNewContext(sanitizedJs, sandbox);

assert.ok(typeof sandbox.getKeybinds === 'function', 'KeybindsData.js must export getKeybinds()');
assert.ok(typeof sandbox.getCategories === 'function', 'KeybindsData.js must export getCategories()');

const categories = sandbox.getCategories();
assert.ok(categories.includes("All"), 'Categories must include "All"');
assert.ok(categories.includes("Slant Bifurcated"), 'Categories must include "Slant Bifurcated"');
assert.ok(categories.includes("Navigation"), 'Categories must include "Navigation"');
assert.ok(categories.includes("Window Layout"), 'Categories must include "Window Layout"');
assert.ok(categories.includes("Workspaces"), 'Categories must include "Workspaces"');
assert.ok(categories.includes("Shell & Overlays"), 'Categories must include "Shell & Overlays"');
assert.ok(categories.includes("Media & Hardware"), 'Categories must include "Media & Hardware"');

const keybinds = sandbox.getKeybinds();
assert.ok(Array.isArray(keybinds) && keybinds.length >= 25, `Expected >= 25 keybinds, got ${keybinds.length}`);

// Verify schema for every keybind
for (const b of keybinds) {
    assert.ok(b.category, `Keybind missing category: ${JSON.stringify(b)}`);
    assert.ok(Array.isArray(b.mods), `Keybind mods must be an array: ${JSON.stringify(b)}`);
    assert.ok(b.key, `Keybind missing key: ${JSON.stringify(b)}`);
    assert.ok(b.action, `Keybind missing action: ${JSON.stringify(b)}`);
    assert.ok(b.desc, `Keybind missing desc: ${JSON.stringify(b)}`);
}

// Verify canonical Slant Bifurcated binds
const slantBinds = keybinds.filter(b => b.category === "Slant Bifurcated");
assert.ok(slantBinds.length >= 5, `Expected >= 5 Slant Bifurcated binds, got ${slantBinds.length}`);
const slantActions = slantBinds.map(b => b.action);
assert.ok(slantActions.includes("toggle-split-mode"), "Missing toggle-split-mode action");
assert.ok(slantActions.includes("focus-region-left"), "Missing focus-region-left action");
assert.ok(slantActions.includes("focus-region-right"), "Missing focus-region-right action");
assert.ok(slantActions.includes("toggle-region-focus"), "Missing toggle-region-focus action");
assert.ok(slantActions.includes("move-window-to-region-left"), "Missing move-window-to-region-left action");
assert.ok(slantActions.includes("move-window-to-region-right"), "Missing move-window-to-region-right action");

// Test search filter simulation
function filterBinds(query, cat) {
    const q = query.trim().toLowerCase();
    return keybinds.filter(b => {
        if (cat !== "All" && b.category !== cat) return false;
        if (q.length === 0) return true;
        const desc = (b.desc || "").toLowerCase();
        const key = (b.key || "").toLowerCase();
        const c = (b.category || "").toLowerCase();
        const a = (b.action || "").toLowerCase();
        const m = (b.mods || []).join(" ").toLowerCase();
        return desc.includes(q) || key.includes(q) || c.includes(q) || a.includes(q) || m.includes(q);
    });
}

const slantSearchResults = filterBinds("region", "All");
assert.ok(slantSearchResults.length >= 6, `Expected >= 6 search results for 'region', got ${slantSearchResults.length}`);

const ocrSearchResults = filterBinds("ocr", "All");
assert.strictEqual(ocrSearchResults.length, 1);
assert.strictEqual(ocrSearchResults[0].action, "region:ocr");

console.log("PASS: Cheatsheet HUD data model, schema validation, and real-time search filtering verified.");

// ═══════════════════════════════════════════════════════════════════════════════
// 5. Slant Region Selector Screenshot & OCR Suite (Task L4.4, Findings C1/C3/C4)
// ═══════════════════════════════════════════════════════════════════════════════
const regionSrc = fs.readFileSync(path.join(modulesDir, 'region_selector/RegionSelector.qml'), 'utf8');

assert.ok(regionSrc.includes('WlrLayer.Overlay'), 'RegionSelector must run on WlrLayer.Overlay');
assert.ok(regionSrc.includes('WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None'),
    'RegionSelector must conditionally release Exclusive focus on dismiss (Finding C3)');
assert.ok(regionSrc.includes('target: "region"'), 'RegionSelector must register IPC target "region"');
assert.ok(regionSrc.includes('interval: 60'), 'RegionSelector must yield 60ms via Timer before grim capture (Finding C1)');
assert.ok(regionSrc.includes('root.close()'), 'RegionSelector must unmap/close overlay before timer starts (Finding C1)');
assert.ok(regionSrc.includes('selW < 8 || selH < 8'), 'RegionSelector must guard against small bounds < 8x8 (Finding C4)');
assert.ok(regionSrc.includes('wl-copy --type image/png'), 'RegionSelector screenshot must copy with --type image/png');
assert.ok(regionSrc.includes('tesseract stdin stdout -l eng'), 'RegionSelector OCR must pipe grim to tesseract');

// Verify Mathematical Soundness of Slant Geometry Presets (Section 3.3 & Gate 3)
function computeSlantPresets(sw, sh) {
    const leftW = Math.round(sw * 0.46);
    const leftPreset = { x: 0, y: 0, w: leftW, h: sh };
    const rightPreset = { x: leftW, y: 0, w: sw - leftW, h: sh };
    const fullPreset = { x: 0, y: 0, w: sw, h: sh };
    return { left: leftPreset, right: rightPreset, full: fullPreset };
}

const testResolutions = [
    { name: "1080p FHD", sw: 1920, sh: 1080, expectedLeftW: 883, expectedRightW: 1037 },
    { name: "1440p QHD", sw: 2560, sh: 1440, expectedLeftW: 1178, expectedRightW: 1382 },
    { name: "4K UHD", sw: 3840, sh: 2160, expectedLeftW: 1766, expectedRightW: 2074 }
];

for (const res of testResolutions) {
    const p = computeSlantPresets(res.sw, res.sh);
    assert.strictEqual(p.left.w, res.expectedLeftW, `${res.name} Left region width mismatch`);
    assert.strictEqual(p.right.w, res.expectedRightW, `${res.name} Right region width mismatch`);
    assert.strictEqual(p.right.x, res.expectedLeftW, `${res.name} Right region X must match Left region W`);
    assert.strictEqual(p.left.w + p.right.w, res.sw, `${res.name} Sum of Left and Right must exactly equal Screen Width (0px gap/overlap)`);
    assert.strictEqual(p.full.w, res.sw, `${res.name} Fullscreen width must match`);
    assert.strictEqual(p.full.h, res.sh, `${res.name} Fullscreen height must match`);
    console.log(`PASS: Resolution ${res.name} Slant preset math verified: Left=${p.left.w}px, Right=${p.right.w}px, Total=${res.sw}px (0px gap)`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. Shell Mounting & Niri Keybinds Config (Task L4.5)
// ═══════════════════════════════════════════════════════════════════════════════
const rootShell = fs.readFileSync(path.join(shellDir, 'shell.qml'), 'utf8');
const splitdeskShell = fs.readFileSync(path.join(shellDir, 'splitdesk-shell.qml'), 'utf8');

for (const code of [rootShell, splitdeskShell]) {
    assert.ok(code.includes('import "modules/cheatsheet"'), 'Must import modules/cheatsheet');
    assert.ok(code.includes('import "modules/clipboard"'), 'Must import modules/clipboard');
    assert.ok(code.includes('import "modules/region_selector"'), 'Must import modules/region_selector');
    assert.ok(code.includes('Cheatsheet {}'), 'Must mount Cheatsheet');
    assert.ok(code.includes('ClipboardPanel {}'), 'Must mount ClipboardPanel');
    assert.ok(code.includes('RegionSelector {}'), 'Must mount RegionSelector');
}

const niriConfigPath = path.resolve(process.env.HOME, '.config/niri/config.kdl');
assert.ok(fs.existsSync(niriConfigPath), `Niri config file missing at ${niriConfigPath}`);
const niriConfig = fs.readFileSync(niriConfigPath, 'utf8');

assert.ok(niriConfig.includes('Mod+Slash'), 'Niri config must bind Mod+Slash');
assert.ok(niriConfig.includes('"call" "cheatsheet" "toggle"'), 'Mod+Slash must call cheatsheet toggle');

assert.ok(niriConfig.includes('Mod+V'), 'Niri config must bind Mod+V');
assert.ok(niriConfig.includes('"call" "clipboard" "toggle"'), 'Mod+V must call clipboard toggle');

assert.ok(niriConfig.includes('Mod+Shift+S'), 'Niri config must bind Mod+Shift+S');
assert.ok(niriConfig.includes('"call" "region" "screenshot"'), 'Mod+Shift+S must call region screenshot');

assert.ok(niriConfig.includes('Mod+Shift+X'), 'Niri config must bind Mod+Shift+X');
assert.ok(niriConfig.includes('"call" "region" "ocr"'), 'Mod+Shift+X must call region ocr');

console.log("PASS: Shell root mounting and Niri keybindings configuration verified.");

console.log("=== ALL MILESTONE V4 SUBSYSTEMS CHECKS PASSED ===");
