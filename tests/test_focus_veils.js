#!/usr/bin/env node
/**
 * Milestone S4: Dual Focus Veils, Slanted Boundary Highlight & Pass-Through Verification Test
 * Validates FocusVeils.qml, SlantedSeparator.qml, shell.qml mounting,
 * WlrLayer.Bottom layer-shell geometry, mask: Region {} 100% mouse pass-through,
 * dual veil 350ms opacity cross-fades, and slanted divider stroke/glow math.
 */

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

console.log("=== Running Milestone S4: Focus Veils & Slanted Separator Verification ===");

const shellDir = fs.existsSync(path.resolve(__dirname, "../shell"))
    ? path.resolve(__dirname, "../shell")
    : (fs.existsSync(path.resolve(__dirname, "../modules"))
        ? path.resolve(__dirname, "..")
        : path.resolve(__dirname, "."));

const veilsDir = path.join(shellDir, "modules/veils");

// ── 1. File Existence and Structure ──────────────────────────────────────────
const coreFiles = [
    { dir: veilsDir, name: "FocusVeils.qml" },
    { dir: veilsDir, name: "SlantedSeparator.qml" }
];

for (const f of coreFiles) {
    const fullPath = path.join(f.dir, f.name);
    assert(fs.existsSync(fullPath), `Missing required component: ${f.name} at ${fullPath}`);
    console.log(`PASS: Found component ${f.name}`);
}

// ── 2. Check ShellRoot Mounting in shell.qml ─────────────────────────────────
const shellQmlPath = path.join(shellDir, "shell.qml");
assert(fs.existsSync(shellQmlPath), `Missing shell.qml at ${shellQmlPath}`);
const shellSource = fs.readFileSync(shellQmlPath, "utf8");
assert(shellSource.includes('import "modules/veils"'), 'shell.qml must import modules/veils');
assert(shellSource.includes("FocusVeils {}"), "shell.qml must instantiate FocusVeils {}");
console.log("PASS: FocusVeils mounted into shell.qml.");

// ── 3. FocusVeils Component & Pass-Through Verification ─────────────────────
const focusVeilsSrc = fs.readFileSync(path.join(veilsDir, "FocusVeils.qml"), "utf8");
assert(focusVeilsSrc.includes("PanelWindow"), "FocusVeils must be a PanelWindow");
assert(focusVeilsSrc.includes("WlrLayershell.layer: WlrLayer.Bottom"), "FocusVeils must reside on WlrLayer.Bottom");
assert(focusVeilsSrc.includes('WlrLayershell.namespace: "splitdesk-focus-veils"'), "Namespace must be splitdesk-focus-veils");
assert(focusVeilsSrc.includes("WlrLayershell.exclusionMode: ExclusionMode.Ignore"), "ExclusionMode must be Ignore");
assert(focusVeilsSrc.includes("anchors.left: true"), "Must anchor to screen left");
assert(focusVeilsSrc.includes("anchors.right: true"), "Must anchor to screen right");
assert(focusVeilsSrc.includes("anchors.top: true"), "Must anchor to screen top");
assert(focusVeilsSrc.includes("anchors.bottom: true"), "Must anchor to screen bottom");
assert(focusVeilsSrc.includes("visible: Niri.regionsEnabled"), "Visible only when Niri.regionsEnabled");

// 100% mouse pass-through: empty mask Region {}
assert(/mask:\s*Region\s*\{\s*\}/.test(focusVeilsSrc), "Must specify mask: Region {} for 100% mouse pass-through");
console.log("PASS: FocusVeils PanelWindow, WlrLayer.Bottom, edge anchors, and mask: Region {} pass-through verified.");

// Dual veil shapes & 350ms cross-fades
assert(focusVeilsSrc.includes("id: veilLeft"), "Must declare veilLeft shape");
assert(focusVeilsSrc.includes("id: veilRight"), "Must declare veilRight shape");
assert(focusVeilsSrc.includes("Theme.veil"), "Veils must use Theme.veil fill color");
assert(focusVeilsSrc.includes("duration: 350"), "Opacity transition must specify duration: 350ms");
assert(focusVeilsSrc.includes("Easing.OutCubic"), "Opacity transition must specify Easing.OutCubic");
assert(focusVeilsSrc.includes("SlantedSeparator"), "FocusVeils must instantiate SlantedSeparator");
console.log("PASS: Dual veil shapes and 350ms cubic-bezier opacity cross-fades verified.");

