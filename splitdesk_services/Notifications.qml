pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var notifications: []
    property var history: []
    readonly property int unreadCount: notifications.length

    NotificationServer {
        id: server

        onNotification: notif => {
            notif.tracked = true;
            const updated = root.notifications.slice();
            updated.unshift(notif);
            root.notifications = updated;

            const hist = root.history.slice();
            hist.unshift({
                id: notif.id,
                appName: notif.appName,
                summary: notif.summary,
                body: notif.body,
                time: new Date().toLocaleTimeString(Qt.locale(), "hh:mm")
            });
            if (hist.length > 50) hist.pop();
            root.history = hist;
        }
    }

    function dismiss(id) {
        const remaining = [];
        for (let i = 0; i < root.notifications.length; i++) {
            const n = root.notifications[i];
            if (n.id === id) {
                n.dismiss();
            } else {
                remaining.push(n);
            }
        }
        root.notifications = remaining;
    }

    function clearAll() {
        for (let i = 0; i < root.notifications.length; i++) {
            root.notifications[i].dismiss();
        }
        root.notifications = [];
    }
}
