// IslandContent.qml — Compact HUD bar row for splitdesk Dynamic Island
// Active window title, region tag [L]/[R], 24h clock, chevron accordion button.

import QtQuick
import QtQuick.Layouts
import splitdesk.services

RowLayout {
    id: root

    property bool expanded: false

    signal toggleExpanded()

    spacing: 10

    // 1. Workspace Pips
    WorkspacePips {
        id: pips
        Layout.alignment: Qt.AlignVCenter
    }

    // 2. Region Tag [L] or [R]
    Rectangle {
        id: regionBadge

        visible: Niri.regionsEnabled && Boolean(Niri.focusedRegion)
        height: 18
        implicitWidth: regionLabel.implicitWidth + 8
        radius: 4
        color: Niri.focusedRegion === "Left" ? Qt.rgba(31/255, 122/255, 122/255, 0.35) : Qt.rgba(233/255, 180/255, 76/255, 0.3)
        border.color: Niri.focusedRegion === "Left" ? Theme.teal : Theme.amber
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: regionLabel

            anchors.centerIn: parent
            text: Niri.focusedRegion === "Left" ? "[L]" : "[R]"
            color: Niri.focusedRegion === "Left" ? Theme.text : Theme.amber
            font.pixelSize: 11
            font.bold: true
        }
    }

    // 3. Active Window Title
    Text {
        id: titleLabel
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        text: {
            if (Niri.regionsEnabled && Niri.focusedRegion === "Left")
                return "Widgets & Dashboard";
            return Niri.activeWindowTitle || "Desktop";
        }
        color: Theme.text
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    // 4. 24h Digital Clock
    Text {
        id: clockLabel
        Layout.alignment: Qt.AlignVCenter

        color: Theme.dim
        font.pixelSize: 13
        font.features: { "tnum": 1 }
        verticalAlignment: Text.AlignVCenter
        text: Qt.formatTime(new Date(), "hh:mm")

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    // 5. Chevron accordion toggle button
    Rectangle {
        id: chevronButton
        Layout.alignment: Qt.AlignVCenter

        width: 28
        height: 28
        radius: 14
        color: chevronMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

        Text {
            anchors.centerIn: parent
            text: "󰅀"
            color: Theme.dim
            font.pixelSize: 14
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: chevronMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleExpanded()
        }
    }
}
