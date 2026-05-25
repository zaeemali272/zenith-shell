import "../.."
import "../../services"
import "../../Settings"
import "./components"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "./components"

PopupWindow {
    id: root

    property var parentWindow: null
    visible: false
    color: "transparent"

    grabFocus: false

    implicitWidth: Theme.scaled(650) 
    implicitHeight: Theme.scaled(600)

    onVisibleChanged: {
        if (visible) {
            MenuService.register(root);
            QuickSettingsService.qsVisible = true;
            mainContent.forceActiveFocus();
            showAnim.restart();
        } else {
            MenuService.unregister(root);
            QuickSettingsService.qsVisible = false;
            mainContent.opacity = 0;
            mainContent.scale = 0.95;
            mainTranslate.y = 30;
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainContent; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuint }
        NumberAnimation { target: mainContent; property: "scale"; from: 0.95; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: mainTranslate; property: "y"; from: 30; to: 0; duration: 500; easing.type: Easing.OutBack }
    }

    // Positioning
    anchor.window: parentWindow
    anchor.edges: Edges.Bottom | Edges.Right 
    anchor.gravity: Edges.Bottom | Edges.Right
    
    anchor.rect: {
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;
        return Qt.rect(barWidth - implicitWidth - 10, barHeight + 10, 0, 0);
    }

    Rectangle {
        id: mainContent
        anchors.fill: parent
        focus: true
        color: Theme.glassBackground
        radius: Theme.menuRadius
        border.color: Theme.glassBorder
        border.width: 1
        opacity: 0
        scale: 0.95
        
        transform: Translate { id: mainTranslate; y: 30 }

        // Glow Layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 2
            anchors.margins: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.menuPadding
            spacing: Theme.menuSpacing

            // --- MODERN TAB DASHBOARD ---
            Rectangle {
                Layout.fillWidth: true
                height: 70
                color: Qt.rgba(0,0,0,0.3)
                radius: 20
                border.color: Theme.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Repeater {
                        model: [
                            { id: "network", icon: "󰤨", title: "NETWORK" },
                            { id: "bluetooth", icon: "󰂯", title: "BLUETOOTH" },
                            { id: "volume", icon: "󰕾", title: "AUDIO" },
                            { id: "powerprofile", icon: "󰍛", title: "PROFILE" },
                            { id: "resources", icon: "󰘚", title: "SYSTEM" },
                            { id: "battery", icon: "󰁹", title: "POWER" },
                            { id: "power", icon: "󰐥", title: "SESSION" }
                        ]

                        delegate: Rectangle {
                            id: tabRect
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: QuickSettingsService.activeTab === modelData.id ? Theme.accentColor : (tabMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                            
                            scale: tabMouse.pressed ? 0.92 : (tabMouse.containsMouse ? 1.05 : 1.0)
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Theme.elasticEasing } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFont; font.pixelSize: 20
                                    color: QuickSettingsService.activeTab === modelData.id ? Theme.base : (tabMouse.containsMouse ? Theme.text : Theme.subtext1)
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.title
                                    font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 1
                                    color: QuickSettingsService.activeTab === modelData.id ? Theme.base : (tabMouse.containsMouse ? Theme.text : Theme.surface2)
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: QuickSettingsService.activeTab = modelData.id
                            }
                        }
                    }
                }
            }

            // --- CONTENT AREA WITH SCROLLING ---
            ScrollView {
                id: scrollArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                contentHeight: contentStack.height

                ScrollBar.vertical: ScrollBar {
                    parent: scrollArea
                    anchors.top: scrollArea.top
                    anchors.bottom: scrollArea.bottom
                    anchors.right: scrollArea.right
                    policy: ScrollBar.AsNeeded
                    width: 4
                    contentItem: Rectangle { radius: 2; color: Theme.accentColor; opacity: 0.3 }
                }

                StackLayout {
                    id: contentStack
                    width: scrollArea.availableWidth
                    // Calculate height dynamically based on the current child
                    height: children[currentIndex] ? children[currentIndex].implicitHeight : 500
                    currentIndex: ["network", "bluetooth", "volume", "powerprofile", "resources", "battery", "power"].indexOf(QuickSettingsService.activeTab)

                    onCurrentIndexChanged: fadeAnim.restart()

                    NumberAnimation { id: fadeAnim; target: contentStack; property: "opacity"; from: 0; to: 1; duration: 300 }

                    WifiContent { }
                    BluetoothContent { }
                    VolumeContent { }
                    PowerProfileContent { }
                    ResourcesContent { }
                    BatteryContent { }
                    PowerContent { }
                }            }
        }
    }
}
