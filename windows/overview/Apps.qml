import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../" as Shell
import "../components" as Components
import ".." as Windows

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

    function updateList() {
        filteredModel.clear();
        let arr = [];
        let searchLower = root.searchText.toLowerCase().replace(/\s/g, "");

        // Helper to check for fuzzy subsequence match
        function isFuzzyMatch(text, query) {
            let sIdx = 0;
            for (let cIdx = 0; cIdx < text.length && sIdx < query.length; cIdx++) {
                if (text[cIdx] === query[sIdx]) sIdx++;
            }
            return sIdx === query.length;
        }

        for (let i = 0; i < folderModel.count; i++) {
            let fn = folderModel.get(i, "fileName");
            let rawId = fn.replace(".desktop", "");
            let nameParts = rawId.split(".");
            let baseName = nameParts[nameParts.length - 1];
            let displayName = baseName.replace(/[-_]/g, " ");
            displayName = displayName.charAt(0).toUpperCase() + displayName.slice(1);
            
            if (!Windows.IconsFetcher.isMainApp(rawId, displayName)) continue;

            let displayLower = displayName.toLowerCase();
            let rawLower = rawId.toLowerCase();
            
            let isMatch = (root.searchText === "") || isFuzzyMatch(displayLower, searchLower) || isFuzzyMatch(rawLower, searchLower);

            if (isMatch) {
                let score = (typeof AppUsageService !== 'undefined') ? AppUsageService.getScore(rawId) : 0;
                arr.push({ 
                    fileName: fn, 
                    appId: rawId, 
                    displayName: displayName,
                    usageScore: score
                });
            }
        }
        
        arr.sort((a, b) => {
            if (b.usageScore !== a.usageScore) return b.usageScore - a.usageScore;
            return a.displayName.localeCompare(b.displayName);
        });
        for (let item of arr) filteredModel.append(item);
        root.currentIndex = 0;
    }

    onSearchTextChanged: updateList()

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
                        candidates: Windows.IconsFetcher.getCandidates(model.appId, model.fileName, "")
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
                onClicked: { launchApp(model.fileName, model.appId); }
            }
        }
    }

    function launchApp(fileName, appId) {
        if (appId && typeof AppUsageService !== 'undefined') AppUsageService.recordLaunch(appId);
        launchProcess.command = ["gtk-launch", fileName];
        launchProcess.running = true;
        root.closeRequested();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (root.currentIndex < filteredModel.count) {
                let item = filteredModel.get(root.currentIndex);
                launchApp(item.fileName, item.appId);
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
