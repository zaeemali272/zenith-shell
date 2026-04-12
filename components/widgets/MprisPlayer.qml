import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import "../"
import "../../"
import Quickshell.Services.Mpris
import "../"
import "../../"
import "../../services"
import "../../"

Rectangle {
    id: mprisPlayer
    color: "#11111b"
    radius: Theme.scaled(16)
    border.color: "#313244"
    border.width: 1
    Layout.fillWidth: true
    implicitHeight: Theme.scaled(110)

    // --- State & Logic ---
    property var player: {
        let active = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
        return active ? active : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
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

    Instantiator {
        model: Mpris.players.values
        onObjectAdded: (index, obj) => {
            obj.playbackStateChanged.connect(() => {
                if (obj.playbackState === MprisPlaybackState.Playing)
                    mprisPlayer.player = obj;
            });
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
        running: CenterState.qsVisible && player && player.playbackState === MprisPlaybackState.Playing && !isResetting
        repeat: true
        onTriggered: {
            if (player && Mpris.players.values.indexOf(player) !== -1) {
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
            width: Theme.scaled(80); height: Theme.scaled(80); radius: Theme.scaled(12); color: "#181825"; clip: true
            Layout.alignment: Qt.AlignVCenter
            Image {
                anchors.fill: parent
                source: player ? String(player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
            Text { 
                anchors.centerIn: parent; text: "󰎆"; color: "#313244"; font.pixelSize: Theme.scaled(28)
                visible: !player || !player.trackArtUrl 
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: Theme.scaled(2)
            Layout.alignment: Qt.AlignVCenter // Ensures text/slider are centered with the image
            
            Label {
                text: player ? formatMediaTitle(String(player.trackTitle || "Media"), player.identity) : "Idle"
                color: "#cdd6f4"; font.bold: true; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight; Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Slider {
                    id: posSlider; Layout.fillWidth: true; 
                    Layout.preferredHeight: Theme.scaled(18) // Slightly bigger height
                    from: 0; to: (player && player.length > 0) ? player.length : 100
                    value: mprisPlayer.currentPos
                    onMoved: { if(player) player.position = value }
                    
                    background: Rectangle {
                        y: parent.height/2 - Theme.scaled(3); height: Theme.scaled(6); width: parent.width; radius: Theme.scaled(3); color: "#313244"
                        Rectangle { 
                            width: posSlider.visualPosition * parent.width; height: Theme.scaled(6); 
                            color: "#89b4fa"; radius: Theme.scaled(3) 
                        }
                    }
                    handle: Rectangle {
                        x: posSlider.visualPosition * (posSlider.availableWidth - Theme.scaled(12)); y: parent.height/2 - Theme.scaled(6)
                        width: Theme.scaled(12); height: Theme.scaled(12); radius: Theme.scaled(6); color: "#f5e0dc"
                        visible: posSlider.hovered || posSlider.pressed
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: formatTime(mprisPlayer.currentPos); color: "#585b70"; font.pixelSize: Theme.scaled(10) }
                    Item { Layout.fillWidth: true }
                    Label { text: formatTime(player ? player.length : 0); color: "#585b70"; font.pixelSize: Theme.scaled(10) }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                RowLayout {
                    spacing: 0
                    Button { 
                        flat: true; implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                        onClicked: { if(player) player.previous() }
                        contentItem: Text { text: "󰒮"; color: "#cdd6f4"; font.pixelSize: Theme.scaled(16); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } 
                    }
                    Button { 
                        flat: true; implicitWidth: Theme.scaled(36); implicitHeight: Theme.scaled(36)
                        onClicked: { if(player) player.playbackState === MprisPlaybackState.Playing ? player.pause() : player.play() }
                        contentItem: Text { 
                            text: (player && player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                            color: "#89b4fa"; font.pixelSize: Theme.scaled(22); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                        } 
                    }
                    Button { 
                        flat: true; implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                        onClicked: { if(player) player.next() }
                        contentItem: Text { text: "󰒭"; color: "#cdd6f4"; font.pixelSize: Theme.scaled(16); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } 
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
                                color: (mprisPlayer.player === modelData) ? "#f5c2e7" : "#45475a"
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