pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property var pinnedEntries: []
    property bool isLoading: false
    readonly property int maxEntries: 200
    property var rawBuffer: []

    Process {
        id: listProc
        command: ["/usr/sbin/cliphist", "list"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (root.rawBuffer.length < root.maxEntries && line.trim().length > 0) {
                    root.rawBuffer.push(line);
                }
            }
        }

        onExited: (code, status) => {
            root.parseBuffer();
            root.isLoading = false;
        }
    }

    FileView {
        id: pinsView
        path: (Quickshell.env("HOME") || "") + "/.cache/splitdesk/clipboard_pins.json"
        watchChanges: true
        onTextChanged: {
            root.loadPins();
        }
    }

    function refresh() {
        if (listProc.running) {
            listProc.running = false;
        }
        rawBuffer = [];
        isLoading = true;
        listProc.running = true;
    }

    function parseBuffer() {
        const parsed = [];
        const imgRegex = /^\s*(\d+)\t\[\[\s*binary data\s+(\d+)x(\d+)\s+([a-zA-Z0-9]+)\s*\]\]$/;

        for (let i = 0; i < rawBuffer.length; i++) {
            const line = rawBuffer[i];
            const tabIdx = line.indexOf("\t");
            if (tabIdx === -1) continue;

            const id = line.slice(0, tabIdx).trim();
            const rest = line.slice(tabIdx + 1);
            const imgMatch = line.match(imgRegex);

            if (imgMatch) {
                const dims = imgMatch[2] + "x" + imgMatch[3] + " " + imgMatch[4];
                parsed.push({
                    id: id,
                    preview: "[Image: " + dims + "]",
                    isImage: true,
                    dims: dims,
                    raw: line
                });
            } else {
                parsed.push({
                    id: id,
                    preview: rest,
                    isImage: false,
                    dims: "",
                    raw: line
                });
            }
        }
        root.entries = parsed;
    }

    function copy(id, isImage) {
        if (!/^\d+$/.test(String(id).trim())) {
            console.error("[Cliphist] Invalid numeric ID rejected:", id);
            return;
        }
        const numericId = parseInt(id, 10);
        if (isNaN(numericId) || numericId < 0) {
            console.error("[Cliphist] Invalid numeric ID rejected:", id);
            return;
        }
        const typeFlag = isImage ? "--type image/png" : "";
        const script = `cliphist decode "$1" | wl-copy ${typeFlag}`.trim();
        Quickshell.execDetached(["/usr/bin/bash", "-c", script, "_", String(numericId)]);
    }

    function deleteEntry(raw) {
        if (!raw) return;
        Quickshell.execDetached(["/usr/bin/bash", "-c", 'printf "%s\\n" "$1" | cliphist delete', "_", raw]);
        const updated = [];
        for (let i = 0; i < root.entries.length; i++) {
            if (root.entries[i].raw !== raw) {
                updated.push(root.entries[i]);
            }
        }
        root.entries = updated;
    }

    function clearAll() {
        Quickshell.execDetached(["/usr/sbin/cliphist", "wipe"]);
        root.entries = [];
    }

    function isPinned(raw) {
        if (!raw) return false;
        for (let i = 0; i < root.pinnedEntries.length; i++) {
            if (root.pinnedEntries[i].raw === raw) return true;
        }
        return false;
    }

    function togglePin(entry) {
        if (!entry || !entry.raw) return;
        const currentPins = root.pinnedEntries.slice();
        let foundIdx = -1;
        for (let i = 0; i < currentPins.length; i++) {
            if (currentPins[i].raw === entry.raw) {
                foundIdx = i;
                break;
            }
        }

        if (foundIdx >= 0) {
            currentPins.splice(foundIdx, 1);
        } else {
            currentPins.unshift({
                id: entry.id,
                preview: entry.preview,
                isImage: entry.isImage,
                dims: entry.dims,
                raw: entry.raw
            });
        }
        root.pinnedEntries = currentPins;
        persistPins(currentPins);
    }

    function persistPins(pins) {
        const json = JSON.stringify(pins);
        Quickshell.execDetached(["/usr/bin/bash", "-c", 'mkdir -p "$HOME/.cache/splitdesk" && printf "%s" "$1" > "$HOME/.cache/splitdesk/clipboard_pins.json"', "_", json]);
    }

    function loadPins() {
        const raw = pinsView.text ? pinsView.text.trim() : "";
        if (!raw) {
            root.pinnedEntries = [];
            return;
        }
        try {
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) {
                root.pinnedEntries = parsed;
            }
        } catch (e) {
            console.warn("[Cliphist] Failed to parse pinned entries JSON:", e);
        }
    }

    Component.onCompleted: {
        root.refresh();
        root.loadPins();
    }
}
