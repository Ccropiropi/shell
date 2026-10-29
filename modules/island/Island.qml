// Island.qml — Top dynamic HUD pill for splitdesk
// Centered at top edge; compact pill expanding to accordion on toggle.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    // Anchor to top edge, centered horizontally
    anchors.top: true
    anchors.left: false
    anchors.right: false

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "splitdesk-island"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    // Size: pill shrinks/grows around content
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight + drawer.implicitHeight

    property bool drawerOpen: false

    Rectangle {
        id: pill

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10

        implicitWidth: Math.max(270, pillRow.implicitWidth + 24)
        implicitHeight: 42

        radius: Theme.radiusIsland
        color: Theme.inkPanel

        border.color: Qt.rgba(1, 1, 1, 0.16)
        border.width: 1

        layer.enabled: true
        layer.effect: null // ponytail: swap for MultiEffect blur when Qt 6.7+ confirmed

        RowLayout {
            id: pillRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            WorkspacePips { Layout.alignment: Qt.AlignVCenter }

            ActiveTitle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Clock
            Text {
                id: clock
                color: Theme.text
                font.pixelSize: 13
                font.features: { "tnum": 1 }   // tabular nums
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            // Expand toggle button
            Rectangle {
                width: 28; height: 28; radius: 14
                color: Qt.rgba(1, 1, 1, 0.08)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰅀"
                    color: Theme.dim
                    font.pixelSize: 14
                    rotation: root.drawerOpen ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.drawerOpen = !root.drawerOpen
                }
            }
        }
    }

    IslandDrawer {
        id: drawer
        anchors.top: pill.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: pill.implicitWidth
        open: root.drawerOpen
    }
}
