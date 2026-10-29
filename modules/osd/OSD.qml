import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "splitdesk-osd"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // Gate 3: 100% click/pointer pass-through
    mask: Region {}

    anchors.bottom: true
    anchors.bottomMargin: 90
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property string icon: "󰕾"
    property string title: "Volume"
    property real progress: 0.5
    property bool isMuted: false
    property bool showOsd: false

    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: root.showOsd = false
    }

    function trigger(newIcon, newTitle, newProgress, muted) {
        icon = newIcon;
        title = newTitle;
        progress = Math.max(0.0, Math.min(1.0, newProgress));
        isMuted = muted;
        showOsd = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.trigger(Audio.muted ? "󰝟" : "󰕾", "Volume", Audio.volume, Audio.muted);
        }
        function onMutedChanged() {
            root.trigger(Audio.muted ? "󰝟" : "󰕾", "Volume", Audio.volume, Audio.muted);
        }
    }

    Connections {
        target: Brightness
        function onValueChanged() {
            root.trigger("󰃠", "Brightness", Brightness.value, false);
        }
    }

    // Floating OSD pill centered horizontally
    Rectangle {
        id: pill
        width: 260
        height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 18
        color: "#181824"
        border.color: "#303046"
        border.width: 1

        opacity: root.showOsd ? 1.0 : 0.0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: root.icon
                font.pixelSize: 22
                color: root.isMuted ? "#ff5555" : Theme.amber
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.title
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.text
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.isMuted ? "Muted" : (Math.round(root.progress * 100) + "%")
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: "#28283c"

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: 3
                        color: root.isMuted ? "#ff5555" : Theme.amber
                    }
                }
            }
        }
    }
}
