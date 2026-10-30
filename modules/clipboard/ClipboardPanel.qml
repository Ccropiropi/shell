import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    property bool isOpen: false
    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "splitdesk-clipboard"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property string activeTab: "All" // "All", "Text", "Images", "Pinned"
    property string searchQuery: ""
    property int selectedIndex: 0

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        isOpen = true;
        searchQuery = "";
        searchInput.text = "";
        selectedIndex = 0;
        Cliphist.refresh();
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
    }

    IpcHandler {
        target: "clipboard"
        function toggle() { root.toggle(); }
        function open() { root.open(); }
        function close() { root.close(); }
    }

    function getFilteredList() {
        const query = searchQuery.trim().toLowerCase();
        let baseList = [];

        if (activeTab === "Pinned") {
            baseList = Cliphist.pinnedEntries || [];
        } else {
            baseList = Cliphist.entries || [];
        }

        const res = [];
        for (let i = 0; i < baseList.length; i++) {
            const item = baseList[i];
            if (!item) continue;

            // Tab filtering
            if (activeTab === "Text" && item.isImage) continue;
            if (activeTab === "Images" && !item.isImage) continue;

            // Query filtering
            if (query.length > 0) {
                const preview = (item.preview || "").toLowerCase();
                const dims = (item.dims || "").toLowerCase();
                const idStr = String(item.id || "");
                if (!preview.includes(query) && !dims.includes(query) && !idStr.includes(query)) {
                    continue;
                }
            }
            res.push(item);
        }
        return res;
    }

    // Semi-transparent backdrop for click-to-dismiss (Finding R2)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Central Glass Card
    Rectangle {
        id: card
        width: 520
        height: 620
        anchors.centerIn: parent
        radius: Theme.radiusWindow
        color: Theme.inkPanel
        border.color: Theme.edge
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Prevent clicks inside card from propagating to backdrop
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Top Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Clipboard History"
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.text
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 18
                    radius: 9
                    color: Qt.rgba(31/255, 122/255, 122/255, 0.25)
                    border.color: Qt.rgba(31/255, 122/255, 122/255, 0.5)

                    Text {
                        anchors.centerIn: parent
                        text: String(root.getFilteredList().length)
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.teal
                    }
                }

                Item { Layout.fillWidth: true }

                // Clear All / Wipe button
                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 28
                    radius: 6
                    color: wipeArea.containsMouse ? Qt.rgba(233/255, 76/255, 76/255, 0.25) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: wipeArea.containsMouse ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.pixelSize: 11
                        color: wipeArea.containsMouse ? "#ff6b6b" : Theme.dim
                    }

                    MouseArea {
                        id: wipeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Cliphist.clearAll()
                    }
                }

                // Close Button
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 6
                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: Theme.dim
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: searchInput.activeFocus ? Theme.teal : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "🔍"
                        font.pixelSize: 14
                        color: Theme.dim
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        color: Theme.text
                        clip: true
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                            text: "Search clipboard history..."
                            font.pixelSize: 13
                            color: Qt.rgba(159/255, 179/255, 196/255, 0.45)
                        }

                        onTextChanged: {
                            root.searchQuery = searchInput.text;
                            root.selectedIndex = 0;
                        }

                        Keys.onEscapePressed: root.close()

                        Keys.onDownPressed: {
                            const list = root.getFilteredList();
                            if (root.selectedIndex < list.length - 1) {
                                root.selectedIndex++;
                                listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            }
                        }

                        Keys.onUpPressed: {
                            if (root.selectedIndex > 0) {
                                root.selectedIndex--;
                                listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            }
                        }

                        Keys.onReturnPressed: {
                            const list = root.getFilteredList();
                            if (list.length > root.selectedIndex && root.selectedIndex >= 0) {
                                const item = list[root.selectedIndex];
                                Cliphist.copy(item.id, item.isImage);
                                root.close();
                            }
                        }

                        Keys.onDeletePressed: {
                            const list = root.getFilteredList();
                            if (list.length > root.selectedIndex && root.selectedIndex >= 0) {
                                const item = list[root.selectedIndex];
                                Cliphist.deleteEntry(item.raw);
                            }
                        }
                    }
                }
            }

            // Category Filter Pills
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: ["All", "Text", "Images", "Pinned"]

                    Rectangle {
                        id: pill
                        readonly property bool isActive: root.activeTab === modelData
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: pillText.implicitWidth + 24
                        radius: 8
                        color: isActive
                               ? Qt.rgba(31/255, 122/255, 122/255, 0.35)
                               : (pillMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: isActive ? Theme.teal : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 12
                            font.bold: pill.isActive
                            color: pill.isActive ? Theme.text : Theme.dim
                        }

                        MouseArea {
                            id: pillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = modelData;
                                root.selectedIndex = 0;
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Entries ListView
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: root.getFilteredList()

                delegate: ClipboardItem {
                    width: listView.width
                    entry: modelData
                    isSelected: index === root.selectedIndex
                    isPinned: Cliphist.isPinned(modelData ? modelData.raw : "")

                    onSelectRequested: {
                        root.selectedIndex = index;
                    }

                    onCopyRequested: {
                        Cliphist.copy(modelData.id, modelData.isImage);
                        root.close();
                    }

                    onPinRequested: {
                        Cliphist.togglePin(modelData);
                    }

                    onDeleteRequested: {
                        Cliphist.deleteEntry(modelData.raw);
                    }
                }

                // Empty state indicator
                Text {
                    anchors.centerIn: parent
                    visible: listView.count === 0
                    text: root.searchQuery ? "No matching clipboard entries" : "Clipboard is empty"
                    font.pixelSize: 13
                    color: Theme.dim
                }
            }
        }
    }
}
