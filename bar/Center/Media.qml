import ".."
import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../Menu" as Menu

Rectangle {
    id: mediaWidget
    radius: Theme.pillRadius
    color: Theme.pillColor
    implicitHeight: Theme.pillHeight
    anchors.verticalCenter: parent.verticalCenter
    clip: true

    // --- State ---
    property var trackedPlayer: null
    
    // UI Bindings
    readonly property bool isPlaying: trackedPlayer && trackedPlayer.playbackState === MprisPlaybackState.Playing
    readonly property string displayTrack: {
        if (!trackedPlayer || !isPlaying) return "Nothing playing";
        let title = formatMediaTitle(String(trackedPlayer.trackTitle || trackedPlayer.identity || "Unknown"), trackedPlayer.identity);
        let artist = String(trackedPlayer.trackArtist || "");
        let full = (artist && artist !== "" && artist !== "undefined") ? title + " | " + artist : title;
        if (full.length > 85) {
            let truncated = full.substring(0, 82);
            let lastSpace = truncated.lastIndexOf(" ");
            return (lastSpace > 50 ? truncated.substring(0, lastSpace) : truncated) + "...";
        }
        return full;
    }

    function formatMediaTitle(title, identity) {
        if (!title) return "";
        let id = identity ? identity.toLowerCase() : "";
        if (id.includes("mpv") || id.includes("vlc")) {
            title = title.replace(/\.(mp3|mp4|mkv|avi|flac|wav|ogg|webm|mov|m4a|wmv|mpg|mpeg)$/i, "");
            title = title.replace(/\s*[\(\[].*?[\)\]]/g, "");
        }
        return title.trim();
    }

    width: contentLayout.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
    implicitWidth: width
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    // --- Media Management ---
    Instantiator {
        model: Mpris.players
        onObjectAdded: (key, obj) => {
            if (!mediaWidget.trackedPlayer || obj.playbackState === MprisPlaybackState.Playing)
                mediaWidget.trackedPlayer = obj;
        }
        onObjectRemoved: (key, obj) => {
            if (mediaWidget.trackedPlayer === obj) {
                let active = Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing);
                mediaWidget.trackedPlayer = active ? active : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
            }
        }
        delegate: Connections {
            target: modelData
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    if (mediaWidget.trackedPlayer !== modelData) {
                        mediaWidget.trackedPlayer = modelData;
                        // Android-like focus: Pause others only when a new one starts Playing
                        if (GeneralSettings.autoManageMediaFocus) {
                            Mpris.players.values.forEach(other => {
                                if (other !== modelData && other.playbackState === MprisPlaybackState.Playing) {
                                    other.pause();
                                }
                            });
                        }
                    }
                } else if (mediaWidget.trackedPlayer === modelData) {
                    // If current player stops, check if another one is playing to switch UI focus
                    let active = Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing);
                    if (active) mediaWidget.trackedPlayer = active;
                }
            }
        }
    }

    // --- UI Layout ---
    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Theme.pillGap
        Text {
            id: playPauseIcon
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            text: mediaWidget.isPlaying ? "" : ""
            color: mediaWidget.isPlaying ? "#fab387" : "#7c6f64"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Theme.iconSize
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: mediaText
            text: mediaWidget.displayTrack
            color: mediaWidget.isPlaying ? "#fab387" : "#7c6f64"
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredHeight: Theme.iconSize
        }
    }

    Connections {
        target: VolumeService
        function onMicActiveChanged() {
            if (VolumeService.micActive && mediaWidget.isPlaying) mediaWidget.trackedPlayer.pause();
        }
    }

    Menu.MediaPlayerPopup { id: mediaPopup; parentWindow: bar }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: mediaWidget.color = Theme.pillHoverColor
        onExited: mediaWidget.color = Theme.pillColor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) mediaPopup.visible = !mediaPopup.visible;
            else if (mouse.button === Qt.RightButton && trackedPlayer) {
                if (trackedPlayer.playPause) trackedPlayer.playPause();
                else if (mediaWidget.isPlaying) trackedPlayer.pause();
                else trackedPlayer.play();
            }
        }
    }
}
