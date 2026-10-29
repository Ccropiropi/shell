// WorkspacePips.qml — workspace indicator row
// Each inactive pip: 8×8px circle; active: 22×8px amber pill.

import QtQuick
import qs.services

Row {
    id: root

    spacing: 5

    Repeater {
        model: Niri.workspaces

        Rectangle {
            required property var modelData
            readonly property bool active: modelData.id === Niri.focusedWorkspaceId

            height: 8
            width: active ? 22 : 8
            radius: 4
            color: active ? Theme.amber : Qt.rgba(1, 1, 1, 0.35)

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Niri.focusWorkspace(modelData.id)
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
