import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property var menuRef: null
    readonly property string currentProfile: PowerProfileService.currentProfile

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.implicitWidth

    Pill {
        id: pill

        anchors.fill: parent
        implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("powerprofile");
        }
        
        Behavior on color { ColorAnimation { duration: 300 } }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            Image {
                id: animatedIcon
                source: "../../assets/cat_f" + Math.floor(frameTimer.frameCount % 4) + ".png"
                width: Theme.iconSize
                height: Theme.iconSize
                Layout.preferredWidth: Theme.iconSize + 30
                Layout.preferredHeight: Theme.iconSize + 30
                fillMode: Image.PreserveAspectFit
            }

            Timer {
                id: frameTimer
                property int frameCount: 0
                interval: {
                    switch (currentProfile) {
                        case "performance": return 1000 / 12; // 12 frames/sec
                        case "powersave": return 1000 / 4;   // 4 frames/sec
                        case "balanced": return 1000 / 8;    // 8 frames/sec
                        case "turbo": return 1000 / 16;      // 16 frames/sec
                        default: return 250;
                    }
                }
                running: true
                repeat: true
                onTriggered: frameCount++
            }
        }
    }

}
