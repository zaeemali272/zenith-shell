import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 20
    Layout.fillWidth: true

    Text {
        text: "Performance Mode"
        color: "white"
        font.bold: true
        font.pixelSize: 22
    }

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 15
        columnSpacing: 15

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", color: "#f38ba8", label: "Performance" },
                { id: "balanced", icon: "󰏤", color: "#89b4fa", label: "Balanced" },
                { id: "powersave", icon: "󰍛", color: "#a6e3a1", label: "Power Save" },
                { id: "turbo", icon: "󰞃", color: "#f9e2af", label: "Turbo" }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 80
                color: PowerProfileService.currentProfile === modelData.id ? modelData.color : "#1e1e2e"
                radius: 20
                border.color: "#313244"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: PowerProfileService.setProfile(modelData.id)
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: PowerProfileService.currentProfile === modelData.id ? "rgba(0,0,0,0.1)" : "#2a2a32"
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: 20
                            color: PowerProfileService.currentProfile === modelData.id ? "black" : modelData.color
                        }
                    }

                    Text {
                        text: modelData.label
                        font.pixelSize: 15
                        font.bold: true
                        color: PowerProfileService.currentProfile === modelData.id ? "black" : "white"
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
