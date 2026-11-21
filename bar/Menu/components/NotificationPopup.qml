import "../../../services"
import "../../../Settings"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."

PanelWindow {
    id: popupStack

    readonly property bool useFullscreenLayout: NotificationSettings.fullscreenNotification
    readonly property bool isFullscreen: HyprlandService.isFullscreen

    property bool isInputActive: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: popupStack.isInputActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Standard popup position (top-right)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: osdPopup.visible ? (osdPopup.implicitHeight + Theme.scaled(16)) : Theme.scaled(10)
        right: Theme.scaled(10)
    }

    implicitWidth: Theme.scaled(400)
    // Stable height to avoid Wayland resize overhead during hover expansion
    implicitHeight: activeNotifications.count > 0 ? Theme.scaled(800) : 0
    
    visible: !LockService.locked && activeNotifications.count > 0 && (!popupStack.isFullscreen || popupStack.useFullscreenLayout)
    color: "transparent"

    // Only capture input where notifications actually are
    mask: Region {
        item: mainColumn
    }

    ListModel {
        id: activeNotifications
    }

    ColumnLayout {
        id: mainColumn
        width: Theme.scaled(400)
        spacing: Theme.scaled(10)

        Repeater {
            id: notifRepeater
            model: activeNotifications
            delegate: NotificationItem {
                notification: activeNotifications.get(index)
                Layout.fillWidth: true

                onIsReplyingChanged: {
                    let active = false;
                    for (let i = 0; i < notifRepeater.count; i++) {
                        let it = notifRepeater.itemAt(i);
                        if (it && it.isReplying) { active = true; break; }
                    }
                    popupStack.isInputActive = active;
                }
            }
        }
    }

    Connections {
        target: NotificationService
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
            let active = false;
            for (let i = 0; i < notifRepeater.count; i++) {
                let it = notifRepeater.itemAt(i);
                if (it && it.isReplying) { active = true; break; }
            }
            popupStack.isInputActive = active;
        }
    }
}
