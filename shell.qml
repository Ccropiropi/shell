import QtQuick
import Quickshell
import "splitdesk_services"
import "modules/island"
import "modules/left_panel"
import "modules/veils"
import "modules/background"
import "modules/launcher"
import "modules/nexus"
import "modules/osd"
import "modules/lock"
import "modules/session"
import "modules/notifications"

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

    // System Overlays & Services
    Launcher {}
    Nexus {}
    OSD {}
    LockScreen {}
    SessionMenu {}
    NotificationToasts {}
}
