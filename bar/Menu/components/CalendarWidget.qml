import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../Settings"
import "../../../services" as Services

Rectangle {
    id: root
    property date today: new Date()
    property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: new Date()
    property var eventData: []
    property bool showAllEvents: false

    property int lastFetchedYear: today.getFullYear()
    property string countryCode: Services.Variables.countryCode || "PK"
    property string countryName: Services.Variables.countryName || "Pakistan"

    function nextMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1) }
    function prevMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1) }
    function toggleEvents() { showAllEvents = !showAllEvents }

    function fetchEvents() {
        let year = root.viewDate.getFullYear();
        fetchProcess.command = ['bash', PathSettings.scriptsDir + '/fetch_events.sh', year.toString(), root.countryCode];
        fetchProcess.running = false;
        fetchProcess.running = true;
    }

    onViewDateChanged: fetchEvents()

    Process {
        id: fetchProcess
        command: ['bash', PathSettings.scriptsDir + '/fetch_events.sh', root.today.getFullYear().toString(), root.countryCode]
        onExited: {
            readProcess.running = false;
            readProcess.running = true;
        }
    }

    Process {
        id: readProcess
        command: ['cat', PathSettings.shellDir + '/events.json']
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    try {
                        let parsed = JSON.parse(text);
                        if (Array.isArray(parsed)) {
                            root.eventData = parsed;
                        }
                    } catch (e) {}
                }
            }
        }
    }

    Component.onCompleted: fetchEvents()

    implicitHeight: Theme.scaled(310)
    implicitWidth: Theme.scaled(340)
    color: Theme.menuBackground
    radius: Theme.scaled(16)
    border.color: Theme.surface1
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(16)
        spacing: Theme.scaled(10)

        // Header Section
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 0
                Label {
                    text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                    color: Theme.text
                    font.pixelSize: Theme.scaled(17)
                    font.weight: Font.Bold
                }
                Label {
                    text: "📍 " + root.countryName + " (" + root.countryCode + ")"
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }
            
            // Events Toggle Button
            Button {
                flat: true
                implicitWidth: Theme.scaled(72)
                implicitHeight: Theme.scaled(30)
                onClicked: root.toggleEvents()
                background: Rectangle {
                    color: root.showAllEvents ? Theme.accentColor : Theme.surface0
                    radius: Theme.scaled(8)
                    border.color: Theme.glassBorder
                    border.width: 1
                }
                contentItem: Text {
                    text: root.showAllEvents ? "Calendar" : "Holidays"
                    color: root.showAllEvents ? "#ffffff" : Theme.accentColor
                    font.pixelSize: Theme.scaled(11)
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Month Navigation Buttons
            RowLayout {
                spacing: Theme.scaled(4)
                Button {
                    flat: true; implicitWidth: Theme.scaled(30); implicitHeight: Theme.scaled(30)
                    onClicked: root.prevMonth()
                    background: Rectangle { color: parent.hovered ? Theme.surface1 : "transparent"; radius: Theme.scaled(6) }
                    contentItem: Text { text: "󰁍"; color: Theme.subtext0; font.pixelSize: Theme.scaled(15); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    flat: true; implicitWidth: Theme.scaled(30); implicitHeight: Theme.scaled(30)
                    onClicked: root.nextMonth()
                    background: Rectangle { color: parent.hovered ? Theme.surface1 : "transparent"; radius: Theme.scaled(6) }
                    contentItem: Text { text: "󰁔"; color: Theme.subtext0; font.pixelSize: Theme.scaled(15); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }

        // Main Overlay Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Event List Overlay View
            Rectangle {
                visible: root.showAllEvents
                anchors.fill: parent
                color: Theme.menuBackground

                ScrollView {
                    anchors.fill: parent
                    clip: true

                    ListView {
                        width: parent.width
                        spacing: Theme.scaled(6)
                        model: root.eventData || []
                        delegate: Rectangle {
                            width: ListView.view.width - Theme.scaled(8)
                            height: Theme.scaled(40)
                            radius: Theme.scaled(8)
                            color: Theme.surface0
                            border.color: Theme.glassBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.scaled(8)
                                spacing: Theme.scaled(8)

                                Rectangle {
                                    width: Theme.scaled(6); height: Theme.scaled(22)
                                    radius: Theme.scaled(3)
                                    color: Theme.accentColor
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        text: modelData.name
                                        color: Theme.text
                                        font.bold: true
                                        font.pixelSize: Theme.scaled(11)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.date
                                        color: Theme.subtext0
                                        font.pixelSize: Theme.scaled(9)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Calendar Grid View
            GridLayout {
                id: calendarGrid
                visible: !root.showAllEvents
                anchors.fill: parent
                columns: 7
                columnSpacing: Theme.scaled(4)
                rowSpacing: Theme.scaled(4)

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    delegate: Label {
                        text: modelData; Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.subtext1; font.pixelSize: Theme.scaled(11); font.weight: Font.Black
                    }
                }

                Repeater {
                    model: 35
                    delegate: Rectangle {
                        id: dayCell
                        readonly property var dateValue: {
                            let firstDay = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth(), 1);
                            return new Date(root.viewDate.getFullYear(), root.viewDate.getMonth(), index - firstDay.getDay() + 1);
                        }
                        
                        readonly property bool isToday: dateValue.toDateString() === root.today.toDateString()
                        readonly property bool isSelected: dateValue.toDateString() === root.selectedDate.toDateString()
                        readonly property bool isCurrentMonth: dateValue.getMonth() === root.viewDate.getMonth()
                        readonly property var dayEvents: {
                            let dateStr = Qt.formatDate(dateValue, "yyyy-MM-dd");
                            return root.eventData.filter(e => e.date === dateStr);
                        }
                        readonly property bool hasEvent: dayEvents.length > 0

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.scaled(8)

                        color: {
                            if (!isCurrentMonth) return "transparent";
                            if (hasEvent) return Theme.accentColor;
                            if (isToday) return Theme.surface1;
                            return "transparent";
                        }

                        border.color: {
                            if (isSelected) return "#ffffff";
                            if (isToday) return Theme.accentColor;
                            return "transparent";
                        }
                        border.width: isSelected || isToday ? 2 : 0

                        Label {
                            anchors.centerIn: parent
                            text: dayCell.dateValue.getDate()
                            font.pixelSize: Theme.scaled(12)
                            font.bold: dayCell.isToday || dayCell.isSelected || dayCell.hasEvent
                            color: {
                                if (!dayCell.isCurrentMonth) return Theme.surface2;
                                if (dayCell.hasEvent) return "#ffffff";
                                if (dayCell.isToday) return Theme.accentColor;
                                return Theme.text;
                            }
                        }

                        MouseArea { 
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectedDate = dayCell.dateValue
                        }
                    }
                }
            }
        }
        
        // Selected Date Event Inspector Footer
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.scaled(32)
            color: Theme.surface0
            radius: Theme.scaled(8)
            visible: !root.showAllEvents
            border.color: Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(6)
                spacing: Theme.scaled(8)

                Text {
                    text: Qt.formatDate(root.selectedDate, "yyyy-MM-dd")
                    color: Theme.subtext0
                    font.bold: true
                    font.pixelSize: Theme.scaled(10)
                }

                Text {
                    id: selectedEventLabel
                    Layout.fillWidth: true
                    text: {
                        let dateStr = Qt.formatDate(root.selectedDate, "yyyy-MM-dd");
                        let events = root.eventData.filter(e => e.date === dateStr);
                        if (events.length === 0) return "No official holidays";
                        return events.map(e => e.name).join(" | ");
                    }
                    color: {
                        let dateStr = Qt.formatDate(root.selectedDate, "yyyy-MM-dd");
                        let events = root.eventData.filter(e => e.date === dateStr);
                        return events.length > 0 ? Theme.accentColor : Theme.subtext1;
                    }
                    font.bold: true
                    font.pixelSize: Theme.scaled(11)
                    elide: Text.ElideRight
                }
            }
        }
    }
}