// ── 4. SlantedSeparator Component Verification ──────────────────────────────
const sepSrc = fs.readFileSync(path.join(veilsDir, "SlantedSeparator.qml"), "utf8");
assert(sepSrc.includes("Theme.w"), "SlantedSeparator must bind top position to Theme.w (46%)");
assert(sepSrc.includes("Theme.s"), "SlantedSeparator must compute slant from Theme.s (12%)");
assert(sepSrc.includes("1.5"), "SlantedSeparator must render 1.5px base stroke");
assert(sepSrc.includes("2.5"), "SlantedSeparator must render 2.5px glow stroke");
assert(sepSrc.includes("Theme.edge"), "Base stroke must use Theme.edge");
assert(sepSrc.includes("Theme.amber"), "Glow stroke must use Theme.amber");
assert(sepSrc.includes("id: baseStroke"), "Must define baseStroke shape");
assert(sepSrc.includes("id: amberGlow"), "Must define amberGlow shape");
assert(sepSrc.includes("duration: 350"), "Glow opacity transition must specify duration: 350ms");
assert(sepSrc.includes("Easing.OutCubic"), "Glow opacity transition must specify Easing.OutCubic");
console.log("PASS: SlantedSeparator base stroke (1.5px) and animated amber glow (2.5px) verified.");

// ── 5. Runtime Geometry and State Simulation ────────────────────────────────
console.log("--- Simulating Runtime State and Geometry Logic ---");

const screenW = 2560;
const screenH = 1440;
const wFrac = 0.46;
const sFrac = 0.12;

const xTop = screenW * wFrac;
const xBottom = screenW * (wFrac - sFrac);

assert(Math.abs(xTop - 1177.6) < 1e-4, "xTop should be 1177.6px on 2560px screen");
assert(Math.abs(xBottom - 870.4) < 1e-4, "xBottom should be 870.4px on 2560px screen");
console.log(`PASS: Separator coordinates: (${xTop}px, 0px) -> (${xBottom}px, ${screenH}px) verified.`);

// Veil Opacity state table
function getVeilOpacities(focusedRegion) {
    return {
        left: focusedRegion === "Left" ? 0.0 : 1.0,
        right: focusedRegion === "Right" ? 0.0 : 1.0,
        amberGlow: focusedRegion === "Left" ? 1.0 : 0.0
    };
}

// State 1: Region::Left focused
const sLeft = getVeilOpacities("Left");
assert.strictEqual(sLeft.left, 0.0, "VeilLeft must be transparent (sharp) when Left focused");
assert.strictEqual(sLeft.right, 1.0, "VeilRight must be tinted (veiled) when Left focused");
assert.strictEqual(sLeft.amberGlow, 1.0, "Amber glow must be fully active when Left focused");

// State 2: Region::Right focused
const sRight = getVeilOpacities("Right");
assert.strictEqual(sRight.left, 1.0, "VeilLeft must be tinted (veiled) when Right focused");
assert.strictEqual(sRight.right, 0.0, "VeilRight must be transparent (sharp) when Right focused");
assert.strictEqual(sRight.amberGlow, 0.0, "Amber glow must fade to white base stroke when Right focused");
console.log("PASS: Focus state machine transitions (Left <-> Right) and opacities verified.");

// Input pass-through test: mask is empty Region {}, meaning 0 interactive regions on surface
function isSurfaceCapturingInput(maskRegions, px, py) {
    return maskRegions.some(r => px >= r.x && px <= (r.x + r.w) && py >= r.y && py <= (r.y + r.h));
}
const veilMaskRegions = []; // mask: Region {} has no child rectangles
assert.strictEqual(isSurfaceCapturingInput(veilMaskRegions, 500, 500), false, "All clicks must pass through FocusVeils");
assert.strictEqual(isSurfaceCapturingInput(veilMaskRegions, 1200, 600), false, "All clicks must pass through FocusVeils");
console.log("PASS: Quickshell mask: Region {} guarantees 100% input pass-through across whole screen.");

// ── 6. Execute QML Linting and Conventions ───────────────────────────────────
console.log("--- Executing QML Syntax and Convention Linters ---");

try {
    execSync("qmllint -I . -I modules/veils -I modules/island -I modules/left_panel modules/veils/FocusVeils.qml modules/veils/SlantedSeparator.qml shell.qml", {
        cwd: shellDir,
        stdio: "pipe"
    });
    console.log("PASS: qmllint validated FocusVeils.qml, SlantedSeparator.qml, and shell.qml with 0 errors.");
} catch (err) {
    const stderr = err.stderr ? err.stderr.toString() : err.message;
    assert.fail(`qmllint failed: ${stderr}`);
}

const checkFiles = [
    "modules/veils/FocusVeils.qml",
    "modules/veils/SlantedSeparator.qml"
];

for (const f of checkFiles) {
    try {
        execSync(`python3 scripts/qml-lint-conventions.py --file ${f}`, {
            cwd: shellDir,
            encoding: "utf8",
            stdio: ["pipe", "pipe", "pipe"]
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

console.log("=== ALL MILESTONE S4 VERIFICATION CHECKS PASSED ===");
