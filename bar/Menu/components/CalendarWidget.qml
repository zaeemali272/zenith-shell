import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts

Rectangle {
    id: root

    // --- State Management ---
    property date today: new Date()
    property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: new Date()

    function nextMonth() {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1);
    }

    function prevMonth() {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1);
    }

    // Tightened height
    implicitHeight: 300
    implicitWidth: 350
    color: "#181825"
    radius: 12
    border.color: "#313244"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 8 // Reduced spacing between header and grid

        // --- HEADER: Navigation ---
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                color: "#cdd6f4"
                font.pixelSize: 16 // Slightly smaller font
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 2

                Button {
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: root.prevMonth()

                    contentItem: Text {
                        text: "󰁍"
                        color: "#f5c2e7"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#313244" : "transparent"
                        radius: 4
                    }

                }

                Button {
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: root.nextMonth()

                    contentItem: Text {
                        text: "󰁔"
                        color: "#f5c2e7"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#313244" : "transparent"
                        radius: 4
                    }

                }

            }

        }

        // --- DAY HEADERS ---
        RowLayout {
            Layout.fillWidth: true

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                delegate: Label {
                    text: modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: "#94e2d5"
                    font.pixelSize: 11
                    font.bold: true
                }

            }

        }

        // --- CALENDAR GRID ---
        GridLayout {
            id: calendarGrid

            columns: 7
            rows: 6
            columnSpacing: 2
            rowSpacing: 2
            Layout.fillWidth: true
            // Fixed height prevents the grid from stretching vertically
            Layout.preferredHeight: 220
            Layout.alignment: Qt.AlignTop

            Repeater {
                model: 42

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
                    radius: 6
                    color: isSelected ? "#45475a" : (isToday ? "#313244" : (mouseArea.containsMouse ? "#1e1e2e" : "transparent"))
                    border.color: isToday ? "#f5c2e7" : (isSelected ? "#cdd6f4" : "transparent")

                    Label {
                        anchors.centerIn: parent
                        text: dayCell.dateValue.getDate()
                        font.pixelSize: 12
                        font.bold: dayCell.isToday || dayCell.isSelected
                        color: !dayCell.isCurrentMonth ? "#585b70" : (dayCell.isToday ? "#f5c2e7" : "#cdd6f4")
                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.selectedDate = dayCell.dateValue
                    }

                }

            }

        }

        // Spacer to push everything to the top and prevent middle-stretching
        Item {
            Layout.fillHeight: true
        }

    }

}
