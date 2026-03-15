import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: root
    
    readonly property string home: Quickshell.env("HOME")
    readonly property string wallpaperDir: "file://" + home + "/Pictures/Wallpapers"
    readonly property string thumbDir: "file://" + home + "/.cache/wallpaper_thumbs"
    readonly property string scriptPath: home + "/.config/quickshell/services/generate_thumbnails.py"

    function applyWallpaper(path) {
        let cleanPath = path.replace("file://", "");
        
        applyProcess.command = ["swww", "img", cleanPath, 
            "--transition-type", "fade", 
            "--transition-fps", "60", 
            "--transition-duration", "1"
        ];
        applyProcess.running = true;
        
        saveHistory.command = ["sh", "-c", `echo "${cleanPath}" > ~/.config/current_wallpaper.txt`];
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