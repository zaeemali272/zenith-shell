import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"
import "../" as Shell

PanelWindow {
    id: clipboardRoot
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
    WlrLayershell.namespace: "zenith-clipboard"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property var rawHistory: []
    property var displayedItems: []

    Process { id: actionProc }

    Process {
        id: loadClipProc
        command: ["sh", "-c", "cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipboardRoot.parseCliphistOutput(text);
            }
        }
    }

    Component.onCompleted: {
        if (visible) loadHistory();
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            Qt.callLater(() => searchInput.forceActiveFocus());
            showAnim.restart();
            loadHistory();
        } else {
            mainContent.opacity = 0;
            mainContent.scale = 0.95;
        }
    }

    // Smooth entrance animation matching launcher.qml
    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: mainContent
            property: "opacity"
            from: 0
            to: 1
            duration: Shell.Theme.animNormal
            easing.type: Shell.Theme.animEasing
        }
        NumberAnimation {
            target: mainContent
            property: "scale"
            from: 0.96
            to: 1.0
            duration: Shell.Theme.animNormal
            easing.type: Shell.Theme.animEasing
        }
    }

    function loadHistory() {
        loadClipProc.running = false;
        loadClipProc.running = true;
    }

    function parseCliphistOutput(text) {
        if (!text) {
            rawHistory = [];
            rebuildFiltered();
            return;
        }

        let lines = text.split("\n");
        let items = [];

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line || line.trim() === "") continue;

            let tabIdx = line.indexOf("\t");
            let itemId = "";
            let preview = "";

            if (tabIdx !== -1) {
                itemId = line.substring(0, tabIdx).trim();
                preview = line.substring(tabIdx + 1).trim();
            } else {
                let spaceIdx = line.search(/\s/);
                if (spaceIdx !== -1) {
                    itemId = line.substring(0, spaceIdx).trim();
                    preview = line.substring(spaceIdx + 1).trim();
                } else {
                    itemId = line.trim();
                    preview = line.trim();
                }
            }

            if (!itemId) continue;

            let type = "text";
            let icon = "📋";

            if (preview.startsWith("[[ binary data")) {
                type = "image";
                icon = "🖼️";
            } else if (/^https?:\/\//i.test(preview) || /^www\./i.test(preview)) {
                type = "url";
                icon = "🔗";
            } else if (/[{}\[\];<>]/.test(preview) && (preview.includes("function") || preview.includes("class") || preview.includes("import") || preview.includes("const") || preview.includes("let") || preview.includes("var") || preview.includes("def "))) {
                type = "code";
                icon = "💻";
            }

            items.push({
                id: itemId,
                rawLine: line,
                text: preview,
                type: type,
                icon: icon
            });
        }

        rawHistory = items;
        rebuildFiltered();
    }

    function rebuildFiltered() {
        let query = searchInput.text.toLowerCase().trim();

        if (query === "") {
            displayedItems = rawHistory.slice(0, 30);
        } else {
            let results = [];
            for (let i = 0; i < rawHistory.length; i++) {
                let item = rawHistory[i];
                if (item.text.toLowerCase().includes(query) || item.id.includes(query)) {
                    results.push(item);
                }
            }
            displayedItems = results.slice(0, 30);
        }

        if (displayedItems.length > 0) {
            clipListView.currentIndex = 0;
            clipListView.positionViewAtIndex(0, ListView.Beginning);
        } else {
            clipListView.currentIndex = -1;
        }
    }

    function copyItem(item) {
        if (!item || !item.id) return;
        actionProc.command = ["sh", "-c", "cliphist list | grep '^" + item.id + "\t' | cliphist decode | wl-copy 2>/dev/null || true"];
        actionProc.running = false;
        actionProc.running = true;
        clipboardRoot.close();
    }

    function deleteItem(item) {
        if (!item || !item.id) return;
        actionProc.command = ["sh", "-c", "cliphist list | grep '^" + item.id + "\t' | cliphist delete 2>/dev/null || true"];
        actionProc.running = false;
        actionProc.running = true;
        Qt.callLater(() => loadHistory());
    }

    function wipeHistory() {
        actionProc.command = ["cliphist", "wipe"];
        actionProc.running = false;
        actionProc.running = true;
        Qt.callLater(() => loadHistory());
    }

    // Dismiss overlay backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: clipboardRoot.close()
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

            // Floating Search Bar Input (Matching launcher.qml layout)
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
                        text: "📋"
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 70
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 15
                        color: (Shell.Colors && Shell.Colors.on_background) ? Shell.Colors.on_background : "#f0dfd7"
                        focus: true

                        onTextChanged: clipboardRoot.rebuildFiltered()

                        Keys.onEscapePressed: clipboardRoot.close()

                        Keys.onDownPressed: {
                            if (clipListView.count > 0) {
                                clipListView.currentIndex = Math.min(clipListView.count - 1, clipListView.currentIndex + 1);
                                clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain);
                            }
                        }

                        Keys.onUpPressed: {
                            if (clipListView.count > 0) {
                                clipListView.currentIndex = Math.max(0, clipListView.currentIndex - 1);
                                clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain);
                            }
                        }

                        Keys.onReturnPressed: {
                            if (clipListView.currentIndex >= 0 && clipListView.currentIndex < displayedItems.length) {
                                clipboardRoot.copyItem(displayedItems[clipListView.currentIndex]);
                            }
                        }

                        Keys.onEnterPressed: {
                            if (clipListView.currentIndex >= 0 && clipListView.currentIndex < displayedItems.length) {
                                clipboardRoot.copyItem(displayedItems[clipListView.currentIndex]);
                            }
                        }

                        Keys.onDeletePressed: {
                            if (clipListView.currentIndex >= 0 && clipListView.currentIndex < displayedItems.length) {
                                clipboardRoot.deleteItem(displayedItems[clipListView.currentIndex]);
                            }
                        }

                        Text {
                            text: "Type to search clipboard history..."
                            color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                            font.pixelSize: 15
                            visible: searchInput.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Clear Search Icon / Button
                    Text {
                        text: "✕"
                        color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                        font.pixelSize: 14
                        visible: searchInput.text.length > 0
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Floating Results List Card
            Rectangle {
                width: parent.width
                height: Math.min(displayedItems.length * 52 + 50, 420)
                radius: 14
                visible: displayedItems.length > 0
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    ListView {
                        id: clipListView
                        width: parent.width
                        height: parent.height - 38
                        clip: true
                        model: clipboardRoot.displayedItems
                        spacing: 4
                        interactive: true

                        delegate: Rectangle {
                            id: delegateRoot
                            width: clipListView.width
                            height: 48
                            radius: 10

                            required property var modelData
                            required property int index

                            readonly property bool isSelected: index === clipListView.currentIndex

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

                                onEntered: clipListView.currentIndex = index
                                onClicked: clipboardRoot.copyItem(delegateRoot.modelData)
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: itemDeleteBtn.left
                                anchors.rightMargin: 8
                                spacing: 12

                                // Type Icon
                                Text {
                                    text: (delegateRoot.modelData && delegateRoot.modelData.icon) ? delegateRoot.modelData.icon : "📋"
                                    font.pixelSize: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 36
                                    spacing: 1

                                    Text {
                                        text: (delegateRoot.modelData && delegateRoot.modelData.text) ? delegateRoot.modelData.text : ""
                                        color: delegateRoot.isSelected
                                            ? ((Shell.Colors && Shell.Colors.on_primary_container) ? Shell.Colors.on_primary_container : "#ffdbc9")
                                            : ((Shell.Colors && Shell.Colors.on_surface) ? Shell.Colors.on_surface : "#f0dfd7")
                                        font.pixelSize: 14
                                        font.weight: delegateRoot.isSelected ? Font.Bold : Font.Medium
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: "Item #" + (delegateRoot.modelData ? delegateRoot.modelData.id : "") + (delegateRoot.modelData && delegateRoot.modelData.type === "image" ? " • Image Binary" : "")
                                        color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                                        font.pixelSize: 11
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }

                            // Single Item Delete Action Button
                            Rectangle {
                                id: itemDeleteBtn
                                width: 28
                                height: 28
                                radius: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: deleteMouse.containsMouse ? (Shell.Colors && Shell.Colors.error_container ? Shell.Colors.error_container : "#8c1d18") : "transparent"
                                visible: hoverArea.containsMouse || delegateRoot.isSelected

                                Text {
                                    anchors.centerIn: parent
                                    text: "🗑"
                                    font.pixelSize: 12
                                    color: deleteMouse.containsMouse ? "#ffb4ab" : ((Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8")
                                }

                                MouseArea {
                                    id: deleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        clipboardRoot.deleteItem(delegateRoot.modelData);
                                    }
                                }
                            }
                        }
                    }

                    // Toolbar Footer (Item Count & Wipe History)
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                text: "Showing " + displayedItems.length + " of " + rawHistory.length + " entries"
                                color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            height: 24
                            width: wipeRow.implicitWidth + 14
                            radius: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: wipeMouse.containsMouse ? (Shell.Colors && Shell.Colors.error_container ? Shell.Colors.error_container : "#8c1d18") : "transparent"
                            border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                            border.width: 1

                            Row {
                                id: wipeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "🗑 Clear History"
                                    font.pixelSize: 11
                                    color: wipeMouse.containsMouse ? "#ffb4ab" : ((Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8")
                                }
                            }

                            MouseArea {
                                id: wipeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clipboardRoot.wipeHistory()
                            }
                        }
                    }
                }
            }

            // Floating "No clipboard history found" Card
            Rectangle {
                width: parent.width
                height: 48
                radius: 12
                visible: rawHistory.length === 0 || displayedItems.length === 0
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Text {
                    anchors.centerIn: parent
                    text: rawHistory.length === 0 ? "Clipboard history is empty" : "No matching clipboard entries"
                    color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                    font.pixelSize: 13
                }
            }
        }
    }
}
