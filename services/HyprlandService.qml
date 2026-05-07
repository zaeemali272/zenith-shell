import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: root

    // Property to track if there's a fullscreen window on the active workspace
    property bool isFullscreen: false

    Process {
        id: checkFullscreen
        command: ["sh", "-c", "hyprctl activeworkspace -j | jq '.hasfullscreen'"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let result = text.trim();
                let newState = (result === "true");
                
                if (root.isFullscreen !== newState) {
                    root.isFullscreen = newState;
                    // console.log("[HyprlandService] Fullscreen detected:", newState);
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkFullscreen.running = false;
            checkFullscreen.running = true;
        }
    }

    // Update on completed as well
    Component.onCompleted: {
        checkFullscreen.running = true;
    }
}
