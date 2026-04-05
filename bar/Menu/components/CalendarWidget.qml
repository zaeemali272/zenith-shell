import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts

Rectangle {
    id: root
    property date today: new Date()
    property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: new Date()

    function nextMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1) }
    function prevMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1) }

    implicitHeight: 290
    implicitWidth: 320
    color: "#11111b"
    radius: 16
    border.color: "#313244"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                color: "#cdd6f4"
                font.pixelSize: 18; font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: 8
                Button {
                    flat: true; implicitWidth: 32; implicitHeight: 32
                    onClicked: root.prevMonth()
                    background: Rectangle { color: parent.hovered ? "#313244" : "transparent"; radius: 8 }
                    contentItem: Text { text: "󰁍"; color: "#89b4fa"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    flat: true; implicitWidth: 32; implicitHeight: 32
                    onClicked: root.nextMonth()
                    background: Rectangle { color: parent.hovered ? "#313244" : "transparent"; radius: 8 }
                    contentItem: Text { text: "󰁔"; color: "#89b4fa"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Label {
                    text: modelData; Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: "#585b70"; font.pixelSize: 11; font.weight: Font.Black
                }
            }
        }

      GridLayout {
            id: calendarGrid
            columns: 7
            rows: 5 // Force 5 rows
            columnSpacing: 4
            rowSpacing: 4
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                // Change this from 42 to 35 to strictly show 5 weeks
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

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    
                    // Style matching Zenith
                    color: isSelected ? "#89b4fa" : (isToday ? "#313244" : "transparent")
                    border.color: isToday && !isSelected ? "#89b4fa" : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: dayCell.dateValue.getDate()
                        font.pixelSize: 12
                        font.bold: dayCell.isToday || dayCell.isSelected
                        color: !dayCell.isCurrentMonth ? "#45475a" : (dayCell.isSelected ? "#11111b" : (dayCell.isToday ? "#89b4fa" : "#cdd6f4"))
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
}