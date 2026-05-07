import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."

PanelWindow {
    id: popupStack

    readonly property bool useFullscreenLayout: GeneralSettings.fullscreenNotification && HyprlandService.isFullscreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Standard popup position (top-right)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: popupStack.useFullscreenLayout ? Theme.scaled(10) : (osdPopup.visible ? Theme.scaled(105) : Theme.scaled(10))
        right: osdWindow.useFullscreenLayout ? Theme.scaled(5) : Theme.scaled(10)
    }

    implicitWidth: Theme.scaled(370)
    implicitHeight: mainColumn.implicitHeight
    
    visible: activeNotifications.count > 0
    color: "transparent"

    ListModel {
        id: activeNotifications
    }

    // The layout remains "the same"
    ColumnLayout {
        id: mainColumn
        width: Theme.scaled(370)
        spacing: Theme.scaled(10)

        Repeater {
            model: activeNotifications
            delegate: NotificationItem {
                notification: activeNotifications.get(index)
                Layout.fillWidth: true
                onAutoDismissed: (id) => NotificationService.dismissNotification(id)
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
