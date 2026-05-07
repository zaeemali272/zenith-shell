import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../../services"
import "../../../"

Flickable {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentHeight: mainLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: Theme.scaled(16)

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.scaled(4)
            Layout.rightMargin: Theme.scaled(4)

            Label {
                text: "Notifications"
                color: Theme.text
                font.pixelSize: Theme.scaled(18)
                font.bold: true
            }

            Rectangle {
                width: Theme.scaled(22); height: Theme.scaled(22); radius: Theme.scaled(6)
                color: Theme.surface1
                Label {
                    anchors.centerIn: parent
                    text: NotificationService.notifications.count
                    color: Theme.blue
                    font.pixelSize: Theme.scaled(11); font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                id: fullscreenBtn
                flat: true
                padding: Theme.scaled(8)
                contentItem: RowLayout {
                    spacing: Theme.scaled(4)
                    Text {
                        text: GeneralSettings.fullscreenNotification ? "󰊓" : "󰊔"
                        font.family: Theme.iconFont
                        color: GeneralSettings.fullscreenNotification ? Theme.blue : Theme.surface2
                        font.pixelSize: Theme.scaled(14)
                    }
                    Text {
                        text: "Notify"
                        color: fullscreenBtn.hovered ? Theme.text : Theme.surface2
                        font.pixelSize: Theme.scaled(11); font.bold: true
                    }
                }
                background: Rectangle { 
                    color: fullscreenBtn.hovered ? Theme.surface1 : "transparent"
                    radius: Theme.scaled(8) 
                }
                onClicked: GeneralSettings.fullscreenNotification = !GeneralSettings.fullscreenNotification
            }

            Button {
                id: osdFullscreenBtn
                flat: true
                padding: Theme.scaled(8)
                contentItem: RowLayout {
                    spacing: Theme.scaled(4)
                    Text {
                        text: GeneralSettings.fullscreenOSD ? "󰊓" : "󰊔"
                        font.family: Theme.iconFont
                        color: GeneralSettings.fullscreenOSD ? Theme.blue : Theme.surface2
                        font.pixelSize: Theme.scaled(14)
                    }
                    Text {
                        text: "OSD"
                        color: osdFullscreenBtn.hovered ? Theme.text : Theme.surface2
                        font.pixelSize: Theme.scaled(11); font.bold: true
                    }
                }
                background: Rectangle { 
                    color: osdFullscreenBtn.hovered ? Theme.surface1 : "transparent"
                    radius: Theme.scaled(8) 
                }
                onClicked: GeneralSettings.fullscreenOSD = !GeneralSettings.fullscreenOSD
            }

            Button {
                id: clearBtn
                flat: true
                padding: Theme.scaled(8)
                contentItem: Text {
                    text: "Clear All"
                    color: clearBtn.hovered ? Theme.powerRed : Theme.surface2
                    font.pixelSize: Theme.scaled(12); font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle { 
                    color: clearBtn.hovered ? Theme.surface1 : "transparent"
                    radius: Theme.scaled(8) 
                }
                onClicked: NotificationService.clearAll()
            }
        }

        // The List
        ColumnLayout {
            id: notificationsColumn
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            Repeater {
                model: NotificationService.notifications
                delegate: NotificationItem {
                    notification: NotificationService.notifications.get(index)
                    Layout.fillWidth: true
                    enableAutoDismiss: false
                }
            }
        }

        // Empty State
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.scaled(200)
            visible: NotificationService.notifications.count === 0
            Layout.alignment: Qt.AlignHCenter 
            spacing: Theme.scaled(8)
            opacity: 0.5
            
            Text {
                text: "󰂚"
                font.pixelSize: Theme.scaled(80)
                color: Theme.surface1
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: "All caught up"
                color: Theme.surface2
                font.pixelSize: Theme.scaled(13)
                Layout.alignment: Qt.AlignCenter
            }
        }

        Item { Layout.fillHeight: true }
    }
}