import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../../"
import "../../../services"
import "../../../Settings"

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)
    focus: true
    Keys.onPressed: (event) => handleKeys(event)

    property var selectedWalls: []
    property int refreshTrigger: 0
    property string activeSubTab: CenterState.wallpaperSubTab
    onActiveSubTabChanged: {
        if (CenterState.wallpaperSubTab !== activeSubTab) {
            CenterState.wallpaperSubTab = activeSubTab;
        }
    }
    property bool thumbnailsReady: false
    property int selectedIndex: 0
    property string searchQuery: ""
    property string currentWallpaperPath: ""

    function loadCurrentWallpaper() {
        readCurrentWall.running = false;
        readCurrentWall.running = true;
    }

    function applyRandomWallpaper() {
        let count = wallFolderModel.count;
        if (count <= 0) return;
        let idx = Math.floor(Math.random() * count);
        let url = wallFolderModel.get(idx, "fileUrl");
        if (url) applyWallpaper(url.toString());
    }

    function matchesSearch(name) {
        let q = searchQuery.trim().toLowerCase();
        if (q === "") return true;
        return String(name || "").toLowerCase().indexOf(q) !== -1;
    }

    function cleanBaseName(name) {
        let s = String(name || "");
        let dot = s.lastIndexOf('.');
        return dot > 0 ? s.substring(0, dot) : s;
    }

    function handleKeys(event) {
        if (event.key === Qt.Key_Tab) {
            let subTabs = ["Wallpaper", "Themes", "Slideshow", "Animated"];
            let sIdx = subTabs.indexOf(root.activeSubTab);
            root.activeSubTab = subTabs[(sIdx + 1) % subTabs.length];
            root.selectedIndex = 0;
            event.accepted = true;
            return;
        } else if (event.key === Qt.Key_Backtab) {
            let subTabs = ["Wallpaper", "Themes", "Slideshow", "Animated"];
            let sIdx = subTabs.indexOf(root.activeSubTab);
            root.activeSubTab = subTabs[(sIdx - 1 + subTabs.length) % subTabs.length];
            root.selectedIndex = 0;
            event.accepted = true;
            return;
        }

        if (root.activeSubTab === "Themes") return;

        let cols = 4;
        let isAnimated = (root.activeSubTab === "Animated");
        let model = isAnimated ? animFolderModel : wallFolderModel;
        let maxIdx = model ? model.count - 1 : -1;

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

    onVisibleChanged: {
        if (visible) {
            refreshThumbnails();
            loadCurrentWallpaper();
        }
    }

    function refreshThumbnails() {
        thumbnailsReady = false;
        thumbGen.running = false;
        thumbGen.running = true;
    }

    readonly property string logPath: PathSettings.cacheDir + "/wallpaper.log"
    readonly property string scriptsPath: PathSettings.scriptsDir

    // --- SUB-TABS & TOOLBAR ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(10)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)
            
            Repeater {
                model: [
                    { id: "Wallpaper", icon: "󰸉" },
                    { id: "Themes", icon: "󰏘" },
                    { id: "Slideshow", icon: "󰐍" },
                    { id: "Animated", icon: "󰕧" }
                ]
                delegate: Rectangle {
                    Layout.preferredWidth: subTabRow.implicitWidth + Theme.scaled(22)
                    Layout.preferredHeight: Theme.scaled(32)
                    radius: Theme.bubbleRadiusPill
                    color: root.activeSubTab === modelData.id ? Theme.accentColor : (subTabMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                    border.color: root.activeSubTab === modelData.id ? Theme.accentColor : Theme.glassBorder
                    border.width: 1
                    antialiasing: true
                    scale: subTabMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                    Row {
                        id: subTabRow
                        anchors.centerIn: parent
                        spacing: Theme.scaled(5)
                        Text {
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(12)
                            color: root.activeSubTab === modelData.id ? Colors.on_primary : Theme.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text { 
                            text: modelData.id
                            font.pixelSize: Theme.scaled(11)
                            font.weight: Font.Black
                            color: root.activeSubTab === modelData.id ? Colors.on_primary : (subTabMouse.containsMouse ? Theme.text : Theme.subtext0)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea { 
                        id: subTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeSubTab = modelData.id;
                            root.selectedIndex = 0;
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }

            // Random Wallpaper Button
            Rectangle {
                visible: root.activeSubTab === "Wallpaper" && wallFolderModel.count > 1
                Layout.preferredWidth: randRow.implicitWidth + Theme.scaled(14)
                Layout.preferredHeight: Theme.scaled(30)
                radius: Theme.scaled(8)
                color: randMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1
                Row {
                    id: randRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(5)
                    Text { text: "󰒝"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(13); color: Theme.accentColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Random"; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: randMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyRandomWallpaper()
                }
            }
            
            // Thumbnail Generation Status
            RowLayout {
                spacing: Theme.scaled(6)
                visible: root.activeSubTab !== "Themes" && thumbGen.running
                Text {
                    text: "󱑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.blue
                    RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: thumbGen.running }
                }
                Text { text: "Updating..."; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; color: Theme.subtext1 }
            }
            
            // Refresh Button
            Rectangle {
                Layout.preferredWidth: Theme.scaled(30); Layout.preferredHeight: Theme.scaled(30); radius: Theme.scaled(8)
                color: refreshMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1
                antialiasing: true
                visible: root.activeSubTab !== "Themes" && !thumbGen.running
                Text { anchors.centerIn: parent; text: "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(15); color: refreshMouse.containsMouse ? Theme.text : Theme.subtext1 }
                MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: refreshThumbnails() }
            }
        }

        // Filter & Count Bar (for Wallpaper / Slideshow / Animated)
        RowLayout {
            visible: root.activeSubTab !== "Themes"
            Layout.fillWidth: true
            spacing: Theme.scaled(10)

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(30)
                radius: Theme.scaled(8)
                color: Theme.cardBackground
                border.color: wallSearchInput.activeFocus ? Theme.accentColor : Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.scaled(10)
                    anchors.rightMargin: Theme.scaled(8)
                    spacing: Theme.scaled(6)
                    Text { text: "󰍉"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(12); color: Theme.subtext0 }
                    TextInput {
                        id: wallSearchInput
                        Layout.fillWidth: true
                        color: Theme.text
                        font.pixelSize: Theme.scaled(11)
                        clip: true
                        onTextChanged: root.searchQuery = text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.activeSubTab === "Animated" ? "Filter animated wallpapers..." : "Filter wallpapers by name..."
                            color: Theme.subtext2
                            font.pixelSize: Theme.scaled(11)
                            visible: !parent.text && !parent.activeFocus
                        }
                    }
                    Text {
                        visible: wallSearchInput.text !== ""
                        text: "󰅖"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(11)
                        color: Theme.subtext0
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wallSearchInput.text = "" }
                    }
                }
            }

            Text {
                text: root.activeSubTab === "Animated"
                    ? animFolderModel.count + " videos"
                    : (root.activeSubTab === "Slideshow"
                        ? root.selectedWalls.length + " / " + wallFolderModel.count + " selected"
                        : wallFolderModel.count + " wallpapers")
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(10)
                font.weight: Font.Bold
            }
        }
    }

    // --- GRID AREA ---
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ThemeContent {
            id: themeSubContent
            anchors.fill: parent
            visible: root.activeSubTab === "Themes"
        }

        Flickable {
            FastWheel {}
            id: wallFlickable
            anchors.fill: parent
            contentHeight: wallFlow.height
            visible: root.activeSubTab === "Wallpaper" || root.activeSubTab === "Slideshow"
            clip: true
            ScrollBar.vertical: ScrollBar {
                parent: wallFlickable
                anchors.top: wallFlickable.top
                anchors.bottom: wallFlickable.bottom
                anchors.right: wallFlickable.right
                anchors.rightMargin: 1
                width: 4
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
            }

            Connections {
                target: root
                function onSelectedIndexChanged() {
                    let item = wallRepeater.itemAt(root.selectedIndex);
                    if (item) {
                        let itemPos = item.y;
                        if (itemPos < wallFlickable.contentY) wallFlickable.contentY = itemPos;
                        else if (itemPos + item.height > wallFlickable.contentY + wallFlickable.height) wallFlickable.contentY = itemPos + item.height - wallFlickable.height;
                    }
                }
            }

            Flow {
                id: wallFlow
                width: parent.width
                spacing: Theme.scaled(15)
                Repeater {
                    id: wallRepeater
                    model: FolderListModel {
                        id: wallFolderModel
                        folder: WallpaperService.wallpaperDir
                        nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.webp"]
                        onCountChanged: if (root.visible) refreshThumbnails();
                    }
                    delegate: Rectangle {
                        id: wallCard
                        readonly property bool matchesFilter: root.matchesSearch(fileName)
                        readonly property bool isCurrentWall: root.currentWallpaperPath !== "" && fileUrl.toString().replace("file://", "") === root.currentWallpaperPath
                        visible: matchesFilter
                        width: matchesFilter ? (wallFlow.width - Theme.scaled(45)) / 4 : 0
                        height: matchesFilter ? ((wallFlow.width - Theme.scaled(45)) / 4) * 0.6 : 0
                        radius: Theme.scaled(14)
                        color: Theme.cardBackground
                        antialiasing: true
                        property bool isSelected: root.selectedWalls.indexOf(fileUrl) !== -1
                        property int selectionIndex: root.selectedWalls.indexOf(fileUrl)
                        property bool isFocused: index === root.selectedIndex

                        // 1. Raw thumbnail image (hidden, MultiEffect renders it masked)
                        Image {
                            id: thumbImg
                            anchors.fill: parent
                            source: (fileName && fileName.lastIndexOf('.') > 0 && root.thumbnailsReady) 
                                ? ("file://" + Quickshell.env("HOME") + "/.cache/wallpaper_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png") 
                                : ""
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            asynchronous: true
                            visible: false
                        }

                        // 2. Smooth rounded mask for the image (hidden)
                        Rectangle {
                            id: cardMask
                            anchors.fill: parent
                            radius: wallCard.radius
                            color: "white"
                            layer.enabled: true
                            antialiasing: true
                            visible: false
                        }

                        // 3. MultiEffect renders the true rounded masked thumbnail
                        MultiEffect {
                            anchors.fill: parent
                            source: thumbImg
                            maskEnabled: true
                            maskSource: cardMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            opacity: (thumbImg.status === Image.Ready) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                            visible: opacity > 0
                        }

                        // Loading spinner
                        Text {
                            anchors.centerIn: parent
                            text: "󱑐"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: Theme.blue
                            visible: !root.thumbnailsReady || thumbImg.status !== Image.Ready
                            RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                        }

                        // Darken if selected
                        Rectangle {
                            anchors.fill: parent
                            color: wallCard.isSelected ? Qt.rgba(0, 0, 0, 0.4) : "transparent"
                            radius: wallCard.radius
                            antialiasing: true
                            visible: wallCard.isSelected
                        }

                        // Hover overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: wallCard.radius
                            color: cardMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                            antialiasing: true
                        }

                        // Clean anti-aliased border on top of the image
                        Rectangle {
                            anchors.fill: parent
                            radius: wallCard.radius
                            color: "transparent"
                            border.color: (wallCard.isFocused || wallCard.isSelected) ? Theme.accentColor : Theme.glassBorder
                            border.width: (wallCard.isFocused || wallCard.isSelected) ? 2 : 1
                            antialiasing: true
                            z: 2
                        }

                        // Hover filename pill
                        Rectangle {
                            visible: cardMouse.containsMouse
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: Theme.scaled(6)
                            height: Theme.scaled(20)
                            radius: Theme.scaled(6)
                            color: Qt.rgba(0, 0, 0, 0.72)
                            z: 3
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.scaled(6)
                                anchors.rightMargin: Theme.scaled(6)
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: root.cleanBaseName(fileName)
                                color: "#ffffff"
                                font.pixelSize: Theme.scaled(9)
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }

                        // Active Wallpaper Badge
                        Rectangle {
                            visible: wallCard.isCurrentWall && !wallCard.isSelected
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: Theme.scaled(7)
                            width: activeBadgeTxt.implicitWidth + Theme.scaled(10)
                            height: Theme.scaled(18)
                            radius: 999
                            color: Theme.accentColor
                            z: 3
                            Text {
                                id: activeBadgeTxt
                                anchors.centerIn: parent
                                text: "ACTIVE"
                                color: Colors.on_primary
                                font.pixelSize: Theme.scaled(8)
                                font.weight: Font.Black
                            }
                        }

                        // Selection Number Badge
                        Rectangle {
                            visible: wallCard.isSelected
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: Theme.scaled(8)
                            width: Theme.scaled(24)
                            height: Theme.scaled(24)
                            radius: Theme.scaled(12)
                            color: Theme.accentColor
                            antialiasing: true
                            z: 3
                            Text {
                                anchors.centerIn: parent
                                text: (wallCard.selectionIndex + 1).toString()
                                font.pixelSize: Theme.scaled(12)
                                font.bold: true
                                color: Theme.base
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: { 
                                let pathString = fileUrl.toString();
                                if (root.activeSubTab === "Wallpaper") applyWallpaper(pathString); 
                                else if (root.activeSubTab === "Slideshow") toggleSelection(pathString);
                            }
                        }
                    }
                }
            }

            // Empty state placeholder for Wallpapers / Slideshow
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(10)
                visible: wallFolderModel.count === 0 && !thumbGen.running
                Text {
                    text: "󰉏"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(48)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Directory is empty"
                    font.pixelSize: Theme.scaled(14)
                    font.weight: Font.Bold
                    color: Theme.subtext1
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "~/Pictures/Wallpapers"
                    font.pixelSize: Theme.scaled(11)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Flickable {
            FastWheel {}
            id: animFlickable
            anchors.fill: parent
            contentHeight: animFlow.height
            visible: root.activeSubTab === "Animated"
            clip: true
            ScrollBar.vertical: ScrollBar {
                parent: animFlickable
                anchors.top: animFlickable.top
                anchors.bottom: animFlickable.bottom
                anchors.right: animFlickable.right
                anchors.rightMargin: 1
                width: 4
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
            }

            Connections {
                target: root
                function onSelectedIndexChanged() {
                    let item = animRepeater.itemAt(root.selectedIndex);
                    if (item) {
                        let itemPos = item.y;
                        if (itemPos < animFlickable.contentY) animFlickable.contentY = itemPos;
                        else if (itemPos + item.height > animFlickable.contentY + animFlickable.height) animFlickable.contentY = itemPos + item.height - animFlickable.height;
                    }
                }
            }

            Flow {
                id: animFlow
                width: parent.width
                spacing: Theme.scaled(15)
                Repeater {
                    id: animRepeater
                    model: FolderListModel {
                        id: animFolderModel
                        folder: WallpaperService.animationDir
                        nameFilters: ["*.mp4", "*.mkv", "*.webm"]
                        onCountChanged: if (root.visible) refreshThumbnails();
                    }
                    delegate: Rectangle {
                        id: animCard
                        width: (animFlow.width - Theme.scaled(45)) / 4
                        height: width * 0.6
                        radius: Theme.scaled(14)
                        color: Theme.cardBackground
                        antialiasing: true
                        property bool isFocused: index === root.selectedIndex

                        // 1. Raw animated video thumbnail image (hidden, MultiEffect renders it masked)
                        Image {
                            id: animImg
                            anchors.fill: parent
                            source: (fileName && fileName.lastIndexOf('.') > 0 && root.thumbnailsReady)
                                ? ("file://" + Quickshell.env("HOME") + "/.cache/animation_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png")
                                : ""
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            asynchronous: true
                            visible: false
                        }

                        // 2. Smooth rounded mask for the image (hidden)
                        Rectangle {
                            id: animMask
                            anchors.fill: parent
                            radius: animCard.radius
                            color: "white"
                            layer.enabled: true
                            antialiasing: true
                            visible: false
                        }

                        // 3. MultiEffect renders the true rounded masked thumbnail
                        MultiEffect {
                            anchors.fill: parent
                            source: animImg
                            maskEnabled: true
                            maskSource: animMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            opacity: (animImg.status === Image.Ready) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                            visible: opacity > 0
                        }

                        // Hover overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: animCard.radius
                            color: animMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                            antialiasing: true
                        }

                        // Border on top
                        Rectangle {
                            anchors.fill: parent
                            radius: animCard.radius
                            color: "transparent"
                            border.color: animCard.isFocused ? Theme.accentColor : Theme.glassBorder
                            border.width: animCard.isFocused ? 2 : 1
                            antialiasing: true
                            z: 2
                        }

                        MouseArea {
                            id: animMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: applyVideo(fileUrl.toString())
                        }
                    }
                }
            }

            // Empty state placeholder for Animated Videos
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(10)
                visible: animFolderModel.count === 0 && !thumbGen.running
                Text {
                    text: "󰕧"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(48)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Directory is empty"
                    font.pixelSize: Theme.scaled(14)
                    font.weight: Font.Bold
                    color: Theme.subtext1
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "~/Videos/Animated"
                    font.pixelSize: Theme.scaled(11)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- SLIDESHOW CONTROLS ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.scaled(12)
        visible: root.activeSubTab === "Slideshow"

        Rectangle {
            implicitWidth: clearSelTxt.implicitWidth + Theme.scaled(20)
            height: Theme.scaled(36)
            radius: Theme.scaled(10)
            color: Theme.cardBackground
            border.color: Theme.glassBorder
            border.width: 1
            visible: root.selectedWalls.length > 0
            Text { id: clearSelTxt; anchors.centerIn: parent; text: "Clear (" + root.selectedWalls.length + ")"; color: Theme.subtext0; font.pixelSize: Theme.scaled(11); font.weight: Font.Bold }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedWalls = [] }
        }

        Rectangle {
            width: Theme.scaled(180); height: Theme.scaled(36); radius: Theme.scaled(10)
            color: root.selectedWalls.length > 0 ? Theme.accentColor : Theme.surface1
            Text { anchors.centerIn: parent; text: "Start Slideshow"; color: root.selectedWalls.length > 0 ? Colors.on_primary : Theme.subtext1; font.bold: true; font.pixelSize: Theme.scaled(11) }
            MouseArea { anchors.fill: parent; enabled: root.selectedWalls.length > 0; cursorShape: Qt.PointingHandCursor; onClicked: startSlideshow() }
        }
        Rectangle {
            width: Theme.scaled(160); height: Theme.scaled(36); radius: Theme.scaled(10)
            color: Theme.red
            visible: slideshowRunning
            Text { anchors.centerIn: parent; text: "Stop Slideshow"; color: Colors.on_primary; font.bold: true; font.pixelSize: Theme.scaled(11) }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: stopSlideshow() }
        }
    }

    property bool slideshowRunning: false
    Timer {
        interval: 2000; running: root.activeSubTab === "Slideshow"; repeat: true; triggeredOnStart: true
        onTriggered: checkSlideshowStatus()
    }
    function checkSlideshowStatus() {
        checkStatus.command = ["systemctl", "--user", "is-active", "--quiet", "zenith-slideshow.service"];
        checkStatus.running = true;
    }
    Process { id: checkStatus; onExited: (exitCode, exitStatus) => slideshowRunning = (exitCode === 0) }

    // --- LOGIC FUNCTIONS ---
    function toggleSelection(path) {
        let arr = [...root.selectedWalls];
        let idx = arr.indexOf(path);
        if (idx !== -1) arr.splice(idx, 1);
        else arr.push(path);
        root.selectedWalls = arr;
    }
    function applyWallpaper(path) {
        CenterState.close();
        killMpv.running = true; stopSlideshow(); awwwDaemon.running = true; 
        let cleanPath = path.replace("file://", "");
        saveCurrentWall.path = cleanPath; saveCurrentWall.running = true;
        wallDelay.wallPath = cleanPath; wallDelay.restart();
    }
    function applyVideo(path) {
        CenterState.close();
        killawww.running = true; killMpv.running = true; stopSlideshow();
        videoDelay.videoPath = path.replace("file://", ""); videoDelay.restart();
    }
    function startSlideshow() {
        if (root.selectedWalls.length === 0) return;
        let scriptPath = root.scriptsPath + "/slideshow.sh";
        let listPath = PathSettings.cacheDir + "/slideshow_list";
        let paths = root.selectedWalls.map(p => p.replace("file://", "")).join("\n");
        // One process writes the list and installs the unit; the service is
        // started only after both are on disk.
        let unit = [
            "[Unit]", "Description=Zenith wallpaper slideshow", "",
            "[Service]", "ExecStart=/usr/bin/env bash " + scriptPath,
            "Restart=on-failure", "RestartSec=5", "",
            "[Install]", "WantedBy=default.target"
        ].join("\n");
        installService.command = ["sh", "-c",
            "mkdir -p \"$1\" \"$(dirname \"$2\")\" && printf '%s\\n' \"$3\" > \"$2\" && printf '%s\\n' \"$4\" > \"$1/zenith-slideshow.service\" && systemctl --user daemon-reload",
            "_", PathSettings.configDir + "/systemd/user", listPath, paths, unit];
        installService.running = true;
    }
    Process {
        id: installService
        onExited: (code) => {
            if (code !== 0) return;
            serviceCmd.command = ["systemctl", "--user", "enable", "--now", "zenith-slideshow.service"];
            serviceCmd.running = true;
            CenterState.close();
        }
    }
    function stopSlideshow() {
        serviceCmd.command = ["sh", "-c", "systemctl --user disable --now zenith-slideshow.service 2>/dev/null; rm -f \"$1\"; systemctl --user daemon-reload", "_", PathSettings.configDir + "/systemd/user/zenith-slideshow.service"];
        serviceCmd.running = true;
    }
    function log(msg) { logger.command = ["sh", "-c", "echo '[$(date +%T)] " + msg + "' >> " + logPath]; logger.running = true; }

    Timer { id: wallDelay; property string wallPath: ""; interval: 40; onTriggered: { setWall.command = ["sh", "-c", "awww img --resize=crop '" + wallPath + "' --transition-type fade >> " + root.logPath + " 2>&1; " + PathSettings.scriptsDir + "/zenith-theme.sh --dynamic '" + wallPath + "' >> " + root.logPath + " 2>&1"]; setWall.running = false; setWall.running = true; } }
    Timer { id: videoDelay; property string videoPath: ""; interval: 50; onTriggered: { mpvProcess.command = ["sh", "-c", "MONITOR=$(awww query | head -n1 | cut -d: -f1); if [ -z \"$MONITOR\" ]; then MONITOR=$(wlr-randr | head -n1 | awk '{print $1}'); fi; mpvpaper -vsf -o 'no-audio loop' $MONITOR '" + videoPath + "' >> " + root.logPath + " 2>&1"]; mpvProcess.running = true; } }

    Process { id: logger }
    // Only start the daemon if one is not already listening. Starting it
    // unconditionally -- which applyWallpaper() does on every single wallpaper
    // change -- makes it abort with a Rust panic ("already running on this
    // socket") whenever it is already up, which is the normal case. Those
    // panics and their backtraces were the entire contents of zenith.log.
    Process { id: awwwDaemon; command: ["sh", "-c", "awww query >/dev/null 2>&1 || awww-daemon >> " + logPath + " 2>&1"] }
    Process { id: setWall }
    Process { id: killawww; command: ["killall", "awww-daemon"] }
    Process { id: killMpv; command: ["killall", "mpvpaper"] }
    Process { id: serviceCmd }
    Process { id: mpvProcess }
    Process { id: saveCurrentWall; property string path: ""; command: ["sh", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.config && echo '" + path + "' > " + Quickshell.env("HOME") + "/.config/current_wallpaper.txt"] }
    Process {
        id: readCurrentWall
        command: ["cat", Quickshell.env("HOME") + "/.config/current_wallpaper.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.currentWallpaperPath = String(text).trim();
            }
        }
    }
    Process { id: thumbGen; command: ["python3", (Quickshell.env("ZENITH_ROOT") ? Quickshell.env("ZENITH_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/services/generate_thumbnails.py"]; onRunningChanged: { if (!running) { root.thumbnailsReady = true; root.refreshTrigger++; } } }
    Component.onCompleted: {
        refreshThumbnails();
        loadCurrentWallpaper();
    }

    function resetScroll() {
        root.activeSubTab = "Wallpaper";
        root.selectedIndex = 0;
        wallFlickable.contentY = 0;
        animFlickable.contentY = 0;
    }
}
