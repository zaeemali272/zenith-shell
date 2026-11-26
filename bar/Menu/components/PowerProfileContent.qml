import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(14)
    Layout.fillWidth: true
    implicitHeight: profileGrid.implicitHeight + (consCard.visible ? (consCard.implicitHeight + root.spacing) : 0)

    // 2x2 Grid of Power Profile Cards
    GridLayout {
        id: profileGrid
        columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(12)
        columnSpacing: Theme.scaled(12)
        implicitHeight: (Theme.isSmallScreen && Theme.isPortrait)
            ? (Theme.scaled(82) * 4 + rowSpacing * 3)
            : (Theme.scaled(82) * 2 + rowSpacing)

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", label: "PERFORMANCE", desc: "Max Speed & Power" },
                { id: "balanced",    icon: "󰏤", label: "BALANCED", desc: "Optimal Performance" },
                { id: "powersave",   icon: "󰍛", label: "POWER SAVER", desc: "Extended Battery Life" },
                { id: "turbo",       icon: "󰞃", label: "TURBO", desc: "Peak Boost Mode" }
            ]

            delegate: Rectangle {
                id: profileCard

                readonly property color accent: modelData.id === "performance" ? Theme.powerRed
                                              : modelData.id === "balanced"    ? Theme.blue
                                              : modelData.id === "powersave"   ? Theme.powerGreen
                                              : Theme.powerYellow

                Layout.fillWidth: true
                height: Theme.scaled(82)
                implicitHeight: Theme.scaled(82)
                Layout.preferredHeight: Theme.scaled(82)
                color: PowerProfileService.currentProfile === modelData.id ? 
                       Qt.rgba(profileCard.accent.r, profileCard.accent.g, profileCard.accent.b, 0.20) : 
                       (m.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                radius: Theme.bubbleRadiusMedium
                border.width: 1
                border.color: PowerProfileService.currentProfile === modelData.id ? profileCard.accent : Theme.glassBorder

                scale: m.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Theme.elasticEasing; easing.overshoot: 1.15 } }
                Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(12)
                    spacing: Theme.scaled(12)

                    Rectangle {
                        width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.bubbleRadiusSmall
                        color: "transparent"
                        border.width: 0

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(28)
                            color: profileCard.accent
                        }
                    }

                    ColumnLayout {
                        spacing: Theme.scaled(2)
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: Theme.scaled(6)
                            Text {
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: Font.Bold
                                color: Theme.text
                            }

                            Rectangle {
                                visible: PowerProfileService.currentProfile === modelData.id
                                width: Theme.scaled(6); height: Theme.scaled(6); radius: 3
                                color: profileCard.accent
                            }
                        }

                        Text {
                            text: modelData.desc
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.scaled(11)
                            color: Theme.subtext0
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: m
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerProfileService.setProfile(modelData.id)
                }
            }
        }
    }

    // Dynamic Hardware Battery Conservation Mode Card
    Rectangle {
        id: consCard
        visible: Boolean(PowerProfileService.conservativeSupported)
        Layout.fillWidth: true
        height: Theme.scaled(82)
        implicitHeight: Theme.scaled(82)
        Layout.preferredHeight: Theme.scaled(82)
        radius: Theme.bubbleRadiusMedium
        color: PowerProfileService.conservativeActive ? 
               Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.22) : 
               Theme.cardBackground
        border.width: 1
        border.color: PowerProfileService.conservativeActive ? Theme.accentColor : Theme.glassBorder

        Behavior on color { ColorAnimation { duration: Theme.animInstant } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(14)
            spacing: Theme.scaled(14)

            // Icon Badge
            Rectangle {
                width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.bubbleRadiusSmall
                color: "transparent"
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: PowerProfileService.conservativeActive ? "󰂄" : "󰁹"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(28)
                    color: Theme.accentColor
                }
            }

            // Info Column
            ColumnLayout {
                spacing: Theme.scaled(2)
                Layout.fillWidth: true

                RowLayout {
                    spacing: Theme.scaled(6)

                    Text {
                        text: PowerProfileService.conservativeError !== ""
                              ? "NEEDS PERMISSION"
                              : String(PowerProfileService.conservativeLabel || "Battery Care").toUpperCase()
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        color: PowerProfileService.conservativeError !== ""
                               ? Theme.powerRed : Theme.text
                    }

                    Rectangle {
                        radius: Theme.scaled(6)
                        color: "transparent"
                        border.color: Theme.glassBorder
                        border.width: 1
                        implicitHeight: Theme.scaled(16)
                        implicitWidth: brandText.implicitWidth + Theme.scaled(10)

                        Text {
                            id: brandText
                            anchors.centerIn: parent
                            text: String(PowerProfileService.conservativeBrand || "Battery Care").toUpperCase()
                            color: Theme.accentColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.Bold
                        }
                    }
                }

                Text {
                    text: PowerProfileService.conservativeActive ? 
                          "Charge capped to ~60-80% for maximum lifespan" : 
                          "Charges to 100% (Click switch to enable protection)"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.scaled(11)
                    color: Theme.subtext0
                    elide: Text.ElideRight
                }
            }

            // Interactive Toggle Button
            Rectangle {
                id: consBtn
                width: Theme.scaled(84)
                height: Theme.scaled(36)
                radius: Theme.bubbleRadiusSmall
                color: PowerProfileService.conservativeActive ? Theme.accentColor : (btnMouse.containsMouse ? Theme.menuBackground2Hover : Theme.menuBackground2)
                border.width: 1
                border.color: PowerProfileService.conservativeActive ? Theme.accentColor : Theme.glassBorder

                scale: btnMouse.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.animInstant } }

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
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
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
