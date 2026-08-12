import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"
import "../" as Shell
import "../services"

PanelWindow {
    id: overlayRoot
    visible: DynamicIslandService.active
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "zenith-dynamic-island-overlay"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: mainCard
    }


    Component.onDestruction: MenuService.unregister(overlayRoot)



    onVisibleChanged: {
        if (visible) {
            MenuService.register(overlayRoot);
            showAnim.restart();
        } else {
            MenuService.unregister(overlayRoot);
            mainCard.opacity = 0;
            mainCard.scale = 0.95;
        }
    }


    // Ultra-smooth spring entrance animation
    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: mainCard
            property: "opacity"
            from: 0
            to: 1
            duration: 320
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: mainCard
            property: "scale"
            from: 0.92
            to: 1.0
            duration: 450
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
        NumberAnimation {
            target: mainCard
            property: "y"
            from: (Shell.Theme.barHeight || 40) - 10
            to: (Shell.Theme.barHeight || 40) + (Shell.Theme.barMarginTop || 8) + Shell.Theme.scaled(8)
            duration: 400
            easing.type: Easing.OutExpo
        }
    }

    // Dismiss overlay backdrop click
    MouseArea {
        id: backdropMouseArea
        anchors.fill: parent
        onClicked: DynamicIslandService.close()
    }


    // Centered Results Container below the Top Bar Center Widget
    Item {
        id: mainCard
        anchors.horizontalCenter: parent.horizontalCenter
        y: (Shell.Theme.barHeight || 40) + (Shell.Theme.barMarginTop || 8) + Shell.Theme.scaled(8)
        width: Shell.Theme.scaled(593)
        height: cardColumn.implicitHeight
        opacity: 0
        scale: 0.95

        Column {
            id: cardColumn
            width: parent.width
            spacing: Shell.Theme.scaled(8)

            // --- LAUNCHER RESULTS VIEW ---
            Rectangle {
                width: parent.width
                height: Math.max(54, DynamicIslandService.displayedApps.length * 52 + 12)
                radius: Shell.Theme.scaled(14)
                visible: DynamicIslandService.activeMode === "launcher"
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: Shell.Theme.glassBorder
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                ListView {
                    id: appListView
                    anchors.fill: parent
                    anchors.margins: 6
                    clip: true
                    model: DynamicIslandService.displayedApps
                    spacing: 4
                    interactive: false
                    currentIndex: DynamicIslandService.selectedIndex

                    visible: DynamicIslandService.displayedApps.length > 0

                    delegate: Rectangle {
                        id: appDelegate
                        width: appListView.width
                        height: 46
                        radius: Shell.Theme.scaled(10)

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === DynamicIslandService.selectedIndex

                        color: isSelected
                            ? ((Shell.Colors && Shell.Colors.primary_container) ? Shell.Colors.primary_container : "#6f3812")
                            : (hoverArea.containsMouse ? Shell.Theme.surfaceContainerHigh : "transparent")

                        border.color: isSelected
                            ? ((Shell.Colors && Shell.Colors.primary) ? Shell.Colors.primary : Shell.Theme.accentColor)
                            : "transparent"
                        border.width: isSelected ? 1 : 0

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: DynamicIslandService.selectedIndex = index
                            onClicked: DynamicIslandService.launchApp(appDelegate.modelData)
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
                                    visible: appDelegate.modelData && appDelegate.modelData.isMath
                                    text: "🧮"
                                    font.pixelSize: 18
                                }

                                IconImage {
                                    anchors.fill: parent
                                    visible: !appDelegate.modelData || !appDelegate.modelData.isMath
                                    appName: (appDelegate.modelData && appDelegate.modelData.name) ? appDelegate.modelData.name : ""
                                    desktopEntry: (appDelegate.modelData && appDelegate.modelData.id) ? appDelegate.modelData.id : ""
                                    iconName: (appDelegate.modelData && appDelegate.modelData.icon) ? appDelegate.modelData.icon : ""
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 38
                                spacing: 1

                                Text {
                                    text: (appDelegate.modelData && appDelegate.modelData.name) ? appDelegate.modelData.name : "Unknown"
                                    color: appDelegate.isSelected ? Shell.Theme.accentColor : Shell.Theme.text
                                    font.pixelSize: Shell.Theme.scaled(13)
                                    font.weight: appDelegate.isSelected ? Font.Bold : Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: (appDelegate.modelData) ? (appDelegate.modelData.genericName || appDelegate.modelData.comment || "") : ""
                                    color: Shell.Theme.subtext0
                                    font.pixelSize: Shell.Theme.scaled(11)
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                    width: parent.width
                                    visible: text !== ""
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: DynamicIslandService.displayedApps.length === 0
                    text: DynamicIslandService.query.trim() === "" ? "Type to search applications..." : "No applications found"
                    color: Shell.Theme.subtext0
                    font.pixelSize: Shell.Theme.scaled(13)
                }
            }

            // --- CLIPBOARD RESULTS VIEW ---
            Rectangle {
                width: parent.width
                height: Math.min(360, Math.max(54, DynamicIslandService.displayedClips.length * 48 + 12))
                radius: Shell.Theme.scaled(14)
                visible: DynamicIslandService.activeMode === "clipboard"
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: Shell.Theme.glassBorder
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                ListView {
                    id: clipListView
                    anchors.fill: parent
                    anchors.margins: 6
                    clip: true
                    model: DynamicIslandService.displayedClips
                    spacing: 4
                    currentIndex: DynamicIslandService.selectedIndex

                    visible: DynamicIslandService.displayedClips.length > 0

                    delegate: Rectangle {
                        id: clipDelegate
                        width: clipListView.width
                        height: 44
                        radius: Shell.Theme.scaled(10)

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === DynamicIslandService.selectedIndex

                        color: isSelected
                            ? ((Shell.Colors && Shell.Colors.primary_container) ? Shell.Colors.primary_container : "#6f3812")
                            : (clipHover.containsMouse ? Shell.Theme.surfaceContainerHigh : "transparent")

                        border.color: isSelected
                            ? ((Shell.Colors && Shell.Colors.primary) ? Shell.Colors.primary : Shell.Theme.accentColor)
                            : "transparent"
                        border.width: isSelected ? 1 : 0

                        MouseArea {
                            id: clipHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: DynamicIslandService.selectedIndex = index
                            onClicked: DynamicIslandService.copyClipItem(clipDelegate.modelData)
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "󰅍"
                                font.family: Shell.Theme.iconFont
                                font.pixelSize: Shell.Theme.scaled(14)
                                color: clipDelegate.isSelected ? Shell.Theme.accentColor : Shell.Theme.subtext0
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: (clipDelegate.modelData && clipDelegate.modelData.preview) ? clipDelegate.modelData.preview : ""
                                color: clipDelegate.isSelected ? Shell.Theme.text : Shell.Theme.subtext0
                                font.pixelSize: Shell.Theme.scaled(12)
                                elide: Text.ElideRight
                                width: parent.width - 60
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "󰆴"
                                font.family: Shell.Theme.iconFont
                                font.pixelSize: Shell.Theme.scaled(13)
                                color: delMouse.containsMouse ? Shell.Theme.powerRed : Shell.Theme.subtext0
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        DynamicIslandService.deleteClipItem(clipDelegate.modelData);
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: DynamicIslandService.displayedClips.length === 0
                    text: "No clipboard history found"
                    color: Shell.Theme.subtext0
                    font.pixelSize: Shell.Theme.scaled(13)
                }
            }

            // --- EMOJI RESULTS VIEW ---
            Rectangle {
                width: parent.width
                height: 320
                radius: Shell.Theme.scaled(14)
                visible: DynamicIslandService.activeMode === "emoji"
                color: (Shell.Colors && Shell.Colors.surface_container_low) ? Shell.Colors.surface_container_low : "#221a15"
                border.color: Shell.Theme.glassBorder
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                Column {
                    id: emojiColumn
                    width: parent.width - 16
                    height: parent.height - 16
                    x: 8
                    y: 8
                    spacing: 8

                    // Category Selector Pills Bar
                    ScrollView {
                        width: parent.width
                        height: 30
                        contentHeight: 30
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                        Row {
                            spacing: 6
                            height: 26

                            Repeater {
                                model: DynamicIslandService.emojiCategories
                                delegate: Rectangle {
                                    height: 24
                                    width: catText.implicitWidth + 15
                                    radius: 12
                                    color: DynamicIslandService.selectedCategory === modelData
                                        ? Shell.Theme.accentColor
                                        : (catMouse.containsMouse ? Shell.Theme.surfaceContainerHigh : "transparent")
                                    border.color: Shell.Theme.glassBorder
                                    border.width: 1

                                    Text {
                                        id: catText
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: Shell.Theme.scaled(11)
                                        font.weight: DynamicIslandService.selectedCategory === modelData ? Font.Bold : Font.Normal
                                        color: DynamicIslandService.selectedCategory === modelData
                                            ? ((Shell.Colors && Shell.Colors.on_primary) ? Shell.Colors.on_primary : "#ffffff")
                                            : Shell.Theme.text
                                    }

                                    MouseArea {
                                        id: catMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: DynamicIslandService.setCategory(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Emoji Grid Container
                    Item {
                        width: parent.width
                        height: parent.height - 38

                        GridView {
                            id: emojiGrid
                            anchors.fill: parent
                            cellWidth: 48
                            cellHeight: 48
                            clip: true
                            model: DynamicIslandService.displayedEmojis
                            currentIndex: DynamicIslandService.selectedIndex

                            visible: DynamicIslandService.displayedEmojis.length > 0

                            delegate: Rectangle {
                                id: emojiDelegate
                                width: 44
                                height: 44
                                radius: 8

                                required property var modelData
                                required property int index

                                readonly property bool isSelected: index === DynamicIslandService.selectedIndex

                                color: isSelected
                                    ? Shell.Theme.accentColor
                                    : (eMouse.containsMouse ? Shell.Theme.surfaceContainerHigh : "transparent")

                                Text {
                                    anchors.centerIn: parent
                                    text: (emojiDelegate.modelData && emojiDelegate.modelData.emoji) ? emojiDelegate.modelData.emoji : ""
                                    font.pixelSize: 26
                                }

                                MouseArea {
                                    id: eMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: DynamicIslandService.selectedIndex = index
                                    onClicked: DynamicIslandService.copyEmoji(emojiDelegate.modelData.emoji)
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: DynamicIslandService.displayedEmojis.length === 0
                            text: "No emojis found"
                            color: Shell.Theme.subtext0
                            font.pixelSize: Shell.Theme.scaled(13)
                        }
                    }
                }
            }
        }
    }
}
