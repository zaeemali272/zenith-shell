import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: root

    readonly property string home: PathSettings.home
    readonly property string wallpaperDir: "file://" + home + "/Pictures/Wallpapers"
    readonly property string animationDir: "file://" + home + "/Videos/Animated"
    readonly property string scriptPath: PathSettings.scriptsDir + "/generate_thumbnails.py"

    function generate() {
        if (!thumbGen.running) {
            thumbGen.running = true;
        }
    }

    Process {
        id: thumbGen
        command: ["python3", root.scriptPath]
        Component.onCompleted: running = true
    }
}