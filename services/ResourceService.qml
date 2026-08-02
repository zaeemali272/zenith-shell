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
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: WidgetSettings.enableResources || QuickSettingsService.qsVisible
        triggeredOnStart: true
        onTriggered: service.refresh()
    }
}
