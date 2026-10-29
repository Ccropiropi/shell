pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var active: Mpris.players.values[0] ?? null

    function getArtUrl(player) {
        if (!player) return "";
        return player.trackArtUrl ?? "";
    }
}
