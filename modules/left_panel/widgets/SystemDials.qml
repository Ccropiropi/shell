// SystemDials.qml — CPU, RAM, and thermal progress indicators for splitdesk Left Region

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../splitdesk_services"

Rectangle {
    id: root

    property real cpuUsage: 0.0
    property var prevCpu: []
    property real ramUsedGb: 0.0
    property real ramTotalGb: 0.0
    property real thermalTempC: 0.0

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 24
    radius: Theme.radiusTile
    color: Theme.inkPanel
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    Timer {
        id: pollTimer

        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuFile.reload();
            memFile.reload();
            tempFile.reload();
        }
    }

    FileView {
        id: cpuFile

        path: "/proc/stat"
        onLoaded: {
            const line = text().split("\n")[0];
            const parts = line.split(/\s+/).slice(1).map(Number);
            if (root.prevCpu.length === parts.length) {
                const prev = root.prevCpu;
                const idleDelta = (parts[3] + parts[4]) - (prev[3] + prev[4]);
                const totalDelta = parts.reduce((a, b) => a + b, 0)
                                 - prev.reduce((a, b) => a + b, 0);
                root.cpuUsage = totalDelta > 0 ? Math.max(0, Math.min(1.0, 1 - idleDelta / totalDelta)) : 0;
            }
            root.prevCpu = parts;
        }
    }

    FileView {
        id: memFile

        path: "/proc/meminfo"
        onLoaded: {
            const lines = text().split("\n");
            const val = key => {
                const l = lines.find(line => line.startsWith(key + ":"));
                return l ? parseInt(l.split(/\s+/)[1], 10) : 0;
            };
            const total = val("MemTotal");
            const avail = val("MemAvailable");
            root.ramTotalGb = parseFloat((total / 1048576).toFixed(1));
            root.ramUsedGb = parseFloat(((total - avail) / 1048576).toFixed(1));
        }
    }

    FileView {
        id: tempFile

        path: "/sys/class/thermal/thermal_zone0/temp"
        printErrors: false
        onLoaded: {
            const raw = parseInt(text().trim(), 10);
            if (!isNaN(raw)) {
                root.thermalTempC = Math.round(raw > 1000 ? raw / 1000 : raw);
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Section Title
        Text {
            Layout.fillWidth: true
            text: "SYSTEM DIALS"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
            color: Theme.dim
        }

        // CPU Metric Row
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "CPU"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Theme.text
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: Math.round(root.cpuUsage * 100) + "%"
                    font.pixelSize: 13
                    font.features: { "tnum": 1 }
                    color: Theme.teal
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    width: parent.width * Math.min(1.0, Math.max(0.0, root.cpuUsage))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.teal

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        // RAM Metric Row
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "RAM"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Theme.text
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.ramUsedGb + " / " + root.ramTotalGb + " GB"
                    font.pixelSize: 13
                    font.features: { "tnum": 1 }
                    color: Theme.amber
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    readonly property real ramFraction: root.ramTotalGb > 0 ? (root.ramUsedGb / root.ramTotalGb) : 0.0

                    width: parent.width * Math.min(1.0, Math.max(0.0, ramFraction))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.amber

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        // Thermal Metric Row
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Thermal"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Theme.text
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: (root.thermalTempC > 0 ? root.thermalTempC : 42) + "°C"
                    font.pixelSize: 13
                    font.features: { "tnum": 1 }
                    color: (root.thermalTempC > 75) ? Theme.amber : Theme.teal
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    readonly property real effectiveTemp: root.thermalTempC > 0 ? root.thermalTempC : 42

                    width: parent.width * Math.min(1.0, Math.max(0.0, effectiveTemp / 100.0))
                    height: parent.height
                    radius: parent.radius
                    color: (root.thermalTempC > 75) ? Theme.amber : Theme.teal

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
