import QtQuick
import Quickshell
import "splitdesk_services"
import "modules/island"
import "modules/left_panel"
import "modules/veils"
import "modules/background"

ShellRoot {
    id: root

    // Instantiate Island HUD (Top dynamic bar)
    IslandBar {}

    // Instantiate Anchor Canvas (Left Region metric cards)
    LeftPanel {}

    // Instantiate Dual Focus Veils & Slanted Boundary Highlight
    FocusVeils {}

    // Instantiate Full-Screen Wallpaper Surface (Backdrop layer)
    WallpaperSurface {}
}
