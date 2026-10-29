// modules/background/WallpaperSurface.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../splitdesk_services"

PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "splitdesk-wallpaper"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    // 100% Wayland Pointer Pass-Through
    mask: Region {}

    Image {
        id: wallpaperImage

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: Theme.wallpaperPath || Quickshell.shellPath("assets/wallpaper.webp")
        asynchronous: true
        cache: true
        smooth: true
    }
}
