import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../.."

Rectangle {
    id: root
    implicitHeight: Theme.scaled(320)
    implicitWidth: Theme.scaled(320)
    color: Theme.menuBackground
    radius: Theme.scaled(16)
    border.color: Theme.surface1
    border.width: 1

    readonly property var weatherData: WeatherService.weatherData
    readonly property bool loading: WeatherService.loading

    function getIcon(code) {
        return WeatherService.getIcon(code);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(20)
        spacing: Theme.scaled(15)

        // Header - Always at the top
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Weather"; color: Theme.blue; font.weight: Font.Black; font.pixelSize: Theme.scaled(14); font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { text: (root.weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || WeatherService.areaName); color: Theme.surface2; font.pixelSize: Theme.scaled(11) }
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
                    color: Theme.powerYellow; font.pixelSize: Theme.scaled(56)
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
                color: Theme.surface1
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
                        Text { text: Qt.formatDate(new Date(modelData.date), "ddd"); color: Theme.surface2; font.pixelSize: Theme.scaled(11); Layout.preferredWidth: Theme.scaled(35) }
                        Text { text: root.getIcon(modelData.hourly[4]?.weatherCode || "113"); color: Theme.powerYellow; font.pixelSize: Theme.scaled(18); Layout.preferredWidth: Theme.scaled(20) }
                        Text { text: modelData.maxtempC + "°"; color: Theme.text; font.pixelSize: Theme.scaled(13); font.bold: true }
                    }
                }
            }
        }

        // Space at the bottom to ensure the main row stays centered
        Item { Layout.fillHeight: true; visible: !root.loading }

        // Loading/Error states
        Text { 
            visible: root.loading
            text: "Loading..."; color: Theme.surface2
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter 
        }
    }
}