//@ pragma UseQApplication
import QtQml 2.15
import Quickshell
import "bar/"
import "bar/Menu"
import "bar/Menu/components"
import "services/"

Scope {
    // This forces the notification service to initialize and start listening
    readonly property var _auth: BatteryNotify

    Bar {
        id: bar

        controlCenterMenuRef: controlCenter
    }

    ControlCenter {
        id: controlCenter
    }

    NotificationPopup {
        id: notificationPopup
    }

    OsdPopup {
        id: osdPopup
    }

}
