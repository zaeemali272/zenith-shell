import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../../../services"
import "../components"
import "../../../" as Shell

ColumnLayout {
    id: root
    spacing: Shell.Theme.scaled(16)
    Layout.fillWidth: true

    readonly property var currentMon: DisplayService.currentMonitor

    // --- HEADER ---
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Shell.Theme.scaled(6)
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        spacing: Shell.Theme.scaled(12)

        ColumnLayout {
            spacing: Shell.Theme.scaled(3)
            Text {
                text: "Displays & Resolution"
                font.pixelSize: Shell.Theme.scaled(20)
                font.weight: Font.Bold
                color: Shell.Theme.text
            }
            Text {
                text: "Configure screen resolutions, scaling, and multi-monitor / projector layouts"
                font.pixelSize: Shell.Theme.scaled(12)
                color: Shell.Theme.subtext0
            }
        }

        Item { Layout.fillWidth: true }

        // Refresh button
        Rectangle {
            width: Shell.Theme.scaled(34)
            height: Shell.Theme.scaled(34)
            radius: height / 2
            color: refreshMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Shell.Theme.cardBackground
            border.color: Shell.Theme.glassBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                font.family: Shell.Theme.iconFont
                font.pixelSize: Shell.Theme.scaled(15)
                color: Shell.Theme.accentColor
                rotation: DisplayService.busy ? 360 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: 800
                        loops: DisplayService.busy ? Animation.Infinite : 1
                        from: 0
                        to: 360
                    }
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: DisplayService.refresh()
            }
        }
    }

    // --- 10-SECOND REVERT / CONFIRMATION BANNER ---
    Rectangle {
        id: confirmBanner
        visible: DisplayService.isConfirming
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        implicitHeight: bannerCol.implicitHeight + Shell.Theme.scaled(24)
        radius: Shell.Theme.bubbleRadiusMedium
        color: Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.16)
        border.color: Shell.Theme.accentColor
        border.width: 1.5
        clip: true

        ColumnLayout {
            id: bannerCol
            anchors.fill: parent
            anchors.margins: Shell.Theme.scaled(14)
            spacing: Shell.Theme.scaled(12)

            RowLayout {
                Layout.fillWidth: true
                spacing: Shell.Theme.scaled(14)

                // Warning Icon
                Rectangle {
                    width: Shell.Theme.scaled(42)
                    height: Shell.Theme.scaled(42)
                    radius: Shell.Theme.scaled(12)
                    color: Shell.Theme.accentColor

                    Text {
                        anchors.centerIn: parent
                        text: "󰍹"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(20)
                        color: Shell.Colors.on_primary
                    }
                }

                // Text Description
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Shell.Theme.scaled(2)

                    Text {
                        text: "Keep these display settings?"
                        font.pixelSize: Shell.Theme.scaled(14)
                        font.weight: Font.Bold
                        color: Shell.Theme.text
                    }

                    Text {
                        text: {
                            let detail = "";
                            if (DisplayService.pendingChange) {
                                if (DisplayService.pendingChange.type === "scale") {
                                    detail = "Scale changed to " + Math.round(DisplayService.pendingChange.newTarget * 100) + "%. ";
                                } else if (DisplayService.pendingChange.type === "resolution") {
                                    detail = "Resolution changed to " + DisplayService.pendingChange.newTarget + ". ";
                                }
                            }
                            return detail + "Reverting in " + DisplayService.revertCountdown + "s if not confirmed.";
                        }
                        font.pixelSize: Shell.Theme.scaled(11)
                        color: Shell.Theme.subtext0
                    }
                }

                // Action Buttons
                RowLayout {
                    spacing: Shell.Theme.scaled(10)

                    // Keep Changes button
                    Rectangle {
                        height: Shell.Theme.scaled(34)
                        implicitWidth: keepText.implicitWidth + Shell.Theme.scaled(24)
                        radius: Shell.Theme.bubbleRadiusPill
                        color: Shell.Theme.accentColor
                        scale: keepMouse.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: keepText
                            anchors.centerIn: parent
                            spacing: Shell.Theme.scaled(6)
                            Text {
                                text: "󰄬"
                                font.family: Shell.Theme.iconFont
                                font.pixelSize: Shell.Theme.scaled(12)
                                color: Shell.Colors.on_primary
                            }
                            Text {
                                text: "Keep Changes"
                                font.pixelSize: Shell.Theme.scaled(11)
                                font.weight: Font.Bold
                                color: Shell.Colors.on_primary
                            }
                        }

                        MouseArea {
                            id: keepMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DisplayService.keepChanges()
                        }
                    }

                    // Revert button
                    Rectangle {
                        height: Shell.Theme.scaled(34)
                        implicitWidth: revText.implicitWidth + Shell.Theme.scaled(24)
                        radius: Shell.Theme.bubbleRadiusPill
                        color: revMouse.containsMouse ? Qt.rgba(Shell.Theme.powerRed.r, Shell.Theme.powerRed.g, Shell.Theme.powerRed.b, 0.25) : Qt.rgba(Shell.Theme.powerRed.r, Shell.Theme.powerRed.g, Shell.Theme.powerRed.b, 0.15)
                        border.color: Shell.Theme.powerRed
                        border.width: 1
                        scale: revMouse.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: revText
                            anchors.centerIn: parent
                            spacing: Shell.Theme.scaled(6)
                            Text {
                                text: "󰅖"
                                font.family: Shell.Theme.iconFont
                                font.pixelSize: Shell.Theme.scaled(12)
                                color: Shell.Theme.powerRed
                            }
                            Text {
                                text: "Revert (" + DisplayService.revertCountdown + "s)"
                                font.pixelSize: Shell.Theme.scaled(11)
                                font.weight: Font.Bold
                                color: Shell.Theme.powerRed
                            }
                        }

                        MouseArea {
                            id: revMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DisplayService.revertChanges()
                        }
                    }
                }
            }

            // Animated countdown bar
            Rectangle {
                Layout.fillWidth: true
                height: Shell.Theme.scaled(3)
                radius: 1.5
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    height: parent.height
                    radius: 1.5
                    width: parent.width * (DisplayService.revertCountdown / 10.0)
                    color: Shell.Theme.accentColor
                    Behavior on width { NumberAnimation { duration: 950; easing.type: Easing.Linear } }
                }
            }
        }
    }

    // --- DETECTED DISPLAYS SECTION ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        spacing: Shell.Theme.scaled(8)

        Text {
            text: "DETECTED DISPLAYS (" + DisplayService.monitorCount + ")"
            font.pixelSize: Shell.Theme.scaled(11)
            font.weight: Font.Bold
            color: Shell.Theme.subtext1
        }

        Flow {
            Layout.fillWidth: true
            spacing: Shell.Theme.scaled(12)

            Repeater {
                model: DisplayService.monitors
                delegate: Rectangle {
                    id: monCard
                    width: Shell.Theme.scaled(250)
                    height: Shell.Theme.scaled(76)
                    radius: Shell.Theme.bubbleRadiusMedium

                    readonly property bool isSelected: DisplayService.selectedMonitor === modelData.name

                    color: isSelected
                           ? Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.16)
                           : (monMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Shell.Theme.cardBackground)
                    border.color: isSelected ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                    border.width: isSelected ? 1.5 : 1
                    scale: monMouse.pressed ? 0.97 : 1.0

                    Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }
                    Behavior on border.color { ColorAnimation { duration: Shell.Theme.animInstant } }
                    Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Shell.Theme.scaled(12)
                        spacing: Shell.Theme.scaled(12)

                        // Monitor Icon
                        Rectangle {
                            width: Shell.Theme.scaled(42)
                            height: Shell.Theme.scaled(42)
                            radius: Shell.Theme.scaled(10)
                            color: monCard.isSelected
                                   ? Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.25)
                                   : Qt.rgba(1, 1, 1, 0.06)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isInternal ? "󰌢" : "󰍹"
                                font.family: Shell.Theme.iconFont
                                font.pixelSize: Shell.Theme.scaled(20)
                                color: monCard.isSelected ? Shell.Theme.accentColor : Shell.Theme.text
                            }
                        }

                        // Info column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Shell.Theme.scaled(2)

                            RowLayout {
                                spacing: Shell.Theme.scaled(6)
                                Text {
                                    text: modelData.name
                                    font.pixelSize: Shell.Theme.scaled(13)
                                    font.weight: Font.Bold
                                    color: Shell.Theme.text
                                }
                                Rectangle {
                                    height: Shell.Theme.scaled(16)
                                    implicitWidth: badgeText.implicitWidth + Shell.Theme.scaled(8)
                                    radius: height / 2
                                    color: Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.2)
                                    Text {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: modelData.isInternal ? "Internal" : "External"
                                        font.pixelSize: Shell.Theme.scaled(9)
                                        font.weight: Font.Bold
                                        color: Shell.Theme.accentColor
                                    }
                                }
                            }

                            Text {
                                text: modelData.description || (modelData.width + "x" + modelData.height)
                                font.pixelSize: Shell.Theme.scaled(10)
                                color: Shell.Theme.subtext0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.mirrorOf
                                      ? ("Mirror of " + modelData.mirrorOf)
                                      : (modelData.width + "x" + modelData.height + " @ " + Math.round(modelData.refreshRate) + "Hz • " + modelData.scale + "x")
                                font.pixelSize: Shell.Theme.scaled(10)
                                font.weight: Font.Medium
                                color: Shell.Theme.accentColor
                            }
                        }
                    }

                    MouseArea {
                        id: monMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DisplayService.selectedMonitor = modelData.name
                    }
                }
            }
        }
    }

    // --- DISPLAY & PROJECTOR MODES ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        spacing: Shell.Theme.scaled(8)

        Text {
            text: "DISPLAY & PROJECTOR MODES"
            font.pixelSize: Shell.Theme.scaled(11)
            font.weight: Font.Bold
            color: Shell.Theme.subtext1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Shell.Theme.scaled(10)

            // Preset 1: Extend
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Shell.Theme.scaled(52)
                radius: Shell.Theme.bubbleRadiusMedium

                readonly property bool isActive: DisplayService.activePreset === "extend"

                color: isActive
                       ? Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.18)
                       : (extMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Shell.Theme.cardBackground)
                border.color: isActive ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                border.width: isActive ? 1.5 : 1
                scale: extMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Shell.Theme.scaled(10)
                    Text {
                        text: "󰍹"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(18)
                        color: parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                    }
                    Column {
                        Text {
                            text: "Extend"
                            font.pixelSize: Shell.Theme.scaled(12)
                            font.weight: Font.Bold
                            color: parent.parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                        }
                        Text {
                            text: "Independent"
                            font.pixelSize: Shell.Theme.scaled(9)
                            color: Shell.Theme.subtext0
                        }
                    }
                }

                MouseArea {
                    id: extMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DisplayService.setPreset("extend")
                }
            }

            // Preset 2: Mirror / Project (Duplicate)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Shell.Theme.scaled(52)
                radius: Shell.Theme.bubbleRadiusMedium

                readonly property bool isActive: DisplayService.activePreset === "mirror"

                color: isActive
                       ? Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.18)
                       : (mirMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Shell.Theme.cardBackground)
                border.color: isActive ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                border.width: isActive ? 1.5 : 1
                scale: mirMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Shell.Theme.scaled(10)
                    Text {
                        text: "󰍺"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(18)
                        color: parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                    }
                    Column {
                        Text {
                            text: "Mirror / Project"
                            font.pixelSize: Shell.Theme.scaled(12)
                            font.weight: Font.Bold
                            color: parent.parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                        }
                        Text {
                            text: "Duplicate Screen"
                            font.pixelSize: Shell.Theme.scaled(9)
                            color: Shell.Theme.subtext0
                        }
                    }
                }

                MouseArea {
                    id: mirMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DisplayService.setPreset("mirror")
                }
            }

            // Preset 3: External Screen Only
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Shell.Theme.scaled(52)
                radius: Shell.Theme.bubbleRadiusMedium

                readonly property bool isActive: DisplayService.activePreset === "secondOnly"

                color: isActive
                       ? Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.18)
                       : (secMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Shell.Theme.cardBackground)
                border.color: isActive ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                border.width: isActive ? 1.5 : 1
                scale: secMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Shell.Theme.scaled(10)
                    Text {
                        text: "󰍹"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(18)
                        color: parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                    }
                    Column {
                        Text {
                            text: "External Only"
                            font.pixelSize: Shell.Theme.scaled(12)
                            font.weight: Font.Bold
                            color: parent.parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                        }
                        Text {
                            text: "Docked / Presentation"
                            font.pixelSize: Shell.Theme.scaled(9)
                            color: Shell.Theme.subtext0
                        }
                    }
                }

                MouseArea {
                    id: secMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DisplayService.setPreset("secondOnly")
                }
            }

            // Preset 4: Laptop Screen Only
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Shell.Theme.scaled(52)
                radius: Shell.Theme.bubbleRadiusMedium

                readonly property bool isActive: DisplayService.activePreset === "internalOnly"

                color: isActive
                       ? Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.18)
                       : (intMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Shell.Theme.cardBackground)
                border.color: isActive ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                border.width: isActive ? 1.5 : 1
                scale: intMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Shell.Theme.scaled(10)
                    Text {
                        text: "󰌢"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(18)
                        color: parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                    }
                    Column {
                        Text {
                            text: "Built-in Only"
                            font.pixelSize: Shell.Theme.scaled(12)
                            font.weight: Font.Bold
                            color: parent.parent.parent.isActive ? Shell.Theme.accentColor : Shell.Theme.text
                        }
                        Text {
                            text: "Disconnect Ext"
                            font.pixelSize: Shell.Theme.scaled(9)
                            color: Shell.Theme.subtext0
                        }
                    }
                }

                MouseArea {
                    id: intMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DisplayService.setPreset("internalOnly")
                }
            }
        }
    }

    // Divider
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        height: 1
        color: Shell.Theme.glassBorder
    }

    // --- DISPLAY SETTINGS SECTION ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        spacing: Shell.Theme.scaled(14)

        RowLayout {
            spacing: Shell.Theme.scaled(8)
            Text {
                text: "DISPLAY SETTINGS:"
                font.pixelSize: Shell.Theme.scaled(11)
                font.weight: Font.Bold
                color: Shell.Theme.subtext1
            }
            Text {
                text: root.currentMon ? (root.currentMon.name + " (" + root.currentMon.width + "x" + root.currentMon.height + "@" + Math.round(root.currentMon.refreshRate) + "Hz)") : "None"
                font.pixelSize: Shell.Theme.scaled(12)
                font.weight: Font.Bold
                color: Shell.Theme.accentColor
            }
        }

        // --- RESOLUTION & REFRESH RATE CARD ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: resCardCol.implicitHeight + Shell.Theme.scaled(28)
            radius: Shell.Theme.bubbleRadiusMedium
            color: Shell.Theme.cardBackground
            border.color: Shell.Theme.glassBorder
            border.width: 1

            ColumnLayout {
                id: resCardCol
                anchors.fill: parent
                anchors.margins: Shell.Theme.scaled(14)
                spacing: Shell.Theme.scaled(12)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Resolution & Refresh Rate"
                        color: Shell.Theme.text
                        font.pixelSize: Shell.Theme.scaled(13)
                        font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: Shell.Theme.scaled(22)
                        implicitWidth: currentBadgeText.implicitWidth + Shell.Theme.scaled(14)
                        radius: Shell.Theme.bubbleRadiusPill
                        color: Qt.rgba(Shell.Theme.accentColor.r, Shell.Theme.accentColor.g, Shell.Theme.accentColor.b, 0.2)
                        border.color: Shell.Theme.accentColor
                        border.width: 1
                        Text {
                            id: currentBadgeText
                            anchors.centerIn: parent
                            text: "Active: " + (root.currentMon ? (root.currentMon.width + "x" + root.currentMon.height + "@" + Math.round(root.currentMon.refreshRate) + "Hz") : "Default")
                            font.pixelSize: Shell.Theme.scaled(10)
                            font.weight: Font.Bold
                            color: Shell.Theme.accentColor
                        }
                    }
                }

                // Supported Resolutions List
                Flow {
                    Layout.fillWidth: true
                    spacing: Shell.Theme.scaled(8)

                    Repeater {
                        model: {
                            let list = [];
                            let cur = root.currentMon;
                            if (!cur) return list;

                            let maxW = cur.nativeWidth || cur.width || 1920;
                            let maxH = cur.nativeHeight || cur.height || 1080;

                            // 1. Any native/driver-reported modes
                            if (cur.availableModes && cur.availableModes.length > 0) {
                                for (let i = 0; i < cur.availableModes.length; i++) {
                                    let rawMode = cur.availableModes[i];
                                    let cleanVal = rawMode.replace("Hz", "").replace(".00", "");
                                    let displayLabel = rawMode;
                                    if (rawMode.indexOf("@") !== -1) {
                                        let parts = rawMode.split("@");
                                        displayLabel = parts[0] + " @ " + parts[1].replace(".00", "");
                                    }
                                    list.push({
                                        label: displayLabel + " (Native)",
                                        value: cleanVal,
                                        w: cur.nativeWidth || cur.width,
                                        h: cur.nativeHeight || cur.height
                                    });
                                }
                            }

                            // 2. Standard scaled modes supported up to physical panel maximum
                            const standardCandidates = [
                                { label: "1920 x 1080 @ 60Hz (Full HD 16:9)", value: "1920x1080@60", w: 1920, h: 1080 },
                                { label: "1600 x 900 @ 60Hz (HD+ 16:9)", value: "1600x900@60", w: 1600, h: 900 },
                                { label: "1366 x 768 @ 60Hz (Laptop HD 16:9)", value: "1366x768@60", w: 1366, h: 768 },
                                { label: "1280 x 720 @ 60Hz (720p HD)", value: "1280x720@60", w: 1280, h: 720 },
                                { label: "1024 x 768 @ 60Hz (Projector 4:3)", value: "1024x768@60", w: 1024, h: 768 },
                                { label: "800 x 600 @ 60Hz (Projector SVGA)", value: "800x600@60", w: 800, h: 600 }
                            ];

                            for (let j = 0; j < standardCandidates.length; j++) {
                                let sc = standardCandidates[j];
                                if (sc.w <= maxW && sc.h <= maxH) {
                                    let exists = false;
                                    for (let k = 0; k < list.length; k++) {
                                        if (list[k].value.indexOf(sc.value.split("@")[0]) === 0) {
                                            exists = true;
                                            break;
                                        }
                                    }
                                    if (!exists) {
                                        list.push(sc);
                                    }
                                }
                            }

                            return list;
                        }

                        delegate: Rectangle {
                            id: resChip
                            height: Shell.Theme.scaled(32)
                            implicitWidth: resChipRow.implicitWidth + Shell.Theme.scaled(20)
                            radius: Shell.Theme.bubbleRadiusPill

                            // Exact match check
                            readonly property bool isCurrent: DisplayService.isCurrentResolution(root.currentMon, modelData.value)

                            color: isCurrent
                                   ? Shell.Theme.accentColor
                                   : (chipMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Qt.rgba(1, 1, 1, 0.04))
                            border.color: isCurrent ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                            border.width: isCurrent ? 1.5 : 1
                            scale: chipMouse.pressed ? 0.94 : 1.0

                            Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }
                            Behavior on border.color { ColorAnimation { duration: Shell.Theme.animInstant } }

                            RowLayout {
                                id: resChipRow
                                anchors.centerIn: parent
                                spacing: Shell.Theme.scaled(6)

                                Text {
                                    visible: resChip.isCurrent
                                    text: "󰄬"
                                    font.family: Shell.Theme.iconFont
                                    font.pixelSize: Shell.Theme.scaled(11)
                                    color: Shell.Colors.on_primary
                                }

                                Text {
                                    text: modelData.label
                                    font.pixelSize: Shell.Theme.scaled(11)
                                    font.weight: resChip.isCurrent ? Font.Bold : Font.Normal
                                    color: resChip.isCurrent ? Shell.Colors.on_primary : Shell.Theme.text
                                }
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentMon) {
                                        DisplayService.requestResolutionChange(root.currentMon.name, modelData.value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- SCALE ROW ---
        Rectangle {
            Layout.fillWidth: true
            height: Shell.Theme.scaled(56)
            radius: Shell.Theme.bubbleRadiusMedium
            color: Shell.Theme.cardBackground
            border.color: Shell.Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Shell.Theme.scaled(16)
                anchors.rightMargin: Shell.Theme.scaled(16)
                spacing: Shell.Theme.scaled(16)

                Text {
                    text: "Display Scaling"
                    color: Shell.Theme.text
                    font.pixelSize: Shell.Theme.scaled(13)
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Shell.Theme.scaled(6)

                    Repeater {
                        model: [
                            { label: "100%", value: 1.0 },
                            { label: "125%", value: 1.25 },
                            { label: "150%", value: 1.5 },
                            { label: "175%", value: 1.75 },
                            { label: "200%", value: 2.0 }
                        ]

                        delegate: Rectangle {
                            id: scaleChip
                            height: Shell.Theme.scaled(30)
                            width: Shell.Theme.scaled(58)
                            radius: Shell.Theme.bubbleRadiusPill

                            readonly property bool isCurrent: root.currentMon && Math.abs(root.currentMon.scale - modelData.value) < 0.05

                            color: isCurrent ? Shell.Theme.accentColor : (scaleMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Qt.rgba(1, 1, 1, 0.04))
                            border.color: isCurrent ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                            border.width: isCurrent ? 1.5 : 1
                            scale: scaleMouse.pressed ? 0.94 : 1.0

                            Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Shell.Theme.scaled(11)
                                font.weight: scaleChip.isCurrent ? Font.Bold : Font.Normal
                                color: scaleChip.isCurrent ? Shell.Colors.on_primary : Shell.Theme.text
                            }

                            MouseArea {
                                id: scaleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentMon) {
                                        DisplayService.requestScaleChange(root.currentMon.name, modelData.value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- ORIENTATION ROW ---
        Rectangle {
            Layout.fillWidth: true
            height: Shell.Theme.scaled(56)
            radius: Shell.Theme.bubbleRadiusMedium
            color: Shell.Theme.cardBackground
            border.color: Shell.Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Shell.Theme.scaled(16)
                anchors.rightMargin: Shell.Theme.scaled(16)
                spacing: Shell.Theme.scaled(16)

                Text {
                    text: "Orientation / Rotation"
                    color: Shell.Theme.text
                    font.pixelSize: Shell.Theme.scaled(13)
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Shell.Theme.scaled(6)

                    Repeater {
                        model: [
                            { label: "Normal (0°)", value: 0 },
                            { label: "90°", value: 1 },
                            { label: "180°", value: 2 },
                            { label: "270°", value: 3 }
                        ]

                        delegate: Rectangle {
                            id: transChip
                            height: Shell.Theme.scaled(30)
                            implicitWidth: transText.implicitWidth + Shell.Theme.scaled(20)
                            radius: Shell.Theme.bubbleRadiusPill

                            readonly property bool isCurrent: root.currentMon && root.currentMon.transform === modelData.value

                            color: isCurrent ? Shell.Theme.accentColor : (transMouse.containsMouse ? Shell.Theme.cardBackgroundHover : Qt.rgba(1, 1, 1, 0.04))
                            border.color: isCurrent ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                            border.width: isCurrent ? 1.5 : 1
                            scale: transMouse.pressed ? 0.94 : 1.0

                            Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Shell.Theme.animInstant } }

                            Text {
                                id: transText
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Shell.Theme.scaled(11)
                                font.weight: transChip.isCurrent ? Font.Bold : Font.Normal
                                color: transChip.isCurrent ? Shell.Colors.on_primary : Shell.Theme.text
                            }

                            MouseArea {
                                id: transMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentMon) {
                                        DisplayService.requestTransformChange(root.currentMon.name, modelData.value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true; height: Shell.Theme.scaled(16) }
}
