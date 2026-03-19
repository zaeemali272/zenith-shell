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

    readonly property list<MprisPlayer> players: Mpris.players.values
        .filter(player => !player.dbusName?.startsWith("org.mpris.MediaPlayer2.chromium") &&
                           !player.dbusName?.startsWith("org.mpris.MediaPlayer2.firefox") &&
                           !player.dbusName?.startsWith("org.mpris.MediaPlayer2.playerctld"))

    property MprisPlayer trackedPlayer: null
    property var activeTrack: { title: "Nothing playing"; artist: ""; artUrl: "" }

    implicitWidth: contentLayout.implicitWidth + (Theme.pillPadding * 2)

    signal trackChanged()

    function updateTrack() {
        if (!trackedPlayer) {
            activeTrack = { title: "Nothing playing", artist: "", artUrl: "" }
        } else {
            activeTrack = {
                title: trackedPlayer.trackTitle ?? "Unknown Title",
                artist: trackedPlayer.trackArtist ?? "Unknown Artist",
                artUrl: trackedPlayer.trackArtUrl ?? ""
            }
        }

        let displayTrack = activeTrack.artist && activeTrack.artist !== ""
            ? activeTrack.title + " | " + activeTrack.artist
            : activeTrack.title

        if (displayTrack.length > 85) {
            let truncated = displayTrack.substring(0, 82);
            let lastSpace = truncated.lastIndexOf(" ");
            if (lastSpace > 50) { // Only truncate at word boundary if it's not too short
                displayTrack = truncated.substring(0, lastSpace) + "...";
            } else {
                displayTrack = truncated + "...";
            }
        }

        mediaText.text = displayTrack

        mediaText.color = trackedPlayer?.isPlaying ? "#fab387" : "#7c6f64"
        playPauseIcon.text = trackedPlayer?.isPlaying ? "" : ""
        playPauseIcon.color = trackedPlayer?.isPlaying ? "#fab387" : "#7c6f64"
        trackChanged()
    }

    // --- Track all players dynamically ---
    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                if (mediaWidget.trackedPlayer === null || modelData.isPlaying) {
                    mediaWidget.trackedPlayer = modelData
                    mediaWidget.updateTrack()
                }
            }

            function onPlaybackStateChanged() {
                if (mediaWidget.trackedPlayer !== modelData && modelData.isPlaying) {
                    mediaWidget.trackedPlayer = modelData
                }
                mediaWidget.updateTrack()
            }

            function onMetadataChanged() {
                mediaWidget.updateTrack()
            }

            Component.onDestruction: {
                if (mediaWidget.trackedPlayer === modelData) {
                    for (const p of Mpris.players.values) {
                        if (p.isPlaying) {
                            mediaWidget.trackedPlayer = p
                            break
                        }
                    }
                    mediaWidget.updateTrack()
                }
            }
        }
    }

    // --- Connections to trackedPlayer (dynamic) ---
    Connections {
        id: trackedPlayerConnections
        target: trackedPlayer

        // Only connect to real signals
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
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            text: ""
            color: "#fab387"
        }

        Text {
            id: mediaText
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            text: "Nothing playing"
            color: "#7c6f64"
        }
    }

    // --- Hover & click to toggle play/pause ---
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
