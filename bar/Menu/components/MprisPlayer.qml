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
    property var player: MediaPlayerService.trackedPlayer
    
    // Heartbeat for browser media
    property real _lastHeartbeatPos: -1
    property bool _posAdvancing: true

    function isActuallyPlaying(p) {
        if (!p || p.playbackState !== MprisPlaybackState.Playing) return false;
        let id = p.identity.toLowerCase();
        if (id.includes("zen") || id.includes("chrom") || id.includes("fox")) return _posAdvancing;
        return true;
    }
    
    property real currentPos: 0
    property string currentTrackId: ""
    property bool isResetting: false

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
            if (player) {
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
            title = title.replace(/\.(mp3|mp4|mkv|avi|flac|wav|ogg|webm|mov|m4a|wmv|mpg|mpeg)$/i, "");
            title = title.replace(/\s*[\(\[].*?[\)\]]/g, "");
        }
        return title.trim();
    }

    function formatTime(s) {
        if (s < 0 || isNaN(s)) return "0:00"
        let mins = Math.floor(s / 60); let secs = Math.floor(s % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // --- UI Layout ---
    RowLayout {
        anchors.centerIn: parent
        width: parent.width - Theme.scaled(24)
        spacing: Theme.scaled(15)

        Rectangle {
            width: Theme.scaled(80); height: Theme.scaled(80); radius: Theme.scaled(12); color: Theme.mantle; clip: true
            Layout.alignment: Qt.AlignVCenter
            Image {
                anchors.fill: parent
                source: player ? String(player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                opacity: (player && player.trackArtUrl && status === Image.Ready) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
            Text { 
                anchors.centerIn: parent; text: "󰎆"; color: Theme.surface1; font.pixelSize: Theme.scaled(28)
                visible: !player || !player.trackArtUrl 
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: Theme.scaled(2)
            Layout.alignment: Qt.AlignVCenter
            
            Label {
                text: player ? formatMediaTitle(String(player.trackTitle || "Media"), player.identity) : (mprisPlayer.isActuallyPlaying(player) ? "Playing" : "Idle")
                color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight; Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Slider {
                    id: posSlider; Layout.fillWidth: true; 
                    Layout.preferredHeight: Theme.scaled(18)
                    from: 0; to: (player && player.length > 0) ? player.length : 100
                    value: mprisPlayer.currentPos
                    onMoved: { if(player) player.position = value }
                    padding: 0; leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
                    background: Rectangle {
                        x: posSlider.leftPadding + Theme.scaled(6); y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                        height: Theme.scaled(6); width: posSlider.availableWidth - Theme.scaled(12); radius: Theme.scaled(3); color: Theme.surface1
                        Rectangle { width: posSlider.visualPosition * parent.width; height: Theme.scaled(6); color: Theme.blue; radius: Theme.scaled(3) }
                    }
                    handle: Rectangle {
                        x: posSlider.leftPadding + posSlider.visualPosition * (posSlider.availableWidth - width)
                        y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                        width: Theme.scaled(12); height: Theme.scaled(12); radius: Theme.scaled(6); color: Theme.lavender
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
                                if (player.playPause) player.playPause();
                                else if (mprisPlayer.isActuallyPlaying(player)) player.pause();
                                else player.play();
                            }
                        }
                        contentItem: Text { 
                            text: mprisPlayer.isActuallyPlaying(player) ? "󰏤" : "󰐊"
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
                            onClicked: MediaPlayerService.updateTrackedPlayer(modelData)
                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: Theme.scaled(16)
                                color: (mprisPlayer.player === modelData) ? Theme.mauve : (modelData.playbackState === MprisPlaybackState.Playing ? Theme.green : Theme.surface2)
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
}
