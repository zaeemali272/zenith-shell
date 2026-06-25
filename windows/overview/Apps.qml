import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../" as Shell
import "../components" as Components
import ".." // Imports parent directory directly to expose the IconsFetcher Singleton cleanly

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

    property var fullAppList: []
    property bool isInitialized: false

    function updateList() {
        if (!isInitialized) {
            if (folderModel.status !== FolderListModel.Ready && folderModel.count === 0) return;
            
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
                            // Drop background agents, installers, handlers, and CLI commands
                            isHidden = true;
                            break;
                        } else if (lowerLine.startsWith("categories=")) {
                            let cats = lowerLine.substring(11);
                            // Drop core development sub-tools and internal setting handlers
                            if (cats.includes("core;") || cats.includes("settings;") || cats.includes("x-desktop-applet;")) {
                                isHidden = true;
                                break;
                            }
                        }
                    }
                } catch(e) {}

                // Evaluate structural system markers + explicit keyword exclusions
                if (isHidden || !IconsFetcher.isMainApp(rawId, displayName)) continue;

                let score = (typeof AppUsageService !== 'undefined') ? AppUsageService.getScore(rawId) : 0;
                arr.push({ 
                    fileName: fn, 
                    filePath: fp,
                    appId: rawId, 
                    displayName: displayName,
                    displayLower: displayName.toLowerCase(),
                    rawLower: rawId.toLowerCase(),
                    iconName: iconName,
                    usageScore: score
                });
            }
            
            if (arr.length > 0 || folderModel.status === FolderListModel.Ready) {
                fullAppList = arr;
                isInitialized = true;
            }
        }

        filteredModel.clear();
        let searchLower = root.searchText.toLowerCase().replace(/\s/g, "");

        function isFuzzyMatch(text, query) {
            let sIdx = 0;
            for (let cIdx = 0; cIdx < text.length && sIdx < query.length; cIdx++) {
                if (text[cIdx] === query[sIdx]) sIdx++;
            }
            return sIdx === query.length;
        }

        let filtered = [];
        if (root.searchText === "") {
            filtered = fullAppList;
        } else {
            for (let item of fullAppList) {
                if (isFuzzyMatch(item.displayLower, searchLower) || isFuzzyMatch(item.rawLower, searchLower)) {
                    filtered.push(item);
                }
            }
        }
        
        filtered.sort((a, b) => {
            if (b.usageScore !== a.usageScore) return b.usageScore - a.usageScore;
            return a.displayName.localeCompare(b.displayName);
        });
        
        for (let item of filtered) filteredModel.append(item);
        root.currentIndex = 0;
    }

    onSearchTextChanged: updateList()
    
    function refreshScores() {
        if (!isInitialized) return;
        let changed = false;
        for (let i = 0; i < fullAppList.length; i++) {
            let score = (typeof AppUsageService !== 'undefined') ? AppUsageService.getScore(fullAppList[i].appId) : 0;
            if (fullAppList[i].usageScore !== score) {
                fullAppList[i].usageScore = score;
                changed = true;
            }
        }
        if (changed || root.searchText === "") updateList();
    }

    GridView {
        id: grid
        anchors.fill: parent
        cellWidth: Math.floor(grid.width / (Shell.Theme.appMenuCol || 6))
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

    function launchApp(filePath, appId) {
        if (appId && typeof AppUsageService !== 'undefined') AppUsageService.recordLaunch(appId);
        // Use setsid to start the command in a new session, detaching it from quickshell's process group.
        // Redirecting output to /dev/null ensures the process doesn't hold onto quickshell's pipes.
        launchProcess.command = ["setsid", "sh", "-c", "ELECTRON_OZONE_PLATFORM_HINT=x11 gio launch " + filePath + " > /dev/null 2>&1 &"];
        launchProcess.running = true;
        root.closeRequested();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (root.currentIndex < filteredModel.count) {
                let item = filteredModel.get(root.currentIndex);
                launchApp(item.filePath, item.appId);
            }
        } else if (event.key === Qt.Key_Right) {
            root.currentIndex = Math.min(root.currentIndex + 1, filteredModel.count - 1);
        } else if (event.key === Qt.Key_Left) {
            root.currentIndex = Math.max(root.currentIndex - 1, 0);
        } else if (event.key === Qt.Key_Down) {
            root.currentIndex = Math.min(root.currentIndex + (Shell.Theme.appMenuCol || 6), filteredModel.count - 1);
        } else if (event.key === Qt.Key_Up) {
            root.currentIndex = Math.max(root.currentIndex - (Shell.Theme.appMenuCol || 6), 0);
        }
    }
    
    Process { id: launchProcess }
}