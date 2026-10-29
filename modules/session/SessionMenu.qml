import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    property bool isOpen: false
    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "splitdesk-session"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    function toggle() {
        isOpen = !isOpen;
    }

    function close() {
        isOpen = false;
    }

    IpcHandler {
        target: "session"
        function toggle() {
            root.toggle();
        }
    }

    Process {
        id: execProc
        running: false
    }

    function runCmd(args) {
        if (execProc.running) execProc.running = false;
        execProc.command = args;
        execProc.running = true;
        root.close();
    }

    // Semi-transparent backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Centered Card
    Rectangle {
        id: card
        width: 440
        height: 160
        anchors.centerIn: parent
        radius: 20
        color: "#181822"
        border.color: "#2a2a3c"
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Prevent clicks from dismissing
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: "Power & Session"
                font.pixelSize: 15
                font.bold: true
                color: Theme.text
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Lock
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: lockArea.containsMouse ? "#28283a" : "#20202c"
                    border.color: "#2e2e42"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "🔒"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Lock"
                            font.pixelSize: 11
                            color: Theme.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: lockArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runCmd(["loginctl", "lock-session"])
                    }
                }

                // Suspend
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: suspendArea.containsMouse ? "#28283a" : "#20202c"
                    border.color: "#2e2e42"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "💤"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Suspend"
                            font.pixelSize: 11
                            color: Theme.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: suspendArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runCmd(["systemctl", "suspend"])
                    }
                }

                // Logout
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: logoutArea.containsMouse ? "#28283a" : "#20202c"
                    border.color: "#2e2e42"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "🚪"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Log Out"
                            font.pixelSize: 11
                            color: Theme.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: logoutArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runCmd(["niri", "msg", "action", "quit", "--skip-confirmation"])
                    }
                }

                // Reboot
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: rebootArea.containsMouse ? "#28283a" : "#20202c"
                    border.color: "#2e2e42"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "🔄"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Reboot"
                            font.pixelSize: 11
                            color: Theme.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runCmd(["systemctl", "reboot"])
                    }
                }

                // Power Off
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: powerArea.containsMouse ? "#3b1e22" : "#20202c"
                    border.color: powerArea.containsMouse ? "#cc4444" : "#2e2e42"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "⏻"
                            font.pixelSize: 18
                            color: "#ff5555"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Power Off"
                            font.pixelSize: 11
                            color: Theme.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runCmd(["systemctl", "poweroff"])
                    }
                }
            }
        }
    }
}
