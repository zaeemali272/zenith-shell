// services/BrightnessService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property int brightness: 100
    property int maxBrightness: 100
    property int percentage: 100
    property int _targetPercent: -1

    function update() {
        if (!readProc.running) {
            readProc.running = true;
        }
    }

    function setBrightness(percent) {
        let p = Math.max(1, Math.min(100, Math.round(percent)));
        service.percentage = p;
        service._targetPercent = p;
        if (!applyTimer.running) {
            applyTimer.start();
        }
    }

    Timer {
        id: applyTimer
        interval: 35
        repeat: false
        onTriggered: {
            if (service._targetPercent < 1) return;
            if (setProc.running) {
                applyTimer.restart();
                return;
            }
            let p = service._targetPercent;
            service._targetPercent = -1;
            setProc.command = ["brightnessctl", "-c", "backlight", "set", p + "%", "-q"];
            setProc.running = true;
        }
    }

    Process {
        id: readProc
        command: ["python3", "-c", `
import glob, os, json
actual, max_b = -1, -1
for p in glob.glob('/sys/class/backlight/*'):
    try:
        with open(os.path.join(p, 'actual_brightness')) as f: actual = int(f.read().strip())
        with open(os.path.join(p, 'max_brightness')) as f: max_b = int(f.read().strip())
        if max_b > 0: break
    except: pass
perc = round((actual / max_b) * 100) if max_b > 0 and actual >= 0 else 100
print(json.dumps({'actual': actual, 'max': max_b, 'perc': perc}))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (data.perc !== undefined) {
                        service.percentage = data.perc;
                        service.brightness = data.actual;
                        service.maxBrightness = data.max;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: setProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    console.warn("BrightnessService setProc error:", text.trim());
                }
            }
        }
        onExited: {
            if (service._targetPercent >= 1) {
                applyTimer.restart();
            }
        }
    }

    Component.onCompleted: service.update()
}
