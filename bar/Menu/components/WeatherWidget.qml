import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."

Rectangle {
    id: root

    implicitHeight: 250
    implicitWidth: 320
    color: "#181825"
    radius: 12
    border.color: "#313244"
    border.width: 1

    Component.onCompleted: console.log("WeatherWidget: Initialized")

    property var weatherData: null
    property bool loading: true

    // WWO Code to Icon mapping - Using dedicated Nerd Font Weather glyphs
    function getIcon(code) {
        if (!code) return ""; // Default to cloudy if no code
        const c = parseInt(code);
        if (c === 113) return ""; // Sunny/Clear
        if (c === 116) return ""; // PartlyCloudy
        if (c === 119 || c === 122) return ""; // Cloudy/Very Cloudy
        if ([143, 248, 260].includes(c)) return ""; // Fog
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308].includes(c)) return ""; // Light Rain/Rain
        if ([200, 386, 389, 392, 395].includes(c)) return ""; // Thundery Showers
        if ([227, 230, 323, 326, 329, 332, 335, 338, 350, 368, 371].includes(c)) return ""; // Snow
        return ""; // Fallback to cloudy
    }

    Process {
        id: weatherProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    root.weatherData = JSON.parse(text);
                } catch(e) {
                    root.weatherData = null;
                }
            }
        }
    }
    
    Timer {
        interval: 1800000 // 30 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.loading = true;
            weatherProc.running = false;
            weatherProc.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Weather"
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 16
            }
            Item { Layout.fillWidth: true }
            Text {
                text: (root.weatherData && root.weatherData.nearest_area) ? root.weatherData.nearest_area[0].areaName[0].value : "..."
                color: "#a6adc8"
                font.pixelSize: 12
            }
        }

        // Main Content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.loading && root.weatherData && root.weatherData.current_condition

            RowLayout {
                anchors.centerIn: parent
                spacing: 20

                // Current Icon & Temp
                ColumnLayout {
                    spacing: 5
                    Layout.alignment: Qt.AlignVCenter // Align vertically in the Row
                    
                    Text {
                        text: root.getIcon(root.weatherData?.current_condition?.[0]?.weatherCode)
                        color: "#f9e2af"
                        font.pixelSize: 48
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.iconFont // Hardcode a known NF for testing, or fallback to Theme.iconFont
                    }
                    Text {
                        text: (root.weatherData?.current_condition?.[0]?.temp_C || "0") + "°C"
                        color: "#cdd6f4"
                        font.pixelSize: 24
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: root.weatherData?.current_condition?.[0]?.weatherDesc?.[0]?.value || ""
                        color: "#bac2de"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.preferredWidth: 100
                        horizontalAlignment: Text.AlignHCenter // Ensure text centering
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: "#313244"
                }

                // Forecast (Next 2 days)
                ColumnLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: (root.weatherData && root.weatherData.weather) ? root.weatherData.weather.slice(1, 3) : []
                        delegate: RowLayout {
                            spacing: 10
                            Text {
                                text: Qt.formatDate(new Date(modelData.date), "ddd")
                                color: "#9399b2"
                                font.pixelSize: 12
                                Layout.preferredWidth: 30
                            }
                            Text {
                                // Use noon forecast (approx index 4)
                                text: root.getIcon(modelData.hourly[4].weatherCode)
                                color: "#f9e2af"
                                font.pixelSize: 14
                                font.family: Theme.iconFont
                            }
                            Text {
                                text: modelData.maxtempC + "° / " + modelData.mintempC + "°"
                                color: "#cdd6f4"
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }

        // Loading State
        Text {
            visible: root.loading
            text: "Loading..."
            color: "#6c7086"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
        
        // Error State
        Text {
            visible: !root.loading && !root.weatherData
            text: "Weather Unavailable"
            color: "#f38ba8"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }
}
