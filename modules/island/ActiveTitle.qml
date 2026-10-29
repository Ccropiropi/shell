// ActiveTitle.qml — elided active window title

import QtQuick
import "../../splitdesk_services"

Text {
    id: root

    text: {
        if (Niri.regionsEnabled && Niri.focusedRegion === "Left")
            return "Widgets & Dashboard";
        return Niri.activeWindow?.title ?? "Desktop";
    }

    color: Theme.text
    font.pixelSize: 13
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
