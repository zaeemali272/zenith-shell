import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 12

    Text {
        text: "Power Profiles"
        font.pixelSize: 18
        font.bold: true
        color: Theme.fontColor
    }

    Repeater {
        model: ["performance", "balanced", "powersave", "turbo"]

        delegate: Rectangle {
            height: 45
            radius: 8
            color: PowerProfileService.currentProfile === modelData ? Theme.accentColor : "#1a1a1a"
            Layout.fillWidth: true

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: {
                        switch (modelData) {
                        case "performance": return "󰀦";
                        case "powersave": return "󰍛";
                        case "balanced": return "󰏤";
                        case "turbo": return "󰞃";
                        default: return "󰀄";
                        }
                    }
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: "white"
                }

                Text {
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    font.pixelSize: 13
                    color: "white"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PowerProfileService.setProfile(modelData)
            }
        }
    }
}
