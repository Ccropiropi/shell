pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property string activeSsid: ""
    property int signalStrength: 0
    property var availableNetworks: []
    property bool enabled: true

    property var pendingNetworks: []

    Process {
        id: statusProc
        running: true
        command: ["nmcli", "-t", "-f", "WIFI", "g"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const text = data.trim().toLowerCase();
                if (text === "enabled") root.enabled = true;
                else if (text === "disabled") root.enabled = false;
            }
        }
    }

    Process {
        id: wifiListProc
        running: true
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const line = data.trim();
                if (!line) return;

                // Handle escaped colons (\:) in SSID
                const placeholder = "\u0000";
                const sanitized = line.replace(/\\:/g, placeholder);
                const parts = sanitized.split(":");
                if (parts.length >= 4) {
                    const ssid = parts[0].replace(new RegExp(placeholder, "g"), ":");
                    const signal = parseInt(parts[1], 10) || 0;
                    const security = parts[2];
                    const inUse = parts[3].trim() === "*";

                    if (ssid) {
                        root.pendingNetworks.push({
                            ssid: ssid,
                            signal: signal,
                            security: security,
                            inUse: inUse
                        });
                        if (inUse) {
                            root.connected = true;
                            root.activeSsid = ssid;
                            root.signalStrength = signal;
                        }
                    }
                }
            }
        }

        onExited: (code, status) => {
            if (root.pendingNetworks.length > 0) {
                root.availableNetworks = root.pendingNetworks.slice();
                let foundActive = false;
                for (let i = 0; i < root.availableNetworks.length; i++) {
                    if (root.availableNetworks[i].inUse) {
                        foundActive = true;
                        break;
                    }
                }
                if (!foundActive) {
                    root.connected = false;
                    root.activeSsid = "";
                    root.signalStrength = 0;
                }
            }
            root.pendingNetworks = [];
        }
    }

    Process {
        id: cmdProc
        running: false
    }

    Process {
        id: connectProc
        running: false
        property string pendingPassword: ""
        onRunningChanged: {
            if (running && pendingPassword) {
                connectProc.write(pendingPassword + "\n");
                pendingPassword = "";
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.scan()
    }

    function scan() {
        if (!wifiListProc.running) {
            root.pendingNetworks = [];
            wifiListProc.running = true;
        }
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function toggleWifi() {
        root.enabled = !root.enabled;
        if (cmdProc.running) cmdProc.running = false;
        cmdProc.command = ["nmcli", "radio", "wifi", root.enabled ? "on" : "off"];
        cmdProc.running = true;
    }

    function connect(ssid, password) {
        if (connectProc.running) connectProc.running = false;
        if (password) {
            connectProc.pendingPassword = password;
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", "-"];
        } else {
            connectProc.pendingPassword = "";
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        connectProc.running = true;
    }
}
