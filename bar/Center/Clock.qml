import ".."
import "../.."
import "../../Settings"
import "../../services" // This was missing
import QtQuick
import Quickshell

Rectangle {
    id: clock

    property var controlCenterMenuRef: null

    visible: ClockSettings.showClock || ClockSettings.showDate
    radius: Theme.pillRadius
    color: Theme.pillColor
    implicitHeight: Theme.pillHeight
    width: clockText.implicitWidth + Theme.pillPadding

    SystemClock {
        id: systemClock

        precision: ClockSettings.precision
    }

    Text {
        id: clockText

        anchors.centerIn: parent
        color: Theme.fontColor
        font.pixelSize: Theme.fontSize
        text: {
            let parts = [];
            if (ClockSettings.showDate)
                parts.push(Qt.formatDateTime(systemClock.date, ClockSettings.dateFormat));

            if (ClockSettings.showClock) {
                let timeFmt = ClockSettings.use24Hour ? ClockSettings.timeFormat24h : ClockSettings.timeFormat12h;
                let timeStr = Qt.formatDateTime(systemClock.date, timeFmt);
                parts.push(timeStr);
            }
            return parts.join(" | ");
        }
    }

    MouseArea { // This entire block was missing
        anchors.fill: parent
        onClicked: {
            console.log("Clock MouseArea clicked!");
            if (controlCenterMenuRef) {
                console.log("controlCenterMenuRef is valid. Toggling Control Center visibility.");
                // Check if the property exists to stop the "non-existent property" error
                if (controlCenterMenuRef.hasOwnProperty("anchorItem"))
                    controlCenterMenuRef.anchorItem = clock;

                // Use the Singleton as the single source of truth for visibility
                CenterState.visible = !CenterState.visible;
                console.log("Control Center toggled via CenterState:", CenterState.visible);
            }
        }
    }

}