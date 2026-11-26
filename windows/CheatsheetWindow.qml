import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../" as Shell
import "../services" as Services
import "../bar/Menu"

MenuWindow {
    id: root

    card: sheetCard
    cardOrigin: Item.Center
    namespaceName: "zenith-cheatsheet"
    onDismissed: {
        root.filterText = "";
        searchInput.text = "";
    }

    onShownChanged: {
        if (shown) {
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
        } else {
            root.filterText = "";
            searchInput.text = "";
        }
    }

    property string filterText: ""

    // Keybindings Dataset
    readonly property var categories: [
        {
            title: "Navigation & Shell",
            icon: "󰕰",
            items: [
                { keys: ["Super"], desc: "Toggle App Launcher" },
                { keys: ["Super", "/"], desc: "Keybindings Cheatsheet" },
                { keys: ["Super", "D"], desc: "Toggle App Launcher" },
                { keys: ["Super", "A"], desc: "Toggle Zenith Dashboard" },
                { keys: ["Ctrl", "Super", "Q"], desc: "Quick Settings Menu" },
                { keys: ["Super", "V"], desc: "Clipboard History" },
                { keys: ["Super", "."], desc: "Emoji Picker" },
                { keys: ["Ctrl", "Super", "T"], desc: "Wallpaper & Themes" },
                { keys: ["Super", "L"], desc: "Lock Screen" },
                { keys: ["Ctrl", "Alt", "Delete"], desc: "Power / Session Menu" },
                { keys: ["Ctrl", "Super", "C"], desc: "Dismiss All Menus" }
            ]
        },
        {
            title: "Applications",
            icon: "󰀻",
            items: [
                { keys: ["Super", "T"], desc: "Terminal (Kitty)" },
                { keys: ["Super", "W"], desc: "Web Browser" },
                { keys: ["Super", "E"], desc: "File Manager" },
                { keys: ["Super", "C"], desc: "Code Editor" },
                { keys: ["Ctrl", "Super", "M"], desc: "Mail Client" },
                { keys: ["Ctrl", "Super", "I"], desc: "Desktop Settings" }
            ]
        },
        {
            title: "Window Management",
            icon: "󰖯",
            items: [
                { keys: ["Super", "Q"], desc: "Close Active Window" },
                { keys: ["Super", "Alt", "Space"], desc: "Toggle Floating" },
                { keys: ["Super", "F"], desc: "Toggle Fullscreen" },
                { keys: ["Super", "Alt", "P"], desc: "Pin Window (Always on Top)" },
                { keys: ["Super", "Comma"], desc: "Toggle Window Group" },
                { keys: ["Alt", "Tab"], desc: "Cycle Active Window" },
                { keys: ["Super", "LMB Drag"], desc: "Move Window" },
                { keys: ["Super", "RMB Drag"], desc: "Resize Window" }
            ]
        },
        {
            title: "Workspaces & Hardware",
            icon: "󰍹",
            items: [
                { keys: ["Super", "1-9"], desc: "Switch to Workspace 1..9" },
                { keys: ["Super", "Alt", "1-9"], desc: "Move Window to Workspace" },
                { keys: ["Super", "Scroll Up/Dn"], desc: "Cycle Workspaces" },
                { keys: ["Super", "S"], desc: "Special Scratchpad" },
                { keys: ["Print"], desc: "Screenshot Region" },
                { keys: ["Super", "Shift", "C"], desc: "Color Picker (Hyprpicker)" },
                { keys: ["SUPER", "Shift", "M"], desc: "Mute Microphone" },
                { keys: ["Ctrl", "Super", "S"], desc: "Volume & Output Panel" }
            ]
        }
    ]

    // Reusable Category Card component
    component CategoryCard: Rectangle {
        id: card
        required property var category
        property string filter: ""

        readonly property bool hasMatches: {
            if (!filter) return true;
            for (let i = 0; i < category.items.length; i++) {
                let it = category.items[i];
                if (it.desc.toLowerCase().includes(filter)) return true;
                for (let j = 0; j < it.keys.length; j++) {
                    if (it.keys[j].toLowerCase().includes(filter)) return true;
                }
            }
            return false;
        }

        visible: hasMatches
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        radius: Shell.Theme.bubbleRadiusMedium
        color: Shell.Colors.surface_container_low
        border.color: Shell.Theme.glassBorder
        border.width: 1
        implicitHeight: cardContent.implicitHeight + Shell.Theme.scaled(28)

        ColumnLayout {
            id: cardContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Shell.Theme.scaled(14)
            anchors.leftMargin: Shell.Theme.scaled(16)
            anchors.rightMargin: Shell.Theme.scaled(16)
            anchors.bottomMargin: Shell.Theme.scaled(14)
            spacing: Shell.Theme.scaled(10)

            // Category Title Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Shell.Theme.scaled(8)

                Text {
                    text: card.category.icon
                    font.family: Shell.Theme.iconFont
                    font.pixelSize: Shell.Theme.scaled(18)
                    color: Shell.Colors.primary
                }

                Text {
                    text: card.category.title
                    font.family: Shell.Theme.fontFamily
                    font.bold: true
                    font.pixelSize: Shell.Theme.scaled(14)
                    color: Shell.Colors.on_surface
                    Layout.fillWidth: true
                }
            }

            // Subtle divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Shell.Colors.outline_variant
                opacity: 0.35
            }

            // Keybinding items
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Shell.Theme.scaled(6)

                Repeater {
                    model: card.category.items

                    delegate: Item {
                        required property var modelData

                        readonly property bool itemMatches: {
                            if (!card.filter) return true;
                            if (modelData.desc.toLowerCase().includes(card.filter)) return true;
                            for (let k of modelData.keys) {
                                if (k.toLowerCase().includes(card.filter)) return true;
                            }
                            return false;
                        }

                        visible: itemMatches
                        Layout.fillWidth: true
                        implicitHeight: itemMatches ? Shell.Theme.scaled(28) : 0
                        height: implicitHeight

                        RowLayout {
                            anchors.fill: parent
                            spacing: Shell.Theme.scaled(8)

                            Text {
                                text: modelData.desc
                                Layout.fillWidth: true
                                font.family: Shell.Theme.fontFamily
                                font.pixelSize: Shell.Theme.scaled(12)
                                color: Shell.Colors.on_surface
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: Shell.Theme.scaled(4)
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                Repeater {
                                    model: modelData.keys

                                    delegate: Rectangle {
                                        required property string modelData
                                        radius: Shell.Theme.scaled(5)
                                        color: Shell.Colors.surface_container_high
                                        border.color: Shell.Colors.outline_variant
                                        border.width: 1
                                        implicitHeight: Shell.Theme.scaled(22)
                                        implicitWidth: keyTxt.implicitWidth + Shell.Theme.scaled(12)

                                        Text {
                                            id: keyTxt
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: Shell.Theme.fontFamily
                                            font.pixelSize: Shell.Theme.scaled(10)
                                            font.bold: true
                                            color: Shell.Colors.primary
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: sheetCard
        anchors.centerIn: parent
        width: Math.min(Shell.Theme.scaled(880), (screen ? screen.width : Shell.Theme.screenWidth) - Shell.Theme.scaled(32))
        height: Math.min(Shell.Theme.scaled(660), (screen ? screen.height : Shell.Theme.screenHeight) - Shell.Theme.scaled(48))
        radius: Shell.Theme.bubbleRadiusLarge
        color: Shell.Theme.glassBackground
        border.color: Shell.Theme.glassBorder
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Shell.Theme.scaled(24)
            spacing: Shell.Theme.scaled(16)

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Shell.Theme.scaled(12)

                Text {
                    text: "󰌌"
                    font.family: Shell.Theme.iconFont
                    font.pixelSize: Shell.Theme.scaled(28)
                    color: Shell.Colors.primary
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: "Zenith Keyboard Shortcuts"
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: Shell.Theme.scaled(20)
                        font.bold: true
                        color: Shell.Colors.on_surface
                    }

                    Text {
                        text: "Press Esc or click outside to dismiss. Filter shortcuts in real-time below."
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: Shell.Theme.scaled(12)
                        color: Shell.Colors.on_surface_variant
                    }
                }

                // Close Button
                Rectangle {
                    width: Shell.Theme.scaled(36)
                    height: Shell.Theme.scaled(36)
                    radius: width / 2
                    color: closeBtnArea.containsMouse ? Shell.Colors.surface_container_high : "transparent"
                    border.color: Shell.Colors.outline_variant
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: Shell.Theme.scaled(14)
                        color: Shell.Colors.on_surface_variant
                    }

                    MouseArea {
                        id: closeBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            // Search / Filter Input
            Rectangle {
                Layout.fillWidth: true
                height: Shell.Theme.scaled(42)
                radius: Shell.Theme.bubbleRadiusSmall
                color: Shell.Colors.surface_container_low
                border.color: searchInput.activeFocus ? Shell.Colors.primary : Shell.Colors.outline_variant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Shell.Theme.scaled(12)
                    anchors.rightMargin: Shell.Theme.scaled(12)
                    spacing: Shell.Theme.scaled(8)

                    Text {
                        text: "󰍉"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(18)
                        color: Shell.Colors.on_surface_variant
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: Shell.Theme.scaled(14)
                        color: Shell.Colors.on_surface
                        selectByMouse: true
                        onTextChanged: root.filterText = text.toLowerCase().trim()

                        Text {
                            anchors.fill: parent
                            text: "Type to search keybindings..."
                            font.family: Shell.Theme.fontFamily
                            font.pixelSize: Shell.Theme.scaled(14)
                            color: Shell.Colors.outline
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }

                    Text {
                        text: "Esc to close"
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: Shell.Theme.scaled(11)
                        color: Shell.Colors.outline
                    }
                }
            }

            // Two-Column Category Cards View inside ScrollView
            ScrollView {
                id: cheatsheetScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                RowLayout {
                    width: cheatsheetScroll.availableWidth
                    spacing: Shell.Theme.scaled(16)
                    Layout.alignment: Qt.AlignTop

                    // Left Column (Navigation & Shell, Window Management)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Shell.Theme.scaled(16)

                        CategoryCard {
                            category: root.categories[0]
                            filter: root.filterText
                        }

                        CategoryCard {
                            category: root.categories[2]
                            filter: root.filterText
                        }
                    }

                    // Right Column (Applications, Workspaces & Hardware)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Shell.Theme.scaled(16)

                        CategoryCard {
                            category: root.categories[1]
                            filter: root.filterText
                        }

                        CategoryCard {
                            category: root.categories[3]
                            filter: root.filterText
                        }
                    }
                }
            }
        }
    }
}
