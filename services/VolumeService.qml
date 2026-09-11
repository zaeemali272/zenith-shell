// services/VolumeService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"
pragma Singleton

Item {
    id: service

    property int outputVolume: 0
    property int micVolume: 0
    property bool muted: false
    property bool micMuted: false 
    property bool micActive: false
    property bool btActive: false
    property var sinks: []
    property var sources: []
    property int activeSinkId: -1
    property int activeSourceId: -1

    readonly property alias appsModel: appModel

    function update() {
        updateTimer.restart();
    }

    function setDefaultDevice(devId) {
        if (!devId) return;
        setDevProc.command = ["wpctl", "set-default", String(devId)];
        setDevProc.running = false;
        setDevProc.running = true;
    }

    function toggleMute() {
        setMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        setMuteProc.running = false;
        setMuteProc.running = true;
    }

    function setOutputVolume(val) {
        let pct = Math.max(0, Math.min(150, val));
        setOutVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (pct / 100).toFixed(2)];
        setOutVolProc.running = false;
        setOutVolProc.running = true;
    }

    function toggleMicMute() {
        setMicMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        setMicMuteProc.running = false;
        setMicMuteProc.running = true;
    }

    function setMicVolume(val) {
        let pct = Math.max(0, Math.min(150, val));
        setMicVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (pct / 100).toFixed(2)];
        setMicVolProc.running = false;
        setMicVolProc.running = true;
    }

    Process { id: setDevProc; onExited: service.update() }
    Process { id: setMuteProc; onExited: service.update() }
    Process { id: setOutVolProc; onExited: service.update() }
    Process { id: setMicMuteProc; onExited: service.update() }
    Process { id: setMicVolProc; onExited: service.update() }

    // Levels and the device list are refreshed on every PipeWire change. The
    // device list used to be read only while a menu was open, so a headset
    // that connected while the panel was closed did not appear until some
    // later event (a volume key) happened to fire with the panel open.
    // Per-application streams are only needed by the panel itself.
    function _performUpdate() {
        if (!volExec.running) volExec.running = true;
        if (!devExec.running) devExec.running = true;
        if (Variables.activeMenuOpen && !appVolExec.running) appVolExec.running = true;
    }

    Timer {
        id: updateTimer
        interval: 300
        onTriggered: _performUpdate()
    }

    // Opening a menu reads everything fresh rather than showing whatever the
    // last background event left behind.
    Connections {
        target: Variables
        function onActiveMenuOpenChanged() {
            if (Variables.activeMenuOpen) service.update();
        }
    }

    Component.onCompleted: _performUpdate()

    ListModel {
        id: appModel
    }

    Process {
        id: appVolExec
        command: ["python3", PathSettings.scriptsDir + "/audio_streams.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data)) {
                        if (data && typeof data === "object") {
                            processData([data]);
                        }
                        return;
                    }
                    processData(data);
                } catch (e) {}
            }
        }
    }

    function processData(data) {
        let currentIds = new Set();
        if (!data || !Array.isArray(data)) return;
        
        for (let i = 0; i < data.length; i++) {
            let app = data[i];
            if (!app || typeof app !== "object") continue;
            
            let vol = 0;
            if (app.volume) {
                try {
                    for (let channel in app.volume) {
                        let chObj = app.volume[channel];
                        if (chObj && chObj.value_percent) {
                            let v = parseInt(chObj.value_percent);
                            if (!isNaN(v)) {
                                vol = v;
                                break;
                            }
                        }
                    }
                } catch (err) {}
            }
            
            let name = "Unknown App";
            if (app.properties) {
                name = app.properties["application.name"] || app.properties["media.name"] || name;
            }
            name = String(name);
            
            let appId = app.index;
            if (appId === undefined) continue;
            
            currentIds.add(appId);
            let found = false;
            for (let j = 0; j < appModel.count; j++) {
                let item = appModel.get(j);
                if (item && item.appId === appId) {
                    if (item.volume !== vol) appModel.setProperty(j, "volume", vol);
                    let muted = app.mute || false;
                    if (item.muted !== muted) appModel.setProperty(j, "muted", muted);
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                appModel.append({
                    "appId": appId,
                    "name": name,
                    "volume": vol,
                    "muted": app.mute || false,
                    "icon": "\uf2d2"
                });
            }
        }
        
        for (let j = appModel.count - 1; j >= 0; j--) {
            let item = appModel.get(j);
            if (item && !currentIds.has(item.appId)) {
                appModel.remove(j);
            }
        }
    }

    Process {
        id: volListener
        // pw-mon is not a trickle of change events: it dumps the entire
        // PipeWire graph on connect -- measured at 10,237 lines in the first
        // second, then silence. Fed straight into SplitParser that became
        // 10,237 JS callbacks, each restarting the debounce timer, every time
        // the listener (re)connected.
        //
        // awk collapses any burst to at most one line per second, so a
        // reconnect costs one update instead of ten thousand callbacks. The
        // pactl fallback is kept only for machines without pw-mon; it emits
        // nothing on this one, verified by subscribing across a real volume
        // change.
        command: ["sh", "-c",
            "{ pw-mon 2>/dev/null || pactl subscribe; } | " +
            "awk 'systime() != t { t = systime(); print \"change\"; fflush() }'"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                service.update();
            }
        }
        onExited: restartDelay.start()
    }

    Timer {
        id: restartDelay
        interval: 3000
        onTriggered: {
            service.update();
            volListener.running = true;
        }
    }

    Process {
        id: volExec
        command: ["bash", PathSettings.scriptsDir + "/audio_state.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (data.outputVolume !== undefined) service.outputVolume = data.outputVolume;
                    if (data.muted !== undefined) service.muted = data.muted;
                    if (data.micVolume !== undefined) service.micVolume = data.micVolume;
                    if (data.micMuted !== undefined) service.micMuted = data.micMuted;
                    if (data.micActive !== undefined) service.micActive = data.micActive;
                    if (data.btActive !== undefined) service.btActive = data.btActive;
                } catch (e) {}
            }
        }
    }

    Process {
        id: devExec
        command: ["python3", PathSettings.scriptsDir + "/audio_devices.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let data = JSON.parse(text);
                    if (data.sinks) service.sinks = data.sinks;
                    if (data.sources) service.sources = data.sources;
                    if (data.activeSinkId !== undefined) service.activeSinkId = data.activeSinkId;
                    if (data.activeSourceId !== undefined) service.activeSourceId = data.activeSourceId;
                } catch (e) {}
            }
        }
    }
}
