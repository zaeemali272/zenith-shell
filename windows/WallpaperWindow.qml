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
        Keys.onPressed: (event) => { if (event.key === Qt.Key_Escape) Qt.quit(); }

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

            // Slideshow Button
            Rectangle {
                Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 200; Layout.preferredHeight: 50
                Layout.bottomMargin: 10; radius: 10; color: "#a6e3a1"
                visible: tabRow.activeIndex === 1 && win.selectedWalls.length > 0
                Text { anchors.centerIn: parent; text: "Start Slideshow"; color: "#11111b"; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: startSlideshow() }
            }
        }
    }

    // --- Logic Functions ---

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
        // Run swww-daemon in a shell to ensure it logs
        swwwDaemon.running = true; 
        
        wallDelay.wallPath = path.replace("file://", "");
        wallDelay.start();
    }

    function applyVideo(path) {
        log("Applying video: " + path);
        killSwww.running = true;
        killMpv.running = true;
        videoDelay.videoPath = path.replace("file://", "");
        videoDelay.start();
    }

    function startSlideshow() {
        log("Starting Slideshow with " + win.selectedWalls.length + " files");
        swwwDaemon.running = true;
        let cleanPaths = win.selectedWalls.map(p => p.replace("file://", ""));
        
        // We'll call swww img on the first one, then you can use a cron or loop script later
        setWall.command = ["sh", "-c", "swww img '" + cleanPaths[0] + "' --transition-type grow >> " + win.logPath + " 2>&1"];
        setWall.running = true;
    }

    function log(msg) {
        // Simple helper to write to terminal and the log file via a Process
        console.log("[Zenith]: " + msg);
        logger.command = ["sh", "-c", "echo '[$(date +%T)] " + msg + "' >> " + logPath];
        logger.running = true;
    }

    // --- Timers & Processes ---

    Timer { 
        id: wallDelay
        property string wallPath: ""
        interval: 600 // Increased further for your Intel CPU to settle
        onTriggered: {
            log("Executing swww img for " + wallPath);
            setWall.command = ["sh", "-c", "swww img '" + wallPath + "' --transition-type fade >> " + win.logPath + " 2>&1"];
            setWall.running = true;
        }
    }

    Timer { 
        id: videoDelay 
        property string videoPath: ""
        interval: 400 
        onTriggered: { 
            log("Executing mpvpaper for " + videoPath);
            mpvProcess.command = ["sh", "-c", "mpvpaper -vsf -o 'no-audio loop' eDP-1 '" + videoPath + "' >> " + win.logPath + " 2>&1"];
            mpvProcess.running = true; 
            quitTimer.start(); 
        } 
    }

    Timer { id: quitTimer; interval: 500; onTriggered: Qt.quit() }

    Process { id: logger }
    Process { id: swwwDaemon; command: ["sh", "-c", "swww-daemon >> " + logPath + " 2>&1"] }
    Process { id: setWall; onExited: { log("swww img finished"); Qt.quit(); } }
    Process { id: killSwww; command: ["pkill", "swww-daemon"] }
    Process { id: killMpv; command: ["pkill", "mpvpaper"] }
    Process { id: mpvProcess }
    Process { id: thumbGen; command: ["python3", Quickshell.env("HOME") + "/Documents/Linux/Dots/zenith-shell/services/generate_thumbnails.py"] }

    Component.onCompleted: {
        log("Zenith Shell Started");
        thumbGen.running = true;
        root.forceActiveFocus();
    }
}