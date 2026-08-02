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

    function refresh() {
        if (!proc.running) {
            proc.running = true;
        }
    }

    Process {
        id: proc
        command: ["bash", scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
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
                    service.coreUsages = data.core_usages ?? [];
                    service.coreTemps = data.core_temps ?? [];
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: Variables.activeMenuOpen ? Variables.fastInterval : Variables.mediumInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: service.refresh()
    }
}
