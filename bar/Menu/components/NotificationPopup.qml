import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: popupStack

    anchor.window: bar
    anchor.edges: Edges.Top | Edges.Right
    anchor.rect.x: 4
    anchor.rect.y: bar.height + (osdPopup.visible ? 100 : 10)
    implicitWidth: 350
    implicitHeight: mainColumn.implicitHeight
    visible: activeNotifications.count > 0
    color: "transparent"

    ListModel {
        id: activeNotifications
    }

    ColumnLayout {
        id: mainColumn

        width: 350
        spacing: 10

        Repeater {
            model: activeNotifications

            delegate: NotificationItem {
                notification: model
                Layout.fillWidth: true
                Component.onCompleted: {
                    let id = model.id;
                    const t = Qt.createQmlObject("import QtQuick 2.15; Timer { interval: 5000; running: true }", this);
                    t.triggered.connect(() => {
                        for (let i = 0; i < activeNotifications.count; i++) {
                            if (activeNotifications.get(i).id === id) {
                                activeNotifications.remove(i);
                                break;
                            }
                        }
                    });
                }
            }

        }

    }

    Connections {
        function onNotificationReceived(notifData) {
            activeNotifications.append(notifData);
        }

        target: NotificationService
    }

}
