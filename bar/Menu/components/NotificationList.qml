import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications

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
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Notifications (" + NotificationService.notifications.count + ")"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Clear All"
                flat: true
                onClicked: {
                    NotificationService.clearAll();
                }
            }

        }

        ColumnLayout {
            id: notificationsColumn

            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: NotificationService.notifications

                delegate: NotificationItem {
                    // When using ListModel, we get properties directly
                    // but we can also use model if we want the object
                    notification: model
                    Layout.fillWidth: true
                    Component.onCompleted: {
                        console.log("NotificationItem created in List for:", notification ? notification.summary : "null");
                    }
                }

            }

        }

        Text {
            Layout.alignment: Qt.AlignCenter
            text: "No Notifications"
            color: "#444444"
            visible: NotificationService.notifications.count === 0
            font.pixelSize: 16
        }

        Item {
            Layout.fillHeight: true
        }

    }

}
