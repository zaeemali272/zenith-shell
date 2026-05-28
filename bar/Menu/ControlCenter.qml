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

PanelWindow {
    id: root
    
    property var parentWindow: null
    visible: false
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "controlcenter"

    // Fill screen width to enable perfect centering of mainContent
    anchors {
        top: true
        left: true
        right: true
    }
    
    // Total height of the window container
    implicitHeight: Math.min(Theme.scaled(700), (screen ? screen.height : Theme.screenHeight))

    onVisibleChanged: {
        if (visible) {
            MenuService.register(root);
            CenterState.qsVisible = true;
            
            // Reset scroll for all stack items that support it
            for (let i = 0; i < contentStack.count; i++) {
                let item = contentStack.itemAt(i);
                if (item && typeof item.resetScroll === "function") {
                    item.resetScroll();
                }
            }
            
            // Reset NotificationList specifically as it's nested in the Default tab
            if (notificationList) notificationList.resetScroll();
            
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

    // --- DISMISS ON OUTER CLICK ---
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: CenterState.close()
    }

    Rectangle {
        id: mainContent
        focus: true
        Keys.onPressed: (event) => {
            console.log("ControlCenter: Main key pressed: " + event.key);
            if (event.key === Qt.Key_Escape) {
                root.visible = false;
            } else {
                // Accessing contentStack via its ID
                let currentContent = contentStack.itemAt(contentStack.currentIndex);
                if (currentContent && typeof currentContent.handleKeys === 'function') {
                    currentContent.handleKeys(event);
                }
            }
        }
        
        // Centered relative to the screen width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop + 4

        width: Math.min(Theme.scaled(900), (screen ? screen.width : Theme.screenWidth) - Theme.scaled(20))
        height: Math.min(Theme.scaled(650), (screen ? screen.height : Theme.screenHeight) - Theme.barHeight - Theme.scaled(20))
        
        color: Theme.glassBackground
        radius: Theme.scaled(32)
        border.color: Theme.glassBorder
        border.width: 1
        opacity: 0
        scale: 0.98
        
        transform: Translate { id: mainTranslate; y: -20 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(25)
            spacing: Theme.scaled(20)

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(15)
                
                Rectangle { width: Theme.scaled(4); height: Theme.scaled(20); color: Theme.blue; radius: 2 }
                Text { 
                    text: "DASHBOARD"
                    color: Theme.text
                    font.pixelSize: Theme.scaled(12)
                    font.weight: Font.Black
                    font.letterSpacing: 2
                    visible: !Theme.isSmallScreen
                }

                // Tab Switcher
                RowLayout {
                    spacing: Theme.scaled(5)
                    Repeater {
                        model: ["Default", "Pomodoro", "Wallpaper", "Keybinds"]
                        delegate: Rectangle {
                            id: tabRect
                            width: Theme.scaled(80); height: Theme.scaled(30)
                            radius: Theme.scaled(8)
                            color: CenterState.activeTab === modelData ? Theme.accentColor : (tabMouse.containsMouse ? Theme.surface1 : "transparent")
                            border.color: Theme.glassBorder
                            scale: tabMouse.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Theme.scaled(9)
                                color: CenterState.activeTab === modelData ? Theme.base : (tabMouse.containsMouse ? Theme.text : Theme.subtext1)
                            }
                            MouseArea { 
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: CenterState.activeTab = modelData 
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Caffeine Toggle
                Rectangle {
                    id: caffeineRect
                    width: Theme.scaled(32); height: Theme.scaled(32)
                    radius: Theme.scaled(8)
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
                        font.pixelSize: Theme.scaled(16)
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
                id: contentStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ["Default", "Pomodoro", "Wallpaper", "Keybinds"].indexOf(CenterState.activeTab)

                // Default Tab
                GridLayout {
                    columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
                    columnSpacing: Theme.scaled(20)
                    rowSpacing: Theme.scaled(20)

                    // 1. Notifications
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.rowSpan: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
                        color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(24); border.color: Theme.glassBorder; clip: true
                        
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Theme.scaled(15); spacing: Theme.scaled(10)
                            
                            RowLayout {
                                Layout.fillWidth: true; spacing: Theme.scaled(8)
                                Text { text: "󰂚"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: Theme.scaled(14) }
                                Text { text: "NOTIFICATIONS"; color: Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; font.letterSpacing: 1 }
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
                                visible: !Theme.isSmallScreen
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
                                visible: !Theme.isSmallScreen
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
                                    contentItem: Text { text: "󰃢"; font.family: Theme.iconFont; color: Theme.subtext1; font.pixelSize: Theme.scaled(14) }
                                    background: Rectangle { color: clearBtn.hovered ? Theme.surface0 : "transparent"; radius: 6 }
                                    onClicked: NotificationService.clearAll()
                                }
                            }
                            ScrollView {
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                NotificationList {
                                    id: notificationList
                                    visible: GeneralSettings.enableNotifications
                                    Layout.fillWidth: true; height: parent.height 
                                }
                            }
                        }
                    }

                    // 2. Calendar
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        visible: !Theme.isSmallScreen || !Theme.isPortrait
                        color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(24); border.color: Theme.glassBorder
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Theme.scaled(15)
                            RowLayout {
                                spacing: Theme.scaled(8)
                                Text { text: "󰃭"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: Theme.scaled(14) }
                                Text { text: "CALENDAR"; color: Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; font.letterSpacing: 1 }
                            }
                            CalendarWidget { Layout.fillWidth: true; Layout.fillHeight: true }
                        }
                    }

                    // 3. Weather
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        visible: !Theme.isSmallScreen || !Theme.isPortrait
                        color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(24); border.color: Theme.glassBorder
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Theme.scaled(15)
                            RowLayout {
                                spacing: Theme.scaled(8)
                                Text { text: "󰖐"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: Theme.scaled(14) }
                                Text { text: "WEATHER"; color: Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; font.letterSpacing: 1 }
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

                // Wallpaper Tab
                WallpaperContent {
                    id: wallpaperContent
                    Layout.fillWidth: true; Layout.fillHeight: true
                }

                // Keybinds Tab
                KeybindsContent {
                    Layout.fillWidth: true; Layout.fillHeight: true
                }
            }
        }
    }
    // Forward keys when Wallpaper tab is active
    Connections {
        target: CenterState
        function onActiveTabChanged() {
            if (CenterState.activeTab === "Wallpaper") {
                mainContent.Keys.forwardTo = [wallpaperContent];
            } else {
                mainContent.Keys.forwardTo = [];
            }
        }
    }

    function updateFocusForTab(tab) {
        if (tab === "Wallpaper") {
            console.log("ControlCenter: Attempting to focus wallpaperContent.");
            let success = wallpaperContent.forceActiveFocus();
            console.log("ControlCenter: wallpaperContent focus success: " + success);
        }
    }
}


