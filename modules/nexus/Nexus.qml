import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    property bool isOpen: false
    visible: isOpen

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "splitdesk-nexus"

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
        target: "nexus"
        function toggle() {
            root.toggle();
        }
    }

    // Dismiss on backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // Slide-in drawer on top-right
    Rectangle {
        id: panel
        width: 380
        height: Math.min(parent.height - 32, 640)
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        radius: 18
        color: "#16161f"
        border.color: "#28283a"
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Absorb clicks inside
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Control Center"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.text
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeArea.containsMouse ? "#2e2e42" : "#222230"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.dim
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.close()
                    }
                }
            }

            // Quick Toggles Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // Wi-Fi Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 12
                    color: Network.enabled ? "#1f3838" : "#20202c"
                    border.color: Network.enabled ? Theme.teal : "#2b2b3c"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: Network.connected ? "󰖩" : "󰖪"
                            font.pixelSize: 18
                            color: Network.enabled ? Theme.amber : Theme.dim
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Wi-Fi"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.text
                            }

                            Text {
                                text: Network.connected ? Network.activeSsid : (Network.enabled ? "Disconnected" : "Off")
                                font.pixelSize: 10
                                color: Theme.dim
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Network.toggleWifi()
                    }
                }

                // Bluetooth Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 12
                    color: Bluetooth.enabled ? "#252b3d" : "#20202c"
                    border.color: Bluetooth.enabled ? "#4d79ff" : "#2b2b3c"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: Bluetooth.enabled ? "󰂯" : "󰂲"
                            font.pixelSize: 18
                            color: Bluetooth.enabled ? "#6699ff" : Theme.dim
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Bluetooth"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.text
                            }

                            Text {
                                text: Bluetooth.enabled ? (Bluetooth.connectedDevices.length > 0 ? Bluetooth.connectedDevices[0].name : "On") : "Off"
                                font.pixelSize: 10
                                color: Theme.dim
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Bluetooth.togglePower()
                    }
                }
            }

            // Sliders Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Volume
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Audio.muted ? "󰝟 Muted" : "󰕾 Volume"
                            font.pixelSize: 12
                            color: Theme.dim
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(Audio.volume * 100) + "%"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.text
                        }
                    }

                    Slider {
                        id: volumeSlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: Audio.volume
                        onMoved: Audio.setVolume(value)
                    }
                }

                // Brightness
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰃠 Brightness"
                            font.pixelSize: 12
                            color: Theme.dim
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(Brightness.value * 100) + "%"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.text
                        }
                    }

                    Slider {
                        id: brightnessSlider
                        Layout.fillWidth: true
                        from: 0.01
                        to: 1.0
                        value: Brightness.value
                        onMoved: Brightness.setBrightness(value)
                    }
                }
            }

            // Notifications Section
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Text {
                    text: "Notifications (" + Notifications.unreadCount + ")"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.text
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Clear All"
                    font.pixelSize: 11
                    color: Theme.amber
                    visible: Notifications.unreadCount > 0

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifications.clearAll()
                    }
                }
            }

            // Notification List
            ListView {
                id: notifList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: Notifications.notifications

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: notifList.width
                    height: 56
                    radius: 10
                    color: "#1c1c27"
                    border.color: "#28283a"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData && modelData.summary ? modelData.summary : "Notification"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData && modelData.body ? modelData.body : ""
                                font.pixelSize: 11
                                color: Theme.dim
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: "#262638"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 9
                                color: Theme.dim
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData) Notifications.dismiss(modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
