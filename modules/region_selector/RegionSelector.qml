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
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "splitdesk-region-selector"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property string currentAction: "copy" // "copy" or "ocr"
    property string selectedPreset: "drag" // "drag", "left", "right", "fullscreen"

    // Drag selection coordinates
    property int dragStartX: 0
    property int dragStartY: 0
    property int dragCurrentX: 0
    property int dragCurrentY: 0
    property bool isDragging: false

    // Active selection box
    property int selX: 0
    property int selY: 0
    property int selW: 0
    property int selH: 0

    function toggle() {
        if (isOpen) {
            close();
        } else {
            openWithAction("copy");
        }
    }

    function openWithAction(action) {
        currentAction = action === "ocr" ? "ocr" : "copy";
        selectedPreset = "drag";
        selX = 0;
        selY = 0;
        selW = 0;
        selH = 0;
        isDragging = false;
        isOpen = true;
    }

    function close() {
        isOpen = false;
        isDragging = false;
    }

    IpcHandler {
        target: "region"
        function screenshot() { root.openWithAction("copy"); }
        function ocr() { root.openWithAction("ocr"); }
        function toggle() { root.toggle(); }
        function close() { root.close(); }
    }

    function applyPreset(name) {
        selectedPreset = name;
        const sw = root.width > 0 ? root.width : 1920;
        const sh = root.height > 0 ? root.height : 1080;

        if (name === "left") {
            selX = 0;
            selY = 0;
            selW = Math.round(sw * 0.46);
            selH = sh;
        } else if (name === "right") {
            const leftW = Math.round(sw * 0.46);
            selX = leftW;
            selY = 0;
            selW = sw - leftW;
            selH = sh;
        } else if (name === "fullscreen") {
            selX = 0;
            selY = 0;
            selW = sw;
            selH = sh;
        } else {
            selX = 0;
            selY = 0;
            selW = 0;
            selH = 0;
        }
    }

    // Capture triggering logic with Guardrails C1 (Unmap 60ms) and C4 (Min bounds 8x8)
    function triggerCapture() {
        if (selW < 8 || selH < 8) {
            console.warn("[RegionSelector] Selection too small for capture (< 8x8 px):", selW, "x", selH);
            return;
        }

        const geom = selX + "," + selY + " " + selW + "x" + selH;
        captureTimer.geom = geom;
        captureTimer.action = currentAction;

        // Immediately hide overlay so grim does not capture the overlay scrim/UI (Finding C1)
        root.close();

        // Yield execution 60ms for compositor to unmap overlay surface and repaint clean desktop
        captureTimer.start();
    }

    Timer {
        id: captureTimer
        interval: 60
        repeat: false
        property string geom: ""
        property string action: "copy"

        onTriggered: {
            if (action === "copy") {
                root.executeScreenshot(geom);
            } else if (action === "ocr") {
                root.executeOcr(geom);
            }
        }
    }

    function executeScreenshot(geom) {
        const script =
            'geom="$1"; ' +
            'dir="$HOME/Pictures/Screenshots"; ' +
            'mkdir -p "$dir"; ' +
            'file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"; ' +
            'if /usr/sbin/grim -g "$geom" - > "$file"; then ' +
            '    /usr/sbin/wl-copy --type image/png < "$file"; ' +
            '    /usr/bin/notify-send "Screenshot Captured" "Copied to clipboard and saved to $file" -a "Splitdesk"; ' +
            'else ' +
            '    rm -f "$file"; ' +
            '    /usr/bin/notify-send "Screenshot Failed" "Could not capture region $geom" -u critical -a "Splitdesk"; ' +
            'fi';
        Quickshell.execDetached(["/usr/bin/bash", "-c", script, "_", geom]);
    }

    function executeOcr(geom) {
        const script =
            'geom="$1"; ' +
            'raw=$(/usr/sbin/grim -g "$geom" - | /usr/sbin/tesseract stdin stdout -l eng 2>/dev/null); ' +
            'clean=$(printf "%s" "$raw" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//"); ' +
            'if [ -n "$clean" ]; then ' +
            '    printf "%s" "$clean" | /usr/sbin/wl-copy; ' +
            '    snippet=$(printf "%s" "$clean" | head -n 2 | cut -c 1-80); ' +
            '    /usr/bin/notify-send "OCR Text Copied" "$snippet" -a "Splitdesk OCR"; ' +
            'else ' +
            '    /usr/bin/notify-send "OCR Completed" "No recognizable text found in selection" -a "Splitdesk OCR"; ' +
            'fi';
        Quickshell.execDetached(["/usr/bin/bash", "-c", script, "_", geom]);
    }

    // Fullscreen Scrim Backdrop
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.40)

        // MouseArea for freeform rubber-band selection
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor

            onPressed: mouse => {
                root.selectedPreset = "drag";
                root.dragStartX = mouse.x;
                root.dragStartY = mouse.y;
                root.dragCurrentX = mouse.x;
                root.dragCurrentY = mouse.y;
                root.selX = mouse.x;
                root.selY = mouse.y;
                root.selW = 0;
                root.selH = 0;
                root.isDragging = true;
            }

            onPositionChanged: mouse => {
                if (root.isDragging) {
                    root.dragCurrentX = mouse.x;
                    root.dragCurrentY = mouse.y;
                    root.selX = Math.min(root.dragStartX, root.dragCurrentX);
                    root.selY = Math.min(root.dragStartY, root.dragCurrentY);
                    root.selW = Math.abs(root.dragCurrentX - root.dragStartX);
                    root.selH = Math.abs(root.dragCurrentY - root.dragStartY);
                }
            }

            onReleased: mouse => {
                root.isDragging = false;
                if (root.selW >= 8 && root.selH >= 8) {
                    root.triggerCapture();
                }
            }
        }

        // Selection Box visual rectangle
        Rectangle {
            id: selectionBox
            visible: root.selW >= 8 && root.selH >= 8
            x: root.selX
            y: root.selY
            width: root.selW
            height: root.selH
            color: Qt.rgba(31/255, 122/255, 122/255, 0.15)
            border.color: Theme.teal
            border.width: 2

            // Dimension Badge Pill
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 6
                width: badgeText.implicitWidth + 14
                height: 22
                radius: 6
                color: Qt.rgba(11/255, 22/255, 38/255, 0.85)
                border.color: Theme.edge
                border.width: 1

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.selW + " × " + root.selH + " px"
                    font.family: "Monospace"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.text
                }
            }
        }
    }

    // Top Centered Floating Glass Toolbar
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        height: 52
        width: toolbarLayout.implicitWidth + 28
        radius: Theme.radiusIsland
        color: Theme.inkPanel
        border.color: Theme.edge
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Prevent dragging from propagating to backdrop
        }

        RowLayout {
            id: toolbarLayout
            anchors.centerIn: parent
            spacing: 8

            // Mode Label
            Text {
                text: root.currentAction === "ocr" ? "📄 OCR MODE" : "📷 CAPTURE"
                font.pixelSize: 11
                font.bold: true
                color: root.currentAction === "ocr" ? Theme.amber : Theme.teal
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // Preset: Left Region
            Rectangle {
                id: leftPresetBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: leftText.implicitWidth + 18
                radius: 8
                color: root.selectedPreset === "left"
                       ? Qt.rgba(31/255, 122/255, 122/255, 0.4)
                       : (leftMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04))
                border.color: root.selectedPreset === "left" ? Theme.teal : Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: leftText
                    anchors.centerIn: parent
                    text: "◧ Left Region"
                    font.pixelSize: 12
                    font.bold: root.selectedPreset === "left"
                    color: root.selectedPreset === "left" ? Theme.text : Theme.dim
                }

                MouseArea {
                    id: leftMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.applyPreset("left");
                        root.triggerCapture();
                    }
                }
            }

            // Preset: Right Region
            Rectangle {
                id: rightPresetBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: rightText.implicitWidth + 18
                radius: 8
                color: root.selectedPreset === "right"
                       ? Qt.rgba(31/255, 122/255, 122/255, 0.4)
                       : (rightMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04))
                border.color: root.selectedPreset === "right" ? Theme.teal : Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: rightText
                    anchors.centerIn: parent
                    text: "◨ Right Region"
                    font.pixelSize: 12
                    font.bold: root.selectedPreset === "right"
                    color: root.selectedPreset === "right" ? Theme.text : Theme.dim
                }

                MouseArea {
                    id: rightMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.applyPreset("right");
                        root.triggerCapture();
                    }
                }
            }

            // Preset: Fullscreen
            Rectangle {
                id: fullPresetBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: fullText.implicitWidth + 18
                radius: 8
                color: root.selectedPreset === "fullscreen"
                       ? Qt.rgba(31/255, 122/255, 122/255, 0.4)
                       : (fullMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04))
                border.color: root.selectedPreset === "fullscreen" ? Theme.teal : Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: fullText
                    anchors.centerIn: parent
                    text: "⛶ Fullscreen"
                    font.pixelSize: 12
                    font.bold: root.selectedPreset === "fullscreen"
                    color: root.selectedPreset === "fullscreen" ? Theme.text : Theme.dim
                }

                MouseArea {
                    id: fullMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.applyPreset("fullscreen");
                        root.triggerCapture();
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // Action: Copy Screenshot
            Rectangle {
                id: copyActionBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: copyText.implicitWidth + 18
                radius: 8
                color: root.currentAction === "copy"
                       ? Qt.rgba(31/255, 122/255, 122/255, 0.35)
                       : (copyMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04))
                border.color: root.currentAction === "copy" ? Theme.teal : Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: copyText
                    anchors.centerIn: parent
                    text: "📷 Copy"
                    font.pixelSize: 12
                    color: root.currentAction === "copy" ? Theme.text : Theme.dim
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentAction = "copy";
                        if (root.selW >= 8 && root.selH >= 8) {
                            root.triggerCapture();
                        }
                    }
                }
            }

            // Action: OCR text
            Rectangle {
                id: ocrActionBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: ocrText.implicitWidth + 18
                radius: 8
                color: root.currentAction === "ocr"
                       ? Qt.rgba(233/255, 180/255, 76/255, 0.3)
                       : (ocrMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04))
                border.color: root.currentAction === "ocr" ? Theme.amber : Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: ocrText
                    anchors.centerIn: parent
                    text: "📄 OCR"
                    font.pixelSize: 12
                    color: root.currentAction === "ocr" ? Theme.amber : Theme.dim
                }

                MouseArea {
                    id: ocrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentAction = "ocr";
                        if (root.selW >= 8 && root.selH >= 8) {
                            root.triggerCapture();
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // Cancel / Close
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.04)

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 13
                    color: Theme.dim
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }
    }
}
