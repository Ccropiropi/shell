// FocusVeils.qml — Dual focus veils and boundary highlight for splitdesk
// PanelWindow on WlrLayer.Bottom anchored to all screen edges.
// mask: Region {} ensures 100% mouse pass-through to underlying application windows.
// Dual veil shapes apply 350ms cubic-bezier opacity cross-fades based on Niri.focusedRegion.
// ponytail: dual veil polygon shapes; add compositor-level blur shader attachment when available

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    readonly property real xTop: width * Theme.w
    readonly property real xBottom: width * (Theme.w - Theme.s)

    visible: Niri.regionsEnabled
    color: "transparent"

    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "splitdesk-focus-veils"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    mask: Region {}

    Shape {
        id: veilLeft

        anchors.fill: parent
        opacity: Niri.focusedRegion === "Left" ? 0.0 : 1.0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Theme.veil

            startX: 0
            startY: 0

            PathLine {
                x: root.xTop
                y: 0
            }

            PathLine {
                x: root.xBottom
                y: root.height
            }

            PathLine {
                x: 0
                y: root.height
            }

            PathLine {
                x: 0
                y: 0
            }
        }
    }

    Shape {
        id: veilRight

        anchors.fill: parent
        opacity: Niri.focusedRegion === "Right" ? 0.0 : 1.0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Theme.veil

            startX: root.xTop
            startY: 0

            PathLine {
                x: root.width
                y: 0
            }

            PathLine {
                x: root.width
                y: root.height
            }

            PathLine {
                x: root.xBottom
                y: root.height
            }

            PathLine {
                x: root.xTop
                y: 0
            }
        }
    }

    SlantedSeparator {
        id: separator

        anchors.fill: parent
    }
}
