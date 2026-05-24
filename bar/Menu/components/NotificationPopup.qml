import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."

PanelWindow {
    id: popupStack

    readonly property bool useFullscreenLayout: GeneralSettings.fullscreenNotification
    readonly property bool isFullscreen: HyprlandService.isFullscreen


    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Standard popup position (top-right)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: popupStack.isFullscreen ? (osdPopup.visible ? Theme.scaled(40) : - bar.height) : (osdPopup.visible ? Theme.scaled(105) : Theme.scaled(10))
        right: popupStack.isFullscreen ? Theme.scaled(5) : Theme.scaled(10)
    }

    implicitWidth: Theme.scaled(400)
    // Use a stable height to avoid Wayland resize overhead during hover expansion
    implicitHeight: activeNotifications.count > 0 ? Theme.scaled(800) : 0
    
    visible: activeNotifications.count > 0 && (!popupStack.isFullscreen || popupStack.useFullscreenLayout)
    color: "transparent"

    // Only capture input where notifications actually are
    mask: Region {
        item: mainColumn
    }

    ListModel {
        id: activeNotifications
    }

    // The layout remains "the same"
    ColumnLayout {
        id: mainColumn
        width: Theme.scaled(400)
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
