import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "splitdesk-notification-toasts"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors.top: true
    anchors.right: true
    anchors.topMargin: 68
    anchors.rightMargin: 16

    width: 340
    height: Math.min(600, Math.max(1, toastList.contentHeight))
    visible: Notifications.notifications.length > 0
    color: "transparent"

    ListView {
        id: toastList
        anchors.fill: parent
        spacing: 10
        interactive: false
        model: Notifications.notifications

        delegate: Rectangle {
            id: toastCard
            required property var modelData
            required property int index

            width: toastList.width
            height: 72
            radius: 14
            color: "#181824"
            border.color: "#2e2e42"
            border.width: 1

            Timer {
                interval: 5000
                running: true
                repeat: false
                onTriggered: {
                    if (toastCard.modelData) {
                        Notifications.dismiss(toastCard.modelData.id);
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: "#222232"

                    Text {
                        anchors.centerIn: parent
                        text: "🔔"
                        font.pixelSize: 14
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: toastCard.modelData && toastCard.modelData.summary ? toastCard.modelData.summary : "Notification"
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: toastCard.modelData && toastCard.modelData.appName ? toastCard.modelData.appName : ""
                            font.pixelSize: 10
                            color: Theme.dim
                        }
                    }

                    Text {
                        text: toastCard.modelData && toastCard.modelData.body ? toastCard.modelData.body : ""
                        font.pixelSize: 11
                        color: Theme.dim
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: closeBtnArea.containsMouse ? "#2f2f45" : "#222232"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 10
                        color: Theme.dim
                    }

                    MouseArea {
                        id: closeBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (toastCard.modelData) {
                                Notifications.dismiss(toastCard.modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
}
