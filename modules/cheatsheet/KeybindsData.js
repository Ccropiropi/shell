.pragma library

var keybinds = [
    // ═══ 1. Slant Bifurcated Controls ════════════════════════════════════════
    { category: "Slant Bifurcated", mods: ["Mod"], key: "E", action: "toggle-split-mode", desc: "Toggle Split Mode On/Off (Stock Fallback)" },
    { category: "Slant Bifurcated", mods: ["Mod"], key: "[", action: "focus-region-left", desc: "Focus Left Region (Anchor Canvas)" },
    { category: "Slant Bifurcated", mods: ["Mod"], key: "]", action: "focus-region-right", desc: "Focus Right Region (Workspace Sequence)" },
    { category: "Slant Bifurcated", mods: ["Mod"], key: "G", action: "toggle-region-focus", desc: "Toggle Active Region Focus" },
    { category: "Slant Bifurcated", mods: ["Mod"], key: "Tab", action: "toggle-region-focus", desc: "Toggle Active Region Focus" },
    { category: "Slant Bifurcated", mods: ["Mod", "Shift"], key: "[", action: "move-window-to-region-left", desc: "Move Window Across Slant to Left Region" },
    { category: "Slant Bifurcated", mods: ["Mod", "Shift"], key: "]", action: "move-window-to-region-right", desc: "Move Window Across Slant to Right Region" },

    // ═══ 2. Left & Right Region Navigation ═══════════════════════════════════
    { category: "Navigation", mods: ["Mod"], key: "H", action: "focus-column-left", desc: "Focus Column Left (Within Active Region)" },
    { category: "Navigation", mods: ["Mod"], key: "L", action: "focus-column-right", desc: "Focus Column Right (Within Active Region)" },
    { category: "Navigation", mods: ["Mod"], key: "J", action: "focus-window-down", desc: "Focus Window Down" },
    { category: "Navigation", mods: ["Mod"], key: "K", action: "focus-window-up", desc: "Focus Window Up" },
    { category: "Navigation", mods: ["Mod", "Ctrl"], key: "H", action: "move-column-left", desc: "Move Column Left" },
    { category: "Navigation", mods: ["Mod", "Ctrl"], key: "L", action: "move-column-right", desc: "Move Column Right" },
    { category: "Navigation", mods: ["Mod"], key: "Home", action: "focus-column-first", desc: "Focus First Column in Region" },
    { category: "Navigation", mods: ["Mod"], key: "End", action: "focus-column-last", desc: "Focus Last Column in Region" },

    // ═══ 3. Window Layout & Sizing ═══════════════════════════════════════════
    { category: "Window Layout", mods: ["Mod"], key: "Q", action: "close-window", desc: "Close Active Window" },
    { category: "Window Layout", mods: ["Mod"], key: "F", action: "fullscreen-window", desc: "Toggle Fullscreen Window" },
    { category: "Window Layout", mods: ["Mod"], key: "D", action: "maximize-column", desc: "Maximize Active Column" },
    { category: "Window Layout", mods: ["Mod"], key: "A", action: "toggle-window-floating", desc: "Toggle Window Floating" },
    { category: "Window Layout", mods: ["Mod"], key: "C", action: "center-column", desc: "Center Active Column" },
    { category: "Window Layout", mods: ["Mod"], key: "R", action: "switch-preset-column-width", desc: "Switch Preset Column Width" },
    { category: "Window Layout", mods: ["Mod", "Shift"], key: "R", action: "switch-preset-window-height", desc: "Switch Preset Window Height" },
    { category: "Window Layout", mods: ["Mod"], key: "-", action: "set-column-width -10%", desc: "Shrink Column Width by 10%" },
    { category: "Window Layout", mods: ["Mod"], key: "=", action: "set-column-width +10%", desc: "Expand Column Width by 10%" },

    // ═══ 4. Right Region Workspace Sequence ══════════════════════════════════
    { category: "Workspaces", mods: ["Mod"], key: "1..9", action: "focus-workspace", desc: "Focus Sequential Workspace (Right Region)" },
    { category: "Workspaces", mods: ["Mod", "Shift"], key: "1..9", action: "move-column-to-workspace", desc: "Move Column to Workspace (Right Region)" },
    { category: "Workspaces", mods: ["Mod"], key: "U", action: "focus-workspace-down", desc: "Focus Workspace Below" },
    { category: "Workspaces", mods: ["Mod"], key: "I", action: "focus-workspace-up", desc: "Focus Workspace Above" },

    // ═══ 5. Shell & System Overlays ══════════════════════════════════════════
    { category: "Shell & Overlays", mods: ["Mod"], key: "Return", action: "spawn:ghostty", desc: "Launch Ghostty Terminal" },
    { category: "Shell & Overlays", mods: ["Mod"], key: "Space", action: "launcher:toggle", desc: "Application & Math Launcher" },
    { category: "Shell & Overlays", mods: ["Mod"], key: "N", action: "nexus:toggle", desc: "Nexus Quick Settings & Hardware Control" },
    { category: "Shell & Overlays", mods: ["Mod"], key: "Slash", action: "cheatsheet:toggle", desc: "Interactive Keybinds Cheatsheet HUD" },
    { category: "Shell & Overlays", mods: ["Mod"], key: "V", action: "clipboard:toggle", desc: "Clipboard History Manager" },
    { category: "Shell & Overlays", mods: ["Mod", "Shift"], key: "S", action: "region:screenshot", desc: "Slant Region Screenshot Suite" },
    { category: "Shell & Overlays", mods: ["Mod", "Shift"], key: "X", action: "region:ocr", desc: "Slant Region Optical Character Recognition" },
    { category: "Shell & Overlays", mods: ["Mod"], key: "X", action: "session:toggle", desc: "Power & Session Menu" },
    { category: "Shell & Overlays", mods: ["Mod", "Alt"], key: "L", action: "lock-session", desc: "Lock Screen (PAM Authentication)" },
    { category: "Shell & Overlays", mods: ["Mod"], key: "O", action: "toggle-overview", desc: "Toggle Compositor Overview" },
    { category: "Shell & Overlays", mods: ["Mod", "Shift"], key: "E", action: "quit", desc: "Quit Compositor Session" },

    // ═══ 6. Hardware & Media Controls ════════════════════════════════════════
    { category: "Media & Hardware", mods: [], key: "AudioRaiseVolume", action: "wpctl:volume-up", desc: "Raise Default Audio Sink Volume (+5%)" },
    { category: "Media & Hardware", mods: [], key: "AudioLowerVolume", action: "wpctl:volume-down", desc: "Lower Default Audio Sink Volume (-5%)" },
    { category: "Media & Hardware", mods: [], key: "AudioMute", action: "wpctl:mute-toggle", desc: "Toggle Audio Output Mute" },
    { category: "Media & Hardware", mods: [], key: "AudioMicMute", action: "wpctl:mic-mute-toggle", desc: "Toggle Microphone Mute" },
    { category: "Media & Hardware", mods: [], key: "MonBrightnessUp", action: "brightness:up", desc: "Increase Screen Backlight (+5%)" },
    { category: "Media & Hardware", mods: [], key: "MonBrightnessDown", action: "brightness:down", desc: "Decrease Screen Backlight (-5%)" },
    { category: "Media & Hardware", mods: [], key: "AudioPlay", action: "playerctl:play-pause", desc: "MPRIS Play / Pause Toggle" },
    { category: "Media & Hardware", mods: [], key: "AudioNext", action: "playerctl:next", desc: "MPRIS Next Track" },
    { category: "Media & Hardware", mods: [], key: "AudioPrev", action: "playerctl:previous", desc: "MPRIS Previous Track" },
    { category: "Media & Hardware", mods: [], key: "Print", action: "screenshot", desc: "Compositor Native Fullscreen Screenshot" }
];

function getKeybinds() {
    return keybinds;
}

function getCategories() {
    return [
        "All",
        "Slant Bifurcated",
        "Navigation",
        "Window Layout",
        "Workspaces",
        "Shell & Overlays",
        "Media & Hardware"
    ];
}
