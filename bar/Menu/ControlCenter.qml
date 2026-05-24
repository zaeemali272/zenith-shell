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

PopupWindow {
    id: root
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) root.visible = false
    }

    property var parentWindow: null
    visible: false
    color: "transparent"
    grabFocus: false

    implicitWidth: Theme.scaled(900)
    implicitHeight: Theme.scaled(650)

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

    anchor.window: parentWindow
    anchor.edges: Edges.Top
    
    anchor.rect: {
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;
        let targetX = (barWidth - root.implicitWidth) / 2;
        return Qt.rect(Math.max(10, Math.min(barWidth - root.implicitWidth - 10, targetX)), barHeight + 8, 0, 0);
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

            // --- MINIMAL HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                Rectangle { width: 4; height: 20; color: Theme.blue; radius: 2 }
                Text { 
                    text: "SYSTEM DASHBOARD"
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }
                Item { Layout.fillWidth: true }
                Text { 
                    text: Qt.formatDateTime(new Date(), "ddd, MMM d")
                    color: Theme.subtext1
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            // --- 2-COLUMN RESPONSIVE GRID ---
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                columnSpacing: 20
                rowSpacing: 20

                // 1. Notifications
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rowSpan: 2
                    color: Qt.rgba(0,0,0,0.2)
                    radius: 24
                    border.color: Theme.glassBorder
                    clip: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        // Header with Counter and Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
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
                                contentItem: Text {
                                    text: "󰃢" // Trash Bin Icon
                                    font.family: Theme.iconFont
                                    color: clearBtn.hovered ? Theme.powerRed : Theme.subtext1
                                    font.pixelSize: 14
                                }
                                background: Rectangle { color: clearBtn.hovered ? Theme.surface0 : "transparent"; radius: 6 }
                                onClicked: NotificationService.clearAll()
                            }
                        }

                        // Scrollable List
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth
                            
                            NotificationList {
                                visible: GeneralSettings.enableNotifications
                                Layout.fillWidth: true
                                // Explicitly set height to fill the ScrollView
                                height: parent.height 
                            }
                        }
                    }
                }

                // 2. Calendar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0,0,0,0.2)
                    radius: 24
                    border.color: Theme.glassBorder
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        RowLayout {
                            spacing: 8
                            Text { text: "󰃭"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: 14 }
                            Text { text: "CALENDAR"; color: Theme.subtext1; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1 }
                        }
                        CalendarWidget {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                // 3. Weather
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0,0,0,0.2)
                    radius: 24
                    border.color: Theme.glassBorder
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        RowLayout {
                            spacing: 8
                            Text { text: "󰖐"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: 14 }
                            Text { text: "WEATHER"; color: Theme.subtext1; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1 }
                        }
                        WeatherWidget {
                            visible: GeneralSettings.enableWeather
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
