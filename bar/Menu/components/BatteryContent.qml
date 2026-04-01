import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 12

    Text {
        text: "Battery Status"
        font.pixelSize: 18
        font.bold: true
        color: Theme.fontColor
    }

    Rectangle {
        Layout.fillWidth: true
        height: 100
        color: "#1a1a1a"
        radius: 12
        border.color: Theme.borderColor
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: BatteryService.acOnline ? "󰂄" : "󰁹"
                font.family: Theme.iconFont
                font.pixelSize: 48
                color: BatteryService.acOnline ? Theme.chargingColor : (BatteryService.percentage > 20 ? Theme.highColor : Theme.criticalColor)
            }

            ColumnLayout {
                Text {
                    text: BatteryService.percentage + "%"
                    font.pixelSize: 32
                    font.bold: true
                    color: "white"
                }
                Text {
                    text: BatteryService.status
                    font.pixelSize: 14
                    color: "#888"
                }
            }
        }
    }
}
