// LeftPanel.qml — Left Region Static Canvas for splitdesk
// PanelWindow on WlrLayer.Bottom anchored to Left, Top, Bottom.
// Visible only when Niri.regionsEnabled, width bound to Screen.width * 0.46.
// Uses Quickshell.Region input masking for click pass-through to tiled client windows.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"
import "widgets"

PanelWindow {
    id: root

    visible: Niri.regionsEnabled
    color: "transparent"

    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    width: Screen.width * 0.46

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "splitdesk-left-panel"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    mask: Region {
        id: panelMask

        Region {
            x: contentColumn.x + clockCard.x
            y: contentColumn.y + clockCard.y
            width: clockCard.width
            height: clockCard.height
        }

        Region {
            x: contentColumn.x + dialsCard.x
            y: contentColumn.y + dialsCard.y
            width: dialsCard.width
            height: dialsCard.height
        }

        Region {
            x: contentColumn.x + mediaCard.x
            y: contentColumn.y + mediaCard.y
            width: mediaCard.width
            height: mediaCard.height
        }

        Region {
            x: contentColumn.x + actionsCard.x
            y: contentColumn.y + actionsCard.y
            width: actionsCard.width
            height: actionsCard.height
        }
    }

    ColumnLayout {
        id: contentColumn

        anchors.top: parent.top
        anchors.topMargin: Theme.topOffset + 20
        anchors.left: parent.left
        anchors.leftMargin: 24
        width: Math.min(root.width - 48, 340)
        spacing: 14

        ClockCard {
            id: clockCard

            Layout.fillWidth: true
        }

        SystemDials {
            id: dialsCard

            Layout.fillWidth: true
        }

        MediaCard {
            id: mediaCard

            Layout.fillWidth: true
        }

        QuickActions {
            id: actionsCard

            Layout.fillWidth: true
        }
    }
}
