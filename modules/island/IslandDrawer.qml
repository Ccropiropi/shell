// IslandDrawer.qml — accordion expansion card (media + quick toggles)

import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property bool open: false

    clip: true
    implicitHeight: open ? content.implicitHeight : 0

    Behavior on implicitHeight {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: content
        width: parent.width
        spacing: Theme.gap

        // Media info row
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.gap

            Text {
                text: "♪  —"
                color: Theme.dim
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        // Quick toggles row (Wi-Fi, Bluetooth, Night Light, Game Mode)
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.gap
            spacing: Theme.gap

            Repeater {
                model: ["wifi", "bluetooth", "night", "game"]

                Rectangle {
                    required property string modelData
                    width: 36; height: 36; radius: 999
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: ["󰤨", "󰂯", "󰌵", "󰊗"][index]
                        font.pixelSize: 16
                        color: Theme.dim
                    }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}
