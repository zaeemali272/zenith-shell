import ".."
import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../services"
import "../Menu" as Menu

Rectangle {
    id: mediaWidget
    radius: Theme.pillRadius
    color: Theme.pillColor
    implicitHeight: Theme.pillHeight
    anchors.verticalCenter: parent.verticalCenter
    clip: true

    // --- Media State ---
    readonly property var trackedPlayer: MediaPlayerService.trackedPlayer
    readonly property bool isActuallyPlaying: MediaPlayerService.isActuallyPlaying
    
    // --- Weather State (Integrated from WeatherWidget.qml) ---
    property var weatherData: null
    property bool loading: true

    function getWeatherIcon(code) {
        const c = parseInt(code);
        if (c === 113) return ""; if (c === 116) return ""; if (c === 119 || c === 122) return "";
        if ([143, 248, 260].includes(c)) return ""; if ([176, 263, 266, 293, 296, 302, 308].includes(c)) return "";
        if ([200, 386, 389].includes(c)) return ""; return "";
    }

    Process {
        id: weatherProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: StdioCollector { 
            onStreamFinished: { 
                mediaWidget.loading = false; 
                try { mediaWidget.weatherData = JSON.parse(text); } catch(e) { mediaWidget.weatherData = null; } 
            } 
        }
    }
    
    Timer { 
        interval: 1800000; running: true; repeat: true; triggeredOnStart: true; 
        onTriggered: { mediaWidget.loading = true; weatherProc.running = false; weatherProc.running = true; } 
    }

    // --- Content Selection ---
    readonly property bool showMedia: trackedPlayer && isActuallyPlaying

    readonly property string displayTrack: {
        if (!trackedPlayer) return "";
        let title = MediaPlayerService.formatMediaTitle(String(trackedPlayer.trackTitle || trackedPlayer.identity || "Unknown"), trackedPlayer.identity);
        let artist = String(trackedPlayer.trackArtist || "");
        let full = (artist && artist !== "" && artist !== "undefined") ? title + " | " + artist : title;
        let limit = Theme.isSmallScreen ? 20 : 50;
        if (full.length > limit) return full.substring(0, limit - 3) + "...";
        return full;
    }

    width: contentLayout.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
    implicitWidth: width
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    // --- UI Layout ---
    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Theme.pillGap

        // --- MEDIA SECTION ---
        RowLayout {
            spacing: Theme.pillGap
            visible: mediaWidget.showMedia
            Text {
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                text: ""
                color: Theme.accentColor
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: mediaWidget.displayTrack
                color: Theme.accentColor
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // --- WEATHER SECTION ---
        RowLayout {
            spacing: Theme.pillGap
            visible: !mediaWidget.showMedia
            Text {
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(16)
                text: mediaWidget.getWeatherIcon(mediaWidget.weatherData?.current_condition?.[0]?.weatherCode)
                color: Theme.overlay0
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: (mediaWidget.weatherData?.current_condition?.[0]?.temp_C || "0") + "°C"
                color: Theme.overlay0
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: mediaWidget.weatherData?.current_condition?.[0]?.weatherDesc?.[0]?.value || ""
                color: Theme.subtext1
                font.pixelSize: Theme.scaled(11)
                Layout.alignment: Qt.AlignVCenter
                visible: text !== "" && !Theme.isSmallScreen
            }
        }
    }

    Connections {
        target: VolumeService
        function onMicActiveChanged() {
            if (VolumeService.micActive && mediaWidget.isActuallyPlaying) mediaWidget.trackedPlayer.pause();
        }
    }

    Menu.MediaPlayerPopup { 
        id: mediaPopup; 
        parentWindow: bar 
        Component.onCompleted: CenterState.mediaPopupRef = mediaPopup
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: 10
        onEntered: {
            mediaWidget.color = Theme.pillHoverColor;
        }
        onExited: mediaWidget.color = Theme.pillColor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (!mediaPopup.visible) {
                    QuickSettingsService.close();
                    CenterState.close();
                }
                mediaPopup.visible = !mediaPopup.visible;
            } else if (mouse.button === Qt.RightButton && trackedPlayer) {
                if (trackedPlayer.playPause) trackedPlayer.playPause();
                else if (mediaWidget.isActuallyPlaying) trackedPlayer.pause();
                else trackedPlayer.play();
            }
        }
    }
}
