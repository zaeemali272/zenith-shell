import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

FloatingWindow {
    id: win
    title: "WallpaperPicker"
    implicitWidth: 1100
    implicitHeight: 750

    property var selectedWalls: []
    property int refreshTrigger: 0
    readonly property string logPath: (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/zenith.log"
    readonly property string scriptsPath: (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/scripts"

    Rectangle {
        id: root
        anchors.fill: parent
        color: "#11111b"; radius: 12; border.color: "#313244"; border.width: 1
        focus: true
        Keys.onPressed: (event) => { if (event.key === Qt.Key_Escape) safeQuit(); }

        ColumnLayout {
            id: mainContent
            anchors.fill: parent; anchors.margins: 25; spacing: 20
            visible: !thumbGen.running

            // --- Tabs ---
            Row {
                id: tabRow
                Layout.alignment: Qt.AlignHCenter; spacing: 40
                property int activeIndex: 0
                Repeater {
                    model: ["Wallpaper", "Slideshow", "Animated"]
                    delegate: Text {
                        text: modelData
                        font.pixelSize: 20; font.bold: true
                        color: tabRow.activeIndex === index ? "#89b4fa" : "#585b70"
                        Rectangle {
                            anchors.top: parent.bottom; anchors.topMargin: 4
                            width: parent.width; height: 2; color: "#89b4fa"
                            visible: tabRow.activeIndex === index
                        }
                        MouseArea { anchors.fill: parent; onClicked: tabRow.activeIndex = index }
                    }
                }
            }

            // --- Content ---
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                // Wallpapers & Slideshow Grid
                Flickable {
                    anchors.fill: parent
                    contentHeight: wallFlow.childrenRect.height
                    visible: tabRow.activeIndex < 2
                    clip: true
                    Flow {
                        id: wallFlow; width: parent.width; spacing: 18
                        Repeater {
                            model: FolderListModel {
                                folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
                                nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.webp"]
                            }
                            delegate: Rectangle {
                                width: 248; height: 152; radius: 8; color: "#1e1e2e"
                                property bool isSelected: win.selectedWalls.indexOf(filePath) !== -1
                                border.color: isSelected && tabRow.activeIndex === 1 ? "#a6e3a1" : "transparent"
                                border.width: 3
                                Image {
                                    anchors.fill: parent; anchors.margins: 4
                                    source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_thumbs/" + fileName + ".png"
                                    fillMode: Image.PreserveAspectCrop; cache: false 
                                    property int trigger: win.refreshTrigger
                                    onTriggerChanged: {
                                        let old = source;
                                        source = "";
                                        source = old;
                                    }
                                }
                                MouseArea { 
                                    anchors.fill: parent
                                    onClicked: {
                                        if (tabRow.activeIndex === 0) applyWallpaper(filePath);
                                        else toggleSelection(filePath);
                                    }
                                }
                            }
                        }
                    }
                }

                // Animated Grid
                Flickable {
                    anchors.fill: parent
                    contentHeight: animFlow.childrenRect.height
                    visible: tabRow.activeIndex === 2
                    clip: true
                    Flow {
                        id: animFlow; width: parent.width; spacing: 18
                        Repeater {
                            model: FolderListModel {
                                folder: "file://" + Quickshell.env("HOME") + "/Videos/Animations"
                                nameFilters: ["*.mp4", "*.mkv", "*.webm"]
                            }
                            delegate: Rectangle {
                                width: 248; height: 152; radius: 8; color: "#1e1e2e"
                                Image {
                                    anchors.fill: parent; anchors.margins: 4
                                    source: "file://" + Quickshell.env("HOME") + "/.cache/animation_thumbs/" + fileName + ".png"
                                    fillMode: Image.PreserveAspectCrop
                                    property int trigger: win.refreshTrigger
                                    onTriggerChanged: {
                                        let old = source;
                                        source = "";
                                        source = old;
                                    }
                                }
                                MouseArea { anchors.fill: parent; onClicked: applyVideo(filePath) }
                            }
                        }
                    }
                }
            }

            // Slideshow Controls
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                visible: tabRow.activeIndex === 1

                // Start Button
                Rectangle {
                    width: 180; height: 50; radius: 10; color: "#a6e3a1"
                    visible: win.selectedWalls.length > 0
                    Text { anchors.centerIn: parent; text: "Start Slideshow"; color: "#11111b"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: startSlideshow() }
                }

                // Stop Button
                Rectangle {
                    width: 180; height: 50; radius: 10; color: "#f38ba8"
                    Text { anchors.centerIn: parent; text: "Stop Slideshow"; color: "#11111b"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: stopSlideshow() }
                }
            }
        }

        // --- Loading Screen ---
        ColumnLayout {
            anchors.centerIn: parent
            visible: thumbGen.running
            spacing: 20

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "\uf110"
                font.family: "MesloLGS NF"
                font.pixelSize: 48
                color: "#89b4fa"

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: thumbGen.running
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Generating Thumbnails..."
                font.pixelSize: 20
                font.bold: true
                color: "#cdd6f4"
            }
        }
    }

    // --- Logic Functions ---

    function safeQuit() {
        win.visible = false; // Hide immediately to prevent white flash
        quitTimer.start();
    }

    function toggleSelection(path) {
        let arr = [...win.selectedWalls];
        let idx = arr.indexOf(path);
        if (idx !== -1) arr.splice(idx, 1);
        else arr.push(path);
        win.selectedWalls = arr;
    }

    function applyWallpaper(path) {
        log("Applying wallpaper: " + path);
        killMpv.running = true;
        stopSlideshow(); // Stop any active slideshow loops
        awwwDaemon.running = true; 
        
        let cleanPath = path.replace("file://", "");
        saveCurrentWall.path = cleanPath;
        saveCurrentWall.running = true;

        wallDelay.wallPath = cleanPath;
        wallDelay.start();
    }

    function applyVideo(path) {
        log("Applying video: " + path);
        killawww.running = true;
        killMpv.running = true;
        stopSlideshow();
        videoDelay.videoPath = path.replace("file://", "");
        videoDelay.start();
    }

    function startSlideshow() {
        if (win.selectedWalls.length === 0) return;

        let home = Quickshell.env("HOME");
        let scriptPath = win.scriptsPath + "/slideshow.sh";
        let servicePath = home + "/.config/systemd/user/zenith-slideshow.service";
        let listPath = home + "/.cache/zenith_wallpaper_list";

        // 1. Save images
        let paths = win.selectedWalls.map(p => p.replace("file://", "")).join("\n");
        saveList.command = ["sh", "-c", "echo '" + paths + "' > " + listPath];
        saveList.running = true;

        // 2. Build Service - Explicitly call bash on the scriptPath
        // Removed hardcoded User ID and environment variables that are handled by systemd user instance
        let serviceContent = "[Unit]\nDescription=Zenith Slideshow\n\n[Service]\n" +
                     "ExecStart=/bin/bash " + scriptPath + "\n" +
                     "Restart=always\n" +
                     "RestartSec=5\n" +
                     "Environment=PATH=/usr/bin:/bin:/usr/local/bin\n" +
                     "[Install]\nWantedBy=default.target";

        // 3. Automated Setup
        installService.command = ["sh", "-c", 
            "echo -e '" + serviceContent + "' > " + servicePath + " && " +
            "chmod +x " + scriptPath + " && " + 
            "systemctl --user daemon-reload"
        ];
        installService.running = true;

        startTimer.start();
    }

    Timer {
        id: startTimer
        interval: 500
        onTriggered: {
            serviceCmd.command = ["systemctl", "--user", "enable", "--now", "zenith-slideshow.service"];
            serviceCmd.running = true;
            log("Slideshow service enabled and started.");
            safeQuit();
        }
    }

    function stopSlideshow() {
        log("Stopping and disabling slideshow service.");
        serviceCmd.command = ["systemctl", "--user", "disable", "--now", "zenith-slideshow.service"];
        serviceCmd.running = true;
    }

    function log(msg) {
        console.log("[Zenith]: " + msg);
        logger.command = ["sh", "-c", "echo '[$(date +%T)] " + msg + "' >> " + logPath];
        logger.running = true;
    }

    // --- Timers & Processes ---

    Timer { 
        id: wallDelay
        property string wallPath: ""
        interval: 600 
        onTriggered: {
            setWall.command = ["sh", "-c", "awww img '" + wallPath + "' --transition-type fade >> " + win.logPath + " 2>&1"];
            setWall.running = true;
        }
    }

    Timer { 
        id: videoDelay 
        property string videoPath: ""
        interval: 400 
        onTriggered: { 
            // Dynamically detect the monitor using awww query (assuming awww is installed/running, or fallback to first detected output)
            mpvProcess.command = ["sh", "-c", "MONITOR=$(awww query | head -n1 | cut -d: -f1); if [ -z \"$MONITOR\" ]; then MONITOR=$(wlr-randr | head -n1 | awk '{print $1}'); fi; mpvpaper -vsf -o 'no-audio loop' $MONITOR '" + videoPath + "' >> " + win.logPath + " 2>&1"];
            mpvProcess.running = true; 
            safeQuit(); 
        } 
    }

    Timer { id: quitTimer; interval: 600; onTriggered: Qt.quit() }

    Process { id: logger }
    Process { id: awwwDaemon; command: ["sh", "-c", "awww-daemon >> " + logPath + " 2>&1"] }
    Process { id: setWall; onExited: { log("awww img finished"); safeQuit(); } }
    
    // Improved kill commands
    Process { id: killawww; command: ["killall", "awww-daemon"] }
    Process { id: killMpv; command: ["killall", "mpvpaper"] }
    Process { id: killLoop; command: ["sh", "-c", "pkill -f 'awww img'"] } // Target the slideshow loop

    Process { id: installService }
    Process { id: saveList }
    Process { id: serviceCmd }

    Process { id: mpvProcess }
    Process { id: slideshowProc }
    Process {
        id: saveCurrentWall
        property string path: ""
        command: ["sh", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.config && echo '" + path + "' > " + Quickshell.env("HOME") + "/.config/current_wallpaper.txt"]
    }
    Process { 
        id: thumbGen
        command: ["python3", (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/services/generate_thumbnails.py"]
        onRunningChanged: {
            if (!running) {
                console.log("[WallpaperWindow]: Thumbnail generation finished.");
                win.refreshTrigger++;
            }
        }
    }

    Component.onCompleted: {
        log("Zenith Shell Started");
        thumbGen.running = true;
        root.forceActiveFocus();
    }
}