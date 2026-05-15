import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../../services"
import "../../../"

Rectangle {
    id: mprisPlayer
    color: Theme.menuBackground
    radius: Theme.scaled(16)
    border.color: Theme.surface1
    border.width: 1
    Layout.fillWidth: true
    implicitHeight: Theme.scaled(110)

    // --- State & Logic ---
    property bool active: false
    property var player: null
    property var lastPlayer: null
    
    Component.onCompleted: {
        let activePlayer = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
        player = activePlayer ? activePlayer : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
    }
    
    property real currentPos: 0
    property string currentTrackId: ""
    property bool isResetting: false
    
    // --- Heartbeat Logic ---
    property real _lastHeartbeatPos: -1
    property bool _posAdvancing: true

    readonly property bool isActuallyPlaying: {
        if (!player) return false;
        if (player.playbackState !== MprisPlaybackState.Playing) return false;
        let id = player.identity.toLowerCase();
        if (id.includes("zen") || id.includes("chrom") || id.includes("fox")) {
            return _posAdvancing;
        }
        return true;
    }

    function triggerReset() {
        isResetting = true;
        currentPos = 0;
        let id = player ? player.identity.toLowerCase() : "";
        let isBrowser = id.includes("zen") || id.includes("chrom") || id.includes("fox");
        lockTimer.interval = isBrowser ? 2000 : 1000;
        lockTimer.restart();
    }

    Timer {
        id: lockTimer
        repeat: false
        onTriggered: {
            if (player && Mpris.players.values.indexOf(player) !== -1) currentPos = player.position;
            isResetting = false;
        }
    }

    Instantiator {
        model: Mpris.players
        onObjectAdded: (key, obj) => {
            if (mprisPlayer.player === null || obj.playbackState === MprisPlaybackState.Playing)
                mprisPlayer.player = obj;
        }

        onObjectRemoved: (key, obj) => {
            if (mprisPlayer.player === obj) {
                mprisPlayer.player = null;
                let activePlayer = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
                mprisPlayer.player = activePlayer ? activePlayer : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
            }
        }

        delegate: Connections {
            target: modelData
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    if (mprisPlayer.player !== modelData) {
                        // Media Focus Logic
                        let all = Mpris.players.values;
                        for (let i = 0; i < all.length; i++) {
                            let other = all[i];
                            if (other && other.dbusName !== modelData.dbusName && other.playbackState === MprisPlaybackState.Playing) {
                                mprisPlayer.lastPlayer = other;
                                other.pause();
                            }
                        }
                        mprisPlayer.player = modelData;
                    }
                } else if (mprisPlayer.player === modelData) {
                    if (modelData.playbackState === MprisPlaybackState.Paused || modelData.playbackState === MprisPlaybackState.Stopped) {
                        if (mprisPlayer.lastPlayer && mprisPlayer.lastPlayer.playbackState !== MprisPlaybackState.Playing) {
                            mprisPlayer.lastPlayer.play();
                            mprisPlayer.lastPlayer = null;
                        } else {
                            let active = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
                            if (active) mprisPlayer.player = active;
                        }
                    }
                }
                mprisPlayer.playerChanged(); // Force re-eval of isPlaying bindings
            }
            function onMetadataChanged() {
                if (mprisPlayer.player === modelData) {
                    mprisPlayer.playerChanged();
                }
            }
        }
    }

    Connections {
        target: player
        ignoreUnknownSignals: true
        function onMetadataChanged() {
            let newId = String(player.trackTitle + player.trackArtist);
            if (newId !== currentTrackId) {
                currentTrackId = newId;
                triggerReset();
            }
        }
    }

    Timer {
        interval: 1000
        running: (active || CenterState.qsVisible) && player && player.playbackState === MprisPlaybackState.Playing && !isResetting
        repeat: true
        onTriggered: {
            if (player && Mpris.players.values.indexOf(player) !== -1) {
                _posAdvancing = (player.position !== _lastHeartbeatPos);
                _lastHeartbeatPos = player.position;
                currentPos = player.position
            }
        }
    }

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

    // --- UI Layout ---
    RowLayout {
        anchors.centerIn: parent
        width: parent.width - Theme.scaled(24)
        spacing: Theme.scaled(15)

        // Album Art (Curved Radius)
        Rectangle {
            width: Theme.scaled(80); height: Theme.scaled(80); radius: Theme.scaled(12); color: Theme.mantle; clip: true
            Layout.alignment: Qt.AlignVCenter
            Image {
                anchors.fill: parent
                source: player ? String(player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
            Text { 
                anchors.centerIn: parent; text: "󰎆"; color: Theme.surface1; font.pixelSize: Theme.scaled(28)
                visible: !player || !player.trackArtUrl 
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: Theme.scaled(2)
            Layout.alignment: Qt.AlignVCenter // Ensures text/slider are centered with the image
            
            Label {
                text: player ? formatMediaTitle(String(player.trackTitle || "Media"), player.identity) : (mprisPlayer.isActuallyPlaying ? "Playing" : "Idle")
                color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight; Layout.fillWidth: true
            }

                ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Slider {
                    id: posSlider; Layout.fillWidth: true; 
                    Layout.preferredHeight: Theme.scaled(18) // Slightly bigger height
                    from: 0; to: (player && player.length > 0) ? player.length : 100
                    value: mprisPlayer.currentPos
                    onMoved: { if(player) player.position = value }

                    padding: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0

                    readonly property real handleWidth: Theme.scaled(12)
                    
                    background: Rectangle {
                        x: posSlider.leftPadding + posSlider.handleWidth / 2
                        y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                        height: Theme.scaled(6); width: posSlider.availableWidth - posSlider.handleWidth; radius: Theme.scaled(3); color: Theme.surface1
                        Rectangle { 
                            width: posSlider.visualPosition * parent.width; height: Theme.scaled(6); 
                            color: Theme.blue; radius: Theme.scaled(3) 
                        }
                    }
                    handle: Rectangle {
                        x: posSlider.leftPadding + posSlider.visualPosition * (posSlider.availableWidth - width)
                        y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                        width: posSlider.handleWidth; height: Theme.scaled(12); radius: Theme.scaled(6); color: Theme.lavender
                        visible: posSlider.hovered || posSlider.pressed
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: formatTime(mprisPlayer.currentPos); color: Theme.subtext1; font.pixelSize: Theme.scaled(10) }
                    Item { Layout.fillWidth: true }
                    Label { text: formatTime(player ? player.length : 0); color: Theme.subtext1; font.pixelSize: Theme.scaled(10) }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                RowLayout {
                    spacing: 0
                    Button { 
                        flat: true; implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                        onClicked: { if(player) player.previous() }
                        contentItem: Text { text: "󰒮"; color: Theme.text; font.pixelSize: Theme.scaled(16); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } 
                    }
                    Button { 
                        flat: true; implicitWidth: Theme.scaled(36); implicitHeight: Theme.scaled(36)
                        onClicked: { 
                            if(player) {
                                // Optimistic update for browsers
                                let id = player.identity.toLowerCase();
                                if (id.includes("zen") || id.includes("chrom") || id.includes("fox")) {
                                    mprisPlayer._posAdvancing = !mprisPlayer.isActuallyPlaying;
                                }
                                
                                if (player.playPause) player.playPause();
                                else if (player.playbackState === MprisPlaybackState.Playing) player.pause();
                                else player.play();
                            }
                        }
                        contentItem: Text { 
                            text: mprisPlayer.isActuallyPlaying ? "󰏤" : "󰐊"
                            color: Theme.blue; font.pixelSize: Theme.scaled(22); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                        } 
                    }
                    Button { 
                        flat: true; implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                        onClicked: { if(player) player.next() }
                        contentItem: Text { text: "󰒭"; color: Theme.text; font.pixelSize: Theme.scaled(16); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } 
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                RowLayout {
                    spacing: Theme.scaled(12)
                    Repeater {
                        model: Mpris.players.values
                        delegate: MouseArea {
                            width: Theme.scaled(20); height: Theme.scaled(20)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mprisPlayer.player = modelData // Icon Click Switch
                            
                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: Theme.scaled(16)
                                color: {
                                    if (mprisPlayer.player === modelData) return Theme.mauve;
                                    if (modelData.playbackState === MprisPlaybackState.Playing) return Theme.green;
                                    return Theme.surface2;
                                }
                                text: {
                                    let id = modelData.identity.toLowerCase();
                                    if (id.includes("firefox")) return "󰈹";
                                    if (id.includes("chrom") || id.includes("zen")) return "󰊯";
                                    if (id.includes("spotify")) return "󰓇";
                                    if (id.includes("vlc")) return "󰕼";
                                    return "󰝚";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function formatTime(s) {
        if (s < 0 || isNaN(s)) return "0:00"
        let mins = Math.floor(s / 60); let secs = Math.floor(s % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
}