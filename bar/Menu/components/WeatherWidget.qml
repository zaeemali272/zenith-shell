import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../.."

Rectangle {
    id: root
    implicitHeight: Theme.scaled(300)
    implicitWidth: Theme.scaled(360)
    color: "transparent"
    radius: Theme.scaled(16)
    border.color: Theme.glassBorder
    border.width: 0

    readonly property var weatherData: WeatherService.weatherData
    readonly property bool loading: WeatherService.loading

    function getIcon(code) {
        return WeatherService.getIcon(code);
    }

    function iconColorFor(code) {
        const c = parseInt(code);
        if (c === 113 || c === 116) return Theme.accentColor;
        if ([176, 263, 266, 293, 296, 302, 308, 200, 386, 389].includes(c)) return Theme.blue;
        return Theme.text;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(12)
        spacing: Theme.scaled(10)

        // --- HEADER ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(6)

            Rectangle {
                implicitWidth: locRow.implicitWidth + Theme.scaled(16)
                Layout.maximumWidth: parent.width - Theme.scaled(96)
                height: Theme.scaled(24)
                radius: 999
                color: Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    id: locRow
                    anchors.fill: parent
                    anchors.leftMargin: Theme.scaled(8)
                    anchors.rightMargin: Theme.scaled(8)
                    spacing: Theme.scaled(5)

                    Text {
                        text: "󰍎"
                        font.family: Theme.iconFont
                        color: Theme.accentColor
                        font.pixelSize: Theme.scaled(11)
                    }
                    Text {
                        Layout.fillWidth: true
                        text: WeatherService.areaName + (WeatherService.countryName ? ", " + WeatherService.countryName : "")
                        color: Theme.text
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: WeatherService.lastUpdated !== "" && !root.loading
                text: WeatherService.lastUpdated
                color: Theme.subtext2
                font.pixelSize: Theme.scaled(9)
            }

            Rectangle {
                width: Theme.scaled(24); height: Theme.scaled(24)
                radius: Theme.scaled(7)
                color: refreshMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(12)
                    color: root.loading ? Theme.accentColor : (refreshMouse.containsMouse ? Theme.text : Theme.subtext0)
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherService.refresh()
                }
            }
        }

        // --- MAIN WEATHER CONTENT ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.scaled(10)
            visible: !root.loading && !!root.weatherData

            // Hero Current Weather Row
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.scaled(12)

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.scaled(10)

                    Text {
                        text: root.getIcon(WeatherService.weatherCode)
                        font.family: Theme.iconFont
                        color: root.iconColorFor(WeatherService.weatherCode)
                        font.pixelSize: Theme.scaled(46)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: WeatherService.tempC + "°C"
                            color: Theme.text
                            font.pixelSize: Theme.scaled(28)
                            font.weight: Font.Black
                        }

                        Text {
                            text: WeatherService.weatherDesc
                            color: Theme.subtext1
                            font.pixelSize: Theme.scaled(11)
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: High/Low & Pressure/Cloud summary pill
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: Theme.scaled(3)

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Theme.scaled(6)
                        Text {
                            text: "H: " + WeatherService.todayMaxC + "°"
                            color: Theme.text
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "L: " + WeatherService.todayMinC + "°"
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: "Feels " + WeatherService.feelsLikeC + "°  •  " + WeatherService.pressure + " hPa"
                        color: Theme.subtext2
                        font.pixelSize: Theme.scaled(9)
                    }
                }
            }

            // 4-Column Equal-Width Telemetry Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)

                Repeater {
                    model: [
                        { icon: "󰖎", label: "HUMIDITY", val: WeatherService.humidity + "%", col: Theme.blue },
                        { icon: "󰖝", label: "WIND", val: WeatherService.windSpeed + " km/h", col: Theme.green },
                        { icon: "󰖗", label: "RAIN", val: WeatherService.todayRainChance + "%", col: Theme.accentColor },
                        { icon: "󰖙", label: "UV INDEX", val: WeatherService.uvIndex, col: Theme.accentColor }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: Theme.scaled(46)
                        radius: Theme.scaled(9)
                        color: Theme.cardBackground
                        border.color: Theme.glassBorder
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.scaled(6)
                            spacing: Theme.scaled(1)

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: Theme.scaled(3)
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(10)
                                    color: modelData.col
                                }
                                Text {
                                    text: modelData.label
                                    color: Theme.subtext2
                                    font.pixelSize: Theme.scaled(7.5)
                                    font.weight: Font.Black
                                    font.letterSpacing: 0.4
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.val
                                color: Theme.text
                                font.pixelSize: Theme.scaled(10.5)
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // 5-Day Forecast Strip
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)

                Repeater {
                    model: WeatherService.forecastDays
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: Theme.scaled(74)
                        radius: Theme.scaled(10)
                        color: dayHover.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                        border.color: index === 0 ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.4) : Theme.glassBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        MouseArea {
                            id: dayHover
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.scaled(6)
                            spacing: Theme.scaled(2)

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd")
                                color: index === 0 ? Theme.accentColor : Theme.subtext0
                                font.pixelSize: Theme.scaled(9.5)
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.getIcon(modelData.hourly?.[4]?.weatherCode || "113")
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(19)
                                color: root.iconColorFor(modelData.hourly?.[4]?.weatherCode || "113")
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.maxtempC + "° / " + modelData.mintempC + "°"
                                color: Theme.text
                                font.pixelSize: Theme.scaled(9)
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }

        // --- SKELETON LOADER ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.scaled(10)
            visible: root.loading

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.35; to: 0.75; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.75; to: 0.35; duration: 900; easing.type: Easing.InOutSine }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.scaled(12)
                color: Qt.rgba(255, 255, 255, 0.06)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)
                Repeater {
                    model: 4
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: Theme.scaled(46)
                        radius: Theme.scaled(9)
                        color: Qt.rgba(255, 255, 255, 0.06)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)
                Repeater {
                    model: 5
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: Theme.scaled(74)
                        radius: Theme.scaled(10)
                        color: Qt.rgba(255, 255, 255, 0.06)
                    }
                }
            }
        }

        // --- ERROR / OFFLINE STATE ---
        ColumnLayout {
            visible: !root.loading && !root.weatherData
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.scaled(8)

            Text {
                text: "󰖐"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(36)
                color: Theme.subtext0
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Weather unavailable"
                color: Theme.text
                font.pixelSize: Theme.scaled(12)
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: retryTxt.implicitWidth + Theme.scaled(18)
                height: Theme.scaled(26)
                radius: Theme.scaled(8)
                color: Theme.accentColor
                Text {
                    id: retryTxt
                    anchors.centerIn: parent
                    text: "Retry"
                    color: Colors.on_primary
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Bold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherService.refresh()
                }
            }
        }
    }
}
