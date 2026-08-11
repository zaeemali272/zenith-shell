import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../Settings"

RowLayout {
    id: root
    property var controlCenterMenuRef: null

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    spacing: Theme.pillSpacing

    // --- PRODUCTIVITY / POMODORO COUNTDOWN WIDGET ---
    Rectangle {
        visible: (ProductivityService.running || ProductivityService.isBeeping) && !DynamicIslandService.active
        width: timerText.implicitWidth + Theme.scaled(22)
        height: Theme.pillHeight
        radius: height / 2
        color: ProductivityService.isBeeping ? Theme.powerRed : (ProductivityService.running ? Theme.accentColor : Theme.surfaceContainerHigh)
        border.color: Theme.glassBorder
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        scale: timerMouse.pressed ? 0.95 : (timerMouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        
        SequentialAnimation on opacity {
            running: ProductivityService.isBeeping
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.4; duration: 400 }
            NumberAnimation { from: 0.4; to: 1.0; duration: 400 }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Theme.scaled(6)

            Text {
                text: ProductivityService.isBeeping ? "󰂚" : "󰔛"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(13)
                color: (ProductivityService.running || ProductivityService.isBeeping) ? Colors.on_primary : Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: timerText
                text: {
                    if (ProductivityService.isBeeping) return "DONE";
                    let m = Math.floor(ProductivityService.remaining / 60);
                    let s = ProductivityService.remaining % 60;
                    return m + ":" + s.toString().padStart(2, '0');
                }
                font.weight: Font.Black
                font.pixelSize: Theme.scaled(11)
                color: (ProductivityService.running || ProductivityService.isBeeping) ? Colors.on_primary : Theme.text
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: timerMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (ProductivityService.isBeeping) {
                    ProductivityService.dismissAlarm();
                } else {
                    CenterState.toggle("Pomodoro");
                }
            }
        }
    }

    // --- MASTERWORK JOINED CENTER PILL / DYNAMIC ISLAND ---
    Rectangle {
        id: centerPill
        radius: height / 2
        color: DynamicIslandService.active
            ? Theme.surfaceContainerHigh
            : (pillMouse.containsMouse ? Theme.pillHoverColor : Theme.pillColor)
        border.color: DynamicIslandService.active ? Theme.accentColor : Theme.glassBorder
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        Layout.preferredHeight: Theme.pillHeight
        Layout.alignment: Qt.AlignVCenter
        width: DynamicIslandService.active
            ? Theme.scaled(480)
            : (centerContent.implicitWidth + Theme.pillPadding + Theme.extraPillPadding)
        implicitWidth: width
        clip: true

        scale: DynamicIslandService.active ? 1.0 : (pillMouse.pressed ? 0.95 : (pillMouse.containsMouse ? 1.04 : 1.0))

        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 280 } }
        Behavior on border.color { ColorAnimation { duration: 280 } }

        // --- DEFAULT CENTER CONTENT (Clock/Media/Weather) ---
        RowLayout {
            id: centerContent
            anchors.centerIn: parent
            spacing: Theme.pillGap
            visible: !DynamicIslandService.active

            // --- MEDIA / WEATHER SECTION ---
            RowLayout {
                spacing: Theme.pillGap
                visible: WidgetSettings.enableMedia && !Theme.isSmallScreen

                // Active Playing Media Section
                RowLayout {
                    id: mediaSection
                    spacing: Theme.scaled(6)
                    visible: MediaPlayerService.trackedPlayer && MediaPlayerService.isActuallyPlaying

                    Text {
                        id: mediaIconText
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        text: "󰎆"
                        color: Theme.accentColor
                        Layout.alignment: Qt.AlignVCenter

                        property bool isPulse: false
                        property real breathScale: 1.0

                        scale: isPulse ? 1.28 : breathScale

                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                        }

                        Connections {
                            target: MediaPlayerService
                            function onIsActuallyPlayingChanged() {
                                mediaIconText.isPulse = true;
                                pulseTimer.restart();
                            }
                        }

                        Timer {
                            id: pulseTimer
                            interval: 220
                            onTriggered: mediaIconText.isPulse = false
                        }

                        SequentialAnimation {
                            running: MediaPlayerService.isActuallyPlaying
                            loops: Animation.Infinite
                            NumberAnimation { target: mediaIconText; property: "breathScale"; from: 1.0; to: 1.15; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: mediaIconText; property: "breathScale"; from: 1.15; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        text: {
                            let p = MediaPlayerService.trackedPlayer;
                            if (!p) return "";
                            let title = MediaPlayerService.formatMediaTitle(String(p.trackTitle || p.identity || "Unknown"), p.identity);
                            let artist = String(p.trackArtist || "");
                            let full = (artist && artist !== "" && artist !== "undefined") ? title + " • " + artist : title;
                            let limit = Theme.isSmallScreen ? 18 : 34;
                            return MediaPlayerService.formatMediaMetadata(full, limit, 5);
                        }
                        color: Theme.accentColor
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Weather Section (Displayed when media is idle/paused)
                RowLayout {
                    spacing: Theme.scaled(6)
                    visible: !(MediaPlayerService.trackedPlayer && MediaPlayerService.isActuallyPlaying)

                    Text {
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(15)
                        text: WeatherService.getIcon(WeatherService.weatherCode)
                        color: Theme.accentColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: WeatherService.tempC + "°C"
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: WeatherService.weatherDesc
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(11)
                        visible: text !== "" && !Theme.isSmallScreen
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Elegant Vertical Glass Separator
                Rectangle {
                    width: 1
                    implicitWidth: 1
                    height: Theme.scaled(14)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Theme.scaled(2)
                    Layout.rightMargin: Theme.scaled(2)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.0) }
                        GradientStop { position: 0.5; color: Qt.rgba(255, 255, 255, 0.35) }
                        GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
                    }
                }
            }

            // --- CLOCK SECTION ---
            RowLayout {
                spacing: Theme.scaled(6)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(13)
                    text: "󰥔"
                    color: Theme.subtext0
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: ClockSettings.showDate
                    color: Theme.fontColor
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Normal
                    Layout.alignment: Qt.AlignVCenter
                    text: Qt.formatDateTime(systemClock.date, ClockSettings.dateFormat)
                }

                // Elegant Vertical Glass Separator
                Rectangle {
                    visible: ClockSettings.showDate && ClockSettings.showClock
                    width: 1
                    implicitWidth: 1
                    height: Theme.scaled(14)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Theme.scaled(2)
                    Layout.rightMargin: Theme.scaled(2)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.0) }
                        GradientStop { position: 0.5; color: Qt.rgba(255, 255, 255, 0.35) }
                        GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
                    }
                }

                Text {
                    visible: ClockSettings.showClock
                    color: Theme.fontColor
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Normal
                    Layout.alignment: Qt.AlignVCenter
                    text: {
                        let timeFmt = ClockSettings.use24Hour ? ClockSettings.timeFormat24h : ClockSettings.timeFormat12h;
                        return Qt.formatDateTime(systemClock.date, timeFmt);
                    }
                }
            }
        }

        // --- DYNAMIC ISLAND SEARCH BAR CONTENT ---
        RowLayout {
            id: dynamicIslandSearchContent
            anchors.fill: parent
            anchors.leftMargin: Theme.scaled(10)
            anchors.rightMargin: Theme.scaled(10)
            spacing: Theme.scaled(8)
            visible: DynamicIslandService.active

            // Mode Selector Buttons
            RowLayout {
                spacing: Theme.scaled(4)
                Layout.alignment: Qt.AlignVCenter

                // Launcher / Apps Tab
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(22)
                    radius: Theme.scaled(6)
                    color: DynamicIslandService.activeMode === "launcher" ? Theme.accentColor : (appTabMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰀻"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        color: DynamicIslandService.activeMode === "launcher" ? Colors.on_primary : Theme.text
                    }

                    MouseArea {
                        id: appTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DynamicIslandService.setMode("launcher");
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                // Clipboard Tab
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(22)
                    radius: Theme.scaled(6)
                    color: DynamicIslandService.activeMode === "clipboard" ? Theme.accentColor : (clipTabMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰅍"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        color: DynamicIslandService.activeMode === "clipboard" ? Colors.on_primary : Theme.text
                    }

                    MouseArea {
                        id: clipTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DynamicIslandService.setMode("clipboard");
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                // Emoji Tab
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(22)
                    radius: Theme.scaled(6)
                    color: DynamicIslandService.activeMode === "emoji" ? Theme.accentColor : (emojiTabMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰞅"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        color: DynamicIslandService.activeMode === "emoji" ? Colors.on_primary : Theme.text
                    }

                    MouseArea {
                        id: emojiTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DynamicIslandService.setMode("emoji");
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }

            // Vertical Glass Separator
            Rectangle {
                width: 1
                height: Theme.scaled(14)
                color: Theme.glassBorder
                Layout.alignment: Qt.AlignVCenter
            }

            // Search Input Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: Theme.fontSize
                    color: Theme.text
                    selectByMouse: true
                    text: DynamicIslandService.query
                    focus: DynamicIslandService.active

                    Connections {
                        target: DynamicIslandService
                        function onActiveChanged() {
                            if (DynamicIslandService.active) {
                                Qt.callLater(() => searchInput.forceActiveFocus());
                            }
                        }
                    }

                    onTextChanged: {
                        if (DynamicIslandService.active && text !== DynamicIslandService.query) {
                            DynamicIslandService.query = text;
                            DynamicIslandService.rebuildFiltered();
                        }
                    }

                    Keys.onEscapePressed: DynamicIslandService.close()

                    Keys.onTabPressed: (event) => {
                        DynamicIslandService.cycleMode();
                        event.accepted = true;
                    }

                    Keys.onLeftPressed: (event) => {
                        if (DynamicIslandService.activeMode === "emoji") {
                            let maxIdx = DynamicIslandService.displayedEmojis.length - 1;
                            if (maxIdx >= 0) {
                                DynamicIslandService.selectedIndex = Math.max(0, DynamicIslandService.selectedIndex - 1);
                                event.accepted = true;
                            }
                        }
                    }

                    Keys.onRightPressed: (event) => {
                        if (DynamicIslandService.activeMode === "emoji") {
                            let maxIdx = DynamicIslandService.displayedEmojis.length - 1;
                            if (maxIdx >= 0) {
                                DynamicIslandService.selectedIndex = Math.min(maxIdx, DynamicIslandService.selectedIndex + 1);
                                event.accepted = true;
                            }
                        }
                    }

                    Keys.onDownPressed: (event) => {
                        let maxIdx = 0;
                        if (DynamicIslandService.activeMode === "launcher") {
                            maxIdx = DynamicIslandService.displayedApps.length - 1;
                            if (maxIdx >= 0) DynamicIslandService.selectedIndex = Math.min(maxIdx, DynamicIslandService.selectedIndex + 1);
                        } else if (DynamicIslandService.activeMode === "clipboard") {
                            maxIdx = DynamicIslandService.displayedClips.length - 1;
                            if (maxIdx >= 0) DynamicIslandService.selectedIndex = Math.min(maxIdx, DynamicIslandService.selectedIndex + 1);
                        } else if (DynamicIslandService.activeMode === "emoji") {
                            maxIdx = DynamicIslandService.displayedEmojis.length - 1;
                            if (maxIdx >= 0) DynamicIslandService.selectedIndex = Math.min(maxIdx, DynamicIslandService.selectedIndex + 12);
                        }
                        if (event) event.accepted = true;
                    }

                    Keys.onUpPressed: (event) => {
                        let maxIdx = 0;
                        if (DynamicIslandService.activeMode === "launcher") {
                            maxIdx = DynamicIslandService.displayedApps.length - 1;
                            if (maxIdx >= 0) DynamicIslandService.selectedIndex = Math.max(0, DynamicIslandService.selectedIndex - 1);
                        } else if (DynamicIslandService.activeMode === "clipboard") {
                            maxIdx = DynamicIslandService.displayedClips.length - 1;
                            if (maxIdx >= 0) DynamicIslandService.selectedIndex = Math.max(0, DynamicIslandService.selectedIndex - 1);
                        } else if (DynamicIslandService.activeMode === "emoji") {
                            maxIdx = DynamicIslandService.displayedEmojis.length - 1;
                            if (maxIdx >= 0) DynamicIslandService.selectedIndex = Math.max(0, DynamicIslandService.selectedIndex - 12);
                        }
                        if (event) event.accepted = true;
                    }


                    Keys.onReturnPressed: handleEnter()
                    Keys.onEnterPressed: handleEnter()

                    function handleEnter() {
                        let idx = DynamicIslandService.selectedIndex;
                        if (DynamicIslandService.activeMode === "launcher") {
                            if (idx >= 0 && idx < DynamicIslandService.displayedApps.length) {
                                DynamicIslandService.launchApp(DynamicIslandService.displayedApps[idx]);
                            }
                        } else if (DynamicIslandService.activeMode === "clipboard") {
                            if (idx >= 0 && idx < DynamicIslandService.displayedClips.length) {
                                DynamicIslandService.copyClipItem(DynamicIslandService.displayedClips[idx]);
                            }
                        } else if (DynamicIslandService.activeMode === "emoji") {
                            if (idx >= 0 && idx < DynamicIslandService.displayedEmojis.length) {
                                DynamicIslandService.copyEmoji(DynamicIslandService.displayedEmojis[idx].emoji);
                            }
                        }
                    }

                    Text {
                        text: {
                            if (DynamicIslandService.activeMode === "launcher") return "Search apps or calc (e.g. 6 + 6)...";
                            if (DynamicIslandService.activeMode === "clipboard") return "Search clipboard history...";
                            if (DynamicIslandService.activeMode === "emoji") return "Search emojis...";
                            return "Search...";
                        }
                        color: Theme.subtext0
                        font.pixelSize: Theme.fontSize
                        visible: searchInput.text.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Close Button
            Text {
                text: "󰅖"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(13)
                color: closeMouse.containsMouse ? Theme.powerRed : Theme.subtext0
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.scaled(4)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DynamicIslandService.close()
                }
            }
        }

        SystemClock {
            id: systemClock
            precision: ClockSettings.precision
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !DynamicIslandService.active
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    CenterState.toggle("Default");
                } else if (mouse.button === Qt.RightButton && MediaPlayerService.trackedPlayer) {
                    let p = MediaPlayerService.trackedPlayer;
                    if (p.playPause) p.playPause();
                    else if (MediaPlayerService.isActuallyPlaying) p.pause();
                    else p.play();
                }
            }
        }
    }
}
