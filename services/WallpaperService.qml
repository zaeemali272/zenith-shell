import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: root

    readonly property string home: PathSettings.home
    readonly property string wallpaperDir: "file://" + home + "/Pictures/Wallpapers"
    readonly property string thumbDir: PathSettings.cacheDir + "/wallpaper_thumbs"
    readonly property string scriptPath: PathSettings.scriptsDir + "/generate_thumbnails.py"

    function applyWallpaper(path) {
        let cleanPath = path.replace("file://", "");

        applyProcess.command = ["swww", "img", cleanPath, 
            "--transition-type", "fade", 
            "--transition-fps", "60", 
            "--transition-duration", "1"
        ];
        applyProcess.running = true;

        saveHistory.command = ["sh", "-c", `echo "${cleanPath}" > ` + PathSettings.configDir + `/current_wallpaper.txt` ];
        saveHistory.running = true;
    }


    function generate() {
        if (!thumbGen.running) {
            thumbGen.running = true;
        }
    }

    Process { id: applyProcess }
    Process { id: saveHistory }

    Process {
        id: thumbGen
        command: ["python3", root.scriptPath]
        Component.onCompleted: running = true
    }
}