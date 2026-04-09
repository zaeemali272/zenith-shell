import ".."
import "../.."
import "../../Settings"
import "../../services" 
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

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: clock.color = Theme.pillHoverColor
        onExited: clock.color = Theme.pillColor
        onClicked: {
            CenterState.toggle();
        }
    }

}
