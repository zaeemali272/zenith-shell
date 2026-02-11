//@ pragma UseQApplication
import Quickshell
import "bar/"
import "services/" // Make sure to import the folder where the services are

Scope {
    // This forces the notification service to initialize and start listening
    readonly property var _auth: BatteryNotify

    Bar {
    }

}
