import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../Settings"

RowLayout {
    id: root

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

        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 60 } }
        Behavior on border.color { ColorAnimation { duration: 60 } }

        // --- DEFAULT CENTER CONTENT (Clock/Media/Weather) ---
        RowLayout {
            id: centerContent
            anchors.centerIn: parent
            spacing: Theme.pillGap
            opacity: DynamicIslandService.active ? 0.0 : 1.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

            // --- MEDIA / WEATHER SECTION ---
            RowLayout {
                spacing: Theme.pillGap
                visible: WidgetSettings.enableMedia && !Theme.isSmallScreen

                // Active Playing Media Section
                RowLayout {
                    id: mediaSection
                    spacing: Theme.scaled(6)
                    visible: MediaPlayerService.trackedPlayer && MediaPlayerService.isActuallyPlaying

                    // Live 4-bar reactive audio equalizer
                    Row {
                        id: eqBars
                        spacing: Theme.scaled(2.5)
                        height: Theme.scaled(14)
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: [
                                { minH: 4, maxH: 13, d1: 340, d2: 420 },
                                { minH: 3, maxH: 15, d1: 220, d2: 310 },
                                { minH: 5, maxH: 12, d1: 390, d2: 270 },
                                { minH: 3, maxH: 14, d1: 280, d2: 360 }
                            ]
                            delegate: Rectangle {
                                width: Theme.scaled(2.8)
                                height: Theme.scaled(modelData.minH)
                                radius: width / 2
                                color: Theme.accentColor
                                anchors.bottom: parent.bottom

                                SequentialAnimation on height {
                                    running: MediaPlayerService.isActuallyPlaying
                                    loops: Animation.Infinite
                                    NumberAnimation { to: Theme.scaled(modelData.maxH); duration: modelData.d1; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: Theme.scaled(modelData.minH); duration: modelData.d2; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }

                    // Hover-revealed micro media controls
                    RowLayout {
                        id: mediaControls
                        spacing: Theme.scaled(3)
                        visible: pillMouse.containsMouse
                        opacity: pillMouse.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        // Previous Track Button
                        Rectangle {
                            width: Theme.scaled(18)
                            height: Theme.scaled(18)
                            radius: 999
                            color: prevMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : (prevMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                            scale: prevMouse.pressed ? 0.9 : (prevMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(11)
                                color: Theme.accentColor
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let p = MediaPlayerService.trackedPlayer;
                                    if (p && p.previous) p.previous();
                                }
                            }
                        }

                        // Play/Pause Button
                        Rectangle {
                            width: Theme.scaled(18)
                            height: Theme.scaled(18)
                            radius: 999
                            color: ppMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : (ppMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                            scale: ppMouse.pressed ? 0.9 : (ppMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: MediaPlayerService.isActuallyPlaying ? "󰏤" : "󰐊"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(12)
                                color: Theme.accentColor
                            }

                            MouseArea {
                                id: ppMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let p = MediaPlayerService.trackedPlayer;
                                    if (!p) return;
                                    if (p.playPause) p.playPause();
                                    else if (MediaPlayerService.isActuallyPlaying) p.pause();
                                    else p.play();
                                }
                            }
                        }

                        // Next Track Button
                        Rectangle {
                            width: Theme.scaled(18)
                            height: Theme.scaled(18)
                            radius: 999
                            color: nextMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : (nextMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                            scale: nextMouse.pressed ? 0.9 : (nextMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(11)
                                color: Theme.accentColor
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let p = MediaPlayerService.trackedPlayer;
                                    if (p && p.next) p.next();
                                }
                            }
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
            opacity: DynamicIslandService.active ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

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

                Timer {
                    id: searchDebounce
                    interval: 15
                    repeat: false
                    onTriggered: {
                        DynamicIslandService.query = searchInput.text;
                        DynamicIslandService.rebuildFiltered();
                    }
                }

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: Theme.fontSize
                    color: Theme.text
                    selectByMouse: true
                    focus: DynamicIslandService.active

                    Connections {
                        target: DynamicIslandService
                        function onActiveChanged() {
                            if (DynamicIslandService.active) {
                                searchDebounce.stop();
                                searchInput.text = DynamicIslandService.query;
                                Qt.callLater(() => searchInput.forceActiveFocus());
                            } else {
                                searchDebounce.stop();
                                searchInput.text = "";
                            }
                        }
                        function onActiveModeChanged() {
                            if (DynamicIslandService.active) {
                                searchDebounce.stop();
                                searchInput.text = "";
                                Qt.callLater(() => searchInput.forceActiveFocus());
                            }
                        }
                    }

                    onTextChanged: {
                        if (!DynamicIslandService.active) return;
                        if (text === "") {
                            searchDebounce.stop();
                            DynamicIslandService.query = "";
                            DynamicIslandService.rebuildFiltered();
                        } else {
                            searchDebounce.restart();
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


                    Keys.onReturnPressed: (event) => handleEnter(event)
                    Keys.onEnterPressed: (event) => handleEnter(event)

                    function handleEnter(event) {
                        if (searchDebounce.running) {
                            searchDebounce.stop();
                            DynamicIslandService.query = searchInput.text;
                            DynamicIslandService.rebuildFiltered();
                        }

                        let isShift = event && (event.modifiers & Qt.ShiftModifier);
                        if (isShift && DynamicIslandService.activeMode === "launcher") {
                            DynamicIslandService.runInTerminal(searchInput.text || DynamicIslandService.query);
                            DynamicIslandService.close();
                            if (event) event.accepted = true;
                            return;
                        }

                        let idx = DynamicIslandService.selectedIndex;
                        if (DynamicIslandService.activeMode === "launcher") {
                            if (idx >= 0 && idx < DynamicIslandService.displayedApps.length) {
                                DynamicIslandService.launchApp(DynamicIslandService.displayedApps[idx]);
                            } else {
                                let cmd = (searchInput.text || DynamicIslandService.query).trim();
                                if (cmd !== "") {
                                    DynamicIslandService.runInTerminal(cmd);
                                }
                                DynamicIslandService.close();
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
                        if (event) event.accepted = true;
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
            onWheel: (wheel) => {
                let p = MediaPlayerService.trackedPlayer;
                if (p && MediaPlayerService.isActuallyPlaying) {
                    if (wheel.angleDelta.y < 0) {
                        if (p.next) p.next();
                    } else if (wheel.angleDelta.y > 0) {
                        if (p.previous) p.previous();
                    }
                }
            }
        }
    }
}
