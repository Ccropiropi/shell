import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../splitdesk_services"

Scope {
    id: root

    property alias locked: sessionLock.locked

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface

            Rectangle {
                anchors.fill: parent
                color: "#0a0a10"

                // Subtle radial glow behind clock
                Rectangle {
                    width: 600
                    height: 600
                    anchors.centerIn: parent
                    radius: 300
                    color: Qt.rgba(233/255, 180/255, 76/255, 0.03)
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 24

                    // Oversized Clock
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            id: timeText
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.pixelSize: 84
                            font.bold: true
                            font.letterSpacing: -2
                            color: Theme.text

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                            }
                        }

                        Text {
                            id: dateText
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.pixelSize: 18
                            color: Theme.dim

                            Timer {
                                interval: 60000
                                running: true
                                repeat: true
                                onTriggered: dateText.text = Qt.formatDate(new Date(), "dddd, MMMM d")
                            }
                        }
                    }

                    // User & Password Input Card
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 320
                        height: 140
                        radius: 16
                        color: "#161622"
                        border.color: "#28283c"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Text {
                                    text: "👤"
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: "User Session"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.text
                                }
                            }

                            // Password Input Box
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 8
                                color: "#1c1c2a"
                                border.color: pam.authFailed ? "#ff5555" : (pwdInput.activeFocus ? Theme.amber : "#2a2a3e")
                                border.width: 1

                                TextInput {
                                    id: pwdInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    color: Theme.text
                                    font.pixelSize: 14
                                    focus: sessionLock.locked
                                    clip: true

                                    onAccepted: {
                                        if (text.length > 0) {
                                            pam.authenticate(text);
                                        }
                                    }
                                }
                            }

                            // Feedback message
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: pam.message ? pam.message : (pam.active ? "Verifying..." : "Press Enter to unlock")
                                font.pixelSize: 11
                                color: pam.authFailed ? "#ff5555" : Theme.dim
                            }
                        }
                    }

                    // Media playback banner
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 320
                        height: 48
                        radius: 12
                        color: "#14141e"
                        border.color: "#222232"
                        border.width: 1
                        visible: Players.isPlaying && Players.trackTitle.length > 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: "🎵"
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: Players.trackTitle
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: Players.artist
                                    font.pixelSize: 10
                                    color: Theme.dim
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Pam {
        id: pam
        onUnlocked: {
            sessionLock.locked = false;
            pwdInput.text = "";
        }
        onFailed: {
            pwdInput.text = "";
        }
    }

    IpcHandler {
        target: "lock"
        function lock() {
            sessionLock.locked = true;
        }
        function unlock() {
            sessionLock.locked = false;
        }
    }
}
