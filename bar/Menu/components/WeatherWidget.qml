import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../.."

Rectangle {
    id: root
    implicitHeight: Theme.scaled(320)
    implicitWidth: Theme.scaled(320)
    color: "transparent"
    radius: Theme.scaled(16)
    border.color: Theme.glassBorder
    border.width: 0

    readonly property var weatherData: WeatherService.weatherData
    readonly property bool loading: WeatherService.loading

    function getIcon(code) {
        return WeatherService.getIcon(code);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(20)
        spacing: Theme.scaled(15)

        // Header - Location only (no redundant title)
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(6)
            Text {
                text: "󰍎"
                font.family: Theme.iconFont
                color: Theme.accentColor
                font.pixelSize: Theme.scaled(12)
                Layout.alignment: Qt.AlignVCenter
            }
            Text { 
                text: root.weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || WeatherService.areaName
                color: Theme.accentColor
                font.pixelSize: Theme.scaled(11)
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        // Main Content Row - Forced vertical centering
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.scaled(20)
            visible: !root.loading && root.weatherData

            // Left Side: Current Weather
            ColumnLayout {
                Layout.preferredWidth: Theme.scaled(140)
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(5)
                
                Text {
                    text: root.getIcon(root.weatherData?.current_condition?.[0]?.weatherCode)
                    font.family: Theme.iconFont
                    color: Theme.powerYellow; font.pixelSize: Theme.scaled(64)
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: (root.weatherData?.current_condition?.[0]?.temp_C || WeatherService.tempC) + "°C"
                    color: Theme.text; font.pixelSize: Theme.scaled(32); font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: root.weatherData?.current_condition?.[0]?.weatherDesc?.[0]?.value || WeatherService.weatherDesc
                    color: Theme.subtext0; font.pixelSize: Theme.scaled(12)
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    lineHeight: 0.9
                }
            }

            // Vertical Divider
            Rectangle { 
                width: 1
                Layout.fillHeight: true
                Layout.maximumHeight: Theme.scaled(120)
                color: Theme.glassBorder
                Layout.alignment: Qt.AlignVCenter
            }

            // Right Side: Forecast
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(15)
                
                Repeater {
                    model: (root.weatherData?.weather || []).slice(1, 4)
                    delegate: RowLayout {
                        spacing: Theme.scaled(12)
                        Text { text: Qt.formatDate(new Date(modelData.date), "ddd"); color: Theme.subtext0; font.pixelSize: Theme.scaled(11); Layout.preferredWidth: Theme.scaled(35) }
                        Text { text: root.getIcon(modelData.hourly[4]?.weatherCode || "113"); font.family: Theme.iconFont; color: Theme.powerYellow; font.pixelSize: Theme.scaled(22); Layout.preferredWidth: Theme.scaled(24) }
                        Text { text: modelData.maxtempC + "°"; color: Theme.text; font.pixelSize: Theme.scaled(13); font.bold: true }
                    }
                }
            }
        }

        // Space at the bottom to ensure the main row stays centered
        Item { Layout.fillHeight: true; visible: !root.loading && root.weatherData }

        // --- Weather Skeleton Loader while loading ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.scaled(20)
            visible: root.loading

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.35; to: 0.75; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.75; to: 0.35; duration: 900; easing.type: Easing.InOutSine }
            }

            // Left: Current weather skeleton
            ColumnLayout {
                Layout.preferredWidth: Theme.scaled(140)
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(10)

                Rectangle {
                    width: Theme.scaled(56)
                    height: Theme.scaled(56)
                    radius: width / 2
                    color: Qt.rgba(255, 255, 255, 0.1)
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    width: Theme.scaled(72)
                    height: Theme.scaled(24)
                    radius: Theme.scaled(6)
                    color: Qt.rgba(255, 255, 255, 0.12)
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    width: Theme.scaled(90)
                    height: Theme.scaled(10)
                    radius: Theme.scaled(3)
                    color: Qt.rgba(255, 255, 255, 0.07)
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Vertical Divider
            Rectangle { 
                width: 1
                Layout.fillHeight: true
                Layout.maximumHeight: Theme.scaled(120)
                color: Theme.glassBorder
                Layout.alignment: Qt.AlignVCenter
            }

            // Right: Forecast skeletons
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(16)

                Repeater {
                    model: 3
                    delegate: RowLayout {
                        spacing: Theme.scaled(12)
                        Rectangle { width: Theme.scaled(30); height: Theme.scaled(10); radius: 2; color: Qt.rgba(255, 255, 255, 0.08) }
                        Rectangle { width: Theme.scaled(20); height: Theme.scaled(20); radius: 10; color: Qt.rgba(255, 255, 255, 0.1) }
                        Rectangle { width: Theme.scaled(24); height: Theme.scaled(10); radius: 2; color: Qt.rgba(255, 255, 255, 0.12) }
                    }
                }
            }
        }

        // --- Error/Empty state & helper text ---
        ColumnLayout {
            visible: !root.loading && !root.weatherData
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            Text {
                text: "󰖐"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(36)
                color: Theme.subtext0
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "WEATHER UNAVAILABLE"
                color: Theme.text
                font.pixelSize: Theme.scaled(11)
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Unable to reach forecast server. Retrying automatically."
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(10)
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}