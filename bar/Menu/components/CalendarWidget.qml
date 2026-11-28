import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../Settings"
import "../../../services" as Services

Rectangle {
    id: root

    readonly property date today: Services.CalendarService.today
    property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: new Date(today.getFullYear(), today.getMonth(), today.getDate())

    property string viewMode: "grid" // "grid" | "agenda"
    property string agendaFilter: "all" // "all" | "personal" | "holidays"
    property bool monthPickerOpen: false
    property bool addFormOpen: false
    property string newEventCategory: "event"
    property int _dataRev: 0

    readonly property string selectedDateKey: Services.CalendarService.formatDateKey(selectedDate)
    readonly property bool isViewingCurrentMonth: viewDate.getFullYear() === today.getFullYear() && viewDate.getMonth() === today.getMonth()
    readonly property bool isTodaySelected: selectedDate.toDateString() === today.toDateString()

    readonly property var selectedDayEvents: {
        let _r = _dataRev;
        let _h = Services.CalendarService.holidays.length;
        let _c = Services.CalendarService.customEvents.length;
        let _s = GeneralSettings.showHolidays;
        return Services.CalendarService.eventsForDate(selectedDateKey);
    }

    readonly property var agendaEvents: {
        let _r = _dataRev;
        let _h = Services.CalendarService.holidays.length;
        let _c = Services.CalendarService.customEvents.length;
        let _s = GeneralSettings.showHolidays;
        return Services.CalendarService.upcomingEvents(agendaFilter);
    }

    readonly property var weekdayLabels: {
        let base = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
        let start = GeneralSettings.firstDayOfWeek;
        let out = [];
        for (let i = 0; i < 7; i++) {
            out.push(base[(start + i) % 7]);
        }
        return out;
    }

    readonly property int gridStartOffset: {
        let firstDay = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay();
        return (firstDay - GeneralSettings.firstDayOfWeek + 7) % 7;
    }

    function nextMonth() {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1);
    }
    function prevMonth() {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1);
    }
    function goToToday() {
        let now = Services.CalendarService.today;
        viewDate = new Date(now.getFullYear(), now.getMonth(), 1);
        selectedDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        monthPickerOpen = false;
        viewMode = "grid";
    }
    function categoryColor(cat, type) {
        if (type === "national") return Theme.yellow;
        if (type === "religious") return Theme.green;
        if (cat === "birthday") return Theme.mauve;
        if (cat === "reminder") return Theme.blue;
        return Theme.accentColor;
    }

    onViewDateChanged: Services.CalendarService.ensureYearLoaded(viewDate.getFullYear())

    Connections {
        target: Services.CalendarService
        function onDataUpdated() { root._dataRev++; }
    }

    Component.onCompleted: Services.CalendarService.ensureYearLoaded(viewDate.getFullYear())

    implicitHeight: Theme.scaled(360)
    implicitWidth: Theme.scaled(360)
    color: "transparent"
    radius: Theme.scaled(16)
    border.color: Theme.glassBorder
    border.width: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(12)
        spacing: Theme.scaled(8)

        // --- HEADER ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(6)

            // Month & Year Picker Trigger (No location shown)
            Rectangle {
                id: monthPickerBtn
                implicitWidth: monthLabelRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(30)
                radius: Theme.scaled(8)
                color: monthPickerMouse.containsMouse || root.monthPickerOpen
                    ? Theme.cardBackgroundHover
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    id: monthLabelRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Label {
                        text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                        color: Theme.text
                        font.pixelSize: Theme.scaled(15)
                        font.weight: Font.Bold
                    }
                    Text {
                        text: root.monthPickerOpen ? "󰅃" : "󰅀"
                        font.family: Theme.iconFont
                        color: Theme.accentColor
                        font.pixelSize: Theme.scaled(14)
                    }
                }

                MouseArea {
                    id: monthPickerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthPickerOpen = !root.monthPickerOpen
                }
            }

            Item { Layout.fillWidth: true }

            // Jump to Today Pill
            Rectangle {
                visible: !root.isViewingCurrentMonth || !root.isTodaySelected || root.viewMode !== "grid"
                implicitWidth: todayTxt.implicitWidth + Theme.scaled(12)
                height: Theme.scaled(26)
                radius: Theme.scaled(7)
                color: todayMouse.containsMouse
                    ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.22)
                    : Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.12)
                border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.35)
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: todayTxt
                    anchors.centerIn: parent
                    text: "Today"
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToToday()
                }
            }

            // Grid / Agenda Switcher
            Rectangle {
                implicitWidth: viewBtnRow.implicitWidth + Theme.scaled(12)
                height: Theme.scaled(26)
                radius: Theme.scaled(7)
                color: root.viewMode === "agenda"
                    ? Theme.accentColor
                    : (viewModeMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                border.color: root.viewMode === "agenda" ? Theme.accentColor : Theme.glassBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    id: viewBtnRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Text {
                        text: root.viewMode === "agenda" ? "󰃭" : "󰃰"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(12)
                        color: root.viewMode === "agenda" ? Colors.on_primary : Theme.text
                    }
                    Text {
                        text: root.viewMode === "agenda" ? "Grid" : "Agenda"
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                        color: root.viewMode === "agenda" ? Colors.on_primary : Theme.text
                    }
                }

                MouseArea {
                    id: viewModeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.monthPickerOpen = false;
                        root.viewMode = (root.viewMode === "grid") ? "agenda" : "grid";
                    }
                }
            }

            // Prev / Next Month
            RowLayout {
                visible: root.viewMode === "grid" && !root.monthPickerOpen
                spacing: Theme.scaled(2)

                Rectangle {
                    width: Theme.scaled(26); height: Theme.scaled(26)
                    radius: Theme.scaled(7)
                    color: prevMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: prevMouse.containsMouse ? Theme.text : Theme.subtext0
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                Rectangle {
                    width: Theme.scaled(26); height: Theme.scaled(26)
                    radius: Theme.scaled(7)
                    color: nextMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: nextMouse.containsMouse ? Theme.text : Theme.subtext0
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }
        }

        // --- BODY ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. MONTH / YEAR QUICK PICKER
            ColumnLayout {
                visible: root.monthPickerOpen
                anchors.fill: parent
                spacing: Theme.scaled(8)

                RowLayout {
                    Layout.fillWidth: true
                    Rectangle {
                        width: Theme.scaled(28); height: Theme.scaled(28); radius: Theme.scaled(7)
                        color: yrPrevM.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                        Text { anchors.centerIn: parent; text: "󰅁"; font.family: Theme.iconFont; color: Theme.text; font.pixelSize: Theme.scaled(16) }
                        MouseArea { id: yrPrevM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.viewDate = new Date(root.viewDate.getFullYear() - 1, root.viewDate.getMonth(), 1) }
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.viewDate.getFullYear().toString()
                        color: Theme.text
                        font.pixelSize: Theme.scaled(15)
                        font.weight: Font.Black
                    }
                    Rectangle {
                        width: Theme.scaled(28); height: Theme.scaled(28); radius: Theme.scaled(7)
                        color: yrNextM.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                        Text { anchors.centerIn: parent; text: "󰅂"; font.family: Theme.iconFont; color: Theme.text; font.pixelSize: Theme.scaled(16) }
                        MouseArea { id: yrNextM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.viewDate = new Date(root.viewDate.getFullYear() + 1, root.viewDate.getMonth(), 1) }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    rowSpacing: Theme.scaled(6)
                    columnSpacing: Theme.scaled(6)

                    Repeater {
                        model: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                        delegate: Rectangle {
                            readonly property bool isCurrentViewMonth: root.viewDate.getMonth() === index
                            readonly property bool isRealCurrentMonth: root.today.getFullYear() === root.viewDate.getFullYear() && root.today.getMonth() === index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.scaled(8)
                            color: isCurrentViewMonth
                                ? Theme.accentColor
                                : (mPickMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                            border.color: isRealCurrentMonth && !isCurrentViewMonth ? Theme.accentColor : Theme.glassBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Theme.scaled(12)
                                font.weight: isCurrentViewMonth || isRealCurrentMonth ? Font.Bold : Font.Medium
                                color: isCurrentViewMonth ? Colors.on_primary : Theme.text
                            }

                            MouseArea {
                                id: mPickMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.viewDate = new Date(root.viewDate.getFullYear(), index, 1);
                                    root.monthPickerOpen = false;
                                }
                            }
                        }
                    }
                }
            }

            // 2. AGENDA / UPCOMING EVENTS VIEW
            ColumnLayout {
                visible: !root.monthPickerOpen && root.viewMode === "agenda"
                anchors.fill: parent
                spacing: Theme.scaled(8)

                // Filter Chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(6)
                    Repeater {
                        model: [
                            { id: "all", label: "All" },
                            { id: "personal", label: "Personal" },
                            { id: "holidays", label: "Holidays" }
                        ]
                        delegate: Rectangle {
                            readonly property bool active: root.agendaFilter === modelData.id
                            implicitWidth: chipTxt.implicitWidth + Theme.scaled(16)
                            height: Theme.scaled(24)
                            radius: 999
                            color: active ? Theme.accentColor : (chipM.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                            border.color: active ? Theme.accentColor : Theme.glassBorder
                            border.width: 1
                            Text {
                                id: chipTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Theme.scaled(10)
                                font.weight: Font.Bold
                                color: active ? Colors.on_primary : Theme.subtext0
                            }
                            MouseArea {
                                id: chipM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.agendaFilter = modelData.id
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.agendaEvents.length + " upcoming"
                        color: Theme.subtext2
                        font.pixelSize: Theme.scaled(10)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        visible: root.agendaEvents.length === 0
                        anchors.centerIn: parent
                        text: "No upcoming events"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(12)
                    }

                    ListView {
                        FastWheel {}
                        anchors.fill: parent
                        clip: true
                        spacing: Theme.scaled(6)
                        model: root.agendaEvents
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 3
                            contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
                        }
                        delegate: Rectangle {
                            width: ListView.view.width - Theme.scaled(6)
                            height: Theme.scaled(44)
                            radius: Theme.scaled(8)
                            color: agHover.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                            border.color: Theme.glassBorder
                            border.width: 1

                            MouseArea {
                                id: agHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let p = modelData.date.split("-");
                                    if (p.length === 3) {
                                        let d = new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]));
                                        root.viewDate = new Date(d.getFullYear(), d.getMonth(), 1);
                                        root.selectedDate = d;
                                        root.viewMode = "grid";
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.scaled(8)
                                spacing: Theme.scaled(8)

                                Rectangle {
                                    width: Theme.scaled(4)
                                    height: Theme.scaled(24)
                                    radius: 999
                                    color: root.categoryColor(modelData.category, modelData.type)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.name
                                        color: Theme.text
                                        font.weight: Font.Bold
                                        font.pixelSize: Theme.scaled(11)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.date + (modelData.time ? "  •  " + modelData.time : "") + "  •  " + Services.CalendarService.daysUntilLabel(modelData.date)
                                        color: Theme.subtext0
                                        font.pixelSize: Theme.scaled(9)
                                    }
                                }

                                Rectangle {
                                    visible: modelData.type === "personal"
                                    width: Theme.scaled(22); height: Theme.scaled(22)
                                    radius: Theme.scaled(6)
                                    color: delAgM.containsMouse ? Qt.rgba(Theme.powerRed.r, Theme.powerRed.g, Theme.powerRed.b, 0.2) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(12)
                                        color: delAgM.containsMouse ? Theme.powerRed : Theme.subtext0
                                    }
                                    MouseArea {
                                        id: delAgM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.CalendarService.removeEvent(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. MONTH GRID + INSPECTOR
            ColumnLayout {
                visible: !root.monthPickerOpen && root.viewMode === "grid"
                anchors.fill: parent
                spacing: Theme.scaled(6)

                // Calendar Grid (optional week column + 7x6 day grid)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.scaled(4)

                    MouseArea {
                        // Wheel scroll to navigate months
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        acceptedButtons: Qt.NoButton
                        onWheel: (wheel) => {
                            if (wheel.angleDelta.y > 0) root.prevMonth();
                            else if (wheel.angleDelta.y < 0) root.nextMonth();
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: Theme.scaled(4)

                            // Optional ISO Week Numbers Column
                            ColumnLayout {
                                visible: GeneralSettings.showWeekNumbers
                                Layout.fillHeight: true
                                Layout.preferredWidth: Theme.scaled(22)
                                spacing: Theme.scaled(3)

                                Label {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Theme.scaled(18)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "W"
                                    color: Theme.subtext2
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Bold
                                }

                                Repeater {
                                    model: 6
                                    delegate: Label {
                                        readonly property date rowDate: new Date(
                                            root.viewDate.getFullYear(),
                                            root.viewDate.getMonth(),
                                            (index * 7) - root.gridStartOffset + 1
                                        )
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: Services.CalendarService.isoWeekNumber(rowDate)
                                        color: Theme.subtext2
                                        font.pixelSize: Theme.scaled(9)
                                    }
                                }
                            }

                            // 7-Column Month Grid (7 headers + 42 days = 6 full weeks)
                            GridLayout {
                                id: calendarGrid
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 7
                                columnSpacing: Theme.scaled(3)
                                rowSpacing: Theme.scaled(3)

                                Repeater {
                                    model: root.weekdayLabels
                                    delegate: Label {
                                        text: modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Theme.scaled(18)
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        color: Theme.subtext1
                                        font.pixelSize: Theme.scaled(10)
                                        font.weight: Font.Black
                                    }
                                }

                                Repeater {
                                    model: 42
                                    delegate: Rectangle {
                                        id: dayCell
                                        readonly property date dateValue: new Date(
                                            root.viewDate.getFullYear(),
                                            root.viewDate.getMonth(),
                                            index - root.gridStartOffset + 1
                                        )
                                        readonly property string dateKey: Services.CalendarService.formatDateKey(dateValue)
                                        readonly property bool isToday: dateValue.toDateString() === root.today.toDateString()
                                        readonly property bool isSelected: dateValue.toDateString() === root.selectedDate.toDateString()
                                        readonly property bool isCurrentMonth: dateValue.getMonth() === root.viewDate.getMonth()
                                        readonly property bool hasPersonal: {
                                            let _r = root._dataRev;
                                            let _c = Services.CalendarService.customEvents.length;
                                            return Services.CalendarService.hasPersonalEvent(dateKey);
                                        }
                                        readonly property bool hasHoliday: {
                                            let _r = root._dataRev;
                                            let _h = Services.CalendarService.holidays.length;
                                            let _s = GeneralSettings.showHolidays;
                                            return Services.CalendarService.hasHoliday(dateKey);
                                        }

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Theme.scaled(8)

                                        color: {
                                            if (isToday && isSelected) return Theme.accentColor;
                                            if (isSelected) return Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.18);
                                            if (isToday) return Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.12);
                                            if (dayMouse.containsMouse) return Theme.cardBackgroundHover;
                                            return "transparent";
                                        }
                                        border.color: (isSelected || isToday) ? Theme.accentColor : "transparent"
                                        border.width: (isSelected || isToday) ? 1.5 : 0
                                        scale: dayMouse.pressed ? 0.93 : 1.0
                                        Behavior on color { ColorAnimation { duration: Theme.animInstant } }
                                        Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: Theme.scaled(1)

                                            Label {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: dayCell.dateValue.getDate()
                                                font.pixelSize: Theme.scaled(11)
                                                font.weight: (dayCell.isToday || dayCell.isSelected || dayCell.hasPersonal || dayCell.hasHoliday) ? Font.Bold : Font.Medium
                                                color: {
                                                    if (dayCell.isToday && dayCell.isSelected) return Colors.on_primary;
                                                    if (!dayCell.isCurrentMonth) return Theme.surface2;
                                                    if (dayCell.isToday || dayCell.isSelected) return Theme.accentColor;
                                                    return Theme.text;
                                                }
                                            }

                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                spacing: Theme.scaled(2)
                                                visible: dayCell.hasPersonal || dayCell.hasHoliday

                                                Rectangle {
                                                    visible: dayCell.hasPersonal
                                                    width: Theme.scaled(4); height: Theme.scaled(4); radius: 999
                                                    color: (dayCell.isToday && dayCell.isSelected) ? Colors.on_primary : Theme.accentColor
                                                }
                                                Rectangle {
                                                    visible: dayCell.hasHoliday
                                                    width: Theme.scaled(4); height: Theme.scaled(4); radius: 999
                                                    color: (dayCell.isToday && dayCell.isSelected) ? Colors.on_primary : Theme.yellow
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: dayMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedDate = dayCell.dateValue;
                                                if (!dayCell.isCurrentMonth) {
                                                    root.viewDate = new Date(dayCell.dateValue.getFullYear(), dayCell.dateValue.getMonth(), 1);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- SELECTED DAY INSPECTOR & QUICK-ADD ---
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: inspectorCol.implicitHeight + Theme.scaled(12)
                    radius: Theme.scaled(10)
                    color: Theme.cardBackground
                    border.color: Theme.glassBorder
                    border.width: 1

                    ColumnLayout {
                        id: inspectorCol
                        anchors.fill: parent
                        anchors.margins: Theme.scaled(6)
                        spacing: Theme.scaled(5)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(6)

                            Text {
                                text: Qt.formatDate(root.selectedDate, "ddd, MMM d")
                                color: Theme.text
                                font.weight: Font.Bold
                                font.pixelSize: Theme.scaled(11)
                            }

                            Rectangle {
                                implicitWidth: relTxt.implicitWidth + Theme.scaled(8)
                                height: Theme.scaled(16)
                                radius: 999
                                color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.14)
                                Text {
                                    id: relTxt
                                    anchors.centerIn: parent
                                    text: Services.CalendarService.daysUntilLabel(root.selectedDateKey)
                                    color: Theme.accentColor
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Bold
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Add Event Toggle Button
                            Rectangle {
                                width: Theme.scaled(22); height: Theme.scaled(22)
                                radius: Theme.scaled(6)
                                color: root.addFormOpen
                                    ? Theme.accentColor
                                    : (addBtnM.containsMouse ? Theme.cardBackgroundHover : "transparent")
                                Text {
                                    anchors.centerIn: parent
                                    text: root.addFormOpen ? "󰅖" : "󰐕"
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(13)
                                    color: root.addFormOpen ? Colors.on_primary : Theme.accentColor
                                }
                                MouseArea {
                                    id: addBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.addFormOpen = !root.addFormOpen;
                                        if (root.addFormOpen) Qt.callLater(() => titleInput.forceActiveFocus());
                                    }
                                }
                            }
                        }

                        // Inline Quick-Add Form
                        ColumnLayout {
                            visible: root.addFormOpen
                            Layout.fillWidth: true
                            spacing: Theme.scaled(4)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(4)

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: Theme.scaled(26)
                                    radius: Theme.scaled(6)
                                    color: Theme.surface1
                                    border.color: titleInput.activeFocus ? Theme.accentColor : Theme.glassBorder
                                    border.width: 1
                                    TextInput {
                                        id: titleInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.scaled(8)
                                        anchors.rightMargin: Theme.scaled(8)
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.text
                                        font.pixelSize: Theme.scaled(11)
                                        clip: true
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Event title..."
                                            color: Theme.subtext2
                                            font.pixelSize: Theme.scaled(11)
                                            visible: !parent.text && !parent.activeFocus
                                        }
                                        Keys.onReturnPressed: saveBtnM.save()
                                        Keys.onEscapePressed: root.addFormOpen = false
                                    }
                                }

                                Rectangle {
                                    width: Theme.scaled(54)
                                    height: Theme.scaled(26)
                                    radius: Theme.scaled(6)
                                    color: Theme.surface1
                                    border.color: timeInput.activeFocus ? Theme.accentColor : Theme.glassBorder
                                    border.width: 1
                                    TextInput {
                                        id: timeInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.scaled(6)
                                        anchors.rightMargin: Theme.scaled(6)
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.text
                                        font.pixelSize: Theme.scaled(10)
                                        clip: true
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "14:00"
                                            color: Theme.subtext2
                                            font.pixelSize: Theme.scaled(10)
                                            visible: !parent.text && !parent.activeFocus
                                        }
                                        Keys.onReturnPressed: saveBtnM.save()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(4)

                                Repeater {
                                    model: [
                                        { id: "event", label: "Event" },
                                        { id: "reminder", label: "Reminder" },
                                        { id: "birthday", label: "Birthday" }
                                    ]
                                    delegate: Rectangle {
                                        readonly property bool sel: root.newEventCategory === modelData.id
                                        implicitWidth: catLbl.implicitWidth + Theme.scaled(10)
                                        height: Theme.scaled(20)
                                        radius: 999
                                        color: sel ? root.categoryColor(modelData.id, "personal") : Theme.surface1
                                        Text {
                                            id: catLbl
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: Theme.scaled(9)
                                            font.weight: Font.Bold
                                            color: sel ? Colors.on_primary : Theme.subtext0
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.newEventCategory = modelData.id
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: saveLbl.implicitWidth + Theme.scaled(14)
                                    height: Theme.scaled(22)
                                    radius: Theme.scaled(6)
                                    color: Theme.accentColor
                                    Text {
                                        id: saveLbl
                                        anchors.centerIn: parent
                                        text: "Save"
                                        font.pixelSize: Theme.scaled(10)
                                        font.weight: Font.Bold
                                        color: Colors.on_primary
                                    }
                                    MouseArea {
                                        id: saveBtnM
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        function save() {
                                            if (Services.CalendarService.addEvent(root.selectedDateKey, titleInput.text, timeInput.text, root.newEventCategory, "")) {
                                                titleInput.text = "";
                                                timeInput.text = "";
                                                root.addFormOpen = false;
                                            }
                                        }
                                        onClicked: save()
                                    }
                                }
                            }
                        }

                        // Events List for Selected Date
                        Text {
                            visible: !root.addFormOpen && root.selectedDayEvents.length === 0
                            Layout.fillWidth: true
                            text: "No events or holidays — click + to add one"
                            color: Theme.subtext2
                            font.pixelSize: Theme.scaled(10)
                            elide: Text.ElideRight
                        }

                        ColumnLayout {
                            visible: !root.addFormOpen && root.selectedDayEvents.length > 0
                            Layout.fillWidth: true
                            spacing: Theme.scaled(3)

                            Repeater {
                                model: root.selectedDayEvents.slice(0, 3)
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.scaled(6)

                                    Rectangle {
                                        width: Theme.scaled(4)
                                        height: Theme.scaled(14)
                                        radius: 999
                                        color: root.categoryColor(modelData.category, modelData.type)
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: (modelData.time ? modelData.time + "  " : "") + modelData.name
                                        color: Theme.text
                                        font.pixelSize: Theme.scaled(10)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: modelData.type === "personal"
                                        text: "󰆴"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(11)
                                        color: delDayM.containsMouse ? Theme.powerRed : Theme.subtext2
                                        MouseArea {
                                            id: delDayM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.CalendarService.removeEvent(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
