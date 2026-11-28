import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    id: barRoot
    spacing: 0

    property int subTab: 0

    // Header + Modular Sub-Section Switcher
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        Layout.topMargin: Shell.Theme.scaled(16)
        Layout.bottomMargin: Shell.Theme.scaled(12)
        spacing: Shell.Theme.scaled(12)

        Text {
            text: "Bar & Widgets"
            font.pixelSize: Shell.Theme.scaled(20)
            font.weight: Font.Bold
            color: Shell.Theme.text
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: subRow.implicitWidth + Shell.Theme.scaled(8)
            height: Shell.Theme.scaled(30)
            radius: 999
            color: Shell.Theme.cardBackground
            border.color: Shell.Theme.glassBorder
            border.width: 1

            Row {
                id: subRow
                anchors.centerIn: parent
                spacing: Shell.Theme.scaled(4)

                Repeater {
                    model: ["Layout", "Widgets", "Workspaces", "Media"]
                    delegate: Rectangle {
                        readonly property bool active: barRoot.subTab === index
                        width: subLbl.implicitWidth + Shell.Theme.scaled(16)
                        height: Shell.Theme.scaled(22)
                        radius: 999
                        color: active ? Shell.Theme.accentColor : (subM.containsMouse ? Shell.Theme.cardBackgroundHover : "transparent")
                        Text {
                            id: subLbl
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Shell.Theme.scaled(10)
                            font.weight: Font.Bold
                            color: active ? Shell.Colors.on_primary : Shell.Theme.subtext0
                        }
                        MouseArea {
                            id: subM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: barRoot.subTab = index
                        }
                    }
                }
            }
        }
    }

    // 0: Bar Layout
    ColumnLayout {
        visible: barRoot.subTab === 0
        Layout.fillWidth: true
        spacing: 0

        SettingRow {
            label: "Height"
            description: "Vertical thickness in pixels of the status bar and floating pill containers"
            NumberInput {
                from: 20; to: 100; step: 2
                value: BarSettings.height
                onValueModified: {
                    BarSettings.height = value;
                    PillSettings.height = value;
                }
            }
        }

        SettingRow {
            label: "Radius"
            description: "Corner curvature radius for the bar surface and capsule pill islands"
            NumberInput {
                from: 0; to: 50; step: 2
                value: BarSettings.radius
                onValueModified: {
                    BarSettings.radius = value;
                    PillSettings.radius = value;
                }
            }
        }

        SettingRow {
            label: "Opacity"
            description: "Overall translucency and glassmorphism alpha channel of the status bar"
            MaterialSlider {
                from: 0.1; to: 1.0; stepSize: 0.05
                value: BarSettings.opacity
                onMoved: BarSettings.opacity = value
                onValueChanged: if (pressed) BarSettings.opacity = value
            }
        }

        SettingRow {
            label: "Entry Animation"
            description: "Play smooth slide-in easing animation when the status bar first loads"
            MaterialSwitch {
                checked: BarSettings.entryAnimation
                onClicked: BarSettings.entryAnimation = checked
                onToggled: BarSettings.entryAnimation = checked
            }
        }

        SettingRow {
            label: "Duration (ms)"
            description: "Milliseconds for status bar enter, exit, and hide transitions"
            NumberInput {
                from: 100; to: 3000; step: 100
                value: BarSettings.animationDuration
                onValueModified: BarSettings.animationDuration = value
            }
        }
    }

    // 1: Bar Widgets
    ColumnLayout {
        visible: barRoot.subTab === 1
        Layout.fillWidth: true
        spacing: 0

        SettingRow {
            label: "Enable Media/Weather"
            description: "Display currently playing media tracks and live weather updates in the bar center"
            MaterialSwitch {
                checked: WidgetSettings.enableMedia
                onClicked: WidgetSettings.enableMedia = checked
                onToggled: WidgetSettings.enableMedia = checked
            }
        }

        SettingRow {
            label: "Enable Battery"
            description: "Show battery percentage, remaining time, and charge status in the status bar"
            MaterialSwitch {
                checked: WidgetSettings.enableBattery
                onClicked: WidgetSettings.enableBattery = checked
                onToggled: WidgetSettings.enableBattery = checked
            }
        }

        SettingRow {
            label: "Enable Resources"
            description: "Monitor live CPU load, RAM allocation, and network transfer speeds"
            MaterialSwitch {
                checked: WidgetSettings.enableResources
                onClicked: WidgetSettings.enableResources = checked
                onToggled: WidgetSettings.enableResources = checked
            }
        }
    }

    // 2: Workspaces
    WorkspaceTab {
        visible: barRoot.subTab === 2
        Layout.fillWidth: true
    }

    // 3: Media in Bar
    MediaTab {
        visible: barRoot.subTab === 3
        Layout.fillWidth: true
    }

    Item { Layout.fillHeight: true }
}
