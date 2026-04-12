import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../../"
import Quickshell.Io
import "../"
import "../../"
import "../../.."

Rectangle {
    id: root
    implicitHeight: Theme.scaled(300)
    implicitWidth: Theme.scaled(320)
    color: "#11111b"
    radius: Theme.scaled(16)
    border.color: "#313244"
    border.width: 1

    property var weatherData: null
    property bool loading: true

    function getIcon(code) {
        const c = parseInt(code);
        if (c === 113) return ""; if (c === 116) return ""; if (c === 119 || c === 122) return "";
        if ([143, 248, 260].includes(c)) return ""; if ([176, 263, 266, 293, 296, 302, 308].includes(c)) return "";
        if ([200, 386, 389].includes(c)) return ""; return "";
    }

    Process {
        id: weatherProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: StdioCollector { onStreamFinished: { root.loading = false; try { root.weatherData = JSON.parse(text); } catch(e) { root.weatherData = null; } } }
    }
    
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { root.loading = true; weatherProc.running = false; weatherProc.running = true; } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(20)
        spacing: Theme.scaled(15)

        // Header - Always at the top
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Weather"; color: "#89b4fa"; font.weight: Font.Black; font.pixelSize: Theme.scaled(14); font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { text: (root.weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || "Unknown"); color: "#585b70"; font.pixelSize: Theme.scaled(11) }
        }

        // Main Content Row - Forced vertical centering
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter // This centers the whole block vertically
            spacing: Theme.scaled(20)
            visible: !root.loading && root.weatherData

            // Left Side: Current Weather
            ColumnLayout {
                Layout.preferredWidth: Theme.scaled(140)
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(5) // Tightened spacing for better alignment
                
                Text {
                    text: root.getIcon(root.weatherData?.current_condition?.[0]?.weatherCode)
                    color: "#f9e2af"; font.pixelSize: Theme.scaled(56)
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: (root.weatherData?.current_condition?.[0]?.temp_C || "0") + "°C"
                    color: "#cdd6f4"; font.pixelSize: Theme.scaled(32); font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: root.weatherData?.current_condition?.[0]?.weatherDesc?.[0]?.value || ""
                    color: "#a6adc8"; font.pixelSize: Theme.scaled(12)
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
                Layout.maximumHeight: Theme.scaled(120) // Prevents the line from being too long
                color: "#313244"
                Layout.alignment: Qt.AlignVCenter
            }

            // Right Side: Forecast
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(15) // Spacing between forecast rows
                
                Repeater {
                    model: (root.weatherData?.weather || []).slice(1, 4)
                    delegate: RowLayout {
                        spacing: Theme.scaled(12)
                        Text { text: Qt.formatDate(new Date(modelData.date), "ddd"); color: "#585b70"; font.pixelSize: Theme.scaled(11); Layout.preferredWidth: Theme.scaled(35) }
                        Text { text: root.getIcon(modelData.hourly[4].weatherCode); color: "#f9e2af"; font.pixelSize: Theme.scaled(18); Layout.preferredWidth: Theme.scaled(20) }
                        Text { text: modelData.maxtempC + "°"; color: "#cdd6f4"; font.pixelSize: Theme.scaled(13); font.bold: true }
                    }
                }
            }
        }

        // Space at the bottom to ensure the main row stays centered
        Item { Layout.fillHeight: true; visible: !root.loading }

        // Loading/Error states
        Text { 
            visible: root.loading
            text: "Loading..."; color: "#585b70"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter 
        }
    }
}