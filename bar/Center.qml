import ".."
import "Center"
import QtQuick
import Quickshell

Row {
    id: root
    property var controlCenterMenuRef: null

    Component.onCompleted: {
        console.log("Center.qml controlCenterMenuRef on creation:", controlCenterMenuRef);
    }
    spacing: Theme.pillSpacing

    Clock {
        id: clock

        controlCenterMenuRef: root.controlCenterMenuRef
    }

    Media {
    }

}
