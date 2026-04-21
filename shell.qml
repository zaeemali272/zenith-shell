//@ pragma UseQApplication
import QtQml 2.15
import Quickshell
import "bar/"
import "bar/Menu"
import "bar/Menu/components"
import "services/"
import "windows" as Windows

Scope {
// We need to reference both the Battery and the Notification services
// to ensure they start listening for system events.
readonly property var _notifications: NotificationService // Add this!
    Bar {
        id: bar
        controlCenterMenuRef: controlCenter
    }

    ControlCenter {
        id: controlCenter
        parentWindow: bar
        Component.onCompleted: CenterState.menuRef = controlCenter
    }

    QuickSettingsMenu {
        id: quickSettingsMenu
        parentWindow: bar
        Component.onCompleted: QuickSettingsService.menuRef = quickSettingsMenu
    }

    NotificationPopup {
        id: notificationPopup
    }

    OsdPopup {
        id: osdPopup
    }
}