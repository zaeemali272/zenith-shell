import ".."
import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: mediaWidget
    radius: Theme.pillRadius
    color: Theme.pillColor
    implicitHeight: Theme.pillHeight
    anchors.verticalCenter: parent.verticalCenter
    clip: true

    // --- THE ANIMATION ---
    width: contentLayout.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
    
    Behavior on width {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutExpo
        }
    }

    readonly property list<MprisPlayer> players: Mpris.players.values
        .filter(player => !player.dbusName?.startsWith("org.mpris.MediaPlayer2.chromium") &&
                           !player.dbusName?.startsWith("org.mpris.MediaPlayer2.firefox") &&
                           !player.dbusName?.startsWith("org.mpris.MediaPlayer2.playerctld"))

    property MprisPlayer trackedPlayer: null
    property var activeTrack: { "title": "Nothing playing", "artist": "", "artUrl": "" }

    // implicitWidth must follow the animated width for the parent layout to respect it
    implicitWidth: width

    signal trackChanged()

    function formatMediaTitle(title, identity) {
        if (!title) return "";
        let id = identity ? identity.toLowerCase() : "";
        if (id.includes("mpv") || id.includes("vlc")) {
            // Remove common media extensions
            title = title.replace(/\.(mp3|mp4|mkv|avi|flac|wav|ogg|webm|mov|m4a|wmv|mpg|mpeg)$/i, "");
            // Remove everything in parentheses and brackets
            title = title.replace(/\s*[\(\[].*?[\)\]]/g, "");
        }
        return title.trim();
    }

    function updateTrack() {
        if (!trackedPlayer || !trackedPlayer.isPlaying) {
            activeTrack = { "title": "Nothing playing", "artist": "", "artUrl": "" }
        } else {
            let rawTitle = String(trackedPlayer.trackTitle || trackedPlayer.identity || "Unknown Player");
            activeTrack = {
                title: formatMediaTitle(rawTitle, trackedPlayer.identity),
                artist: String(trackedPlayer.trackArtist || ""),
                artUrl: String(trackedPlayer.trackArtUrl || "")
            }
        }

        let titleStr = String(activeTrack.title);
        let artistStr = String(activeTrack.artist);

        let displayTrack = (artistStr && artistStr !== "" && artistStr !== "undefined")
            ? titleStr + " | " + artistStr
            : titleStr

        if (displayTrack.length > 85) {
            let truncated = displayTrack.substring(0, 82);
            let lastSpace = truncated.lastIndexOf(" ");
            if (lastSpace > 50) {
                displayTrack = truncated.substring(0, lastSpace) + "...";
            } else {
                displayTrack = truncated + "...";
            }
        }

        mediaText.text = displayTrack || "Nothing playing"
        mediaText.color = trackedPlayer?.isPlaying ? "#fab387" : "#7c6f64"
        playPauseIcon.text = trackedPlayer?.isPlaying ? "" : ""
        playPauseIcon.color = trackedPlayer?.isPlaying ? "#fab387" : "#7c6f64"
        trackChanged()
    }

    Instantiator {
        model: Mpris.players
        
        onObjectAdded: (index, player) => {
            if (mediaWidget.trackedPlayer === null || player.playbackState === MprisPlaybackState.Playing) {
                mediaWidget.trackedPlayer = player
                mediaWidget.updateTrack()
            }
        }

        Connections {
            required property MprisPlayer modelData
            target: modelData
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    mediaWidget.trackedPlayer = modelData
                } else if (mediaWidget.trackedPlayer === modelData) {
                    // Current player stopped, look for another playing one
                    let anyPlaying = Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing);
                    if (anyPlaying) mediaWidget.trackedPlayer = anyPlaying;
                }
                mediaWidget.updateTrack()
            }
            function onMetadataChanged() { mediaWidget.updateTrack() }
            Component.onDestruction: {
                if (mediaWidget.trackedPlayer === modelData) {
                    mediaWidget.trackedPlayer = null;
                    let anyPlaying = Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing);
                    if (anyPlaying) mediaWidget.trackedPlayer = anyPlaying;
                    mediaWidget.updateTrack()
                }
            }
        }
    }

    Connections {
        id: trackedPlayerConnections
        target: trackedPlayer
        ignoreUnknownSignals: true // Prevents errors if trackedPlayer is null
        function onMetadataChanged() { mediaWidget.updateTrack() }
        function onPlaybackStateChanged() { mediaWidget.updateTrack() }
    }

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Theme.pillGap

        Text {
            id: playPauseIcon
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Theme.iconSize
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            text: ""
            color: "#fab387"
        }

        Text {
            id: mediaText
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            text: "Nothing playing"
            color: "#7c6f64"
            
            // Fixed height ensures the text doesn't jitter vertically
            Layout.preferredHeight: Theme.iconSize
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: mediaWidget.color = Theme.pillHoverColor
        onExited: mediaWidget.color = Theme.pillColor
        onClicked: {
            if (trackedPlayer?.canTogglePlaying) {
                if (trackedPlayer.isPlaying) trackedPlayer.pause()
                else trackedPlayer.play()
            }
        }
    }
}