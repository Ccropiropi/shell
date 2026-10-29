pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real value: 0.5
    property int maxBrightness: 100
    property string device: ""
    readonly property string brightnessPath: device ? ("/sys/class/backlight/" + device + "/brightness") : ""

    Process {
        id: infoProc
        running: true
        command: ["brightnessctl", "-m", "info"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const parts = line.split(",");
                if (parts.length >= 5) {
                    root.device = parts[0];
                    const curr = parseInt(parts[2], 10);
                    const max = parseInt(parts[4], 10);
                    if (!isNaN(max) && max > 0) {
                        root.maxBrightness = max;
                        if (!isNaN(curr)) {
                            root.value = Math.max(0.0, Math.min(1.0, curr / max));
                        }
                    }
                }
            }
        }
    }

    Process {
        id: setProc
        running: false
    }

    FileView {
        id: fileView
        path: root.brightnessPath
        watchChanges: true
        onTextChanged: {
            const raw = fileView.text.trim();
            if (raw && root.maxBrightness > 0) {
                const curr = parseInt(raw, 10);
                if (!isNaN(curr)) {
                    root.value = Math.max(0.0, Math.min(1.0, curr / root.maxBrightness));
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (fileView.path) {
                fileView.reload();
            } else if (!root.device) {
                if (infoProc.running) infoProc.running = false;
                infoProc.running = true;
            }
        }
    }

    function setBrightness(pct) {
        const clamped = Math.max(0.01, Math.min(1.0, pct));
        root.value = clamped;
        const pctInt = Math.round(clamped * 100);
        if (setProc.running) setProc.running = false;
        setProc.command = ["brightnessctl", "set", pctInt + "%"];
        setProc.running = true;
    }

    function set(val) {
        setBrightness(val);
    }
}
