import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../../services"

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
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            Label {
                text: "Notifications"
                color: "#cdd6f4"
                font.pixelSize: 18
                font.bold: true
            }

            Rectangle {
                width: 22; height: 22; radius: 6
                color: "#313244"
                Label {
                    anchors.centerIn: parent
                    text: NotificationService.notifications.count
                    color: "#89b4fa"
                    font.pixelSize: 11; font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                id: clearBtn
                flat: true
                padding: 8
                contentItem: Text {
                    text: "Clear All"
                    color: clearBtn.hovered ? "#f38ba8" : "#585b70"
                    font.pixelSize: 12; font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle { 
                    color: clearBtn.hovered ? "#313244" : "transparent"
                    radius: 8 
                }
                onClicked: NotificationService.clearAll()
            }
        }

        // The List
        ColumnLayout {
            id: notificationsColumn
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: NotificationService.notifications
                delegate: NotificationItem {
                    notification: model
                    Layout.fillWidth: true
                }
            }
        }

        // Empty State
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            visible: NotificationService.notifications.count === 0
            Layout.alignment: Qt.AlignHCenter 
            spacing: 8
            opacity: 0.5
            
            Text {
                text: "󰂚"
                font.pixelSize: 80
                color: "#313244"
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: "All caught up"
                color: "#585b70"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignCenter
            }
        }

        Item { Layout.fillHeight: true }
    }
}