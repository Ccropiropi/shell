pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool ready: sink ? sink.ready : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0.0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property real micVolume: source && source.audio ? source.audio.volume : 0.0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    Process {
        id: proc
        running: false
    }

    function runCmd(args) {
        if (proc.running) proc.running = false;
        proc.command = args;
        proc.running = true;
    }

    function setVolume(v) {
        const target = Math.max(0.0, Math.min(1.5, v));
        if (sink && sink.audio) {
            sink.audio.volume = target;
        } else {
            runCmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", target.toFixed(2)]);
        }
    }

    function toggleMute() {
        if (sink && sink.audio) {
            sink.audio.muted = !sink.audio.muted;
        } else {
            runCmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        }
    }

    function setMicVolume(v) {
        const target = Math.max(0.0, Math.min(1.5, v));
        if (source && source.audio) {
            source.audio.volume = target;
        } else {
            runCmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", target.toFixed(2)]);
        }
    }

    function toggleMicMute() {
        if (source && source.audio) {
            source.audio.muted = !source.audio.muted;
        } else {
            runCmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
        }
    }
}
