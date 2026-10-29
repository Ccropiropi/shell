// SlantedSeparator.qml — Slanted boundary divider for splitdesk
// Renders base stroke (1.5px) and animated amber glow (2.5px) toward focused region.
// ponytail: straight divider across monitor height; add curved fillet corners if needed

import QtQuick
import QtQuick.Shapes
import "../../splitdesk_services"

Item {
    id: root

    property real w: Theme.w
    property real s: Theme.s
    readonly property real xTop: width * w
    readonly property real xBottom: width * (w - s)
    readonly property bool isLeftFocused: Niri.focusedRegion === "Left"
    readonly property bool isRightFocused: Niri.focusedRegion === "Right"
    property real baseStrokeWidth: 1.5
    property real glowStrokeWidth: 2.5
    property color baseColor: Theme.edge
    property color glowColor: Theme.amber
    property real glowOffset: isLeftFocused ? -0.5 : 0.5

    Shape {
        id: baseStroke

        anchors.fill: parent

        ShapePath {
            strokeWidth: root.baseStrokeWidth
            strokeColor: root.baseColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: root.xTop
            startY: 0

            PathLine {
                x: root.xBottom
                y: root.height
            }
        }
    }

    Shape {
        id: amberGlow

        anchors.fill: parent
        opacity: root.isLeftFocused ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        ShapePath {
            strokeWidth: root.glowStrokeWidth
            strokeColor: root.glowColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: root.xTop + root.glowOffset
            startY: 0

            PathLine {
                x: root.xBottom + root.glowOffset
                y: root.height
            }
        }
    }
}
