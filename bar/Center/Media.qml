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

    property MprisPlayer trackedPlayer: null
    property var lastPlayer: null
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
        
        onObjectAdded: (key, player) => {
            if (mediaWidget.trackedPlayer === null || player.playbackState === MprisPlaybackState.Playing) {
                mediaWidget.trackedPlayer = player
                mediaWidget.updateTrack()
            }
        }

        Connections {
            required property var modelData
            target: modelData
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    // --- MEDIA FOCUS LOGIC ---
                    console.log("[MediaFocus] " + modelData.identity + " started. Pausing others.");
                    let all = Mpris.players.values;
                    for (let i = 0; i < all.length; i++) {
                        let other = all[i];
                        if (other && other.dbusName !== modelData.dbusName && other.playbackState === MprisPlaybackState.Playing) {
                            mediaWidget.lastPlayer = other;
                            other.pause();
                        }
                    }
                    mediaWidget.trackedPlayer = modelData
                    mediaWidget.updateTrack()
                } else if (modelData.playbackState === MprisPlaybackState.Paused || modelData.playbackState === MprisPlaybackState.Stopped) {
                    // Resume last player if no one else is playing
                    if (mediaWidget.trackedPlayer === modelData) {
                        if (mediaWidget.lastPlayer && mediaWidget.lastPlayer.playbackState !== MprisPlaybackState.Playing) {
                            console.log("[MediaFocus] Focus returned. Resuming " + mediaWidget.lastPlayer.identity);
                            mediaWidget.lastPlayer.play();
                            mediaWidget.lastPlayer = null;
                        } else {
                            // Look for another playing one
                            let values = Mpris.players.values;
                            for (let i = 0; i < values.length; i++) {
                                if (values[i].playbackState === MprisPlaybackState.Playing) {
                                    mediaWidget.trackedPlayer = values[i];
                                    break;
                                }
                            }
                        }
                        mediaWidget.updateTrack()
                    }
                }
            }
            function onMetadataChanged() { 
                if (mediaWidget.trackedPlayer === modelData) mediaWidget.updateTrack() 
            }
            Component.onDestruction: {
                if (mediaWidget.trackedPlayer === modelData) {
                    mediaWidget.trackedPlayer = null;
                    let values = Mpris.players.values;
                    for (let i = 0; i < values.length; i++) {
                        if (values[i].playbackState === MprisPlaybackState.Playing) {
                            mediaWidget.trackedPlayer = values[i];
                            break;
                        }
                    }
                    mediaWidget.updateTrack()
                }
            }
        }
    }

    property bool pausedByMic: false

    Connections {
        target: VolumeService
        function onMicActiveChanged() {
            if (VolumeService.micActive) {
                if (trackedPlayer && trackedPlayer.isPlaying) {
                    console.log("[MediaFocus] Mic active. Pausing media.");
                    mediaWidget.pausedByMic = true;
                    trackedPlayer.pause();
                }
            } else {
                if (mediaWidget.pausedByMic) {
                    console.log("[MediaFocus] Mic inactive. Resuming media.");
                    if (trackedPlayer) trackedPlayer.play();
                    mediaWidget.pausedByMic = false;
                }
            }
        }
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
