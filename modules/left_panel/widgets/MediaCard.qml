// MediaCard.qml — Album art, track info, seekbar, and player controls for splitdesk Left Region

import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root

    readonly property bool hasMedia: Boolean(Players.active && (Players.active.trackTitle || Players.active.isPlaying))
    readonly property real mediaPosition: (Players.active && Players.active.position !== undefined) ? Players.active.position : 0.0
    readonly property real mediaLength: (Players.active && Players.active.length !== undefined) ? Players.active.length : 0.0
    readonly property real progressFraction: (mediaLength > 0) ? Math.min(1.0, Math.max(0.0, mediaPosition / mediaLength)) : 0.0

    function formatDuration(sec) {
        if (!sec || isNaN(sec) || sec <= 0) return "0:00";
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }

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
        spacing: 12

        // Header: Album Art & Track Info
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album Art Thumbnail
            Rectangle {
                width: 52
                height: 52
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                clip: true

                Image {
                    id: albumArt

                    anchors.fill: parent
                    source: (Players.active && Players.getArtUrl) ? Players.getArtUrl(Players.active) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !albumArt.visible
                    text: "󰝚"
                    font.pixelSize: 22
                    color: Theme.dim
                }
            }

            // Track & Artist Metadata
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    id: trackTitleText

                    Layout.fillWidth: true
                    text: root.hasMedia ? (Players.active.trackTitle || "Untitled Track") : "No media playing"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }

                Text {
                    id: trackArtistText

                    Layout.fillWidth: true
                    text: root.hasMedia ? (Players.active.trackArtist || "Unknown Artist") : "Playback idle"
                    font.pixelSize: 11
                    color: Theme.dim
                    elide: Text.ElideRight
                }
            }
        }

        // Seekbar Row
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                id: seekbarBg

                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    id: seekbarFill

                    width: parent.width * root.progressFraction
                    height: parent.height
                    radius: parent.radius
                    color: Theme.amber

                    Behavior on width {
                        NumberAnimation { duration: 150 }
                    }
                }

                MouseArea {
                    id: seekbarArea

                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (Players.active && Players.active.canSeek && root.mediaLength > 0) {
                            const frac = Math.max(0.0, Math.min(1.0, mouse.x / parent.width));
                            Players.active.position = frac * root.mediaLength;
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.formatDuration(root.mediaPosition)
                    font.pixelSize: 10
                    font.features: { "tnum": 1 }
                    color: Theme.dim
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.formatDuration(root.mediaLength)
                    font.pixelSize: 10
                    font.features: { "tnum": 1 }
                    color: Theme.dim
                }
            }
        }

        // Player Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Previous Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: prevArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.pixelSize: 14
                    color: Theme.text
                }

                MouseArea {
                    id: prevArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Players.active) {
                            Players.active.previous();
                        }
                    }
                }
            }

            // Play / Pause Button
            Rectangle {
                readonly property bool isPlaying: Boolean(Players.active && Players.active.isPlaying)

                width: 40
                height: 40
                radius: 20
                color: isPlaying ? Theme.amber : (playArea.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12))

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.isPlaying ? "󰏤" : "󰐊"
                    font.pixelSize: 18
                    color: parent.isPlaying ? Theme.ink : Theme.text
                }

                MouseArea {
                    id: playArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Players.active) {
                            Players.active.togglePlaying();
                        }
                    }
                }
            }

            // Next Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: nextArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.pixelSize: 14
                    color: Theme.text
                }

                MouseArea {
                    id: nextArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Players.active) {
                            Players.active.next();
                        }
                    }
                }
            }
        }
    }
}
