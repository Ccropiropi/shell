// WorkspacePips.qml — reactive workspace indicator pips for splitdesk
// Inactive: 8x8px circle dot, Active: 22x8px amber pill (#e9b44c), Clickable.

import QtQuick
import "../../splitdesk_services"

Row {
    id: root

    readonly property var workspaceList: (Niri.workspaces && Niri.workspaces.length > 0)
        ? Niri.workspaces
        : [{ id: 1, is_focused: true }]

    spacing: 6

    Repeater {
        model: root.workspaceList

        Rectangle {
            id: pip

            required property var modelData

            readonly property bool isCurrent: (modelData.id !== undefined && modelData.id === Niri.focusedWorkspaceId)
                || (Niri.focusedWorkspaceId === -1 && Boolean(modelData.is_focused))

            width: isCurrent ? 22 : 8
            height: 8
            radius: 4
            color: isCurrent ? Theme.amber : Qt.rgba(1, 1, 1, 0.35)

            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 220 }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData && modelData.id !== undefined)
                        Niri.focusWorkspace(modelData.id);
                }
            }
        }
    }
}
