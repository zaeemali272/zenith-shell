// Focus timer.
//
// Rebuilt around a progress ring: the old version was a bare number with rows
// of buttons under it, and gave no sense of how much of the session was left
// without reading and subtracting. The ring is the state; everything else is
// secondary.
//
// The service API is unchanged -- duration/remaining/running plus
// setDuration, adjustDuration, toggleTimer and resetTimer.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import "../.."
import "../../../"
import "../../../services"

Item {
    id: root

    readonly property int total: Math.max(1, ProductivityService.duration)
    readonly property real progress: Math.max(0, Math.min(1,
        1 - (ProductivityService.remaining / total)))
    readonly property bool done: ProductivityService.remaining <= 0
    property int sessionsCompleted: 0
    property string activeMode: "focus" // "focus" | "short" | "long"

    onDoneChanged: {
        if (done && activeMode === "focus") sessionsCompleted++;
    }

    function selectMode(mode, secs) {
        activeMode = mode;
        ProductivityService.setDuration(secs);
    }

    function endTimeString() {
        let eta = new Date(Date.now() + ProductivityService.remaining * 1000);
        return Qt.formatTime(eta, "hh:mm AP");
    }

    function handleKeys(event) {
        if (event.key === Qt.Key_Space) {
            ProductivityService.isBeeping ? ProductivityService.dismissAlarm() : ProductivityService.toggleTimer();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            ProductivityService.resetTimer();
            event.accepted = true;
        } else if ((event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) && !ProductivityService.running) {
            ProductivityService.adjustDuration(60);
            event.accepted = true;
        } else if (event.key === Qt.Key_Minus && !ProductivityService.running) {
            ProductivityService.adjustDuration(-60);
            event.accepted = true;
        }
    }

    readonly property color ringColor: ProductivityService.isBeeping ? Theme.powerRed
                                     : ProductivityService.running    ? Theme.accentColor
                                                                      : Theme.blue

    function clock(secs) {
        var s = Math.max(0, secs);
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var r = s % 60;
        return (h > 0 ? h + ":" + String(m).padStart(2, "0")
                      : String(m)) + ":" + String(r).padStart(2, "0");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(10)
        spacing: Theme.scaled(12)

        // Top Mode Segmented Bar + Session Counter
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            Rectangle {
                implicitWidth: modeRow.implicitWidth + Theme.scaled(8)
                height: Theme.scaled(30)
                radius: 999
                color: Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1

                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Repeater {
                        model: [
                            { id: "focus", label: "Focus", secs: 1500 },
                            { id: "short", label: "Short Break", secs: 300 },
                            { id: "long", label: "Long Break", secs: 900 }
                        ]
                        delegate: Rectangle {
                            readonly property bool active: root.activeMode === modelData.id
                            width: mTxt.implicitWidth + Theme.scaled(16)
                            height: Theme.scaled(22)
                            radius: 999
                            color: active ? Theme.accentColor : (mM.containsMouse ? Theme.cardBackgroundHover : "transparent")
                            Text {
                                id: mTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Theme.scaled(10)
                                font.weight: Font.Bold
                                color: active ? Colors.on_primary : Theme.subtext0
                            }
                            MouseArea {
                                id: mM
                                anchors.fill: parent
                                enabled: !ProductivityService.running
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.selectMode(modelData.id, modelData.secs)
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: sessRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(26)
                radius: 999
                color: Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1
                Row {
                    id: sessRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(5)
                    Text { text: "󰄬"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(11); color: Theme.accentColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: root.sessionsCompleted + " sessions"; color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ---------------- ring ----------------
        Item {
            id: ring
            Layout.alignment: Qt.AlignHCenter
            readonly property real dim: Math.max(Theme.scaled(140),
                Math.min(Theme.scaled(230), Math.min(root.width, root.height) * 0.55))
            Layout.preferredWidth: dim
            Layout.preferredHeight: dim

            readonly property real side: Math.min(width, height)
            readonly property real stroke: Math.max(6, side * 0.055)
            readonly property real radius: Math.max(1, (side - stroke) / 2)

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                // track
                ShapePath {
                    strokeColor: Qt.rgba(1, 1, 1, 0.08)
                    strokeWidth: ring.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: ring.width / 2; centerY: ring.height / 2
                        radiusX: ring.radius; radiusY: ring.radius
                        startAngle: -90; sweepAngle: 360
                    }
                }
                // elapsed
                ShapePath {
                    strokeColor: root.ringColor
                    strokeWidth: ring.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: ring.width / 2; centerY: ring.height / 2
                        radiusX: ring.radius; radiusY: ring.radius
                        startAngle: -90
                        sweepAngle: 360 * root.progress
                        Behavior on sweepAngle { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: ring.side * 0.68
                    horizontalAlignment: Text.AlignHCenter
                    text: root.clock(ProductivityService.remaining)
                    font.pixelSize: ring.side * 0.26
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 10
                    font.weight: Font.Black
                    color: root.done ? Theme.powerRed : Theme.text
                    Behavior on color { ColorAnimation { duration: Theme.animInstant } }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ProductivityService.isBeeping ? "TIME UP"
                        : ProductivityService.running   ? "FOCUSING"
                        : root.progress > 0             ? "PAUSED"
                                                        : "READY"
                    color: Theme.subtext0
                    font.pixelSize: Math.max(9, ring.side * 0.055)
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }
                Text {
                    visible: ProductivityService.remaining > 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "Ends " + root.endTimeString()
                    color: Theme.subtext2
                    font.pixelSize: Math.max(9, ring.side * 0.048)
                }
            }
        }

        // ---------------- presets ----------------
        Flow {
            id: presetFlow
            // Layout.fillWidth made this span the whole row, so the chips
            // packed against the left edge while the ring and transport were
            // centred. Sizing it to its own content and centring that keeps
            // all three columns on the same axis; it still wraps when the
            // panel is too narrow for one row.
            readonly property real chipW: Theme.scaled(58)
            readonly property real contentW: 6 * chipW + 5 * spacing

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(contentW, root.width - Theme.scaled(24))
            spacing: Theme.scaled(8)
            visible: !ProductivityService.running

            Repeater {
                // Values only -- no Theme colours in the model, so a palette
                // change cannot force every delegate to be rebuilt.
                model: [300, 600, 900, 1500, 1800, 3600]
                delegate: Rectangle {
                    required property int modelData
                    required property int index
                    readonly property bool active: ProductivityService.duration === modelData
                    width: presetFlow.chipW; height: Theme.scaled(34)
                    radius: height / 2
                    color: active ? Theme.accentColor : (presetMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                    border.width: 0
                    scale: presetMouse.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData >= 3600 ? (modelData / 3600) + "h" : (modelData / 60) + "m"
                        font.pixelSize: Theme.scaled(13)
                        font.weight: Font.Bold
                        color: parent.active ? Colors.on_primary : (presetMouse.containsMouse ? Theme.text : Theme.subtext0)
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ProductivityService.setDuration(modelData)
                    }
                }
            }
        }

        // ---------------- transport ----------------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.scaled(16)

            NudgeBtn { label: "-5"; onTriggered: ProductivityService.adjustDuration(-300) }
            NudgeBtn { label: "-1"; onTriggered: ProductivityService.adjustDuration(-60) }

            Rectangle {
                width: Theme.scaled(72); height: Theme.scaled(72); radius: width / 2
                color: ProductivityService.running ? Theme.powerRed : Theme.accentColor
                scale: playMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Theme.elasticEasing; easing.overshoot: 1.15 } }
                Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                Text {
                    anchors.centerIn: parent
                    // Nudged right because the play triangle is visually
                    // off-centre inside its own glyph box.
                    anchors.horizontalCenterOffset: ProductivityService.running ? 0 : Theme.scaled(2)
                    text: ProductivityService.running ? "󰏤" : "󰐊"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(34)
                    color: Colors.on_primary
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ProductivityService.isBeeping ? ProductivityService.dismissAlarm()
                                                             : ProductivityService.toggleTimer()
                }
            }

            NudgeBtn { label: "+1"; onTriggered: ProductivityService.adjustDuration(60) }
            NudgeBtn { label: "+5"; onTriggered: ProductivityService.adjustDuration(300) }

            Rectangle {
                width: Theme.scaled(46); height: Theme.scaled(46); radius: width / 2
                color: resetMouse.containsMouse ? Theme.menuDarkHover : "transparent"
                border.width: 0
                Text {
                    anchors.centerIn: parent
                    text: "󰜉"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(24)
                    color: resetMouse.containsMouse ? Theme.text : Theme.subtext0
                }
                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ProductivityService.resetTimer()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Space: Start / Pause   •   R: Reset   •   +/-: Adjust 1m"
            color: Theme.subtext2
            font.pixelSize: Theme.scaled(9.5)
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }
    }

    component NudgeBtn: Rectangle {
        property string label
        signal triggered()

        width: Theme.scaled(40); height: Theme.scaled(40); radius: width / 2
        color: nudgeMouse.containsMouse ? Theme.menuBackground2Hover : "transparent"
        border.color: Theme.glassBorder
        border.width: 1
        visible: !ProductivityService.running

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: Theme.scaled(13)
            font.weight: Font.Black
            color: nudgeMouse.containsMouse ? Theme.text : Theme.subtext0
        }
        MouseArea {
            id: nudgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }
}
