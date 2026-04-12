import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: popupStack

    anchor.window: bar
    anchor.edges: Edges.Top | Edges.Right
    anchor.rect.y: bar.height + (osdPopup.visible ? 105 : 10)
    anchor.rect.x: bar.width - implicitWidth - 5

    // Width and height logic
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
        // FIX: Ensure notifications are centered horizontally in the popup window
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            // --- FALLBACK LOGIC ---
            // Inside your NotificationItem.qml, the Image component should have:
            // onStatusChanged: { if (status === Image.Error) source = model.fallbackIcon }

            model: activeNotifications

            delegate: NotificationItem {
                id: delegateRoot
                notification: activeNotifications.get(index)
                Layout.fillWidth: true
                
                onAutoDismissed: (id) => NotificationService.removeNotification(id)
            }

        }

    }

    Connections {
        function onNotificationReceived(notifData) {
            activeNotifications.append(notifData);
        }

        function onNotificationDismissed(id) {
            for (let i = 0; i < activeNotifications.count; i++) {
                if (activeNotifications.get(i).id === id) {
                    activeNotifications.remove(i);
                    break;
                }
            }
        }

        target: NotificationService
    }

}
