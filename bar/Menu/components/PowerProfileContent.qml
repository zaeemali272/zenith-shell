import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        entryAnim.start();
    }
    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 500; easing.type: Theme.elasticEasing }
    }

    Text {
        text: "POWER PROFILES"
        color: Theme.mauve
        font.pixelSize: Theme.scaled(10)
        font.weight: Font.Black
        font.letterSpacing: 2
        Layout.leftMargin: Theme.scaled(5)
    }

    GridLayout {
        columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(15)
        columnSpacing: Theme.scaled(15)

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", color: Theme.powerRed, label: "PERFORMANCE" },
                { id: "balanced",    icon: "󰏤", color: Theme.blue, label: "BALANCED" },
                { id: "powersave",   icon: "󰍛", color: Theme.powerGreen, label: "POWERSAVE" },
                { id: "turbo",       icon: "󰞃", color: Theme.powerYellow, label: "TURBO" }
            ]

            delegate: Rectangle {
                id: profileCard
                Layout.fillWidth: true
                height: Theme.scaled(90)
                // Add margins to prevent border clipping
                anchors.margins: Theme.scaled(2)
                color: PowerProfileService.currentProfile === modelData.id ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.15) : Qt.rgba(0,0,0,0.2)
                radius: Theme.scaled(20)
                border.width: 1
                border.color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.glassBorder
                
                scale: m.pressed ? 0.95 : (m.containsMouse ? 1.0 : 0.95)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Theme.elasticEasing } }
                Behavior on color { ColorAnimation { duration: 300 } }

                MouseArea {
                    id: m
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: PowerProfileService.setProfile(modelData.id)
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.scaled(15); spacing: Theme.scaled(15)
                    
                    Rectangle {
                        width: Theme.scaled(45); height: Theme.scaled(45); radius: Theme.scaled(12)
                        color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Qt.rgba(1,1,1,0.05)
                        Text { 
                            anchors.centerIn: parent; text: modelData.icon; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20)
                            color: PowerProfileService.currentProfile === modelData.id ? Theme.base : modelData.color 
                        }
                    }

                    ColumnLayout {
                        spacing: Theme.scaled(2)
                        Text { text: modelData.label; font.pixelSize: Theme.scaled(12); font.weight: Font.Black; color: Theme.text }
                        Text { 
                            text: PowerProfileService.currentProfile === modelData.id ? "ACTIVE" : "STDBY"
                            font.pixelSize: Theme.scaled(8); font.weight: Font.Black; color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.surface2 
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}