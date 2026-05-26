import ".."
import "Center"
import QtQuick
import Quickshell
import "../services"

Row {
    id: root
    property var controlCenterMenuRef: null

    Component.onCompleted: {
        console.log("Center.qml controlCenterMenuRef on creation:", controlCenterMenuRef);
    }
    spacing: Theme.pillSpacing

    // Timer Widget
    Rectangle {
        visible: ProductivityService.activeTimer !== null
        width: timerText.implicitWidth + 20; height: Theme.pillHeight; radius: Theme.pillRadius
        color: Theme.blue
        anchors.verticalCenter: parent.verticalCenter
        Text {
            id: timerText
            anchors.centerIn: parent
            text: ProductivityService.activeTimer ? Math.floor(ProductivityService.activeTimer.remaining / 60) + ":" + (ProductivityService.activeTimer.remaining % 60).toString().padStart(2, '0') : ""
            font.weight: Font.Black; font.pixelSize: 10; color: Theme.base
        }
    }

    Clock {
        id: clock

        controlCenterMenuRef: root.controlCenterMenuRef
    }

    Media {
    }

}
