import QtQuick
import Quickshell
import Quickshell.Services.Pam

Item {
    id: root

    property string buffer: ""
    property string message: ""
    readonly property bool active: pamContext.active

    signal unlocked()
    signal failed()

    PamContext {
        id: pamContext
        config: "passwd"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.buffer);
                root.buffer = "";
            }
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                root.message = "";
                root.unlocked();
            } else {
                root.message = "Authentication failed";
                root.failed();
                root.buffer = "";
            }
        }
    }

    function start() {
        pamContext.start();
    }

    function abort() {
        pamContext.abort();
    }
}
