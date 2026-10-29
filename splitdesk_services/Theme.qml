pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Color tokens ─────────────────────────────────────────────────────────
    readonly property color ink:   "#0b1626"
    readonly property color teal:  "#1f7a7a"
    readonly property color amber: "#e9b44c"
    readonly property color text:  "#eef3f7"
    readonly property color dim:   "#9fb3c4"
    readonly property color edge:  Qt.rgba(1, 1, 1, 0.55)
    readonly property color veil:  Qt.rgba(180/255, 205/255, 230/255, 0.10)
    readonly property color inkPanel: Qt.rgba(11/255, 22/255, 38/255, 0.78)

    // ── Geometry tokens ──────────────────────────────────────────────────────
    readonly property real w: 0.46        // left region width fraction
    readonly property real s: 0.12        // slant offset fraction
    readonly property int  topOffset: 64  // island HUD clearance px
    readonly property int  margin: 14     // screen edge margin px
    readonly property int  gap: 12        // inter-panel gutter px

    // ── Radius tokens ────────────────────────────────────────────────────────
    readonly property int radiusPanel:    36
    readonly property int radiusWindow:   28
    readonly property int radiusIsland:   26
    readonly property int radiusTile:     22

    // ── Border/spacing tokens ────────────────────────────────────────────────
    readonly property int borderThickness: 2
    readonly property int paddingLarge: 16
    readonly property int spacingMedium: 12

    // ── OSD/Session/Utilities flags ──────────────────────────────────────────
    readonly property bool enabled: true
    readonly property bool utilitiesEnabled: true
    readonly property int osdHideDelay: 1500
    readonly property bool osdEnableMicrophone: true
    readonly property bool osdEnableBrightness: true
    readonly property int osdSliderWidth: 240
    readonly property int osdSliderHeight: 36
    readonly property real maxVolume: 1.5
    readonly property real brightnessIncrement: 0.05
}
