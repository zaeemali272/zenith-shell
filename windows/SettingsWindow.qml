//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import "../" as Shell
import "../Settings" as Settings
import "./settings/tabs" as Tabs
import "../bar/Menu/components" as MenuComponents

Window {
    id: win
    width: 900
    height: 650
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    property alias currentIndex: view.currentIndex
    property int targetTab: 0

    Component.onCompleted: {
        if (targetTab > 0) {
            view.currentIndex = targetTab;
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: 24
        color: Shell.Theme.glassBackground
        border.color: Shell.Theme.glassBorder
        border.width: 1
        
        // Drag handle
        MouseArea {
            anchors.fill: parent
            property point lastMousePos
            onPressed: lastMousePos = Qt.point(mouse.x, mouse.y)
            onPositionChanged: {
                win.x += mouse.x - lastMousePos.x
                win.y += mouse.y - lastMousePos.y
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // --- SIDEBAR ---
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: "transparent"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 12
                    
                    Text {
                        text: "ZENITH"
                        font.pixelSize: 28
                        font.weight: Font.Black
                        color: Shell.Theme.text
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 20
                    }
                    
                    Repeater {
                        model: [
                            { name: "General", icon: "󰘚" },
                            { name: "Bar", icon: "󰇄" },
                            { name: "Appearance", icon: "󰏘" },
                            { name: "Workspace", icon: "󰨇" },
                            { name: "Battery", icon: "󰁹" },
                            { name: "Media", icon: "󰎆" },
                            { name: "Hyprland", icon: "󱓞" },
                            { name: "Displays", icon: "󰍹" }
                        ]
                        delegate: Rectangle {
                            id: tabBtn
                            Layout.fillWidth: true
                            height: 50
                            radius: 14
                            color: view.currentIndex === index ? Shell.Theme.accentColor : (tabMouse.containsMouse ? Shell.Theme.menuBackground2Hover : "transparent")
                            scale: tabMouse.pressed ? 0.96 : 1.0

                            Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }
                            Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                spacing: 15
                                Text {
                                    text: modelData.icon
                                    font.family: Shell.Theme.iconFont
                                    font.pixelSize: 20
                                    color: view.currentIndex === index ? Shell.Colors.on_primary : (tabMouse.containsMouse ? Shell.Theme.text : Shell.Theme.subtext1)
                                }
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 15
                                    font.weight: view.currentIndex === index ? Font.Bold : Font.Normal
                                    color: view.currentIndex === index ? Shell.Colors.on_primary : (tabMouse.containsMouse ? Shell.Theme.text : Shell.Theme.subtext1)
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: view.currentIndex = index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        id: closeBtn
                        text: "Close"
                        Layout.fillWidth: true
                        flat: true
                        scale: closeBtn.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: Shell.Theme.scaled(8)
                            Text {
                                text: "󰅖"
                                font.family: Shell.Theme.iconFont
                                font.pixelSize: Shell.Theme.scaled(14)
                                color: closeBtn.hovered ? Shell.Theme.powerRed : Shell.Theme.subtext1
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: "Close"
                                color: closeBtn.hovered ? Shell.Theme.powerRed : Shell.Theme.subtext1
                                font.bold: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        background: Rectangle {
                            radius: 12
                            color: parent.hovered ? Shell.Theme.menuBackground2Hover : "transparent"
                            border.color: Shell.Theme.glassBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }
                        }
                        onClicked: win.visible = false
                    }
                }
            }

            // Hairline separator
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Shell.Theme.glassBorder
            }
            
            // --- MAIN CONTENT AREA ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Flickable {
                    id: settingsFlickable
                    MenuComponents.FastWheel {}
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: (view.children && view.children[view.currentIndex] ? view.children[view.currentIndex].implicitHeight : 0) + 40

                    ScrollBar.vertical: ScrollBar {
                        parent: settingsFlickable
                        anchors.top: settingsFlickable.top
                        anchors.bottom: settingsFlickable.bottom
                        anchors.right: settingsFlickable.right
                        anchors.rightMargin: 2
                        policy: ScrollBar.AsNeeded
                        width: 4
                        contentItem: Rectangle {
                            radius: 999
                            color: Shell.Theme.accentColor
                            opacity: 0.7
                        }
                    }

                    StackLayout {
                        id: view
                        width: settingsFlickable.width - 14
                        currentIndex: 0
                        
                        onCurrentIndexChanged: settingsFlickable.contentY = 0

                        Tabs.GeneralTab { Layout.fillWidth: true }
                        Tabs.BarTab { Layout.fillWidth: true }
                        Tabs.AppearanceTab { Layout.fillWidth: true }
                        Tabs.WorkspaceTab { Layout.fillWidth: true }
                        Tabs.BatteryTab { Layout.fillWidth: true }
                        Tabs.MediaTab { Layout.fillWidth: true }
                        Tabs.HyprlandTab { Layout.fillWidth: true }
                        Tabs.DisplayTab { Layout.fillWidth: true }
                    }
                }
            }
        }
    }
}
