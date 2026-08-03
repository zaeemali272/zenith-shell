// services/VolumeService.qml
import QtQuick
import Quickshell
import Quickshell.Io
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

    function _performUpdate() {
        if (!volExec.running) {
            volExec.running = true;
        }
        if (Variables.quickSettingsOpen || Variables.controlCenterOpen) {
            if (!appVolExec.running) appVolExec.running = true;
            if (!devExec.running) devExec.running = true;
        }
    }

    Timer {
        id: updateTimer
        interval: 300
        onTriggered: _performUpdate()
    }

    Component.onCompleted: _performUpdate()

    ListModel {
        id: appModel
    }

    Process {
        id: appVolExec
        command: ["sh", "-c", "pactl -f json list sink-inputs 2>/dev/null || python3 -c '\nimport json, subprocess\ntry:\n    data = json.loads(subprocess.check_output([\"pw-dump\"]))\n    result = []\n    for obj in data:\n        if obj.get(\"type\") == \"PipeWire:Interface:Node\":\n            props = obj.get(\"info\", {}).get(\"props\", {})\n            if props.get(\"media.class\") == \"Stream/Output/Audio\":\n                name = props.get(\"application.name\") or props.get(\"media.name\") or \"App\"\n                vol_pct = 100\n                muted = False\n                params = obj.get(\"info\", {}).get(\"params\", {})\n                for p in params.get(\"Props\", []):\n                    if \"channelVolumes\" in p:\n                        vols = p[\"channelVolumes\"]\n                        if vols:\n                            vol_pct = int(round(max(vols) * 100))\n                    if \"mute\" in p:\n                        muted = bool(p[\"mute\"])\n                result.append({\n                    \"index\": obj[\"id\"],\n                    \"properties\": {\"application.name\": name},\n                    \"volume\": {\"front-left\": {\"value_percent\": str(vol_pct) + \"%\"}},\n                    \"mute\": muted\n                })\n    print(json.dumps(result))\nexcept Exception:\n    print(\"[]\")\n'"]
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
        command: ["sh", "-c", "pw-mon 2>/dev/null || pactl subscribe"]
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
        command: ["python3", "-c", `
import json, subprocess, re

res = {"outputVolume": 0, "muted": False, "micVolume": 0, "micMuted": False, "micActive": False, "btActive": False}

try:
    out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True, stderr=subprocess.DEVNULL)
    res["muted"] = "[MUTED]" in out
    m = re.search(r"([0-9]+\.?[0-9]*)", out)
    if m: res["outputVolume"] = round(float(m.group(1)) * 100)
except Exception: pass

try:
    out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], text=True, stderr=subprocess.DEVNULL)
    res["micMuted"] = "[MUTED]" in out
    m = re.search(r"([0-9]+\.?[0-9]*)", out)
    if m: res["micVolume"] = round(float(m.group(1)) * 100)
except Exception: pass

try:
    insp = subprocess.check_output(["wpctl", "inspect", "@DEFAULT_AUDIO_SINK@"], text=True, stderr=subprocess.DEVNULL)
    res["btActive"] = "bluez" in insp.lower()
except Exception: pass

try:
    dump = json.loads(subprocess.check_output(["pw-dump"], stderr=subprocess.DEVNULL))
    res["micActive"] = any(
        obj.get("type") == "PipeWire:Interface:Node" and 
        obj.get("info", {}).get("props", {}).get("media.class") == "Stream/Input/Audio"
        for obj in dump
    )
except Exception: pass

print(json.dumps(res))
`]
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
        command: ["python3", "-c", `
import subprocess, re, json

def get_desc(dev_id):
    try:
        out = subprocess.check_output(['wpctl', 'inspect', str(dev_id)], text=True, timeout=1)
        for line in out.splitlines():
            if 'node.description' in line:
                m = re.search(r'node\\.description\\s*=\\s*"(.*)"', line)
                if m: return m.group(1)
    except: pass
    return ''

def get_devices():
    try: out = subprocess.check_output(['wpctl', 'status'], text=True, timeout=2)
    except Exception: out = ''

    sinks, sources = [], []
    active_sink, active_source = -1, -1

    in_sinks = False
    in_sources = False

    for line in out.splitlines():
        if 'Sinks:' in line:
            in_sinks = True
            in_sources = False
            continue
        elif 'Sources:' in line:
            in_sources = True
            in_sinks = False
            continue
        elif any(k in line for k in ['Filters:', 'Streams:', 'Settings', 'Video']):
            in_sinks = False
            in_sources = False

        m = re.search(r'(\\*?\\s*)(\\d+)\\.\\s+(.*?)\\s*(\\[|$)', line)
        if m and (in_sinks or in_sources):
            is_def = '*' in m.group(1)
            dev_id = int(m.group(2))
            dev_name = m.group(3).strip()

            if not dev_name or dev_name == '(null)' or 'camera' in dev_name.lower():
                continue

            if dev_name.startswith('Built-in Audio'):
                dev_name = 'Built-in Microphone' if in_sources else 'Built-in Speaker'
            elif dev_name.startswith('bluez_'):
                real_desc = get_desc(dev_id)
                if real_desc: dev_name = real_desc

            item = {'id': dev_id, 'name': dev_name, 'isDefault': is_def}
            if in_sinks:
                sinks.append(item)
                if is_def: active_sink = dev_id
            elif in_sources:
                sources.append(item)
                if is_def: active_source = dev_id

    if not any('bluez' in s['name'].lower() or 'bluetooth' in s['name'].lower() or 'yopod' in s['name'].lower() for s in sources):
        for line in out.splitlines():
            if '[Audio/Source]' in line and ('bluez' in line or 'bluetooth' in line):
                m = re.search(r'(\\*?\\s*)(\\d+)\\.\\s+(.*?)\\s*\\[Audio/Source\\]', line)
                if m:
                    is_def = '*' in m.group(1)
                    dev_id = int(m.group(2))
                    real_desc = get_desc(dev_id)
                    dev_name = real_desc if real_desc else 'Bluetooth Microphone'
                    item = {'id': dev_id, 'name': dev_name, 'isDefault': is_def}
                    sources.append(item)
                    if is_def: active_source = dev_id

    return {'sinks': sinks, 'sources': sources, 'activeSinkId': active_sink, 'activeSourceId': active_source}

print(json.dumps(get_devices()))
`]
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
