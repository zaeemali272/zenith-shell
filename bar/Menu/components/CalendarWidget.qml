import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../Settings"

Rectangle {
    id: root
    property date today: new Date()
    property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: new Date()
    property var eventData: []
    property bool showAllEvents: false

    property int lastFetchedYear: today.getFullYear()

    function nextMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1) }
    function prevMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1) }
    function toggleEvents() { showAllEvents = !showAllEvents }

    function fetchEvents() {
        let year = root.viewDate.getFullYear();
        if (year === lastFetchedYear) return;
        
        lastFetchedYear = year;
        fetchProcess.command = ['bash', PathSettings.scriptsDir + '/fetch_events.sh', year.toString()];
        fetchProcess.running = true;
    }

    onViewDateChanged: {
        fetchEvents();
    }

    Process {
        id: fetchProcess
        command: ['bash', PathSettings.scriptsDir + '/fetch_events.sh', root.today.getFullYear().toString()]
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
                        eventData = JSON.parse(text);
                    } catch (e) {
                        console.log("Error parsing events: " + e);
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        fetchProcess.running = true;
    }

    implicitHeight: Theme.scaled(290)
    implicitWidth: Theme.scaled(320)
    color: Theme.menuBackground
    radius: Theme.scaled(16)
    border.color: Theme.surface1
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(20)
        spacing: Theme.scaled(12)

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                color: Theme.text
                font.pixelSize: Theme.scaled(18); font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            
            Button {
                flat: true; implicitWidth: Theme.scaled(60); implicitHeight: Theme.scaled(32)
                onClicked: root.toggleEvents()
                background: Rectangle { color: root.showAllEvents ? Theme.surface1 : "transparent"; radius: Theme.scaled(8) }
                contentItem: Text { text: "Events"; color: Theme.blue; font.pixelSize: Theme.scaled(12); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }

            RowLayout {
                spacing: Theme.scaled(8)
                Button {
                    flat: true; implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                    onClicked: root.prevMonth()
                    background: Rectangle { color: parent.hovered ? Theme.surface1 : "transparent"; radius: Theme.scaled(8) }
                    contentItem: Text { text: "󰁍"; color: Theme.blue; font.pixelSize: Theme.scaled(16); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    flat: true; implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                    onClicked: root.nextMonth()
                    background: Rectangle { color: parent.hovered ? Theme.surface1 : "transparent"; radius: Theme.scaled(8) }
                    contentItem: Text { text: "󰁔"; color: Theme.blue; font.pixelSize: Theme.scaled(16); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }

        // Overlay Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Event List Overlay
            Rectangle {
                visible: root.showAllEvents
                anchors.fill: parent
                color: Theme.menuBackground
                Column {
                    anchors.fill: parent
                    padding: Theme.scaled(10)
                    spacing: Theme.scaled(5)
                    Repeater {
                        model: root.eventData
                        delegate: Label {
                            text: modelData.date + ": " + modelData.name
                            color: Theme.text
                            font.pixelSize: Theme.scaled(11)
                        }
                        }
                        }
                        }
            // Calendar Grid
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
                        readonly property bool hasEvent: {
                            let dateStr = Qt.formatDate(dateValue, "yyyy-MM-dd");
                            return root.eventData.some(e => e.date === dateStr);
                        }

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.scaled(8)
                        color: isSelected ? Theme.blue : (hasEvent && isCurrentMonth ? Qt.alpha(Theme.blue, 0.2) : (isToday ? Theme.surface1 : "transparent"))
                        border.color: isSelected ? "transparent" : (isToday ? Theme.blue : (hasEvent && isCurrentMonth ? Theme.blue : "transparent"))
                        border.width: isSelected ? 0 : 1

                        Label {
                            anchors.centerIn: parent
                            text: dayCell.dateValue.getDate()
                            font.pixelSize: Theme.scaled(12)
                            font.bold: dayCell.isToday || dayCell.isSelected || dayCell.hasEvent
                            color: !dayCell.isCurrentMonth ? Theme.surface2 : (dayCell.isSelected ? Theme.menuBackground : (dayCell.isToday || dayCell.hasEvent ? Theme.blue : Theme.text))
                        }

                        MouseArea { 
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { root.selectedDate = dayCell.dateValue }
                        }
                    }
                }
            }
        }
        
        Label {
            Layout.fillWidth: true
            visible: !root.showAllEvents
            text: {
                let dateStr = Qt.formatDate(root.selectedDate, "yyyy-MM-dd");
                let events = root.eventData.filter(e => e.date === dateStr);
                return events.length > 0 ? "Events: " + events.map(e => e.name).join(", ") : "No events"
            }
            color: Theme.subtext1
            font.pixelSize: Theme.scaled(10)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
