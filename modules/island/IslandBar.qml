// IslandBar.qml — Top Dynamic Island Bar for splitdesk
// Compact HUD (height 42px) smoothly expanding to controls card (height 152px).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    property bool expanded: false

    anchors.top: true
    anchors.left: false
    anchors.right: false

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "splitdesk-island"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight + 10

    Rectangle {
        id: pill

        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: root.expanded ? 380 : Math.max(270, headerRow.implicitWidth + 24)
        implicitHeight: root.expanded ? 152 : 42

        radius: root.expanded ? 28 : Theme.radiusIsland
        color: Theme.inkPanel
        border.color: Qt.rgba(1, 1, 1, 0.16)
        border.width: 1
        clip: true

        Behavior on implicitWidth {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on implicitHeight {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8

            IslandContent {
                id: headerRow

                Layout.fillWidth: true
                Layout.preferredHeight: 30
                expanded: root.expanded
                onToggleExpanded: root.expanded = !root.expanded
            }

            ExpandedControls {
                id: controls

                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: root.expanded ? 1.0 : 0.0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }
}
