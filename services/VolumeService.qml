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

    Process {
        id: setDevProc
        onExited: service.update()
    }

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
        interval: 400
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
                } catch (e) {
                }
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
                } catch (err) {
                }
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
        command: ["sh", "-c", "echo \"SINK=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)\"; echo \"SRC=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)\"; wpctl status 2>/dev/null | grep -A 15 \"Streams:\" | grep -q -i \"Input\" && echo \"MIC_ACTIVE=1\" || echo \"MIC_ACTIVE=0\"; wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q -i \"bluez\" && echo \"BT_ACTIVE=1\" || echo \"BT_ACTIVE=0\""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const lines = text.trim().split("\n");
                service.micActive = text.includes("MIC_ACTIVE=1");
                service.btActive = text.includes("BT_ACTIVE=1");
                for (let l of lines) {
                    if (l.includes("SINK")) {
                        service.muted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m) service.outputVolume = Math.round(parseFloat(m[0]) * 100);
                    }
                    if (l.includes("SRC")) {
                        service.micMuted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m) service.micVolume = Math.round(parseFloat(m[0]) * 100);
                    }
                }
            }
        }
    }

    Process {
        id: devExec
        command: ["python3", "-c", "import subprocess, re, json\ndef get_info():\n    try: out = subprocess.check_output(['wpctl', 'status'], text=True)\n    except Exception: out = ''\n    sinks_raw, sources_raw = [], []\n    active_sink, active_source = -1, -1\n    in_sinks, in_sources = False, False\n    for line in out.split('\\n'):\n        if 'Sinks:' in line: in_sinks, in_sources = True, False; continue\n        elif 'Sources:' in line: in_sources, in_sinks = True, False; continue\n        elif line.strip().startswith('├─') or line.strip().startswith('└─'):\n            if any(k in line for k in ['Filters:', 'Streams:', 'Settings', 'Video']): in_sinks = in_sources = False\n        m = re.search(r'(\\*?\\s*)(\\d+)\\.\\s+(.*?)\\s*(\\[|$)', line)\n        if m and (in_sinks or in_sources):\n            is_def = '*' in m.group(1)\n            dev_id = int(m.group(2))\n            dev_name = m.group(3).strip()\n            item = {'id': dev_id, 'name': dev_name, 'isDefault': is_def}\n            if in_sinks:\n                sinks_raw.append(item)\n                if is_def: active_sink = dev_id\n            elif in_sources:\n                sources_raw.append(item)\n                if is_def: active_source = dev_id\n    try:\n        data = json.loads(subprocess.check_output(['pw-dump']))\n        for obj in data:\n            if obj.get('type') == 'PipeWire:Interface:Node':\n                props = obj.get('info', {}).get('props', {})\n                media_class = props.get('media.class', '')\n                node_id = obj.get('id')\n                desc = props.get('node.description') or props.get('node.nick') or props.get('node.name')\n                name = props.get('node.name', '')\n                if ('Audio/Sink' in media_class) and not any(s['id'] == node_id for s in sinks_raw):\n                    sinks_raw.append({'id': node_id, 'name': desc, 'isDefault': (node_id == active_sink)})\n                elif ('Audio/Source' in media_class or 'Input/Audio' in media_class) and not name.endswith('.monitor') and not any(s['id'] == node_id for s in sources_raw):\n                    sources_raw.append({'id': node_id, 'name': desc, 'isDefault': (node_id == active_source)})\n    except Exception: pass\n    def dedupe(lst):\n        seen = set()\n        res = []\n        for d in lst:\n            if d['name'] not in seen:\n                seen.add(d['name'])\n                res.append(d)\n        return res\n    return {'sinks': dedupe(sinks_raw), 'sources': dedupe(sources_raw), 'activeSinkId': active_sink, 'activeSourceId': active_source}\nprint(json.dumps(get_info()))"]
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
