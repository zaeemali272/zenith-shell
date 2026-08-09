import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property double load: 0.0
    property int loadPerc: 0
    property int fs: 0
    property string cpuModel: ""
    property string freq: ""
    property string arch: ""
    property string kernel: ""
    property string ip: ""
    property var coreUsages: []
    property var coreTemps: []

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/resources.sh"

    // Continuous streaming daemon process (Zero polling timers)
    Process {
        id: proc
        command: ["bash", scriptPath]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (!line || line.trim() === "") return;
                try {
                    const data = JSON.parse(line);
                    service.cpu = data.cpu ?? 0;
                    service.mem = data.mem ?? 0;
                    service.temp = data.temp ?? 0;
                    service.load = data.load ?? 0.0;
                    service.loadPerc = data.load_perc ?? 0;
                    service.fs = data.fs ?? 0;
                    service.cpuModel = data.cpu_model ?? "";
                    service.freq = data.freq ?? "";
                    service.arch = data.arch ?? "";
                    service.kernel = data.kernel ?? "";
                    service.ip = data.ip ?? "";
                } catch (e) {}
            }
        }
        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 3000
        onTriggered: proc.running = true
    }
}
