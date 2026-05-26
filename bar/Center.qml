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
        visible: ProductivityService.running || ProductivityService.isBeeping
        width: timerText.implicitWidth + Theme.scaled(20); height: Theme.pillHeight; radius: Theme.pillRadius
        color: ProductivityService.isBeeping ? Theme.powerRed : (ProductivityService.running ? Theme.blue : Theme.surface1)
        anchors.verticalCenter: parent.verticalCenter
        
        // Add a simple pulse animation for when it's beeping
        SequentialAnimation on opacity {
            running: ProductivityService.isBeeping
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.5; duration: 500 }
            NumberAnimation { from: 0.5; to: 1.0; duration: 500 }
        }

        Text {
            id: timerText
            anchors.centerIn: parent
            text: {
                if (ProductivityService.isBeeping) return "󰂚 DONE";
                let m = Math.floor(ProductivityService.remaining / 60);
                let s = ProductivityService.remaining % 60;
                return m + ":" + s.toString().padStart(2, '0');
            }
            font.weight: Font.Black; font.pixelSize: Theme.scaled(11); 
            color: (ProductivityService.running || ProductivityService.isBeeping) ? Theme.base : Theme.text
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (ProductivityService.isBeeping) {
                    ProductivityService.dismissAlarm();
                } else {
                    CenterState.activeTab = "Pomodoro";
                    CenterState.toggle();
                }
            }
        }
    }

    Clock {
        id: clock

        controlCenterMenuRef: root.controlCenterMenuRef
    }

    Media {
        visible: !Theme.isSmallScreen
    }

}
