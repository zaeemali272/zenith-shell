import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import "./" as Shell
import "./Settings" as Settings
import "./windows/settings/tabs" as Tabs

Window {
    id: win
    width: 900
    height: 650
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window
    
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
                color: Qt.rgba(0, 0, 0, 0.2)
                radius: 24
                
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
                            { name: "User", icon: "󰀂" }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 50
                            radius: 14
                            color: view.currentIndex === index ? Shell.Theme.surface1 : "transparent"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                spacing: 15
                                Text {
                                    text: modelData.icon
                                    font.family: Shell.Theme.iconFont
                                    font.pixelSize: 20
                                    color: view.currentIndex === index ? Shell.Theme.blue : Shell.Theme.subtext1
                                }
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 15
                                    font.weight: view.currentIndex === index ? Font.Bold : Font.Normal
                                    color: view.currentIndex === index ? Shell.Theme.text : Shell.Theme.subtext1
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: view.currentIndex = index
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    Button {
                        text: "Save & Apply"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 45
                        contentItem: Text {
                            text: parent.text
                            color: Shell.Theme.base
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 12
                            color: Shell.Theme.blue
                        }
                    }

                    Button {
                        text: "Close"
                        Layout.fillWidth: true
                        flat: true
                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? "white" : Shell.Theme.subtext1
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: 12
                            color: parent.hovered ? Shell.Theme.red : "transparent"
                            border.color: parent.hovered ? "transparent" : Shell.Theme.surface1
                        }
                        onClicked: win.visible = false
                    }
                }
            }
            
            // --- MAIN CONTENT AREA ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                StackLayout {
                    id: view
                    anchors.fill: parent
                    anchors.margins: 10
                    currentIndex: 0
                    
                    Tabs.GeneralTab { }
                    Tabs.BarTab { }
                    Tabs.AppearanceTab { }
                    Tabs.WorkspaceTab { }
                    Tabs.BatteryTab { }
                    Tabs.MediaTab { }
                    Tabs.HyprlandTab { }
                    Tabs.UserSettingsTab { }
                }
            }
        }
    }
}
