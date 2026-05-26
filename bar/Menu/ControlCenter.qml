import "../../services"
import "../../Settings"
import "./components"
import "../.."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) root.visible = false
    }

    property var parentWindow: null
    visible: false
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "controlcenter"

    implicitWidth: Theme.scaled(900)
    implicitHeight: Theme.scaled(650)

    // Centered positioning: top anchor
    anchors.top: true
    WlrLayershell.margins.top: Theme.barMarginTop + 4

    onVisibleChanged: {
        if (visible) {
            MenuService.register(root);
            CenterState.qsVisible = true;
            mainContent.forceActiveFocus();
            showAnim.restart();
        } else {
            MenuService.unregister(root);
            CenterState.qsVisible = false;
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainContent; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuint }
        NumberAnimation { target: mainContent; property: "scale"; from: 0.98; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: mainTranslate; property: "y"; from: -20; to: 0; duration: 500; easing.type: Easing.OutBack }
    }

    Rectangle {
        id: mainContent
        width: root.width
        height: root.height
        focus: true
        color: Theme.glassBackground
        radius: 32
        border.color: Theme.glassBorder
        border.width: 1
        opacity: 0
        scale: 0.98
        
        transform: Translate { id: mainTranslate; y: -20 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Rectangle { width: 4; height: 20; color: Theme.blue; radius: 2 }
                Text { 
                    text: "DASHBOARD"
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }

                // Tab Switcher
                RowLayout {
                    spacing: 5
                    Repeater {
                        model: ["Default", "Pomodoro"]
                        delegate: Rectangle {
                            width: 80; height: 30
                            radius: 8
                            color: CenterState.activeTab === modelData ? Theme.blue : "transparent"
                            border.color: Theme.glassBorder
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 9
                                color: CenterState.activeTab === modelData ? Theme.base : Theme.text
                            }
                            MouseArea { anchors.fill: parent; onClicked: CenterState.activeTab = modelData }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Caffeine Toggle
                Rectangle {
                    id: caffeineRect
                    width: 32; height: 32
                    radius: 8
                    color: CaffeineService.active ? Theme.blue : (caffeineMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                    border.color: CaffeineService.active ? Theme.blue : Theme.glassBorder
                    scale: caffeineMouse.pressed ? 0.9 : 1.0
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󱄅"
                        font.family: "Font Awesome 6 Free"
                        font.weight: Font.Black
                        font.pixelSize: 16
                        color: CaffeineService.active ? Theme.base : (caffeineMouse.containsMouse ? Theme.text : Theme.subtext1)
                    }
                    MouseArea { 
                        id: caffeineMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: CaffeineService.toggle() 
                    }
                }
            }

            // --- CONTENT AREA ---
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: CenterState.activeTab === "Pomodoro" ? 1 : 0

                // Default Tab
                GridLayout {
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 20

                    // 1. Notifications
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.rowSpan: 2
                        color: Qt.rgba(0,0,0,0.2); radius: 24; border.color: Theme.glassBorder; clip: true
                        
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 15; spacing: 10
                            
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: "󰂚"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: 14 }
                                Text { text: "NOTIFICATIONS"; color: Theme.subtext1; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1 }
                                Rectangle {
                                       width: Theme.scaled(22); height: Theme.scaled(22); radius: Theme.scaled(6)
                                       color: Theme.surface1
                                       Label {
                                           anchors.centerIn: parent
                                           text: NotificationService.notifications.count
                                           color: Theme.blue
                                           font.pixelSize: Theme.scaled(11); font.bold: true
                                       }
                                   }

                                Item { Layout.fillWidth: true }
                                
                            Button {
                                id: fullscreenBtn
                                flat: true
                                padding: Theme.scaled(4)
                                contentItem: RowLayout {
                                    spacing: 4
                                    Text {
                                        text: GeneralSettings.fullscreenNotification ? "󰊓" : "󰊔"
                                        font.family: Theme.iconFont
                                        color: GeneralSettings.fullscreenNotification ? Theme.blue : Theme.surface2
                                        font.pixelSize: 12
                                    }
                                    Text { text: "NOTIFY"; font.pixelSize: 8; font.weight: Font.Black; color: Theme.subtext1 }
                                }
                                background: Rectangle { color: fullscreenBtn.hovered ? Theme.surface0 : "transparent"; radius: 6 }
                                onClicked: GeneralSettings.fullscreenNotification = !GeneralSettings.fullscreenNotification
                            }
                            Button {
                                id: osdFullscreenBtn
                                flat: true
                                padding: Theme.scaled(4)
                                contentItem: RowLayout {
                                    spacing: 4
                                    Text {
                                        text: GeneralSettings.fullscreenOSD ? "󰊓" : "󰊔"
                                        font.family: Theme.iconFont
                                        color: GeneralSettings.fullscreenOSD ? Theme.blue : Theme.surface2
                                        font.pixelSize: 12
                                    }
                                    Text { text: "OSD"; font.pixelSize: 8; font.weight: Font.Black; color: Theme.subtext1 }
                                }
                                background: Rectangle { color: osdFullscreenBtn.hovered ? Theme.surface0 : "transparent"; radius: 6 }
                                onClicked: GeneralSettings.fullscreenOSD = !GeneralSettings.fullscreenOSD
                            }
                                Button {
                                    id: clearBtn
                                    flat: true
                                    padding: Theme.scaled(4)
                                    contentItem: Text { text: "󰃢"; font.family: Theme.iconFont; color: Theme.subtext1; font.pixelSize: 14 }
                                    background: Rectangle { color: clearBtn.hovered ? Theme.surface0 : "transparent"; radius: 6 }
                                    onClicked: NotificationService.clearAll()
                                }
                            }
                            ScrollView {
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                NotificationList {
                                    visible: GeneralSettings.enableNotifications
                                    Layout.fillWidth: true; height: parent.height 
                                }
                            }
                        }
                    }

                    // 2. Calendar
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Qt.rgba(0,0,0,0.2); radius: 24; border.color: Theme.glassBorder
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 15
                            RowLayout {
                                spacing: 8
                                Text { text: "󰃭"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: 14 }
                                Text { text: "CALENDAR"; color: Theme.subtext1; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1 }
                            }
                            CalendarWidget { Layout.fillWidth: true; Layout.fillHeight: true }
                        }
                    }

                    // 3. Weather
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Qt.rgba(0,0,0,0.2); radius: 24; border.color: Theme.glassBorder
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 15
                            RowLayout {
                                spacing: 8
                                Text { text: "󰖐"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: 14 }
                                Text { text: "WEATHER"; color: Theme.subtext1; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1 }
                            }
                            WeatherWidget {
                                visible: GeneralSettings.enableWeather
                                Layout.fillWidth: true; Layout.fillHeight: true
                            }
                        }
                    }
                }

                // Pomodoro Tab
                PomodoroContent {
                    Layout.fillWidth: true; Layout.fillHeight: true
                }
            }
        }
    }
}
