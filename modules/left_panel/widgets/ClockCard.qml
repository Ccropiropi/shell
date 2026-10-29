// ClockCard.qml — Stylized clock, day, date display for splitdesk Left Region

import QtQuick
import QtQuick.Layouts
import splitdesk.services

Rectangle {
    id: root

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 28
    radius: Theme.radiusTile
    color: Theme.inkPanel
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    Timer {
        id: refreshTimer

        interval: 1000
        running: true
        repeat: true
        onTriggered: now.time = new Date()
    }

    QtObject {
        id: now

        property date time: new Date()
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        Text {
            id: clockText

            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(now.time, "HH:mm")
            font.pixelSize: 56
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            color: Theme.text
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                id: dayText

                text: Qt.formatDate(now.time, "dddd")
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Theme.amber
            }

            Text {
                text: "•"
                font.pixelSize: 12
                color: Theme.dim
            }

            Text {
                id: dateText

                text: Qt.formatDate(now.time, "MMMM d, yyyy")
                font.pixelSize: 14
                color: Theme.text
            }
        }
    }
}
