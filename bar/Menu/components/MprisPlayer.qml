import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Pane {
    id: mprisPlayer

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property real currentPos: player ? player.position : 0

    function formatTime(s) {
        if (s < 0 || isNaN(s))
            return "0:00";

        let mins = Math.floor(s / 60);
        let secs = Math.floor(s % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    // FIX 1: Force position update immediately when switching players
    onPlayerChanged: {
        if (player)
            currentPos = player.position;

    }
    Layout.fillWidth: true
    implicitHeight: 110

    // FIX 2: Listen for position changes (manual seeks/YT Music updates)
    Connections {
        function onPositionChanged() {
            mprisPlayer.currentPos = player.position;
        }

        target: player
        ignoreUnknownSignals: true
    }

    Timer {
        interval: 1000
        running: player && player.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: mprisPlayer.currentPos = player.position
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            width: 70
            height: 70
            radius: 6
            color: "#181825"

            Image {
                anchors.fill: parent
                source: player ? player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: "#45475a"
                font.pixelSize: 24
                visible: !player || !player.trackArtUrl
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                text: player ? player.trackTitle || "Nothing Playing" : "Idle"
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 13
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Slider {
                    id: posSlider

                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    from: 0
                    to: (player && player.length > 0) ? player.length : 100
                    value: mprisPlayer.currentPos
                    onMoved: player.position = value

                    background: Rectangle {
                        y: posSlider.topPadding + posSlider.availableHeight / 2 - height / 2
                        implicitHeight: 4
                        width: posSlider.availableWidth
                        radius: 2
                        color: "#313244"

                        Rectangle {
                            width: posSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#f5c2e7"
                            radius: 2
                        }

                    }

                    handle: Rectangle {
                        x: posSlider.leftPadding + posSlider.visualPosition * (posSlider.availableWidth - width)
                        y: posSlider.topPadding + posSlider.availableHeight / 2 - height / 2
                        width: 10.5
                        height: 10.5
                        radius: 4
                        color: '#b59eaf'
                        visible: posSlider.hovered || posSlider.pressed
                    }

                }

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: formatTime(mprisPlayer.currentPos)
                        color: "#6c7086"
                        font.pixelSize: 10
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Label {
                        text: formatTime(player ? player.length : 0)
                        color: "#6c7086"
                        font.pixelSize: 10
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    spacing: 2

                    Button {
                        flat: true
                        text: "󰒮"
                        onClicked: player.previous()

                        contentItem: Text {
                            text: parent.text
                            color: "#cdd6f4"
                            font.pixelSize: 14
                        }

                    }

                    Button {
                        flat: true
                        text: (player && player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                        onClicked: player.playbackState === MprisPlaybackState.Playing ? player.pause() : player.play()

                        contentItem: Text {
                            text: parent.text
                            color: "#f5c2e7"
                            font.pixelSize: 18
                        }

                    }

                    Button {
                        flat: true
                        text: "󰒭"
                        onClicked: player.next()

                        contentItem: Text {
                            text: parent.text
                            color: "#cdd6f4"
                            font.pixelSize: 14
                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 10

                    Repeater {
                        model: Mpris.players.values

                        delegate: MouseArea {
                            width: 18
                            height: 18
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player = modelData

                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 16
                                color: (player === modelData) ? "#f5c2e7" : "#45475a"
                                text: {
                                    let id = modelData.identity.toLowerCase();
                                    if (id.includes("firefox"))
                                        return "󰈹";

                                    if (id.includes("chromium") || id.includes("chrome") || id.includes("zen"))
                                        return "󰊯";

                                    if (id.includes("spotify"))
                                        return "󰓇";

                                    return "󰝚";
                                }
                            }

                        }

                    }

                }

            }

        }

    }

    background: Rectangle {
        color: "#11111b"
        radius: 10
        border.color: "#313244"
    }

}
