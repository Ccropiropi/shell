pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property var connectedDevices: []
    property var pendingDevices: []

    Process {
        id: showProc
        running: true
        command: ["bluetoothctl", "show"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const match = data.match(/Powered:\s*(yes|no)/i);
                if (match) {
                    root.enabled = match[1].toLowerCase() === "yes";
                }
            }
        }
    }

    Process {
        id: devicesProc
        running: true
        command: ["bluetoothctl", "devices", "Connected"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const line = data.trim();
                const match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.*)$/);
                if (match) {
                    root.pendingDevices.push({
                        mac: match[1],
                        name: match[2]
                    });
                }
            }
        }

        onExited: (code, status) => {
            root.connectedDevices = root.pendingDevices.slice();
            root.pendingDevices = [];
        }
    }

    Process {
        id: cmdProc
        running: false
    }

    Timer {
        id: pollTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.update()
    }

    function update() {
        if (!showProc.running) showProc.running = true;
        if (!devicesProc.running) {
            root.pendingDevices = [];
            devicesProc.running = true;
        }
    }

    function togglePower() {
        root.enabled = !root.enabled;
        if (cmdProc.running) cmdProc.running = false;
        cmdProc.command = ["bluetoothctl", "power", root.enabled ? "on" : "off"];
        cmdProc.running = true;
    }
}
