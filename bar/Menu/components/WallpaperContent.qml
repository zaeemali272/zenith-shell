import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../../"
import "../../../services"

Item {
    id: root

    property var selectedWalls: []
    property int refreshTrigger: 0
    property string activeSubTab: "Wallpaper"
    property bool thumbnailsReady: false

    onVisibleChanged: {
        if (visible) {
            refreshThumbnails();
        }
    }

    function refreshThumbnails() {
        thumbnailsReady = false;
        thumbGen.running = false;
        thumbGen.running = true;
    }

    readonly property string logPath: (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/zenith.log"
    readonly property string scriptsPath: (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/scripts"

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(20)

        // --- SUB-TABS ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(10)
            
            Repeater {
                model: ["Wallpaper", "Slideshow", "Animated"]
                delegate: Rectangle {
                    id: subTabRect
                    width: Theme.scaled(100); height: Theme.scaled(32); radius: Theme.scaled(10)
                    color: root.activeSubTab === modelData ? Theme.accentColor : (subTabMouse.containsMouse ? Theme.surface1 : Theme.surface0)
                    border.color: Theme.glassBorder
                    scale: subTabMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text { 
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Black
                        color: root.activeSubTab === modelData ? Theme.base : (subTabMouse.containsMouse ? Theme.text : Theme.subtext1)
                    }
                    MouseArea { 
                        id: subTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.activeSubTab = modelData 
                    }
                }
            }
            Item { Layout.fillWidth: true }
            
            // Thumbnail Generation Status
            RowLayout {
                spacing: Theme.scaled(8)
                visible: thumbGen.running
                
                Text {
                    text: "󱑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(14)
                    color: Theme.blue
                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: thumbGen.running
                    }
                }
                Text {
                    text: "Updating..."
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Black
                    color: Theme.subtext1
                }
            }
            
            // Refresh Button (Icon Only)
            Rectangle {
                width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8)
                color: refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                visible: !thumbGen.running
                
                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(16)
                    color: refreshMouse.containsMouse ? Theme.text : Theme.subtext1
                }
                
                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: refreshThumbnails()
                }
            }
        }

        // --- GRID AREA ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Wallpapers & Slideshow Grid
            Flickable {
                anchors.fill: parent
                contentHeight: wallFlow.height
                visible: root.activeSubTab !== "Animated"
                clip: true
                
                ScrollBar.vertical: ScrollBar { width: 4; policy: ScrollBar.AsNeeded }

                Flow {
                    id: wallFlow
                    width: parent.width
                    spacing: Theme.scaled(15)
                    
                    Repeater {
                        model: FolderListModel {
                            id: wallFolderModel
                            folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
                            nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.webp"]
                            onCountChanged: {
                                if (root.visible) refreshThumbnails();
                            }
                        }
                        delegate: Rectangle {
                            id: wallItem
                            width: (wallFlow.width - Theme.scaled(45)) / 4
                            height: width * 0.6
                            radius: Theme.scaled(12)
                            color: Theme.surface1
                            clip: true
                            
                            property bool isSelected: root.selectedWalls.indexOf(filePath) !== -1
                            border.color: isSelected && root.activeSubTab === "Slideshow" ? Theme.blue : Theme.glassBorder
                            border.width: isSelected && root.activeSubTab === "Slideshow" ? 3 : 1
                            
                            Loader {
                                id: thumbLoader
                                anchors.fill: parent
                                sourceComponent: (fileName && root.thumbnailsReady) ? thumbComponent : undefined
                                
                                Component {
                                    id: thumbComponent
                                    Image {
                                        id: thumbImg
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png"
                                        fillMode: Image.PreserveAspectCrop
                                        cache: false
                                        asynchronous: true
                                        opacity: status === Image.Ready ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 400 } }
                                    }
                                }
                            }

                            // Loading Spinner per item
                            Text {
                                anchors.centerIn: parent
                                text: "󱑐"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(20)
                                color: Theme.blue
                                // Visible if thumbnail is not ready or if the Loader has not finished loading
                                visible: !root.thumbnailsReady || (thumbLoader.item && thumbLoader.item.status !== Image.Ready)
                                opacity: 0.5
                                
                                RotationAnimator on rotation {
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible
                                }
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                                opacity: clickMouse.containsMouse ? 0.2 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            MouseArea {
                                id: clickMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (root.activeSubTab === "Wallpaper") applyWallpaper(filePath);
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
                contentHeight: animFlow.height
                visible: root.activeSubTab === "Animated"
                clip: true
                
                ScrollBar.vertical: ScrollBar { width: 4; policy: ScrollBar.AsNeeded }

                Flow {
                    id: animFlow
                    width: parent.width
                    spacing: Theme.scaled(15)
                    
                    Repeater {
                        model: FolderListModel {
                            folder: "file://" + Quickshell.env("HOME") + "/Videos/Animations"
                            nameFilters: ["*.mp4", "*.mkv", "*.webm"]
                            onCountChanged: {
                                if (root.visible) refreshThumbnails();
                            }
                        }
                        delegate: Rectangle {
                            id: animItem
                            width: (animFlow.width - Theme.scaled(45)) / 4
                            height: width * 0.6
                            radius: Theme.scaled(12)
                            color: Theme.surface1
                            clip: true
                            
                            Loader {
                                id: animThumbLoader
                                anchors.fill: parent
                                sourceComponent: (fileName && root.thumbnailsReady) ? animThumbComponent : undefined
                                
                                Component {
                                    id: animThumbComponent
                                    Image {
                                        id: animThumbImg
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: "file://" + Quickshell.env("HOME") + "/.cache/animation_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png"
                                        fillMode: Image.PreserveAspectCrop
                                        cache: false
                                        asynchronous: true
                                        opacity: status === Image.Ready ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 400 } }
                                    }
                                }
                            }

                            // Loading Spinner per item
                            Text {
                                anchors.centerIn: parent
                                text: "󱑐"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(20)
                                color: Theme.blue
                                // Visible if thumbnail is not ready or if the Loader has not finished loading
                                visible: !root.thumbnailsReady || (animThumbLoader.item && animThumbLoader.item.status !== Image.Ready)
                                opacity: 0.5
                                
                                RotationAnimator on rotation {
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible
                                }
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                                opacity: animMouse.containsMouse ? 0.2 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            MouseArea {
                                id: animMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: applyVideo(filePath)
                            }
                        }
                    }
                }
            }
        }

        // --- SLIDESHOW CONTROLS ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.scaled(20)
            visible: root.activeSubTab === "Slideshow"

            Rectangle {
                width: Theme.scaled(180); height: Theme.scaled(40); radius: Theme.scaled(10)
                color: root.selectedWalls.length > 0 ? Theme.accentColor : Theme.surface1
                opacity: root.selectedWalls.length > 0 ? 1 : 0.5
                scale: startMouse.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text { 
                    anchors.centerIn: parent; text: "Start Slideshow"; color: Theme.blue; font.bold: true 
                }
                MouseArea { 
                    id: startMouse
                    anchors.fill: parent
                    enabled: root.selectedWalls.length > 0
                    onClicked: startSlideshow() 
                }
            }

            Rectangle {
                width: Theme.scaled(180); height: Theme.scaled(40); radius: Theme.scaled(10)
                color: Theme.red
                Text { 
                    anchors.centerIn: parent; text: "Stop Slideshow"; color: Theme.base; font.bold: true 
                }
                MouseArea { anchors.fill: parent; onClicked: stopSlideshow() }
            }
        }
    }

    // --- LOGIC FUNCTIONS ---

    function toggleSelection(path) {
        let arr = [...root.selectedWalls];
        let idx = arr.indexOf(path);
        if (idx !== -1) arr.splice(idx, 1);
        else arr.push(path);
        root.selectedWalls = arr;
    }

    function applyWallpaper(path) {
        log("Applying wallpaper: " + path);
        killMpv.running = true;
        stopSlideshow(); 
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
        if (root.selectedWalls.length === 0) return;

        let home = Quickshell.env("HOME");
        let scriptPath = root.scriptsPath + "/slideshow.sh";
        let servicePath = home + "/.config/systemd/user/zenith-slideshow.service";
        let listPath = home + "/.cache/zenith_wallpaper_list";

        let paths = root.selectedWalls.map(p => p.replace("file://", "")).join("\n");
        saveList.command = ["sh", "-c", "echo '" + paths + "' > " + listPath];
        saveList.running = true;

        let serviceContent = "[Unit]\nDescription=Zenith Slideshow\n\n[Service]\n" +
                     "ExecStart=/bin/bash " + scriptPath + "\n" +
                     "Restart=always\n" +
                     "RestartSec=5\n" +
                     "Environment=PATH=/usr/bin:/bin:/usr/local/bin\n" +
                     "[Install]\nWantedBy=default.target";

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
            CenterState.close();
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

    // --- TIMERS & PROCESSES ---

    Timer { 
        id: wallDelay
        property string wallPath: ""
        interval: 600 
        onTriggered: {
            setWall.command = ["sh", "-c", "awww img '" + wallPath + "' --transition-type fade >> " + root.logPath + " 2>&1" + "&& ~/.config/quickshell/scripts/zenith-theme.sh --autoselect"];
            setWall.running = true;
        }
    }

    Timer { 
        id: videoDelay 
        property string videoPath: ""
        interval: 400 
        onTriggered: { 
            mpvProcess.command = ["sh", "-c", "MONITOR=$(awww query | head -n1 | cut -d: -f1); if [ -z \"$MONITOR\" ]; then MONITOR=$(wlr-randr | head -n1 | awk '{print $1}'); fi; mpvpaper -vsf -o 'no-audio loop' $MONITOR '" + videoPath + "' >> " + root.logPath + " 2>&1"];
            mpvProcess.running = true; 
            CenterState.close(); 
        } 
    }

    Process { id: logger }
    Process { id: awwwDaemon; command: ["sh", "-c", "awww-daemon >> " + logPath + " 2>&1"] }
    Process { id: setWall; onExited: { log("awww img finished"); CenterState.close(); } }
    
    Process { id: killawww; command: ["killall", "awww-daemon"] }
    Process { id: killMpv; command: ["killall", "mpvpaper"] }

    Process { id: installService }
    Process { id: saveList }
    Process { id: serviceCmd }

    Process { id: mpvProcess }
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
                console.log("[WallpaperContent]: Thumbnail generation finished.");
                root.thumbnailsReady = true;
                root.refreshTrigger++;
            }
        }
    }

    Component.onCompleted: {
        refreshThumbnails();
    }
}
