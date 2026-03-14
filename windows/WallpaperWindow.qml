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
    readonly property string logPath: Quickshell.env("HOME") + "/Documents/Linux/Dots/zenith-shell/zenith.log"

    Rectangle {
        id: root
        anchors.fill: parent
        color: "#11111b"; radius: 12; border.color: "#313244"; border.width: 1
        focus: true
        Keys.onPressed: (event) => { if (event.key === Qt.Key_Escape) safeQuit(); }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 25; spacing: 20

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
                                width: 245; height: 145; radius: 8; color: "#1e1e2e"
                                property bool isSelected: win.selectedWalls.indexOf(filePath) !== -1
                                border.color: isSelected && tabRow.activeIndex === 1 ? "#a6e3a1" : "transparent"
                                border.width: 3
                                Image {
                                    anchors.fill: parent; anchors.margins: 4
                                    source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_thumbs/" + fileName + ".png"
                                    fillMode: Image.PreserveAspectCrop; cache: false 
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
                                width: 245; height: 145; radius: 8; color: "#1e1e2e"
                                Image {
                                    anchors.fill: parent; anchors.margins: 4
                                    source: "file://" + Quickshell.env("HOME") + "/.cache/animation_thumbs/" + fileName + ".png"
                                    fillMode: Image.PreserveAspectCrop
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
        swwwDaemon.running = true; 
        
        wallDelay.wallPath = path.replace("file://", "");
        wallDelay.start();
    }

    function applyVideo(path) {
        log("Applying video: " + path);
        killSwww.running = true;
        killMpv.running = true;
        stopSlideshow();
        videoDelay.videoPath = path.replace("file://", "");
        videoDelay.start();
    }

    function startSlideshow() {
        if (win.selectedWalls.length === 0) return;

        let home = Quickshell.env("HOME");
        // Using your linked path:
        let scriptPath = home + "/.config/quickshell/scripts/slideshow.sh";
        let servicePath = home + "/.config/systemd/user/zenith-slideshow.service";
        let listPath = home + "/.cache/zenith_wallpaper_list";

        // 1. Save images
        let paths = win.selectedWalls.map(p => p.replace("file://", "")).join("\n");
        saveList.command = ["sh", "-c", "echo '" + paths + "' > " + listPath];
        saveList.running = true;

        // 2. Build Service - Explicitly call bash on the scriptPath
        let serviceContent = "[Unit]\nDescription=Zenith Slideshow\n\n[Service]\n" +
                     "ExecStart=/bin/bash " + scriptPath + "\n" +
                     "Restart=always\n" +
                     "RestartSec=5\n" +
                     "Environment=PATH=/usr/bin:/bin:/usr/local/bin\n" +
                     "Environment=XDG_RUNTIME_DIR=/run/user/1000\n" +
                     "Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus\n\n" + 
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
            setWall.command = ["sh", "-c", "swww img '" + wallPath + "' --transition-type fade >> " + win.logPath + " 2>&1"];
            setWall.running = true;
        }
    }

    Timer { 
        id: videoDelay 
        property string videoPath: ""
        interval: 400 
        onTriggered: { 
            mpvProcess.command = ["sh", "-c", "mpvpaper -vsf -o 'no-audio loop' eDP-1 '" + videoPath + "' >> " + win.logPath + " 2>&1"];
            mpvProcess.running = true; 
            safeQuit(); 
        } 
    }

    Timer { id: quitTimer; interval: 600; onTriggered: Qt.quit() }

    Process { id: logger }
    Process { id: swwwDaemon; command: ["sh", "-c", "swww-daemon >> " + logPath + " 2>&1"] }
    Process { id: setWall; onExited: { log("swww img finished"); safeQuit(); } }
    
    // Improved kill commands
    Process { id: killSwww; command: ["killall", "swww-daemon"] }
    Process { id: killMpv; command: ["killall", "mpvpaper"] }
    Process { id: killLoop; command: ["sh", "-c", "pkill -f 'swww img'"] } // Target the slideshow loop

    Process { id: installService }
    Process { id: saveList }
    Process { id: serviceCmd }

    Process { id: mpvProcess }
    Process { id: slideshowProc }
    Process { id: thumbGen; command: ["python3", Quickshell.env("HOME") + "/Documents/Linux/Dots/zenith-shell/services/generate_thumbnails.py"] }

    Component.onCompleted: {
        log("Zenith Shell Started");
        thumbGen.running = true;
        root.forceActiveFocus();
    }
}