import QtQuick
import QtQuick.Layouts
import "../../splitdesk_services"

Rectangle {
    id: root

    property var entry: ({})
    property bool isSelected: false
    property bool isPinned: false

    signal selectRequested()
    signal copyRequested()
    signal pinRequested()
    signal deleteRequested()

    width: parent ? parent.width : 480
    height: 52
    radius: 10
    color: isSelected
           ? Qt.rgba(31/255, 122/255, 122/255, 0.28)
           : (itemArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
    border.color: isSelected
                  ? Theme.teal
                  : (itemArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.06))
    border.width: 1

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.selectRequested();
            root.copyRequested();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Type badge pill
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 22
            radius: 6
            color: root.entry && root.entry.isImage
                   ? Qt.rgba(233/255, 180/255, 76/255, 0.18)
                   : Qt.rgba(31/255, 122/255, 122/255, 0.22)
            border.color: root.entry && root.entry.isImage
                          ? Qt.rgba(233/255, 180/255, 76/255, 0.5)
                          : Qt.rgba(31/255, 122/255, 122/255, 0.5)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.entry && root.entry.isImage ? "IMG" : "TXT"
                font.pixelSize: 10
                font.bold: true
                color: root.entry && root.entry.isImage ? Theme.amber : Theme.teal
            }
        }

        // Preview and metadata
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.entry ? (root.entry.preview || "").replace(/\n/g, " ") : ""
                font.pixelSize: 13
                color: Theme.text
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.entry && root.entry.isImage
                      ? root.entry.dims
                      : ("#" + (root.entry ? root.entry.id : ""))
                font.pixelSize: 11
                color: Theme.dim
                elide: Text.ElideRight
            }
        }

        // Action: Pin toggle
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 6
            color: pinArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.isPinned ? "★" : "☆"
                font.pixelSize: 14
                color: root.isPinned ? Theme.amber : Theme.dim
            }

            MouseArea {
                id: pinArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pinRequested()
            }
        }

        // Action: Delete entry
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 6
            color: deleteArea.containsMouse ? Qt.rgba(233/255, 76/255, 76/255, 0.25) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                color: deleteArea.containsMouse ? "#ff6b6b" : Theme.dim
            }

            MouseArea {
                id: deleteArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.deleteRequested()
            }
        }
    }
}
