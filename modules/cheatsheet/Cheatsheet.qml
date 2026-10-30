import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"
import "KeybindsData.js" as KeybindsData

PanelWindow {
    id: root

    property bool isOpen: false
    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "splitdesk-cheatsheet"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property string activeCategory: "All"
    property string searchQuery: ""

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
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle() { root.toggle(); }
        function open() { root.open(); }
        function close() { root.close(); }
    }

    function getFilteredKeybinds() {
        const query = searchQuery.trim().toLowerCase();
        const allBinds = KeybindsData.getKeybinds();
        const res = [];

        for (let i = 0; i < allBinds.length; i++) {
            const b = allBinds[i];
            if (!b) continue;

            // Category filter
            if (activeCategory !== "All" && b.category !== activeCategory) {
                continue;
            }

            // Search query filter
            if (query.length > 0) {
                const desc = (b.desc || "").toLowerCase();
                const key = (b.key || "").toLowerCase();
                const cat = (b.category || "").toLowerCase();
                const act = (b.action || "").toLowerCase();
                const mods = (b.mods || []).join(" ").toLowerCase();

                if (!desc.includes(query) && !key.includes(query) && !cat.includes(query) && !act.includes(query) && !mods.includes(query)) {
                    continue;
                }
            }

            res.push(b);
        }
        return res;
    }

    // Full-screen Scrim Backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Centered Glass Modal Card
    Rectangle {
        id: card
        width: 880
        height: 640
        anchors.centerIn: parent
        radius: Theme.radiusWindow
        color: Theme.inkPanel
        border.color: Theme.edge
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Stop propagation to backdrop
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Keybinds Cheatsheet"
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.text
                }

                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 20
                    radius: 10
                    color: Qt.rgba(233/255, 180/255, 76/255, 0.2)
                    border.color: Theme.amber
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "SLANT V4"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.amber
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Bar
                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.preferredHeight: 36
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: searchInput.activeFocus ? Theme.teal : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "🔍"
                            font.pixelSize: 12
                            color: Theme.dim
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.pixelSize: 12
                            color: Theme.text
                            clip: true
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                visible: !searchInput.text && !searchInput.inputMethodComposing
                                text: "Search shortcuts (key, action, region)..."
                                font.pixelSize: 12
                                color: Qt.rgba(159/255, 179/255, 196/255, 0.45)
                            }

                            onTextChanged: {
                                root.searchQuery = searchInput.text;
                            }

                            Keys.onEscapePressed: root.close()
                        }
                    }
                }

                // Close Button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 14
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

            // Category Filter Pills
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: KeybindsData.getCategories()

                    Rectangle {
                        id: pill
                        readonly property bool isActive: root.activeCategory === modelData
                        readonly property bool isSlantCategory: modelData === "Slant Bifurcated"
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: pillLabel.implicitWidth + 20
                        radius: 8

                        color: isActive
                               ? (isSlantCategory ? Qt.rgba(233/255, 180/255, 76/255, 0.3) : Qt.rgba(31/255, 122/255, 122/255, 0.35))
                               : (pillMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: isActive
                                      ? (isSlantCategory ? Theme.amber : Theme.teal)
                                      : (isSlantCategory ? Qt.rgba(233/255, 180/255, 76/255, 0.4) : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        Text {
                            id: pillLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: pill.isActive || pill.isSlantCategory
                            color: pill.isActive
                                   ? (pill.isSlantCategory ? Theme.amber : Theme.text)
                                   : (pill.isSlantCategory ? Theme.amber : Theme.dim)
                        }

                        MouseArea {
                            id: pillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeCategory = modelData;
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Keybindings Grid / ListView
            ListView {
                id: bindsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.getFilteredKeybinds()

                delegate: CheatsheetCard {
                    width: bindsList.width
                    bind: modelData
                }

                Text {
                    anchors.centerIn: parent
                    visible: bindsList.count === 0
                    text: "No shortcuts match query \"" + root.searchQuery + "\""
                    font.pixelSize: 13
                    color: Theme.dim
                }
            }
        }
    }
}
