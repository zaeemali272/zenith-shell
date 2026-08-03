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

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.scaled(6)

        Text {
            font.family: Theme.iconFont
            font.pixelSize: Theme.scaled(13)
            text: "󰥔"
            color: Theme.subtext0
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: ClockSettings.showDate
            color: Theme.fontColor
            font.pixelSize: Theme.fontSize
            font.weight: Font.Normal
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDateTime(systemClock.date, ClockSettings.dateFormat)
        }

        // Elegant Vertical Glass Separator
        Rectangle {
            visible: ClockSettings.showDate && ClockSettings.showClock
            width: 1
            implicitWidth: 1
            height: Theme.scaled(14)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Theme.scaled(2)
            Layout.rightMargin: Theme.scaled(2)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.0) }
                GradientStop { position: 0.5; color: Qt.rgba(255, 255, 255, 0.35) }
                GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
            }
        }

        Text {
            visible: ClockSettings.showClock
            color: Theme.fontColor
            font.pixelSize: Theme.fontSize
            font.weight: Font.Normal
            Layout.alignment: Qt.AlignVCenter
            text: {
                let parts = [];
                if (ClockSettings.showDate)
                    parts.push(Qt.formatDateTime(systemClock.date, ClockSettings.dateFormat));

                if (ClockSettings.showClock) {
                    let timeFmt = ClockSettings.use24Hour ? ClockSettings.timeFormat24h : ClockSettings.timeFormat12h;
                return Qt.formatDateTime(systemClock.date, timeFmt);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: 10 // Ensure MouseArea is on top for hover/click
        onEntered: {
            clock.color = Theme.pillHoverColor;
        }
        onExited: {
            clock.color = Theme.pillColor;
        }
        onClicked: {
            CenterState.toggle();
        }
    }

}
