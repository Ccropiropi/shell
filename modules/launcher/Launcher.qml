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

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "splitdesk-launcher"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    function toggle() {
        isOpen = !isOpen;
        if (isOpen) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    function close() {
        isOpen = false;
    }

    IpcHandler {
        target: "launcher"
        function toggle() {
            root.toggle();
        }
    }

    function evaluateMath(expr) {
        if (!expr || expr.length > 256) return null;
        if (!/^[0-9+\-*/().^ %eEpiPI\s]+$/.test(expr)) return null;
        try {
            const sanitized = expr.replace(/\^/g, "**")
                                  .replace(/\bpi\b/gi, "Math.PI")
                                  .replace(/\b[eE]\b/g, "Math.E");
            const res = Function('"use strict"; return (' + sanitized + ')')();
            return Number.isFinite(res) ? String(res) : null;
        } catch (e) {
            return null;
        }
    }

    // Backdrop click dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // Modal dialog card
    Rectangle {
        id: card
        width: 560
        height: 420
        anchors.centerIn: parent
        radius: 16
        color: "#16161d"
        border.color: "#282834"
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Prevent clicks from dismissing
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 10
                color: "#1c1c24"
                border.color: searchInput.activeFocus ? Theme.amber : "#2a2a38"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "🔍"
                        font.pixelSize: 14
                        color: "#888899"
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "#f0f0f5"
                        font.pixelSize: 14
                        clip: true
                        focus: root.isOpen

                        property string mathResult: root.evaluateMath(text.trim())

                        Keys.onEscapePressed: root.close()
                        Keys.onDownPressed: {
                            if (appListView.count > 0) {
                                appListView.currentIndex = Math.min(appListView.currentIndex + 1, appListView.count - 1);
                            }
                        }
                        Keys.onUpPressed: {
                            if (appListView.count > 0) {
                                appListView.currentIndex = Math.max(appListView.currentIndex - 1, 0);
                            }
                        }
                        Keys.onReturnPressed: {
                            if (mathResult !== null) {
                                searchInput.text = mathResult;
                                return;
                            }
                            if (appListView.count > 0 && appListView.currentItem) {
                                appListView.currentItem.launch();
                                root.close();
                            }
                        }
                    }
                }
            }

            // Math evaluation result pill
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 8
                color: "#20252b"
                border.color: Theme.amber
                border.width: 1
                visible: searchInput.mathResult !== null

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: "Result:"
                        color: "#88a0b0"
                        font.pixelSize: 13
                    }

                    Text {
                        Layout.fillWidth: true
                        text: searchInput.mathResult ? searchInput.mathResult : ""
                        color: Theme.amber
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }

            // Applications List
            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4

                model: DesktopEntries.applications

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    width: appListView.width
                    height: matchesQuery ? 44 : 0
                    visible: matchesQuery
                    radius: 8
                    color: appListView.currentIndex === index ? "#262634" : (itemMouseArea.containsMouse ? "#1e1e28" : "transparent")

                    readonly property string appName: modelData && modelData.name ? modelData.name : ""
                    readonly property string appComment: modelData && modelData.genericName ? modelData.genericName : ""
                    readonly property string q: searchInput.text.trim().toLowerCase()
                    readonly property bool matchesQuery: {
                        if (!q || searchInput.mathResult !== null) return true;
                        return appName.toLowerCase().indexOf(q) !== -1 || appComment.toLowerCase().indexOf(q) !== -1;
                    }

                    function launch() {
                        if (modelData) {
                            modelData.execute();
                            root.close();
                        }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: delegateRoot.launch()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        visible: delegateRoot.matchesQuery

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: "#222230"
                            Text {
                                anchors.centerIn: parent
                                text: delegateRoot.appName.length > 0 ? delegateRoot.appName.charAt(0).toUpperCase() : "A"
                                color: Theme.amber
                                font.bold: true
                                font.pixelSize: 13
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: delegateRoot.appName
                                color: "#f0f0f5"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: delegateRoot.appComment
                                color: "#808094"
                                font.pixelSize: 11
                                visible: text.length > 0
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
