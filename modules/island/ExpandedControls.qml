// ExpandedControls.qml — Accordion expansion controls for splitdesk Dynamic Island
// Media playback controls and quick toggles (Split mode toggle, Region switch, Volume, Night Light).

import QtQuick
import QtQuick.Layouts
import splitdesk.services

ColumnLayout {
    id: root

    property bool nightLightActive: false

    spacing: 8

    // ── 1. Media Playback Controls ───────────────────────────────────────────
    Rectangle {
        id: mediaCard
        Layout.fillWidth: true
        Layout.preferredHeight: 46

        radius: 14
        color: Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(255, 255, 255, 0.08)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            // Track metadata
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    id: trackTitle
                    Layout.fillWidth: true

                    text: (Players.active && Players.active.trackTitle) ? Players.active.trackTitle : "No media playing"
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    id: trackArtist
                    Layout.fillWidth: true

                    visible: text.length > 0
                    text: (Players.active && Players.active.trackArtist) ? Players.active.trackArtist : ""
                    color: Theme.dim
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            // Transport buttons
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                // Previous
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Theme.dim
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: prevMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                        if (Players.active)
                            Players.active.previous();
                    }
                    }
                }

                // Play / Pause
                Rectangle {
                    readonly property bool isPlaying: Boolean(Players.active && Players.active.isPlaying)

                    width: 30
                    height: 30
                    radius: 15
                    color: isPlaying ? Theme.amber : (playMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12))

                    Behavior on color {
                        ColorAnimation { duration: 180 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.isPlaying ? "󰏤" : "󰐊"
                        color: parent.isPlaying ? Theme.ink : Theme.text
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: playMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                        if (Players.active)
                            Players.active.togglePlaying();
                    }
                    }
                }

                // Next
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Theme.dim
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                        if (Players.active)
                            Players.active.next();
                    }
                    }
                }
            }
        }
    }

    // ── 2. Quick Toggles Row ─────────────────────────────────────────────────
    RowLayout {
        id: togglesRow
        Layout.fillWidth: true
        Layout.preferredHeight: 36

        spacing: 6

        // 1. Split Mode Toggle
        Rectangle {
            id: splitBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            radius: 12
            color: Niri.regionsEnabled
                ? Qt.rgba(31/255, 122/255, 122/255, 0.35)
                : (splitMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
            border.color: Niri.regionsEnabled ? Theme.teal : Qt.rgba(255, 255, 255, 0.12)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "◫"
                    font.pixelSize: 13
                    color: Niri.regionsEnabled ? Theme.teal : Theme.dim
                }

                Text {
                    text: "Split"
                    font.pixelSize: 11
                    font.weight: Niri.regionsEnabled ? Font.Bold : Font.Normal
                    color: Niri.regionsEnabled ? Theme.text : Theme.dim
                }
            }

            MouseArea {
                id: splitMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.toggleSplitMode()
            }
        }

        // 2. Region Switch
        Rectangle {
            id: regionBtn

            readonly property bool isLeft: Niri.focusedRegion === "Left"

            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 12
            color: Niri.regionsEnabled
                ? (isLeft ? Qt.rgba(31/255, 122/255, 122/255, 0.35) : Qt.rgba(233/255, 180/255, 76/255, 0.35))
                : (regionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
            border.color: !Niri.regionsEnabled
                ? Qt.rgba(255, 255, 255, 0.12)
                : (isLeft ? Theme.teal : Theme.amber)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "⇄"
                    font.pixelSize: 13
                    color: !Niri.regionsEnabled ? Theme.dim : (regionBtn.isLeft ? Theme.teal : Theme.amber)
                }

                Text {
                    text: !Niri.regionsEnabled ? "Focus" : (regionBtn.isLeft ? "Reg [L]" : "Reg [R]")
                    font.pixelSize: 11
                    font.weight: Niri.regionsEnabled ? Font.Bold : Font.Normal
                    color: Niri.regionsEnabled ? Theme.text : Theme.dim
                }
            }

            MouseArea {
                id: regionMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.toggleRegionFocus()
            }
        }

        // 3. Volume Toggle
        Rectangle {
            id: volumeBtn

            readonly property bool isMuted: Audio.muted

            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 12
            color: !isMuted
                ? Qt.rgba(31/255, 122/255, 122/255, 0.25)
                : (volMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
            border.color: !isMuted ? Theme.teal : Qt.rgba(255, 255, 255, 0.12)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: volumeBtn.isMuted ? "󰖁" : "󰕾"
                    font.pixelSize: 13
                    color: !volumeBtn.isMuted ? Theme.teal : Theme.dim
                }

                Text {
                    text: volumeBtn.isMuted ? "Mute" : Math.round(Audio.volume * 100) + "%"
                    font.pixelSize: 11
                    font.weight: !volumeBtn.isMuted ? Font.Bold : Font.Normal
                    color: !volumeBtn.isMuted ? Theme.text : Theme.dim
                }
            }

            MouseArea {
                id: volMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Audio.sink && Audio.sink.audio)
                        Audio.sink.audio.muted = !Audio.sink.audio.muted;
                }
            }
        }

        // 4. Night Light Toggle
        Rectangle {
            id: nightBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            radius: 12
            color: root.nightLightActive
                ? Qt.rgba(233/255, 180/255, 76/255, 0.35)
                : (nightMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
            border.color: root.nightLightActive ? Theme.amber : Qt.rgba(255, 255, 255, 0.12)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: root.nightLightActive ? "󰌵" : "󰌶"
                    font.pixelSize: 13
                    color: root.nightLightActive ? Theme.amber : Theme.dim
                }

                Text {
                    text: root.nightLightActive ? "Night" : "Day"
                    font.pixelSize: 11
                    font.weight: root.nightLightActive ? Font.Bold : Font.Normal
                    color: root.nightLightActive ? Theme.text : Theme.dim
                }
            }

            MouseArea {
                id: nightMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nightLightActive = !root.nightLightActive
            }
        }
    }
}
