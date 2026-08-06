import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"
import "../" as Shell

PanelWindow {
    id: emojiRoot
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
    WlrLayershell.namespace: "zenith-emoji"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property string selectedCategory: "All"
    property var allEmojisCache: []
    property var displayedEmojis: []
    readonly property string jsonPath: (Quickshell.env("ZENITH_ROOT") || (Quickshell.env("HOME") + "/.config/quickshell")) + "/assets/emojis.json"

    Process { id: copyProc }

    Process {
        id: loadEmojiProc
        command: ["cat", jsonPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text) || [];
                    emojiRoot.buildCache(parsed);
                } catch(e) {
                    emojiRoot.allEmojisCache = [];
                    emojiRoot.rebuildFiltered();
                }
            }
        }
    }

    readonly property var categories: ["All", "Smileys", "People", "Animals", "Food", "Activities", "Travel", "Objects", "Symbols", "Flags"]

    Component.onCompleted: {
        loadEmojiProc.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            selectedCategory = "All";
            Qt.callLater(() => searchInput.forceActiveFocus());
            showAnim.restart();
            if (allEmojisCache.length === 0) {
                loadEmojiProc.running = false;
                loadEmojiProc.running = true;
            } else {
                rebuildFiltered();
            }
        } else {
            mainContent.opacity = 0;
            mainContent.scale = 0.95;
        }
    }

    // Entrance Animation matching launcher.qml
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

    // Pre-index items for microsecond filtering
    function buildCache(rawItems) {
        let cache = [];
        for (let i = 0; i < rawItems.length; i++) {
            let item = rawItems[i];
            if (!item || !item.char) continue;

            let char = item.char || "";
            let name = item.name || "";
            let cat = item.cat || "";
            let tags = item.tags || "";

            cache.push({
                char: char,
                name: name,
                cat: cat,
                tags: tags,
                searchKey: (name + " " + tags + " " + cat + " " + char).toLowerCase()
            });
        }

        allEmojisCache = cache;
        rebuildFiltered();
    }

    function rebuildFiltered() {
        let query = searchInput.text.toLowerCase().trim();
        let cat = selectedCategory;

        let results = [];
        for (let i = 0; i < allEmojisCache.length; i++) {
            let item = allEmojisCache[i];

            // Category filter
            if (cat !== "All" && item.cat !== cat) continue;

            // Search query filter
            if (query !== "") {
                if (!item.searchKey.includes(query)) continue;
            }

            results.push(item);
        }

        displayedEmojis = results;

        if (displayedEmojis.length > 0) {
            emojiGridView.currentIndex = 0;
        } else {
            emojiGridView.currentIndex = -1;
        }
    }

    function copyEmoji(item) {
        if (!item || !item.char) return;
        copyProc.command = ["sh", "-c", "echo -n '" + item.char + "' | wl-copy 2>/dev/null || true"];
        copyProc.running = false;
        copyProc.running = true;
        emojiRoot.close();
    }

    // Dismiss backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: emojiRoot.close()
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

            // Search Bar Input
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
                        text: "😀"
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

                        onTextChanged: emojiRoot.rebuildFiltered()

                        Keys.onEscapePressed: emojiRoot.close()

                        Keys.onRightPressed: {
                            if (emojiGridView.count > 0) {
                                emojiGridView.currentIndex = Math.min(emojiGridView.count - 1, emojiGridView.currentIndex + 1);
                                emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain);
                            }
                        }

                        Keys.onLeftPressed: {
                            if (emojiGridView.count > 0) {
                                emojiGridView.currentIndex = Math.max(0, emojiGridView.currentIndex - 1);
                                emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain);
                            }
                        }

                        Keys.onDownPressed: {
                            if (emojiGridView.count > 0) {
                                let cols = Math.floor(emojiGridView.width / emojiGridView.cellWidth);
                                emojiGridView.currentIndex = Math.min(emojiGridView.count - 1, emojiGridView.currentIndex + cols);
                                emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain);
                            }
                        }

                        Keys.onUpPressed: {
                            if (emojiGridView.count > 0) {
                                let cols = Math.floor(emojiGridView.width / emojiGridView.cellWidth);
                                emojiGridView.currentIndex = Math.max(0, emojiGridView.currentIndex - cols);
                                emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain);
                            }
                        }

                        Keys.onReturnPressed: {
                            if (emojiGridView.currentIndex >= 0 && emojiGridView.currentIndex < displayedEmojis.length) {
                                emojiRoot.copyEmoji(displayedEmojis[emojiGridView.currentIndex]);
                            }
                        }

                        Keys.onEnterPressed: {
                            if (emojiGridView.currentIndex >= 0 && emojiGridView.currentIndex < displayedEmojis.length) {
                                emojiRoot.copyEmoji(displayedEmojis[emojiGridView.currentIndex]);
                            }
                        }

                        Text {
                            text: "Type to search emojis..."
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

            // Category Filter Pills Row
            Rectangle {
                width: parent.width
                height: 38
                radius: 12
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 4
                    contentWidth: categoryRow.width
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: categoryRow
                        spacing: 6

                        Repeater {
                            model: emojiRoot.categories

                            delegate: Rectangle {
                                width: catText.implicitWidth + 16
                                height: 30
                                radius: 8

                                required property string modelData

                                readonly property bool isActive: modelData === emojiRoot.selectedCategory

                                color: isActive
                                    ? ((Shell.Colors && Shell.Colors.primary_container) ? Shell.Colors.primary_container : "#6f3812")
                                    : (catMouse.containsMouse ? ((Shell.Colors && Shell.Colors.surface_container_high) ? Shell.Colors.surface_container_high : "#312823") : "transparent")

                                border.color: isActive
                                    ? ((Shell.Colors && Shell.Colors.primary) ? Shell.Colors.primary : "#ffb68d")
                                    : "transparent"
                                border.width: isActive ? 1 : 0

                                Text {
                                    id: catText
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.pixelSize: 12
                                    font.weight: parent.isActive ? Font.Bold : Font.Normal
                                    color: parent.isActive
                                        ? ((Shell.Colors && Shell.Colors.on_primary_container) ? Shell.Colors.on_primary_container : "#ffdbc9")
                                        : ((Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8")
                                }

                                MouseArea {
                                    id: catMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        emojiRoot.selectedCategory = parent.modelData;
                                        emojiRoot.rebuildFiltered();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Floating Emoji Grid Card (GRID WITHOUT NAME/TITLE IN CELLS)
            Rectangle {
                width: parent.width
                height: Math.min(Math.ceil(displayedEmojis.length / 10) * 56 + 46, 380)
                radius: 14
                visible: displayedEmojis.length > 0
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

                    GridView {
                        id: emojiGridView
                        width: parent.width
                        height: parent.height - 34
                        cellWidth: 56
                        cellHeight: 56
                        clip: true
                        model: emojiRoot.displayedEmojis
                        interactive: true

                        delegate: Rectangle {
                            id: delegateRoot
                            width: 50
                            height: 50
                            radius: 10

                            required property var modelData
                            required property int index

                            readonly property bool isSelected: index === emojiGridView.currentIndex

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

                                onEntered: emojiGridView.currentIndex = index
                                onClicked: emojiRoot.copyEmoji(delegateRoot.modelData)
                            }

                            // Large Emoji Character ONLY (No name/title text in cell)
                            Text {
                                anchors.centerIn: parent
                                text: (delegateRoot.modelData && delegateRoot.modelData.char) ? delegateRoot.modelData.char : ""
                                font.pixelSize: 26
                            }
                        }
                    }

                    // Bottom Bar showing active emoji description & count
                    Rectangle {
                        width: parent.width
                        height: 26
                        color: "transparent"

                        Item {
                            anchors.fill: parent

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: (emojiGridView.currentIndex >= 0 && emojiGridView.currentIndex < displayedEmojis.length)
                                    ? (displayedEmojis[emojiGridView.currentIndex].char + "  " + displayedEmojis[emojiGridView.currentIndex].name + " (" + displayedEmojis[emojiGridView.currentIndex].cat + ")")
                                    : "Hover or select an emoji"
                                color: (Shell.Colors && Shell.Colors.on_surface) ? Shell.Colors.on_surface : "#f0dfd7"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                width: parent.width - 120
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: displayedEmojis.length + " emojis"
                                color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            // Floating "No emojis found" Card
            Rectangle {
                width: parent.width
                height: 48
                radius: 12
                visible: displayedEmojis.length === 0
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: (Shell.Colors && Shell.Colors.surface_variant) ? Shell.Colors.surface_variant : "#52443c"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Text {
                    anchors.centerIn: parent
                    text: "No emojis found"
                    color: (Shell.Colors && Shell.Colors.on_surface_variant) ? Shell.Colors.on_surface_variant : "#d7c2b8"
                    font.pixelSize: 13
                }
            }
        }
    }
}
