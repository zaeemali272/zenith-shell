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
    property var lastPlayer: null
    property bool pausedByMic: false

    Component.onCompleted: {
        let active = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
        trackedPlayer = active ? active : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
    }

    // --- Formatting Logic ---
    function formatMediaTitle(title, identity) {
        if (!title) return "";
        let id = identity ? identity.toLowerCase() : "";
        if (id.includes("mpv") || id.includes("vlc")) {
            title = title.replace(/\.(mp3|mp4|mkv|avi|flac|wav|ogg|webm|mov|m4a|wmv|mpg|mpeg)$/i, "");
            title = title.replace(/\s*[\(\[].*?[\)\]]/g, "");
        }
        return title.trim();
    }

    // --- Heartbeat Logic (for browsers that lie about playback state) ---
    property real _lastPos: -1
    property bool _posAdvancing: true
    
    Timer {
        id: heartbeatTimer
        interval: 2000
        running: trackedPlayer && trackedPlayer.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: {
            if (trackedPlayer) {
                // If position hasn't changed, it's likely paused on the website
                _posAdvancing = (trackedPlayer.position !== _lastPos);
                _lastPos = trackedPlayer.position;
            }
        }
    }

    readonly property bool isPlaying: {
        if (!trackedPlayer) return false;
        if (trackedPlayer.playbackState !== MprisPlaybackState.Playing) return false;
        
        let id = trackedPlayer.identity.toLowerCase();
        if (id.includes("zen") || id.includes("chrom") || id.includes("fox")) {
            return _posAdvancing;
        }
        return true;
    }
    
    readonly property string displayTrack: {
        if (!trackedPlayer || !isPlaying) return "Nothing playing";
        
        let rawTitle = String(trackedPlayer.trackTitle || trackedPlayer.identity || "Unknown Player");
        let title = formatMediaTitle(rawTitle, trackedPlayer.identity);
        let artist = String(trackedPlayer.trackArtist || "");
        
        let full = (artist && artist !== "" && artist !== "undefined") ? title + " | " + artist : title;
        
        if (full.length > 85) {
            let truncated = full.substring(0, 82);
            let lastSpace = truncated.lastIndexOf(" ");
            return (lastSpace > 50 ? truncated.substring(0, lastSpace) : truncated) + "...";
        }
        return full;
    }

    // --- UI Layout ---
    width: contentLayout.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
    implicitWidth: width
    
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

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

    // --- Event Handling ---
    Instantiator {
        model: Mpris.players
        onObjectAdded: (key, obj) => {
            if (mediaWidget.trackedPlayer === null || obj.playbackState === MprisPlaybackState.Playing) {
                mediaWidget.trackedPlayer = obj
            }
        }
        
        onObjectRemoved: (key, obj) => {
            if (mediaWidget.trackedPlayer === obj) {
                mediaWidget.trackedPlayer = null;
                let active = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
                mediaWidget.trackedPlayer = active ? active : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
            }
        }

        delegate: Connections {
            target: modelData
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    if (mediaWidget.trackedPlayer !== modelData) {
                        // Media Focus Logic
                        let all = Mpris.players.values;
                        for (let i = 0; i < all.length; i++) {
                            let other = all[i];
                            if (other && other.dbusName !== modelData.dbusName && other.playbackState === MprisPlaybackState.Playing) {
                                mediaWidget.lastPlayer = other;
                                other.pause();
                            }
                        }
                        mediaWidget.trackedPlayer = modelData;
                    }
                } else if (mediaWidget.trackedPlayer === modelData) {
                    if (modelData.playbackState === MprisPlaybackState.Paused || modelData.playbackState === MprisPlaybackState.Stopped) {
                        // Resume last player if no one else is playing
                        if (mediaWidget.lastPlayer && mediaWidget.lastPlayer.playbackState !== MprisPlaybackState.Playing) {
                            mediaWidget.lastPlayer.play();
                            mediaWidget.lastPlayer = null;
                        } else {
                            // Look for another playing one
                            let active = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
                            if (active) mediaWidget.trackedPlayer = active;
                        }
                    }
                }
                mediaWidget.trackedPlayerChanged();
            }
            
            function onMetadataChanged() { 
                if (mediaWidget.trackedPlayer === modelData) mediaWidget.trackedPlayerChanged(); 
            }
        }
    }

    Connections {
        target: VolumeService
        function onMicActiveChanged() {
            if (VolumeService.micActive) {
                if (mediaWidget.trackedPlayer && mediaWidget.isPlaying) {
                    mediaWidget.pausedByMic = true;
                    mediaWidget.trackedPlayer.pause();
                }
            } else if (mediaWidget.pausedByMic) {
                if (mediaWidget.trackedPlayer) mediaWidget.trackedPlayer.play();
                mediaWidget.pausedByMic = false;
            }
        }
    }

    Menu.MediaPlayerPopup {
        id: mediaPopup
        parentWindow: bar
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: mediaWidget.color = Theme.pillHoverColor
        onExited: mediaWidget.color = Theme.pillColor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) mediaPopup.visible = !mediaPopup.visible;
            else if (mouse.button === Qt.RightButton && trackedPlayer) {
                // Optimistic update for browsers
                let id = trackedPlayer.identity.toLowerCase();
                if (id.includes("zen") || id.includes("chrom") || id.includes("fox")) {
                    mediaWidget._posAdvancing = !mediaWidget.isPlaying;
                }

                if (trackedPlayer.playPause) trackedPlayer.playPause();
                else if (mediaWidget.isPlaying) trackedPlayer.pause();
                else trackedPlayer.play();
            }
        }
    }
}
