// QuickActions.qml — Quick actions and shortcuts for splitdesk Left Region
// Region switch, move window, split toggle shortcuts.

import QtQuick
import QtQuick.Layouts
import "../../../splitdesk_services"

Rectangle {
    id: root

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 24
    radius: Theme.radiusTile
    color: Theme.inkPanel
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Section Title
        Text {
            Layout.fillWidth: true
            text: "QUICK ACTIONS"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
            color: Theme.dim
        }

        // Action 1: Switch Region Focus
        Rectangle {
            readonly property bool isLeft: Niri.focusedRegion === "Left"

            Layout.fillWidth: true
            height: 44
            radius: 12
            color: switchArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
            border.color: isLeft ? Theme.teal : Theme.amber
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: parent.parent.isLeft ? "󰍹" : "󰍺"
                    font.pixelSize: 16
                    color: parent.parent.isLeft ? Theme.teal : Theme.amber
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Switch Region"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.text
                    }

                    Text {
                        text: parent.parent.parent.isLeft ? "Active: Left [L]" : "Active: Right [R]"
                        font.pixelSize: 10
                        color: Theme.dim
                    }
                }

                Text {
                    text: "Mod+Tab"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.dim
                }
            }

            MouseArea {
                id: switchArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.toggleRegionFocus()
            }
        }

        // Action 2: Move Window to Opposite Region
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 12
            color: moveArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "󰆏"
                    font.pixelSize: 16
                    color: Theme.amber
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Move Window"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.text
                    }

                    Text {
                        text: Niri.focusedRegion === "Left" ? "Send to Right [R]" : "Send to Left [L]"
                        font.pixelSize: 10
                        color: Theme.dim
                    }
                }

                Text {
                    text: "Mod+M"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.dim
                }
            }

            MouseArea {
                id: moveArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Niri.focusedRegion === "Left") {
                        Niri.moveWindowToRegionRight();
                    } else {
                        Niri.moveWindowToRegionLeft();
                    }
                }
            }
        }

        // Action 3: Toggle Split Mode
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 12
            color: splitArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
            border.color: Niri.regionsEnabled ? Theme.teal : Qt.rgba(1, 1, 1, 0.10)
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "󰤼"
                    font.pixelSize: 16
                    color: Niri.regionsEnabled ? Theme.teal : Theme.dim
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Split Mode"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.text
                    }

                    Text {
                        text: Niri.regionsEnabled ? "Dual Regions Active" : "Single Region (Disabled)"
                        font.pixelSize: 10
                        color: Theme.dim
                    }
                }

                Text {
                    text: "Mod+E"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.dim
                }
            }

            MouseArea {
                id: splitArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.toggleSplitMode()
            }
        }
    }
}
