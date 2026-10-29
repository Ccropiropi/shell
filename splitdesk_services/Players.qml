pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var active: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0)
        ? Mpris.players.values[0]
        : null

    readonly property string trackTitle: active && active.trackTitle ? active.trackTitle : ""
    readonly property string artist: active && active.trackArtist ? active.trackArtist : ""
    readonly property string albumArtUrl: active && active.trackArtUrl ? active.trackArtUrl : ""
    readonly property var playbackState: active ? active.playbackState : null
    readonly property bool isPlaying: active ? active.isPlaying : false
    readonly property real position: active ? active.position : 0.0
    readonly property real duration: active && active.lengthSupported ? active.length : 0.0

    function play() {
        if (active && active.canPlay) active.play();
    }

    function pause() {
        if (active && active.canPause) active.pause();
    }

    function togglePlaying() {
        if (active && active.canTogglePlaying) active.togglePlaying();
    }

    function next() {
        if (active && active.canGoNext) active.next();
    }

    function previous() {
        if (active && active.canGoPrevious) active.previous();
    }

    function getArtUrl(player) {
        if (!player) return "";
        return player.trackArtUrl ? player.trackArtUrl : "";
    }
}
