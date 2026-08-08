import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../Settings"

RowLayout {
    id: root
    property var controlCenterMenuRef: null

    spacing: Theme.pillSpacing

    // --- PRODUCTIVITY / POMODORO COUNTDOWN WIDGET ---
    Rectangle {
        visible: ProductivityService.running || ProductivityService.isBeeping
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

    // --- MASTERWORK JOINED CENTER PILL (Media/Weather + Clock) ---
    Rectangle {
        id: centerPill
        radius: height / 2
        color: pillMouse.containsMouse ? Theme.pillHoverColor : Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        implicitHeight: Theme.pillHeight
        width: centerContent.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        implicitWidth: width
        Layout.alignment: Qt.AlignVCenter
        clip: true

        scale: pillMouse.pressed ? 0.95 : (pillMouse.containsMouse ? 1.04 : 1.0)

        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            id: centerContent
            anchors.centerIn: parent
            spacing: Theme.pillGap

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

        SystemClock {
            id: systemClock
            precision: ClockSettings.precision
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
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
