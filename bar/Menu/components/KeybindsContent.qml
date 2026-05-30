import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../"
import "../../../Settings"

Rectangle {
    id: root
    color: "transparent"

    property var keybindsData: []

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(20)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(10)
            
            Text {
                text: "󰌌"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(16)
                color: Theme.blue
            }
            Text {
                text: "KEYBINDINGS"
                font.pixelSize: Theme.scaled(14)
                font.weight: Font.Black
                color: Theme.text
                font.letterSpacing: 1
            }
            Item { Layout.fillWidth: true }
        }

        // --- HINT / LEGEND ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(15)
            Rectangle {
                Layout.fillWidth: true
                height: Theme.scaled(35)
                color: Qt.rgba(0,0,0,0.2)
                radius: Theme.scaled(8)
                border.color: Theme.glassBorder
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.scaled(20)
                    
                    Text { 
                        text: "HINT:"
                        color: Theme.blue
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Black
                    }

                    Repeater {
                        model: [
                            { icon: "󰘳", label: "SUPER" },
                            { icon: "󰘵", label: "CTRL" },
                            { icon: "󰘴", label: "ALT" },
                            { icon: "󰘶", label: "SHIFT" }
                        ]
                        delegate: RowLayout {
                            spacing: Theme.scaled(5)
                            Text { text: modelData.icon; color: Theme.lavender; font.pixelSize: Theme.scaled(12); font.bold: true }
                            Text { text: modelData.label; color: Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Bold }
                        }
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                id: list
                width: parent.width
                model: root.keybindsData
                spacing: Theme.scaled(25)
                interactive: true
                
                delegate: ColumnLayout {
                    width: list.width
                    spacing: Theme.scaled(12)
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: Theme.scaled(1)
                        color: Theme.surface0
                        visible: index > 0
                    }

                    Text {
                        text: modelData.section.toUpperCase()
                        color: Theme.blue
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Black
                        font.letterSpacing: 2
                    }
                    
                    GridLayout {
                        id: grid
                        columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
                        columnSpacing: Theme.scaled(50)
                        rowSpacing: Theme.scaled(18)
                        Layout.fillWidth: true

                        Repeater {
                            model: modelData.binds
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: (grid.width - grid.columnSpacing) / grid.columns
                                spacing: Theme.scaled(15)
                                
                                Rectangle {
                                    width: Theme.scaled(140)
                                    height: Theme.scaled(32)
                                    radius: Theme.scaled(8)
                                    color: Theme.surface1
                                    border.color: Theme.glassBorder
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.combo
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(13)
                                        font.weight: Font.Bold
                                        color: Theme.lavender
                                    }
                                }
                                
                                Text {
                                    text: modelData.desc
                                    color: Theme.text
                                    font.pixelSize: Theme.scaled(13)
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
                
                    // Improved regex to handle "bind = , KEY, ..." and "bind = MOD, KEY, ..."
                let match = lineNoComment.match(/bind[a-z]*\s*=\s*([^,]*),\s*([^,]+)/);
                if (match) {
                    let mod = match[1].trim();
                    let key = match[2].trim();
                    
                    let combo = [];
                    if (mod) {
                        mod.split(/[\s&_+]+/).forEach(m => {
                            let clean = m.trim().toUpperCase();
                            if (clean === "$MAINMOD" || clean === "SUPER" || clean === "MOD4" || clean === "SUPER_L" || clean === "SUPER_R") combo.push("󰘳");
                            else if (clean === "$CTRLMOD" || clean === "CONTROL" || clean === "CTRL" || clean === "CTRL_L" || clean === "CTRL_R") combo.push("󰘵");
                            else if (clean === "$SHIFTMOD" || clean === "SHIFT" || clean === "SHIFT_L" || clean === "SHIFT_R") combo.push("󰘶");
                            else if (clean === "$ALTMOD" || clean === "ALT" || clean === "MOD1" || clean === "^" || clean === "ALT_L" || clean === "ALT_R") combo.push("󰘴");
                            else if (clean.length > 0) combo.push(m.trim());
                        });
                    }

                    let cleanKey = key.replace("XF86", "").trim();
                    if (cleanKey.toLowerCase() === "left") cleanKey = "";
                    else if (cleanKey.toLowerCase() === "right") cleanKey = "";
                    else if (cleanKey.toLowerCase() === "up") cleanKey = "";
                    else if (cleanKey.toLowerCase() === "down") cleanKey = "";
                    
                    if (cleanKey.length > 0) combo.push(cleanKey);

                    currentSection.binds.push({ 
                        combo: combo.filter(c => c && c.length > 0).join("  "), 
                        desc: comment || "No description" 
                    });
                }
            }
        }
        if (currentSection.binds.length > 0) sections.push(currentSection);
        root.keybindsData = sections;
    }

    Process {
        id: keybindsReader
        command: ["cat", PathSettings.configDir + "/hypr/hyprland/keybinds.conf"]
        stdout: StdioCollector {
            onStreamFinished: { if (typeof text !== "undefined" && text !== null) parseKeybinds(text); }
        }
    }

    Component.onCompleted: {
        keybindsReader.running = true;
    }

    function resetScroll() {
        list.positionViewAtBeginning();
    }
}
