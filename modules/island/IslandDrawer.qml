// IslandDrawer.qml — accordion expansion card (media controls + splitdesk quick toggles)
// Wired to: Quickshell.Services.Mpris (Players), Quickshell.Services.Pipewire (Audio), Niri, IdleInhibitor

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../splitdesk_services"

Item {
    id: root

    property bool open: false

    clip: true
    implicitWidth: 320
    implicitHeight: open ? content.implicitHeight : 0

    Behavior on implicitHeight {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    // Active MPRIS player (null-safe)
    readonly property MprisPlayer player: Players.active

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 0

        // ── Media section ────────────────────────────────────────────────────

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            implicitHeight: mediaCol.implicitHeight + 16
            radius: Theme.radiusTile
            color: Qt.rgba(1, 1, 1, 0.05)
            visible: root.player !== null

            ColumnLayout {
                id: mediaCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 4

                // Track title
                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle ?? ""
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                // Artist
                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist ?? ""
                    color: Theme.dim
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                // Prev / PlayPause / Next
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    // Previous
                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: prevArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.pixelSize: 14
                            color: (root.player?.canGoPrevious ?? false) ? Theme.text : Theme.dim
                        }
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.player?.canGoPrevious) root.player.previous(); }
                        }
                    }

                    // Play / Pause
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: ppArea.containsMouse ? Theme.amber : Qt.rgba(233/255, 180/255, 76/255, 0.80)
                        Text {
                            anchors.centerIn: parent
                            text: (root.player?.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                            font.pixelSize: 15
                            color: Theme.ink
                        }
                        MouseArea {
                            id: ppArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.player?.canTogglePlaying) root.player.togglePlaying(); }
                        }
                    }

                    // Next
                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: nextArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.pixelSize: 14
                            color: (root.player?.canGoNext ?? false) ? Theme.text : Theme.dim
                        }
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.player?.canGoNext) root.player.next(); }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        // Fallback: no player
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.leftMargin: 12
            visible: root.player === null
            text: "♪  No media"
            color: Theme.dim
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }

        // ── Quick toggles ────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 6

            // Split Mode toggle — amber when enabled
            ToggleChip {
                label: "Split"
                icon: "󰕢"
                active: Niri.regionsEnabled
                onToggled: Niri.toggleSplitMode()
            }

            // Region Focus toggle — teal when Left
            ToggleChip {
                label: Niri.focusedRegion === "Left" ? "[L]" : "[R]"
                icon: "󰝘"
                active: Niri.focusedRegion === "Left"
                activeColor: Theme.teal
                onToggled: Niri.toggleRegionFocus()
            }

            // Volume / Mute toggle
            ToggleChip {
                label: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
                icon: Audio.muted ? "󰖁" : "󰕾"
                active: !Audio.muted
                activeColor: Theme.teal
                onToggled: {
                    if (Audio.sink?.audio)
                        Audio.sink.audio.muted = !Audio.sink.audio.muted;
                }
            }

            // Idle Inhibit / Night Light toggle
            ToggleChip {
                label: "Idle"
                icon: IdleInhibitor.enabled ? "󰛨" : "󰛩"
                active: IdleInhibitor.enabled
                activeColor: Theme.teal
                onToggled: IdleInhibitor.enabled = !IdleInhibitor.enabled
            }
        }
    }

    // ── Inline sub-component: ToggleChip ──────────────────────────────────────
    // ponytail: extract to components/ if used outside island; single use here

    component ToggleChip: Rectangle {
        required property string label
        required property string icon
        required property bool active

        property color activeColor: Theme.amber

        signal toggled()

        Layout.fillWidth: true
        implicitHeight: 36
        radius: 999
        color: active ? Qt.alpha(activeColor, 0.20) : Qt.rgba(1, 1, 1, 0.07)

        border.color: active ? Qt.alpha(activeColor, 0.60) : "transparent"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.icon
                font.pixelSize: 13
                color: parent.parent.active ? parent.parent.activeColor : Theme.dim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.label
                font.pixelSize: 10
                color: parent.parent.active ? parent.parent.activeColor : Theme.dim
            }
        }

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }
    }
}
