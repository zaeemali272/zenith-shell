import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"
import "../" as Shell

PanelWindow {
    id: launcherRoot
    visible: false
    color: "transparent"

    function toggle() {
        visible = !visible;
    }

    function close() {
        visible = false;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "zenith-launcher"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property string storagePath: Quickshell.env("HOME") + "/.config/quickshell/app_usage.json"
    property var usageMap: ({})
    property var allAppsCache: []
    property var displayedApps: []

    Process { id: shellExecProc }

    // Pre-index applications cache when model updates
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { launcherRoot.rebuildCache(); }
        function onRowsInserted() { launcherRoot.rebuildCache(); }
        function onModelReset() { launcherRoot.rebuildCache(); }
    }

    Component.onCompleted: {
        rebuildCache();
        loadUsageProc.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            Qt.callLater(() => searchInput.forceActiveFocus());
            showAnim.restart();
            if (allAppsCache.length === 0) rebuildCache();
            else rebuildFiltered();
        } else {
            mainContent.opacity = 0;
            mainContent.scale = 0.95;
        }
    }

    // Smooth entrance animation
    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: mainContent
            property: "opacity"
            from: 0
            to: 1
            duration: 180
            easing.type: Easing.OutQuint
        }
        NumberAnimation {
            target: mainContent
            property: "scale"
            from: 0.95
            to: 1.0
            duration: 180
            easing.type: Easing.OutBack
        }
    }

    // --- Usage Persistence ---
    Process {
        id: loadUsageProc
        command: ["cat", launcherRoot.storagePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    launcherRoot.usageMap = JSON.parse(text) || {};
                } catch(e) {
                    launcherRoot.usageMap = {};
                }
                launcherRoot.rebuildFiltered();
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) launcherRoot.rebuildFiltered();
        }
    }

    Process { id: saveUsageProc }

    function saveUsage() {
        saveUsageProc.command = [
            "python3", "-c",
            "import json, os, sys; p=sys.argv[1]; d=sys.argv[2]; os.makedirs(os.path.dirname(p), exist_ok=True); f=open(p, 'w'); f.write(d); f.close()",
            storagePath,
            JSON.stringify(usageMap)
        ];
        saveUsageProc.running = true;
    }

    function recordAppUsage(appId) {
        if (!appId) return;
        let count = usageMap[appId] || 0;
        usageMap[appId] = count + 1;
        saveUsage();
    }

    // --- Pre-Index App Cache ---
    function rebuildCache() {
        let rawApps = DesktopEntries.applications.values || [];
        let cache = [];

        for (let i = 0; i < rawApps.length; i++) {
            let entry = rawApps[i];
            if (!entry || !entry.name || entry.noDisplay) continue;

            let name = entry.name || "";
            let appId = entry.id || "";
            let genericName = entry.genericName || "";
            let comment = entry.comment || "";
            let categories = entry.categories || "";

            cache.push({
                entry: entry,
                id: appId,
                name: name,
                icon: entry.icon || "",
                genericName: genericName,
                comment: comment,
                searchKey: (name + " " + appId + " " + genericName + " " + comment + " " + categories).toLowerCase()
            });
        }

        allAppsCache = cache;
        rebuildFiltered();
    }

    // --- Fast Math Evaluator (e.g. "6 + 6" -> "12") ---
    function evalMath(expr) {
        try {
            let clean = expr.trim();
            if (!/^[\d\s\+\-\*\/\%\(\)\.\^]+$/.test(clean)) return null;
            if (!/[\+\-\*\/\%\^]/.test(clean)) return null;
            
            clean = clean.replace(/\^/g, '**');
            let val = Function('"use strict"; return (' + clean + ')')();
            if (typeof val === "number" && !isNaN(val) && isFinite(val)) {
                let formatted = Number.isInteger(val) ? val.toString() : val.toFixed(4).replace(/\.?0+$/, '');
                return formatted;
            }
        } catch(e) {}
        return null;
    }

    // --- Dynamic Microsecond Filter ---
    function rebuildFiltered() {
        let query = searchInput.text.toLowerCase().trim();

        if (query === "") {
            displayedApps = [];
            appListView.currentIndex = -1;
            return;
        }

        let results = [];

        // 1. Math Calculation
        let mathRes = evalMath(searchInput.text);
        if (mathRes !== null) {
            results.push({
                isMath: true,
                result: mathRes,
                name: searchInput.text.trim() + " = " + mathRes,
                genericName: "Calculation Result (Press Enter to copy)",
                icon: "calculator",
                id: "math_calc",
                score: 100000
            });
        }

        // 2. Filter Pre-Indexed Cache
        for (let i = 0; i < allAppsCache.length; i++) {
            let app = allAppsCache[i];
            let nameLower = app.name.toLowerCase();
            let idLower = app.id.toLowerCase();

            if (app.searchKey.includes(query)) {
                let usage = usageMap[app.id] || 0;
                let score = usage * 1000;

                if (nameLower === query) score += 5000;
                else if (nameLower.startsWith(query)) score += 2000;
                else if (nameLower.includes(query)) score += 1000;
                else if (idLower.includes(query)) score += 500;

                results.push({
                    isMath: false,
                    entry: app.entry,
                    id: app.id,
                    name: app.name,
                    icon: app.icon,
                    genericName: app.genericName,
                    comment: app.comment,
                    score: score
                });
            }
        }

        results.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            return a.name.localeCompare(b.name);
        });

        // Limit to top 3 matching items
        displayedApps = results.slice(0, 3);

        if (displayedApps.length > 0) {
            appListView.currentIndex = 0;
            appListView.positionViewAtIndex(0, ListView.Beginning);
        } else {
            appListView.currentIndex = -1;
        }
    }

    function launchApp(appItem) {
        if (!appItem) return;
        
        if (appItem.isMath) {
            shellExecProc.command = ["sh", "-c", "echo -n '" + appItem.result + "' | wl-copy 2>/dev/null || true"];
            shellExecProc.running = true;
            launcherRoot.close();
            return;
        }

        if (appItem.entry) {
            recordAppUsage(appItem.id);
            appItem.entry.execute();
            launcherRoot.close();
        }
    }

    // Dismiss overlay backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: launcherRoot.close()
    }

    // Centered Container with Animation
    Item {
        id: mainContent
        anchors.centerIn: parent
        width: 580
        height: mainColumn.implicitHeight
        opacity: 0
        scale: 0.95

        Column {
            id: mainColumn
            width: parent.width
            spacing: 8

            // Floating Search Bar Input (No focus border)
            Rectangle {
                width: parent.width
                height: 48
                radius: 14
                color: (Shell.Colors && Shell.Colors.surface_container) ? Shell.Colors.surface_container : "#271e19"
                border.width: 0

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: "⌕"
                        color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 40
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 15
                        color: (Shell.Colors && Shell.Colors.on_background) ? Shell.Colors.on_background : "#f0dfd7"
                        focus: true

                        onTextChanged: launcherRoot.rebuildFiltered()

                        Keys.onEscapePressed: launcherRoot.close()

                        Keys.onDownPressed: {
                            if (appListView.count > 0) {
                                appListView.currentIndex = Math.min(appListView.count - 1, appListView.currentIndex + 1);
                                appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain);
                            }
                        }

                        Keys.onUpPressed: {
                            if (appListView.count > 0) {
                                appListView.currentIndex = Math.max(0, appListView.currentIndex - 1);
                                appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain);
                            }
                        }

                        Keys.onReturnPressed: {
                            if (appListView.currentIndex >= 0 && appListView.currentIndex < displayedApps.length) {
                                launcherRoot.launchApp(displayedApps[appListView.currentIndex]);
                            }
                        }

                        Keys.onEnterPressed: {
                            if (appListView.currentIndex >= 0 && appListView.currentIndex < displayedApps.length) {
                                launcherRoot.launchApp(displayedApps[appListView.currentIndex]);
                            }
                        }

                        Text {
                            text: "Type to search applications or calculate (e.g. 6 + 6)..."
                            color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                            font.pixelSize: 15
                            visible: searchInput.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Floating Results List Card (Appears floating below search bar ONLY upon typing)
            Rectangle {
                width: parent.width
                height: displayedApps.length * 52 + 8
                radius: 14
                visible: searchInput.text.trim() !== "" && displayedApps.length > 0
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                ListView {
                    id: appListView
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    model: launcherRoot.displayedApps
                    spacing: 4
                    interactive: false

                    delegate: Rectangle {
                        id: delegateRoot
                        width: appListView.width
                        height: 48
                        radius: 10

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === appListView.currentIndex

                        color: isSelected
                            ? ((Shell.Colors && Shell.Colors.primary_container) ? Shell.Colors.primary_container : "#6f3812")
                            : (hoverArea.containsMouse ? ((Shell.Colors && Shell.Colors.surface_container_high) ? Shell.Colors.surface_container_high : "#312823") : "transparent")

                        border.color: isSelected
                            ? ((Shell.Colors && Shell.Colors.primary) ? Shell.Colors.primary : "#ffb68d")
                            : "transparent"
                        border.width: isSelected ? 1 : 0

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: appListView.currentIndex = index
                            onClicked: launcherRoot.launchApp(delegateRoot.modelData)
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            spacing: 12

                            // Math Icon or App Icon
                            Item {
                                width: 26
                                height: 26
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    visible: delegateRoot.modelData && delegateRoot.modelData.isMath
                                    text: "🧮"
                                    font.pixelSize: 18
                                }

                                IconImage {
                                    anchors.fill: parent
                                    visible: !delegateRoot.modelData || !delegateRoot.modelData.isMath
                                    appName: (delegateRoot.modelData && delegateRoot.modelData.name) ? delegateRoot.modelData.name : ""
                                    desktopEntry: (delegateRoot.modelData && delegateRoot.modelData.id) ? delegateRoot.modelData.id : ""
                                    iconName: (delegateRoot.modelData && delegateRoot.modelData.icon) ? delegateRoot.modelData.icon : ""
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 38
                                spacing: 1

                                Text {
                                    text: (delegateRoot.modelData && delegateRoot.modelData.name) ? delegateRoot.modelData.name : "Unknown"
                                    color: delegateRoot.isSelected
                                        ? ((Shell.Colors && Shell.Colors.on_primary_container) ? Shell.Colors.on_primary_container : "#ffdbc9")
                                        : ((Shell.Colors && Shell.Colors.on_surface) ? Shell.Colors.on_surface : "#f0dfd7")
                                    font.pixelSize: 14
                                    font.weight: delegateRoot.isSelected ? Font.Bold : Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: (delegateRoot.modelData) ? (delegateRoot.modelData.genericName
                                        || delegateRoot.modelData.comment
                                        || "") : ""
                                    color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                                    font.pixelSize: 11
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                    width: parent.width
                                    visible: text !== ""
                                }
                            }
                        }
                    }
                }
            }

            // Floating "No applications found" Card
            Rectangle {
                width: parent.width
                height: 44
                radius: 12
                visible: searchInput.text.trim() !== "" && displayedApps.length === 0
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Text {
                    anchors.centerIn: parent
                    text: "No applications found"
                    color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                    font.pixelSize: 13
                }
            }
        }
    }
}