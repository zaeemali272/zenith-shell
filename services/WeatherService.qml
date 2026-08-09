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

    readonly property string tempC: weatherData?.current_condition?.[0]?.temp_C || "0"
    readonly property string weatherCode: weatherData?.current_condition?.[0]?.weatherCode || "113"
    readonly property string weatherDesc: weatherData?.current_condition?.[0]?.weatherDesc?.[0]?.value || ""
    readonly property string areaName: weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || "Unknown"

    readonly property string cacheFile: PathSettings.cacheDir + "/weather.json"
    readonly property string scriptPath: PathSettings.scriptsDir + "/weather.sh"

    function getIcon(code) {
        const c = parseInt(code);
        if (c === 113) return ""; 
        if (c === 116) return ""; 
        if (c === 119 || c === 122) return "";
        if ([143, 248, 260].includes(c)) return ""; 
        if ([176, 263, 266, 293, 296, 302, 308].includes(c)) return "";
        if ([200, 386, 389].includes(c)) return ""; 
        return "";
    }

    function refresh() {
        if (!weatherProc.running) {
            service.loading = true;
            weatherProc.running = true;
        }
    }

    Component.onCompleted: {
        loadCache.running = true;
        refresh();
    }

    Process {
        id: loadCache
        command: ["python3", "-c", "import sys, os, json; p=sys.argv[1]; print(open(p).read() if os.path.exists(p) else '')", cacheFile]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    try {
                        let parsed = JSON.parse(text);
                        if (parsed && parsed.current_condition) {
                            service.weatherData = parsed;
                            service.loading = false;
                        }
                    } catch (e) {}
                }
            }
        }
    }

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
                        saveCache.command = ["python3", "-c", "import sys, os; p=sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(sys.argv[2])", cacheFile, text];
                        saveCache.running = false;
                        saveCache.running = true;
                    }
                } catch (e) {}
            }
        }
    }

    Process { id: saveCache }

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        onTriggered: service.refresh()
    }
}
