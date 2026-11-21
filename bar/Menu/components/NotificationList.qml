import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../../services"
import "../../../"

Flickable {
    FastWheel {}
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentHeight: mainLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        width: 3
        contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
    }

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: Theme.scaled(16)

        // The List
        ColumnLayout {
            id: notificationsColumn
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            Repeater {
                model: NotificationService.notifications
                delegate: NotificationItem {
                    notification: NotificationService.notifications.get(index)
                    itemIndex: index
                    Layout.fillWidth: true
                    enableAutoDismiss: false
                    animateOut: false
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
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(80)
                color: Theme.surface1
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: "All caught up"
                color: Theme.text
                font.pixelSize: Theme.scaled(13)
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: "No pending desktop notifications"
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(10)
                Layout.alignment: Qt.AlignCenter
            }
        }

        Item { Layout.fillHeight: true }
    }

    function resetScroll() {
        root.contentY = 0;
    }
}