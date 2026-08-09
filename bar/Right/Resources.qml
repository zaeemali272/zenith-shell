// bar/Right/Resources.qml
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    readonly property int cpu: ResourceService.cpu
    readonly property int mem: ResourceService.mem
    readonly property int temp: ResourceService.temp
    readonly property string currentProfile: PowerProfileService.currentProfile

    // Dynamic thresholds: RAM visible > 60%, Temp visible > 90°C
    readonly property bool showMem: mem > 60
    readonly property bool showTemp: temp > 90

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: outerContainer.width

    // Outer Glass Container matching QuickSettingsCluster exactly
    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.scaled(24)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    QuickSettingsService.toggle("powerprofile");
            }
        }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.scaled(6)

            // Power Profile Cat Avatar Sub-Widget
            Item {
                width: Theme.scaled(35)
                height: Theme.scaled(35)
                Layout.alignment: Qt.AlignVCenter

                Image {
                    id: catSprite
                    anchors.centerIn: parent
                    source: "../../assets/cat_f" + Math.floor(frameTimer.frameCount % 4) + ".png"
                    width: Theme.scaled(35)
                    height: Theme.scaled(35)
                    fillMode: Image.PreserveAspectFit
                }

                Timer {
                    id: frameTimer
                    property int frameCount: 0
                    interval: {
                        switch (currentProfile) {
                            case "performance": return 80;
                            case "turbo": return 50;
                            case "powersave": return 220;
                            case "balanced": return 150;
                            default: return 200;
                        }
                    }
                    running: true
                    repeat: true
                    onTriggered: frameCount++
                }
            }

            // Dot Separator after Cat Avatar
            Text {
                text: "•"
                color: Theme.glassBorder
                font.pixelSize: Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter
            }

            // CPU Stats (Always visible)
            RowLayout {
                spacing: Theme.scaled(4)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: ""
                    color: Theme.powerRed
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.cpu + "%"
                    color: Theme.fontColor
                    font.pixelSize: Theme.fontSize
                    font.family: "JetBrains Mono"
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Dot Separator for RAM (Visible when RAM > 60%)
            Text {
                visible: root.showMem
                text: "•"
                color: Theme.glassBorder
                font.pixelSize: Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter
            }

            // RAM Stats (Only visible when > 60%)
            RowLayout {
                visible: root.showMem
                spacing: Theme.scaled(4)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: ""
                    color: Theme.powerGreen
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.mem + "%"
                    color: Theme.fontColor
                    font.pixelSize: Theme.fontSize
                    font.family: "JetBrains Mono"
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Dot Separator for Temp (Visible when Temp > 90°C)
            Text {
                visible: root.showTemp
                text: "•"
                color: Theme.glassBorder
                font.pixelSize: Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter
            }

            // Temp Stats (Only visible when > 90°C)
            RowLayout {
                visible: root.showTemp
                spacing: Theme.scaled(4)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: ""
                    color: Theme.powerYellow
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.temp + "°C"
                    color: Theme.fontColor
                    font.pixelSize: Theme.fontSize
                    font.family: "JetBrains Mono"
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
