import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../" as Shell
import "../components" as Components
import ".."

Item {
    id: root
    property string searchText: ""
    property int currentIndex: 0
    signal closeRequested()

    ListModel { id: filteredModel }
    
    FolderListModel {
        id: folderModel
        folder: "file:///usr/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: updateList()
    }

    property string cachePath: "/tmp/zenith_apps_cache.json"
    property var fullAppList: []
    property bool isInitialized: false
    readonly property int columns: Shell.Theme.appMenuCol || 6

    Component.onCompleted: {
        loadCache();
    }

    function loadCache() {
        try {
            let data = Quickshell.Io.readTextFile(cachePath);
            fullAppList = JSON.parse(data);
            isInitialized = true;
            updateList();
        } catch(e) {}
    }

    Process { id: saveProc }

    function saveCache() {
        let content = JSON.stringify(fullAppList).replace(/'/g, "'\\''");
        saveProc.command = ["sh", "-c", "echo '" + content + "' > " + cachePath];
        saveProc.running = true;
    }

    function updateList() {
        if (!isInitialized) {
            let arr = [];
            for (let i = 0; i < folderModel.count; i++) {
                let fn = folderModel.get(i, "fileName");
                let fp = folderModel.get(i, "filePath");
                let rawId = fn.replace(".desktop", "");
                let nameParts = rawId.split(".");
                let baseName = nameParts[nameParts.length - 1];
                let displayName = baseName.replace(/[-_]/g, " ");
                displayName = displayName.charAt(0).toUpperCase() + displayName.slice(1);
                
                let iconName = rawId; 
                let isHidden = false;

                try {
                    let content = Quickshell.Io.readTextFile(fp);
                    let lines = content.split("\n");
                    for (let line of lines) {
                        let trimmed = line.trim();
                        let lowerLine = trimmed.toLowerCase();
                        
                        if (trimmed.startsWith("Icon=")) {
                            iconName = trimmed.substring(5).trim();
                        } else if (trimmed.startsWith("Name=")) {
                            let n = trimmed.substring(5).trim();
                            if (n) displayName = n;
                        } else if (lowerLine.startsWith("nodisplay=true") || 
                                   lowerLine.startsWith("no_display=true") ||
                                   lowerLine.startsWith("terminal=true")) { 
                            isHidden = true;
                            break;
                        } else if (lowerLine.startsWith("categories=")) {
                            let cats = lowerLine.substring(11);
                            if (cats.includes("core;") || cats.includes("settings;") || cats.includes("x-desktop-applet;")) {
                                isHidden = true;
                                break;
                            }
                        }
                    }
                } catch(e) {}

                if (isHidden || !IconsFetcher.isMainApp(rawId, displayName)) continue;

                arr.push({ 
                    fileName: fn, 
                    filePath: fp,
                    appId: rawId, 
                    displayName: displayName,
                    displayLower: displayName.toLowerCase(),
                    rawLower: rawId.toLowerCase(),
                    iconName: iconName
                });
            }
            
            if (arr.length > 0) {
                fullAppList = arr;
                isInitialized = true;
                saveCache();
            }
        }

        filteredModel.clear();
        let searchLower = root.searchText.toLowerCase().replace(/\s/g, "");

        function getMatchScore(text, query) {
            if (text === query) return 100;
            if (text.startsWith(query)) return 80;
            if (text.includes(query)) return 50;
            return 0;
        }

        let filtered = [];
        if (root.searchText === "") {
            filtered = fullAppList;
        } else {
            for (let item of fullAppList) {
                let score = Math.max(getMatchScore(item.displayLower, searchLower), getMatchScore(item.rawLower, searchLower));
                if (score > 0) {
                    item.matchScore = score;
                    filtered.push(item);
                }
            }
        }
        
        filtered.sort((a, b) => {
            if (root.searchText !== "") {
                if (b.matchScore !== a.matchScore) return b.matchScore - a.matchScore;
            }
            return a.displayName.localeCompare(b.displayName);
        });
        
        for (let item of filtered) filteredModel.append(item);
        root.currentIndex = 0;
    }

    onSearchTextChanged: updateList()
    
    // Performance Navigation Handlers driven cleanly from Search context
    function navigate(direction) {
        if (filteredModel.count === 0) return;
        if (direction === "right") {
            root.currentIndex = Math.min(root.currentIndex + 1, filteredModel.count - 1);
        } else if (direction === "left") {
            root.currentIndex = Math.max(root.currentIndex - 1, 0);
        } else if (direction === "down") {
            root.currentIndex = Math.min(root.currentIndex + root.columns, filteredModel.count - 1);
        } else if (direction === "up") {
            root.currentIndex = Math.max(root.currentIndex - root.columns, 0);
        }
    }

    function launchCurrent() {
        if (root.currentIndex < filteredModel.count) {
            let item = filteredModel.get(root.currentIndex);
            launchApp(item.filePath, item.appId);
        }
    }

    function launchApp(filePath, appId) {
        launchProcess.command = ["setsid", "sh", "-c", "ELECTRON_OZONE_PLATFORM_HINT=x11 gio launch " + filePath + " > /dev/null 2>&1 &"];
        launchProcess.running = true;
        root.closeRequested();
    }

    GridView {
        id: grid
        anchors.fill: parent
        cellWidth: Math.floor(grid.width / root.columns)
        cellHeight: Shell.Theme.scaled ? Shell.Theme.scaled(120) : 120
        clip: true
        model: filteredModel
        snapMode: GridView.SnapToRow
        
        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            
            Rectangle {
                anchors.fill: layout
                anchors.margins: -5
                color: (index === root.currentIndex) ? (Shell.Theme.surface1 || '#a1232323') : "transparent"
                radius: 12
                z: -1
            }

            ColumnLayout {
                id: layout
                anchors.centerIn: parent
                spacing: 8
                width: grid.cellWidth - 20
                
                Rectangle {
                    width: Shell.Theme.scaled ? Shell.Theme.scaled(56) : 56
                    height: width
                    radius: 14
                    color: (index === root.currentIndex) ? (Shell.Theme.mauve || '#a6010101') : (Shell.Theme.surface0 || '#a1232323')
                    Layout.alignment: Qt.AlignHCenter
                    
                    Components.IconImage {
                        anchors.centerIn: parent
                        width: parent.width * 0.7
                        height: parent.height * 0.7
                        appName: model.displayName
                        desktopEntry: model.fileName
                        iconName: model.iconName
                    }
                }

                Text {
                    text: model.displayName
                    color: (index === root.currentIndex) ? (Shell.Theme.mauve || '#b5b5b5') : (Shell.Theme.text || "#cdd6f4")
                    font.pixelSize: 12
                    font.bold: index === root.currentIndex
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.currentIndex = index
                onClicked: { launchApp(model.filePath, model.appId); }
            }
        }
    }
    
    Process { id: launchProcess }
}