import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../.."
import "../../services"
import "../../Settings"
import "./components"

PanelWindow {
    id: root
    property var parentWindow: null
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "controlcenter"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: mainContent
    }

    Component.onDestruction: MenuService.unregister(root)

    onVisibleChanged: {
        Variables.controlCenterOpen = visible;
        if (visible) {
            MenuService.register(root);
            CenterState.qsVisible = true;
            Qt.callLater(() => {
                mainContent.forceActiveFocus();
                updateFocusForTab(CenterState.activeTab);
            });
            showAnim.restart();
        } else {
            MenuService.unregister(root);
            CenterState.qsVisible = false;
            mainContent.opacity = 0;
            mainContent.scale = 0.94;
            mainTranslate.y = -6;
        }
    }


    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainContent; property: "opacity"; from: 0; to: 1; duration: Theme.animFast; easing.type: Theme.animEasing }
        NumberAnimation { target: mainContent; property: "scale"; from: 0.94; to: 1.0; duration: Theme.animFast; easing.type: Theme.animEasing }
        NumberAnimation { target: mainTranslate; property: "y"; from: -6; to: 0; duration: Theme.animFast; easing.type: Theme.animEasing }
    }

    // Outer clicks are dismissed by DismissOverlay, a separate full-screen
    // layer window that calls MenuService.closeAll().
    //
    // There used to be a "dismiss on outer click" MouseArea filling this window
    // at z: -1. It could never do that job: `mask: Region { item: ... }` above
    // means the compositor only delivers input that lands inside the card, so
    // the only clicks that MouseArea ever received were *inside* the menu. The
    // card is a plain Rectangle and does not accept mouse events, so any click
    // on empty card area -- padding, gaps between widgets, the tab strip
    // background -- fell straight through to it and closed the menu.

    // Masterwork Material 3 Floating ControlCenter Card (Centered directly below bar)
    Rectangle {
        id: mainContent
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.barMarginTop + Theme.scaled(4)

        // Masterwork Adaptive Sizing
        width: Math.min(Theme.scaled(840), (screen ? screen.width : Theme.screenWidth) - Theme.scaled(24))
        height: Math.min(Theme.scaled(680), (screen ? screen.height : Theme.screenHeight) - Theme.barHeight - Theme.scaled(20))

        color: Theme.glassBackground
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 2
        clip: true

        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                CenterState.close();
            } else {
                let currentContent = contentStack.children[contentStack.currentIndex];
                if (currentContent && typeof currentContent.handleKeys === 'function') {
                    currentContent.handleKeys(event);
                }
            }
        }
        
        opacity: 0
        scale: 0.94
        transformOrigin: Item.Top
        
        transform: Translate { id: mainTranslate; y: -6 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(18)
            spacing: Theme.scaled(14)

            // --- HEADER WITH BUBBLE SWITCHER & CONTROLS ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(12)
                
                Rectangle {
                    width: Theme.scaled(4)
                    height: Theme.scaled(24)
                    color: Theme.accentColor
                    radius: 999
                }

                Text { 
                    text: "DASHBOARD"
                    color: "#ffffff"
                    font.pixelSize: Theme.scaled(12.5)
                    font.weight: Font.Black
                    font.letterSpacing: 2
                    visible: !Theme.isSmallScreen
                }

                // Bubble Tab Switcher Capsule
                Rectangle {
                    height: Theme.scaled(38)
                    implicitWidth: tabRow.implicitWidth + Theme.scaled(8)
                    radius: 999
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: 0

                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: Theme.scaled(4)

                        Repeater {
                            model: ["Default", "Pomodoro", "Mail", "Wallpaper"]
                            delegate: Rectangle {
                                id: tabRect
                                width: Math.max(Theme.scaled(82), tabText.implicitWidth + Theme.scaled(18))
                                height: Theme.scaled(30)
                                radius: 999
                                color: CenterState.activeTab === modelData ? Theme.accentColor : (tabMouse.containsMouse ? Qt.rgba(255,255,255,0.12) : "transparent")
                                scale: tabMouse.pressed ? 0.94 : (tabMouse.containsMouse ? 1.03 : 1.0)
                                
                                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Text {
                                    id: tabText
                                    anchors.centerIn: parent
                                    text: root.tabLabel(modelData)
                                    font.pixelSize: Theme.scaled(11)
                                    font.weight: Font.Bold
                                    color: CenterState.activeTab === modelData ? Colors.on_primary : "#ffffff"
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
                }
                
                Item { Layout.fillWidth: true }
                
                // --- MEDIA PLAYER AUTO-FOCUS BUBBLE TOGGLE (Positioned before Caffeine) ---
                Rectangle {
                    id: focusRect
                    width: Theme.scaled(38); height: Theme.scaled(38)
                    radius: 999
                    color: MediaPlayerService.mediaFocus ? Theme.accentColor : (focusMouse.containsMouse ? Qt.rgba(255,255,255,0.12) : Qt.rgba(0,0,0,0.3))
                    border.width: 0
                    scale: focusMouse.pressed ? 0.94 : (focusMouse.containsMouse ? 1.05 : 1.0)
                    
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    Text {
                        anchors.centerIn: parent
                        text: MediaPlayerService.mediaFocus ? "󰎆" : "󰎇"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(17)
                        color: MediaPlayerService.mediaFocus ? Colors.on_primary : "#ffffff"
                    }
                    MouseArea { 
                        id: focusMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: MediaPlayerService.mediaFocus = !MediaPlayerService.mediaFocus
                    }
                }

                // --- CAFFEINE BUBBLE TOGGLE ---
                Rectangle {
                    id: caffeineRect
                    width: Theme.scaled(38); height: Theme.scaled(38)
                    radius: 999
                    color: CaffeineService.active ? Theme.accentColor : (caffeineMouse.containsMouse ? Qt.rgba(255,255,255,0.12) : Qt.rgba(0,0,0,0.3))
                    border.width: 0
                    scale: caffeineMouse.pressed ? 0.94 : (caffeineMouse.containsMouse ? 1.05 : 1.0)
                    
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    Text {
                        anchors.centerIn: parent
                        text: CaffeineService.active ? "󰅶" : "󰛊"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(17)
                        color: CaffeineService.active ? Colors.on_primary : "#ffffff"
                    }
                    MouseArea { 
                        id: caffeineMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: CaffeineService.toggle() 
                    }
                }
            }

            ParallelAnimation {
                id: fadeAnim
                NumberAnimation { target: contentStack; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
                NumberAnimation { target: contentTranslate; property: "y"; from: 8; to: 0; duration: 250; easing.type: Easing.OutQuad }
            }

            // --- CONTENT AREA ---
            StackLayout {
                id: contentStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ["Default", "Pomodoro", "Mail", "Wallpaper"].indexOf(CenterState.activeTab)
                transform: Translate { id: contentTranslate }
                onCurrentIndexChanged: fadeAnim.restart()

                // Default Tab
                GridLayout {
                    columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
                    columnSpacing: Theme.scaled(14)
                    rowSpacing: Theme.scaled(14)

                    // LEFT COLUMN: Notifications (Top) + Media Player (Bottom)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.rowSpan: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
                        spacing: Theme.scaled(12)

                        // 1. Notifications Bubble Card
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            color: Qt.rgba(0,0,0,0.3); radius: Theme.cardRadius; border.color: Theme.glassBorder; border.width: 1; clip: true
                            
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: Theme.scaled(14); spacing: Theme.scaled(8)
                                
                                RowLayout {
                                    Layout.fillWidth: true; spacing: Theme.scaled(8)
                                    Text { text: "󰂚"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: Theme.scaled(16) }
                                    Text { text: "NOTIFICATIONS"; color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1 }
                                    Rectangle {
                                        width: Theme.scaled(22); height: Theme.scaled(22); radius: 999
                                        color: Theme.surface1
                                        Label {
                                            anchors.centerIn: parent
                                            text: NotificationService.notifications.count
                                            color: Theme.accentColor
                                            font.pixelSize: Theme.scaled(11); font.bold: true
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                    
                                    Button {
                                        id: fullscreenBtn
                                        flat: true
                                        padding: Theme.scaled(3)
                                        visible: !Theme.isSmallScreen
                                        contentItem: RowLayout {
                                            spacing: 4
                                            Text {
                                                text: NotificationSettings.fullscreenNotification ? "󰊓" : "󰊔"
                                                font.family: Theme.iconFont
                                                color: NotificationSettings.fullscreenNotification ? Theme.accentColor : "#ffffff"
                                                font.pixelSize: 13
                                            }
                                            Text { text: "NOTIFY"; font.pixelSize: 9; font.weight: Font.Black; color: "#ffffff" }
                                        }
                                        background: Rectangle { color: fullscreenBtn.hovered ? Qt.rgba(255,255,255,0.1) : "transparent"; radius: 999 }
                                        onClicked: NotificationSettings.fullscreenNotification = !NotificationSettings.fullscreenNotification
                                    }
                                    Button {
                                        id: osdFullscreenBtn
                                        flat: true
                                        padding: Theme.scaled(3)
                                        visible: !Theme.isSmallScreen
                                        contentItem: RowLayout {
                                            spacing: 4
                                            Text {
                                                text: NotificationSettings.fullscreenOSD ? "󰊓" : "󰊔"
                                                font.family: Theme.iconFont
                                                color: NotificationSettings.fullscreenOSD ? Theme.accentColor : "#ffffff"
                                                font.pixelSize: 13
                                            }
                                            Text { text: "OSD"; font.pixelSize: 9; font.weight: Font.Black; color: "#ffffff" }
                                        }
                                        background: Rectangle { color: osdFullscreenBtn.hovered ? Qt.rgba(255,255,255,0.1) : "transparent"; radius: 999 }
                                        onClicked: NotificationSettings.fullscreenOSD = !NotificationSettings.fullscreenOSD
                                    }
                                    Button {
                                        id: clearBtn
                                        flat: true
                                        padding: Theme.scaled(3)
                                        contentItem: Text { text: "󰃢"; font.family: Theme.iconFont; color: "#ffffff"; font.pixelSize: Theme.scaled(15) }
                                        background: Rectangle { color: clearBtn.hovered ? Qt.rgba(255,255,255,0.1) : "transparent"; radius: 999 }
                                        onClicked: NotificationService.clearAll()
                                    }
                                }
                                ScrollView {
                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                    NotificationList {
                                        id: notificationList
                                        visible: NotificationSettings.enableNotifications
                                        Layout.fillWidth: true; height: parent.height 
                                    }
                                }
                            }
                        }

                        // 2. Media Player Bubble Card (Positioned directly underneath notifications with increased height)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Theme.scaled(170)
                            color: Qt.rgba(0,0,0,0.3); radius: Theme.cardRadius; border.color: Theme.glassBorder; border.width: 1; clip: true

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: Theme.scaled(14); spacing: Theme.scaled(8)

                                RowLayout {
                                    Layout.fillWidth: true; spacing: Theme.scaled(8)
                                    Text { text: "󰎆"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: Theme.scaled(16) }
                                    Text { text: "MEDIA PLAYER"; color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1 }

                                    Item { Layout.fillWidth: true }
                                }

                                MprisPlayer {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    active: CenterState.qsVisible
                                }
                            }
                        }
                    }

                    // RIGHT COLUMN: Calendar (Top) + Weather (Bottom)
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        visible: !Theme.isSmallScreen || !Theme.isPortrait
                        color: Qt.rgba(0,0,0,0.3); radius: Theme.cardRadius; border.color: Theme.glassBorder; border.width: 1; clip: true
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Theme.scaled(14)
                            RowLayout {
                                spacing: Theme.scaled(8)
                                Text { text: "󰃭"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: Theme.scaled(16) }
                                Text { text: "CALENDAR"; color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1 }
                            }
                            CalendarWidget { Layout.fillWidth: true; Layout.fillHeight: true }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        visible: (!Theme.isSmallScreen || !Theme.isPortrait) && WidgetSettings.enableWeather
                        color: Qt.rgba(0,0,0,0.3); radius: Theme.cardRadius; border.color: Theme.glassBorder; border.width: 1; clip: true
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Theme.scaled(14)
                            RowLayout {
                                spacing: Theme.scaled(8)
                                Text { text: "󰖐"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: Theme.scaled(16) }
                                Text { text: "WEATHER"; color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1 }
                            }
                            WeatherWidget {
                                Layout.fillWidth: true; Layout.fillHeight: true
                            }
                        }
                    }
                }

                // Pomodoro Tab
                PomodoroContent {
                    Layout.fillWidth: true; Layout.fillHeight: true
                }

                // Mail Tab
                MailContent {
                    Layout.fillWidth: true; Layout.fillHeight: true
                }

                // Wallpaper Tab
                WallpaperContent {
                    id: wallpaperContent
                    Layout.fillWidth: true; Layout.fillHeight: true
                }
            }
        }
    }

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

    // The tab strings double as identifiers, so this maps identifier -> label
    // rather than renaming them. "Default" is meaningless to a reader; the tab
    // shows the overview cards.
    function tabLabel(tabId) {
        // "Pomodoro" names one technique, but the tab holds a todo list and a
        // timer; "Focus" covers both.
        if (tabId === "Default") return "Overview";
        if (tabId === "Pomodoro") return "Focus";
        return tabId;
    }

    function updateFocusForTab(tab) {
        if (tab === "Wallpaper") {
            wallpaperContent.forceActiveFocus();
        }
    }
}
