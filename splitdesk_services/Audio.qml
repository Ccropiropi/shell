pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink ? sink.audio.volume : 0.5
    readonly property bool muted: sink ? sink.audio.muted : false
}
