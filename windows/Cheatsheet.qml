import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../" as Root

PanelWindow {
    id: win
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.margins { top: 20; bottom: 20; left: 20; right: 20 }
    
    visible: true
    color: "transparent"
    
    property bool active: true
    property string activeTab: "Keybinds"
    
    onActiveChanged: {
        if (active) {
            win.visible = true;
            root.opacity = 0;
            root.scale = 0.98;
            showAnim.start();
        } else {
            hideAnim.start();
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; from: 0.98; to: 1; duration: 300; easing.type: Easing.OutCubic }
    }
    
    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "scale"; to: 0.98; duration: 250; easing.type: Easing.InCubic }
        }
        PropertyAction { target: win; property: "visible"; value: false }
    }

    Rectangle {
        id: root
        anchors.fill: parent
        radius: 20
        color: Root.Theme.crust ? Qt.rgba(Root.Theme.crust.r, Root.Theme.crust.g, Root.Theme.crust.b, 0.96) : "#f511111b"
        border.color: Root.Theme.surface0 || "#313244"
        border.width: 1
        
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) active = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: active = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 20

            // Header & Tabs
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Cheatsheet"
                    font.pixelSize: 28
                    font.bold: true
                    color: Root.Theme.mauve || "#cba6f7"
                }

                Item { Layout.fillWidth: true } // Spacer

                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    Repeater {
                        model: ["Keybinds", "Gestures", "Features"]
                        delegate: Rectangle {
                            width: 100; height: 32; radius: 16
                            color: win.activeTab === modelData ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.surface0 || "#313244")
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 13; font.bold: true
                                color: win.activeTab === modelData ? (Root.Theme.crust || "#11111b") : (Root.Theme.text || "#cdd6f4")
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: win.activeTab = modelData
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Spacer
                
                // Keep balance
                Item { width: 100 }
            }

            // Content Area
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ["Keybinds", "Gestures", "Features"].indexOf(win.activeTab)

                // Keybinds Tab (Masonry/Flow style)
                Flickable {
                    contentHeight: masonryRow.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar { }

                    RowLayout {
                        id: masonryRow
                        width: parent.width
                        spacing: 30

                        Repeater {
                            model: [0, 1, 2] // 3 columns
                            delegate: ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: true
                                spacing: 25

                                Repeater {
                                    // Distribute sections into columns
                                    model: {
                                        let res = [];
                                        for (let i = index; i < win.keybindsData.length; i += 3) {
                                            res.push(win.keybindsData[i]);
                                        }
                                        return res;
                                    }
                                    delegate: ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        Text {
                                            text: modelData.section
                                            font.pixelSize: 22; font.bold: true
                                            color: Root.Theme.blue || "#89b4fa"
                                            Layout.alignment: Qt.AlignHCenter
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Repeater {
                                                model: modelData.binds
                                                delegate: ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2
                                                    Text {
                                                        text: modelData.combo
                                                        font.family: "monospace"; font.pixelSize: 15; font.bold: true
                                                        color: Root.Theme.peach || "#fab387"
                                                        Layout.alignment: Qt.AlignHCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    Text {
                                                        text: modelData.desc
                                                        font.pixelSize: 14; color: Root.Theme.text || "#cdd6f4"
                                                        Layout.alignment: Qt.AlignHCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                        wrapMode: Text.WordWrap
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true } // Push content up
                            }
                        }
                    }
                }

                // Gestures Tab
                Flickable {
                    contentHeight: gesturesColumn.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar { }
                    ColumnLayout {
                        id: gesturesColumn; width: parent.width; spacing: 30
                        Repeater {
                            model: win.gesturesData
                            delegate: Rectangle {
                                Layout.fillWidth: true; implicitHeight: gestCol.implicitHeight + 40
                                color: Root.Theme.surface0 || "#313244"; radius: 16
                                ColumnLayout {
                                    id: gestCol; anchors.fill: parent; anchors.margins: 20; spacing: 15
                                    Text {
                                        text: modelData.type.toUpperCase(); font.pixelSize: 20; font.bold: true
                                        color: Root.Theme.green || "#a6e3a1"; Layout.alignment: Qt.AlignHCenter
                                    }
                                    Repeater {
                                        model: modelData.items
                                        delegate: RowLayout {
                                            Layout.fillWidth: true; spacing: 20
                                            Text {
                                                text: modelData.trigger; font.pixelSize: 16; font.bold: true
                                                color: Root.Theme.mauve || "#cba6f7"; Layout.preferredWidth: 150
                                            }
                                            Text {
                                                text: modelData.command; font.family: "monospace"; font.pixelSize: 14
                                                color: Root.Theme.subtext0 || "#a6adc8"; Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Features Tab
                Flickable {
                    contentHeight: featuresColumn.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar { }
                    ColumnLayout {
                        id: featuresColumn; width: parent.width; spacing: 25
                        Repeater {
                            model: [
                                { title: "Modern Animated UI", desc: "A fluid and responsive interface built with Quickshell and QML.", icon: "󰄛" },
                                { title: "Intelligent Media Focus", desc: "Automatically manages media playback and microphone priority.", icon: "󰎆" },
                                { title: "Dynamic App Grid", desc: "A smart application launcher for quick access.", icon: "󰀻" },
                                { title: "GNOME-style Overview", desc: "Real-time workspace previews and window management.", icon: "󰕰" },
                                { title: "Wallpaper Engine", desc: "Static, slideshow, or live video backgrounds.", icon: "󰸉" },
                                { title: "System Integration", desc: "Deep integration with Hyprland, Mpris, and NetworkManager.", icon: "󰒓" }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true; implicitHeight: 100
                                color: Root.Theme.surface0 || "#313244"; radius: 16
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 20; spacing: 20
                                    Text { text: modelData.icon; font.pixelSize: 40; color: Root.Theme.mauve || "#cba6f7"; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignHCenter }
                                    ColumnLayout {
                                        spacing: 5
                                        Text { text: modelData.title; font.pixelSize: 18; font.bold: true; color: Root.Theme.text || "#cdd6f4" }
                                        Text { text: modelData.desc; font.pixelSize: 14; color: Root.Theme.subtext1 || "#bac2de"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Data Models & Parsers ---

    property var keybindsData: []
    property var gesturesData: []

    function parseKeybinds(content) {
        if (!content) return;
        let sections = [];
        let lines = content.split("\n");
        let currentSection = { section: "General", binds: [] };
        
        for (let line of lines) {
            let trimmed = line.trim();
            if (trimmed.startsWith("##!")) {
                if (currentSection.binds.length > 0) sections.push(currentSection);
                currentSection = { section: trimmed.replace("##!", "").trim(), binds: [] };
                continue;
            }
            if (!trimmed || (trimmed.startsWith("#") && !trimmed.startsWith("#!"))) continue;

            if (trimmed.startsWith("bind")) {
                if (trimmed.includes("# [hidden]")) continue;
                let comment = "";
                let lineNoComment = trimmed;
                if (trimmed.includes("#")) {
                    let parts = trimmed.split("#");
                    comment = parts[parts.length - 1].trim();
                    lineNoComment = parts.slice(0, -1).join("#").trim();
                }
                let match = lineNoComment.match(/bind[a-z]*\s*=\s*([^,]+),\s*([^,]+)/);
                if (match) {
                    currentSection.binds.push({ 
                        combo: match[1].trim() + " + " + match[2].trim(), 
                        desc: comment || "No description" 
                    });
                }
            }
        }
        if (currentSection.binds.length > 0) sections.push(currentSection);
        win.keybindsData = sections;
    }

    function parseGestures(content) {
        if (!content) return;
        let sections = [];
        let swipes = { type: "Swipes", items: [] };
        let holds = { type: "Holds", items: [] };
        let pinches = { type: "Pinches", items: [] };
        let lines = content.split("\n");
        let currentType = "";
        let currentFingers = "";
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            let indent = line.search(/\S/);
            let trimmed = line.trim();
            if (!trimmed || trimmed.startsWith("#")) continue;
            if (trimmed.startsWith("swipe:")) currentType = "swipe";
            else if (trimmed.startsWith("hold:")) currentType = "hold";
            else if (trimmed.startsWith("pinch:")) currentType = "pinch";
            else if (indent === 2 && trimmed.endsWith(":")) currentFingers = trimmed.replace(":", "");
            else if (indent === 4 && trimmed.endsWith(":")) {
                let direction = trimmed.replace(":", "");
                let trigger = currentFingers + " fingers " + direction;
                let cmd = "";
                for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
                    if (lines[j].trim().startsWith("command:")) {
                        cmd = lines[j].split("command:")[1].trim().replace(/\"/g, "");
                        break;
                    }
                }
                if (cmd) {
                    if (currentType === "swipe") swipes.items.push({ trigger: trigger, command: cmd });
                    else if (currentType === "pinch") pinches.items.push({ trigger: trigger, command: cmd });
                }
            } else if (currentType === "hold" && indent === 4 && trimmed.includes("sendkey:")) {
                holds.items.push({ trigger: currentFingers + " fingers", command: trimmed.split("sendkey:")[1].trim() });
            }
        }
        if (swipes.items.length > 0) sections.push(swipes);
        if (holds.items.length > 0) sections.push(holds);
        if (pinches.items.length > 0) sections.push(pinches);
        win.gesturesData = sections;
    }

    Process {
        id: keybindsReader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/hyprland/keybinds.conf"]
        stdout: StdioCollector {
            onStreamFinished: { if (typeof text !== "undefined" && text !== null) parseKeybinds(text); }
        }
    }

    Process {
        id: gesturesReader
        command: ["cat", Quickshell.env("HOME") + "/.config/fusuma/config.yml"]
        stdout: StdioCollector {
            onStreamFinished: { if (typeof text !== "undefined" && text !== null) parseGestures(text); }
        }
    }

    Component.onCompleted: {
        keybindsReader.running = true;
        gesturesReader.running = true;
    }
}
