// services/WeatherService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property var weatherData: null
    property bool loading: true
    property string lastUpdated: ""

    readonly property var current: weatherData?.current_condition?.[0] || null
    readonly property var todayForecast: weatherData?.weather?.[0] || null
    readonly property var forecastDays: (weatherData?.weather || []).slice(0, 5)

    readonly property string tempC: current?.temp_C || "0"
    readonly property string feelsLikeC: current?.FeelsLikeC || tempC
    readonly property string humidity: current?.humidity || "0"
    readonly property string pressure: current?.pressure || "0"
    readonly property string windSpeed: current?.windspeedKmph || "0"
    readonly property string windDir: current?.winddir16Point || ""
    readonly property string cloudCover: current?.cloudcover || "0"
    readonly property string uvIndex: current?.uvIndex || "0"
    readonly property string weatherCode: current?.weatherCode || "113"
    readonly property string weatherDesc: current?.weatherDesc?.[0]?.value || ""
    readonly property string areaName: weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || "Unknown"
    readonly property string countryName: weatherData?.nearest_area?.[0]?.country?.[0]?.value || ""
    readonly property string todayMaxC: todayForecast?.maxtempC || tempC
    readonly property string todayMinC: todayForecast?.mintempC || tempC
    readonly property string todayRainChance: todayForecast?.hourly?.[0]?.chanceofrain || "0"

    readonly property string scriptPath: PathSettings.scriptsDir + "/weather.sh"

    function getIcon(code) {
        const c = parseInt(code);
        if (c === 113) return "󰖙";
        if (c === 116) return "󰖕";
        if (c === 119 || c === 122) return "󰖐";
        if ([143, 248, 260].includes(c)) return "󰖑";
        if ([176, 263, 266, 293, 296, 302, 308].includes(c)) return "󰖖";
        if ([200, 386, 389].includes(c)) return "󰖓";
        if ([227, 230, 323, 326, 329, 332, 335, 338].includes(c)) return "󰖘";
        return "󰖐";
    }

    function refresh() {
        if (!weatherProc.running) {
            service.loading = true;
            weatherProc.running = true;
        }
    }

    // weather.sh keeps its own on-disk cache and answers from it instantly
    // when it is under 30 minutes old, so the first call paints the bar at
    // once; only a stale cache costs a network round-trip.
    Component.onCompleted: refresh()

    Process {
        id: weatherProc
        command: ["bash", scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                service.loading = false;
                if (!text || text.trim() === "") return;
                try {
                    let parsed = JSON.parse(text);
                    if (parsed && parsed.current_condition) {
                        service.weatherData = parsed;
                        service.lastUpdated = Qt.formatTime(new Date(), "hh:mm AP");
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        onTriggered: service.refresh()
    }
}
