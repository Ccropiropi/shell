import QtQuick
import QtQuick.Layouts
import "../../splitdesk_services"

Rectangle {
    id: root

    property var bind: ({})
    readonly property bool isSlant: bind && bind.category === "Slant Bifurcated"

    width: parent ? parent.width : 400
    height: 56
    radius: 12

    color: isSlant
           ? Theme.veil
           : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
    border.color: isSlant
                  ? Theme.amber
                  : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08))
    border.width: isSlant ? 1.5 : 1

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // Left: Description & Category Subtitle
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 6
                Text {
                    text: root.bind ? (root.bind.desc || "") : ""
                    font.pixelSize: 13
                    font.bold: root.isSlant
                    color: root.isSlant ? Theme.amber : Theme.text
                    elide: Text.ElideRight
                }

                // Amber badge for Slant Bifurcated
                Rectangle {
                    visible: root.isSlant
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 16
                    radius: 4
                    color: Qt.rgba(233/255, 180/255, 76/255, 0.2)
                    border.color: Theme.amber
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "SLANT"
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.amber
                    }
                }
            }

            Text {
                text: root.bind ? ((root.bind.category || "") + "  •  " + (root.bind.action || "")) : ""
                font.pixelSize: 10
                color: Theme.dim
                elide: Text.ElideRight
            }
        }

        // Right: Keycaps pill
        RowLayout {
            spacing: 4

            Repeater {
                model: root.bind && root.bind.mods ? root.bind.mods : []

                RowLayout {
                    spacing: 4

                    Rectangle {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: modText.implicitWidth + 12
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: root.isSlant ? Qt.rgba(233/255, 180/255, 76/255, 0.5) : Theme.edge
                        border.width: 1

                        Text {
                            id: modText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Monospace"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.isSlant ? Theme.amber : Theme.text
                        }
                    }

                    Text {
                        text: "+"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.dim
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: keyText.implicitWidth + 12
                radius: 6
                color: root.isSlant
                       ? Qt.rgba(233/255, 180/255, 76/255, 0.22)
                       : Qt.rgba(31/255, 122/255, 122/255, 0.22)
                border.color: root.isSlant ? Theme.amber : Theme.teal
                border.width: 1

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: root.bind ? (root.bind.key || "") : ""
                    font.family: "Monospace"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.isSlant ? Theme.amber : Theme.teal
                }
            }
        }
    }
}
