import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)
    Layout.fillWidth: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        entryAnim.start();
    }
    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 500; easing.type: Theme.elasticEasing }
    }

    // Header Row
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.scaled(5)
        Layout.rightMargin: Theme.scaled(5)

        Text {
            text: "POWER PROFILES"
            color: Theme.mauve
            font.pixelSize: Theme.scaled(10)
            font.weight: Font.Black
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            radius: Theme.scaled(10)
            color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.3)
            implicitHeight: Theme.scaled(22)
            implicitWidth: activeLabel.implicitWidth + Theme.scaled(16)

            Text {
                id: activeLabel
                anchors.centerIn: parent
                text: PowerProfileService.currentProfile.toUpperCase()
                color: Theme.accentColor
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Bold
            }
        }
    }

    // 2x2 Grid of Power Profile Cards
    GridLayout {
        columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(12)
        columnSpacing: Theme.scaled(12)

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", color: Theme.powerRed, label: "PERFORMANCE", desc: "Max Speed & Power" },
                { id: "balanced",    icon: "󰏤", color: Theme.blue, label: "BALANCED", desc: "Optimal Performance" },
                { id: "powersave",   icon: "󰍛", color: Theme.powerGreen, label: "POWER SAVER", desc: "Extended Battery Life" },
                { id: "turbo",       icon: "󰞃", color: Theme.powerYellow, label: "TURBO", desc: "Peak Boost Mode" }
            ]

            delegate: Rectangle {
                id: profileCard
                Layout.fillWidth: true
                height: Theme.scaled(82)
                color: PowerProfileService.currentProfile === modelData.id ? 
                       Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18) : 
                       Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
                radius: Theme.scaled(18)
                border.width: PowerProfileService.currentProfile === modelData.id ? 2 : 1
                border.color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.glassBorder

                scale: m.pressed ? 0.96 : (m.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Theme.elasticEasing } }
                Behavior on color { ColorAnimation { duration: 250 } }

                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: PowerProfileService.setProfile(modelData.id)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(12)
                    spacing: Theme.scaled(12)

                    Rectangle {
                        width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(14)
                        color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Qt.rgba(1,1,1,0.06)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: PowerProfileService.currentProfile === modelData.id ? Theme.base : modelData.color
                        }
                    }

                    ColumnLayout {
                        spacing: Theme.scaled(2)
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: Theme.scaled(6)
                            Text {
                                text: modelData.label
                                font.pixelSize: Theme.scaled(11)
                                font.weight: Font.Black
                                color: Theme.text
                            }

                            Rectangle {
                                visible: PowerProfileService.currentProfile === modelData.id
                                width: Theme.scaled(6); height: Theme.scaled(6); radius: 3
                                color: modelData.color
                            }
                        }

                        Text {
                            text: modelData.desc
                            font.pixelSize: Theme.scaled(9)
                            color: Theme.subtext0
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // Dynamic Hardware Battery Conservation Mode Card
    Rectangle {
        id: consCard
        visible: PowerProfileService.conservativeSupported
        Layout.fillWidth: true
        height: Theme.scaled(82)
        radius: Theme.scaled(18)
        color: PowerProfileService.conservativeActive ? 
               Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.16) : 
               Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
        border.width: PowerProfileService.conservativeActive ? 2 : 1
        border.color: PowerProfileService.conservativeActive ? Theme.accentColor : Theme.glassBorder

        Behavior on color { ColorAnimation { duration: 250 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(14)
            spacing: Theme.scaled(14)

            // Icon Badge
            Rectangle {
                width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(14)
                color: PowerProfileService.conservativeActive ? Theme.accentColor : Qt.rgba(1,1,1,0.06)

                Text {
                    anchors.centerIn: parent
                    text: PowerProfileService.conservativeActive ? "󰂄" : "󰁹"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(22)
                    color: PowerProfileService.conservativeActive ? Theme.base : Theme.accentColor
                }
            }

            // Info Column
            ColumnLayout {
                spacing: Theme.scaled(2)
                Layout.fillWidth: true

                RowLayout {
                    spacing: Theme.scaled(6)

                    Text {
                        text: PowerProfileService.conservativeLabel
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Black
                        color: Theme.text
                    }

                    Rectangle {
                        radius: Theme.scaled(6)
                        color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.2)
                        implicitHeight: Theme.scaled(16)
                        implicitWidth: brandText.implicitWidth + Theme.scaled(10)

                        Text {
                            id: brandText
                            anchors.centerIn: parent
                            text: String(PowerProfileService.conservativeBrand || "Battery Care").toUpperCase()
                            color: Theme.accentColor
                            font.pixelSize: Theme.scaled(7)
                            font.weight: Font.Bold
                        }
                    }
                }

                Text {
                    text: PowerProfileService.conservativeActive ? 
                          "Charge capped to ~60-80% for maximum lifespan" : 
                          "Charges to 100% (Click switch to enable protection)"
                    font.pixelSize: Theme.scaled(9)
                    color: Theme.subtext0
                    elide: Text.ElideRight
                }
            }

            // Interactive Toggle Button
            Rectangle {
                id: consBtn
                width: Theme.scaled(84)
                height: Theme.scaled(36)
                radius: Theme.scaled(12)
                color: PowerProfileService.conservativeActive ? Theme.accentColor : Qt.rgba(255, 255, 255, 0.12)
                border.width: 1
                border.color: PowerProfileService.conservativeActive ? Theme.accentColor : Theme.glassBorder

                scale: btnMouse.pressed ? 0.95 : (btnMouse.containsMouse ? 1.03 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.scaled(6)

                    Text {
                        text: PowerProfileService.conservativeActive ? "󰄬" : "󰅖"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(12)
                        color: PowerProfileService.conservativeActive ? Theme.base : Theme.text
                    }

                    Text {
                        text: PowerProfileService.conservativeActive ? "ON" : "OFF"
                        color: PowerProfileService.conservativeActive ? Theme.base : Theme.text
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Black
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerProfileService.toggleConservativeMode()
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}