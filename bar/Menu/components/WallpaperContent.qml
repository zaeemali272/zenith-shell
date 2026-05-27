import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../../"
import "../../../services"

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)

    property var selectedWalls: []
    property int refreshTrigger: 0
    property string activeSubTab: "Wallpaper"
    property bool thumbnailsReady: false
    property int selectedIndex: 0

    function handleKeys(event) {
        console.log("WallpaperContent: Handling key: " + event.key);
        let cols = 4;
        let isAnimated = (root.activeSubTab === "Animated");
        let model = isAnimated ? animFolderModel : wallFolderModel;
        let maxIdx = model.count - 1;

        if (maxIdx < 0) return;

        if (event.key === Qt.Key_Right) {
            root.selectedIndex = Math.min(root.selectedIndex + 1, maxIdx);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.selectedIndex = Math.min(root.selectedIndex + cols, maxIdx);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.selectedIndex = Math.max(root.selectedIndex - cols, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === 16777220) {
            let path = model.get(root.selectedIndex, "fileUrl");
            if (path) {
                let pathString = path.toString();
                if (root.activeSubTab === "Wallpaper") applyWallpaper(pathString);
                else if (root.activeSubTab === "Slideshow") toggleSelection(pathString);
                else if (root.activeSubTab === "Animated") applyVideo(pathString);
            }
            event.accepted = true;
        }
    }

    onVisibleChanged: { if (visible) refreshThumbnails(); }

    function refreshThumbnails() {
        thumbnailsReady = false;
        thumbGen.running = false;
        thumbGen.running = true;
    }

    readonly property string logPath: (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/zenith.log"
    readonly property string scriptsPath: (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/scripts"

    // --- SUB-TABS ---
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(10)
        
        Repeater {
            model: ["Wallpaper", "Slideshow", "Animated"]
            delegate: Rectangle {
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
                    onClicked: {
                        root.activeSubTab = modelData;
                        root.selectedIndex = 0;
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
        
        // Thumbnail Generation Status
        RowLayout {
            spacing: Theme.scaled(8)
            visible: thumbGen.running
            Text {
                text: "󱑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.blue
                RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: thumbGen.running }
            }
            Text { text: "Updating..."; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; color: Theme.subtext1 }
        }
        
        // Refresh Button
        Rectangle {
            width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8)
            color: refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
            visible: !thumbGen.running
            Text { anchors.centerIn: parent; text: "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(16); color: refreshMouse.containsMouse ? Theme.text : Theme.subtext1 }
            MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: refreshThumbnails() }
        }
    }

    // --- GRID AREA ---
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

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
                    id: wallRepeater
                    model: FolderListModel {
                        id: wallFolderModel
                        folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
                        nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.webp"]
                        onCountChanged: if (root.visible) refreshThumbnails();
                    }
                    delegate: Rectangle {
                        width: (wallFlow.width - Theme.scaled(45)) / 4
                        height: width * 0.6
                        radius: Theme.scaled(12)
                        color: Theme.surface1
                        clip: true
                        property bool isSelected: root.selectedWalls.indexOf(fileUrl) !== -1
                        property bool isFocused: index === root.selectedIndex
                        border.color: isFocused ? Theme.accentColor : (isSelected && root.activeSubTab === "Slideshow" ? Theme.blue : Theme.glassBorder)
                        border.width: isFocused ? 3 : (isSelected && root.activeSubTab === "Slideshow" ? 3 : 1)
                        
                        Loader {
                            id: thumbLoader; anchors.fill: parent
                            sourceComponent: (fileName && root.thumbnailsReady) ? thumbComponent : undefined
                            Component {
                                id: thumbComponent
                                Image {
                                    anchors.fill: parent; anchors.margins: 2
                                    source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png"
                                    fillMode: Image.PreserveAspectCrop; cache: false; asynchronous: true
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 400 } }
                                }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent; text: "󱑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20); color: Theme.blue
                            visible: !root.thumbnailsReady || (thumbLoader.item && thumbLoader.item.status !== Image.Ready)
                            RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: { 
                                let pathString = fileUrl.toString();
                                if (root.activeSubTab === "Wallpaper") applyWallpaper(pathString); 
                                else toggleSelection(pathString); 
                            }
                        }                    }
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
                        id: animRepeater
                        model: FolderListModel {
                            id: animFolderModel
                            folder: "file://" + Quickshell.env("HOME") + "/Videos/Animations"
                            nameFilters: ["*.mp4", "*.mkv", "*.webm"]
                            onCountChanged: if (root.visible) refreshThumbnails();
                        }
                        delegate: Rectangle {
                            width: (animFlow.width - Theme.scaled(45)) / 4
                            height: width * 0.6
                            radius: Theme.scaled(12)
                            color: Theme.surface1
                            clip: true
                            property bool isFocused: index === root.selectedIndex
                            border.color: isFocused ? Theme.accentColor : Theme.glassBorder
                            border.width: isFocused ? 3 : 1
                            
                            Loader {
                                id: animThumbLoader; anchors.fill: parent
                                sourceComponent: (fileName && root.thumbnailsReady) ? animThumbComponent : undefined
                                Component {
                                    id: animThumbComponent
                                    Image {
                                        anchors.fill: parent; anchors.margins: 2
                                        source: "file://" + Quickshell.env("HOME") + "/.cache/animation_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png"
                                        fillMode: Image.PreserveAspectCrop; cache: false; asynchronous: true
                                        opacity: status === Image.Ready ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 400 } }
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: applyVideo(fileUrl.toString())
                            }
                        }
                    }
                }
            }
        }

        // --- SLIDESHOW CONTROLS ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: Theme.scaled(20); visible: root.activeSubTab === "Slideshow"
            Rectangle {
                width: Theme.scaled(180); height: Theme.scaled(40); radius: Theme.scaled(10)
                color: root.selectedWalls.length > 0 ? Theme.accentColor : Theme.surface1
                Text { anchors.centerIn: parent; text: "Start Slideshow"; color: Theme.blue; font.bold: true }
                MouseArea { anchors.fill: parent; enabled: root.selectedWalls.length > 0; onClicked: startSlideshow() }
            }
            Rectangle {
                width: Theme.scaled(180); height: Theme.scaled(40); radius: Theme.scaled(10)
                color: Theme.red
                Text { anchors.centerIn: parent; text: "Stop Slideshow"; color: Theme.base; font.bold: true }
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
        killMpv.running = true; stopSlideshow(); awwwDaemon.running = true; 
        let cleanPath = path.replace("file://", "");
        saveCurrentWall.path = cleanPath; saveCurrentWall.running = true;
        wallDelay.wallPath = cleanPath; wallDelay.start();
    }
    function applyVideo(path) {
        killawww.running = true; killMpv.running = true; stopSlideshow();
        videoDelay.videoPath = path.replace("file://", ""); videoDelay.start();
    }
    function startSlideshow() {
        if (root.selectedWalls.length === 0) return;
        let home = Quickshell.env("HOME");
        let scriptPath = root.scriptsPath + "/slideshow.sh";
        let servicePath = home + "/.config/systemd/user/zenith-slideshow.service";
        let listPath = home + "/.cache/zenith_wallpaper_list";
        let paths = root.selectedWalls.map(p => p.replace("file://", "")).join("\n");
        saveList.command = ["sh", "-c", "echo '" + paths + "' > " + listPath]; saveList.running = true;
        let serviceContent = "[Unit]\nDescription=Zenith Slideshow\n\n[Service]\nExecStart=/bin/bash " + scriptPath + "\nRestart=always\nRestartSec=5\nEnvironment=PATH=/usr/bin:/bin:/usr/local/bin\n[Install]\nWantedBy=default.target";
        installService.command = ["sh", "-c", "echo -e '" + serviceContent + "' > " + servicePath + " && chmod +x " + scriptPath + " && systemctl --user daemon-reload"];
        installService.running = true;
        startTimer.start();
    }
    Timer { id: startTimer; interval: 500; onTriggered: { serviceCmd.command = ["systemctl", "--user", "enable", "--now", "zenith-slideshow.service"]; serviceCmd.running = true; CenterState.close(); } }
    function stopSlideshow() { serviceCmd.command = ["systemctl", "--user", "disable", "--now", "zenith-slideshow.service"]; serviceCmd.running = true; }
    function log(msg) { logger.command = ["sh", "-c", "echo '[$(date +%T)] " + msg + "' >> " + logPath]; logger.running = true; }

    Timer { id: wallDelay; property string wallPath: ""; interval: 600; onTriggered: { setWall.command = ["sh", "-c", "awww img '" + wallPath + "' --transition-type fade >> " + root.logPath + " 2>&1 && ~/.config/quickshell/scripts/zenith-theme.sh --autoselect"]; setWall.running = true; } }
    Timer { id: videoDelay; property string videoPath: ""; interval: 400; onTriggered: { mpvProcess.command = ["sh", "-c", "MONITOR=$(awww query | head -n1 | cut -d: -f1); if [ -z \"$MONITOR\" ]; then MONITOR=$(wlr-randr | head -n1 | awk '{print $1}'); fi; mpvpaper -vsf -o 'no-audio loop' $MONITOR '" + videoPath + "' >> " + root.logPath + " 2>&1"]; mpvProcess.running = true; CenterState.close(); } }

    Process { id: logger }
    Process { id: awwwDaemon; command: ["sh", "-c", "awww-daemon >> " + logPath + " 2>&1"] }
    Process { id: setWall; onExited: { CenterState.close(); } }
    Process { id: killawww; command: ["killall", "awww-daemon"] }
    Process { id: killMpv; command: ["killall", "mpvpaper"] }
    Process { id: installService }
    Process { id: saveList }
    Process { id: serviceCmd }
    Process { id: mpvProcess }
    Process { id: saveCurrentWall; property string path: ""; command: ["sh", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.config && echo '" + path + "' > " + Quickshell.env("HOME") + "/.config/current_wallpaper.txt"] }
    Process { id: thumbGen; command: ["python3", (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/services/generate_thumbnails.py"]; onRunningChanged: { if (!running) { root.thumbnailsReady = true; root.refreshTrigger++; } } }
    Component.onCompleted: refreshThumbnails()
}
