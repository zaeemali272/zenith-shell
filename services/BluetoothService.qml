pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

Item {
    id: root

    // --- State Variables ---
    property var devices: []
    property int deviceCount: devices.length
    property bool powered: false
    property bool connected: false
    property bool scanning: false
    property bool serviceActive: true
    property bool isServiceEnabled: false
    property string state: "Idle"
    
    readonly property bool isPerformingAction: actionExec.running || powerExec.running || scanExec.running || oneShotScan.running || _actionInProgress || startupToggleExec.running
    readonly property bool isRefreshing: statusExec.running
    property bool busy: isPerformingAction || isRefreshing

    // ---- SPIN STATE FOR THE MANUAL REFRESH CONTROL ----
    //
    // `busy` is true for *any* status probe, including the background ones
    // fired by every bluetoothctl monitor event and the three follow-up polls
    // that run one second apart after each action. Driving the refresh
    // button's spinner and colour from it meant the button strobed several
    // times whenever you connected or paired a device -- the flicker.
    //
    // This tracks only work the user actually asked for, and holds for a
    // minimum period so a probe that finishes in 150ms still reads as
    // deliberate feedback rather than a flash.
    readonly property bool userBusy: isPerformingAction || _manualRefreshActive

    property bool _manualRefreshActive: false

    property Timer _manualRefreshFloor: Timer {
        interval: 700
        onTriggered: if (!statusExec.running) root._manualRefreshActive = false
    }

    property Connections _manualRefreshWatch: Connections {
        target: statusExec
        function onRunningChanged() {
            if (!statusExec.running && !root._manualRefreshFloor.running)
                root._manualRefreshActive = false;
        }
    }
    
    property bool _actionInProgress: false

    // Primary connected device info
    property string connectedName: ""
    property string connectedAddress: ""
    property int connectedBattery: -1
    property string connectedIcon: "bluetooth"

    function refresh(full, userInitiated) {
        if (statusExec.running) return;

        if (userInitiated) {
            _manualRefreshActive = true;
            _manualRefreshFloor.restart();
        }

        let doFull = (full !== undefined) ? full : Variables.quickSettingsOpen;
        
        statusExec.command = ["python3", "-c", `
import subprocess, json, re

def run(cmd):
    try: return subprocess.check_output(cmd, text=True, timeout=3).strip()
    except: return ''

show = run(['bluetoothctl', 'show'])
is_powered = 'Powered: yes' in show
is_scanning = 'Discovering: yes' in show

do_full = ${doFull ? "True" : "False"}

all_devs_raw = run(['bluetoothctl', 'devices']) if do_full else ''
paired_devs_raw = run(['bluetoothctl', 'paired-devices']) if do_full else ''
connected_devs_raw = run(['bluetoothctl', 'devices', 'Connected'])

paired_addrs = set(l.split()[1] for l in paired_devs_raw.splitlines() if l.startswith('Device ')) if do_full else set()
connected_addrs = set(l.split()[1] for l in connected_devs_raw.splitlines() if l.startswith('Device '))

devices = []
if do_full:
    seen = set()
    for line in all_devs_raw.splitlines():
        p = line.split()
        if len(p) >= 2 and p[0] == 'Device':
            addr = p[1]
            if addr in seen: continue
            seen.add(addr)
            raw_name = ' '.join(p[2:]) if len(p) > 2 else addr
            is_addr_fmt = bool(re.match(r'^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$', raw_name))
            has_real_name = len(p) > 2 and not is_addr_fmt
            devices.append({
                'address': addr,
                'name': raw_name,
                'hasName': has_real_name,
                'paired': addr in paired_addrs,
                'connected': addr in connected_addrs,
                'icon': 'bluetooth',
                'battery': -1
            })

conn_name = ''
conn_addr = ''
conn_battery = -1
conn_icon = 'bluetooth'

if connected_addrs:
    first_conn = list(connected_addrs)[0]
    
    for c_addr in connected_addrs:
        info_raw = run(['bluetoothctl', 'info', c_addr])
        c_name = ''
        c_icon = 'bluetooth'
        c_batt = -1
        
        for line in info_raw.splitlines():
            l = line.strip()
            if l.startswith('Name: '): c_name = l[6:]
            elif l.startswith('Icon: '): c_icon = l[6:]
            elif l.startswith('Battery Percentage:'):
                try:
                    # Safely parse strings like "Battery Percentage: 0x0a (10)" or "Battery Percentage: 100"
                    if '(' in l and ')' in l:
                        c_batt = int(l.split('(')[1].split(')')[0])
                    else:
                        c_batt = int(l.split(':')[-1].strip())
                except:
                    pass
        
        if c_addr == first_conn:
            conn_addr = c_addr
            conn_name = c_name
            conn_icon = c_icon
            conn_battery = c_batt
            
        for d in devices:
            if d['address'] == c_addr:
                d['battery'] = c_batt
                d['icon'] = c_icon
                if c_name and (not d['name'] or d['name'] == c_addr):
                    d['name'] = c_name

service_active = run(['systemctl', 'is-active', 'bluetooth.service']) == 'active'
is_enabled = run(['systemctl', 'is-enabled', 'bluetooth.service']) == 'enabled'

print(json.dumps({
    'powered': is_powered,
    'scanning': is_scanning,
    'connected': len(connected_addrs) > 0,
    'connectedName': conn_name,
    'connectedAddress': conn_addr,
    'connectedBattery': conn_battery,
    'connectedIcon': conn_icon,
    'serviceActive': service_active,
    'isServiceEnabled': is_enabled,
    'devices': devices if do_full else None
}))
`];
        statusExec.running = true;
    }

    Process {
        id: statusExec
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let data = JSON.parse(text);
                    root.powered = data.powered || false;
                    root.scanning = data.scanning || false;
                    root.connected = data.connected || false;
                    root.connectedName = data.connectedName || "";
                    root.connectedAddress = data.connectedAddress || "";
                    root.connectedBattery = data.connectedBattery !== undefined ? data.connectedBattery : -1;
                    root.connectedIcon = data.connectedIcon || "bluetooth";
                    root.serviceActive = data.serviceActive || false;
                    root.isServiceEnabled = data.isServiceEnabled || false;

                    if (!root.serviceActive) {
                        root.state = "Service Error";
                    } else if (root.state === "Service Error" || root.state === "Idle" || root.state === "Scanning") {
                        root.state = root.scanning ? "Scanning" : "Idle";
                    }

                    if (data.devices && Array.isArray(data.devices)) {
                        updateModel(data.devices);
                    }
                } catch (e) {}
            }
        }
    }

    function toggleStartup() {
        let target = !isServiceEnabled;
        startupToggleExec.command = ["pkexec", "systemctl", target ? "enable" : "disable", "bluetooth.service"];
        startupToggleExec.running = true;
    }

    Process {
        id: startupToggleExec
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.refresh(false);
            }
        }
    }

    function restartService() {
        root.state = "Restarting Service";
        actionExec.command = ["pkexec", "systemctl", "restart", "bluetooth"];
        actionExec.running = true;
    }

    function updateModel(newDevices) {
        newDevices.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        root.devices = newDevices;
    }

    function togglePower() {
        if (isPerformingAction) return;
        let newState = !powered;
        root.state = newState ? "Powering On" : "Powering Off";
        _actionInProgress = true;
        root.powered = newState;
        
        powerExec.command = ["bluetoothctl", "power", newState ? "on" : "off"];
        powerExec.running = true;
    }

    function toggleScan() {
        if (isPerformingAction) return;
        let target = !scanning;
        root.state = target ? "Starting Scan" : "Stopping Scan";
        root.scanning = target;
        
        scanExec.command = ["bluetoothctl", "scan", target ? "on" : "off"];
        scanExec.running = true;
    }

    function startScan() {
        if (!powered || scanning || isPerformingAction) return;
        root.state = "Starting Scan";
        root.scanning = true;
        scanExec.command = ["bluetoothctl", "scan", "on"];
        scanExec.running = true;
    }

    function stopScan() {
        if (!scanning || isPerformingAction) return;
        root.state = "Stopping Scan";
        root.scanning = false;
        scanExec.command = ["bluetoothctl", "scan", "off"];
        scanExec.running = true;
    }

    function action(mode, addr) {
        if (isPerformingAction) return;
        root.state = mode.charAt(0).toUpperCase() + mode.slice(1) + "ing...";

        let cmd = "";
        if (mode === "connect") {
             cmd = `(bluetoothctl trust ${addr} && (bluetoothctl pair ${addr} || true) && bluetoothctl connect ${addr}) || bluetoothctl connect ${addr}`;
        } else if (mode === "pair") {
             cmd = `bluetoothctl trust ${addr} && (bluetoothctl pair ${addr} || true)`;
        } else if (mode === "disconnect") {
             cmd = `bluetoothctl disconnect ${addr}`;
        } else if (mode === "remove") {
             cmd = `bluetoothctl remove ${addr}`;
        }

        actionExec.command = ["sh", "-c", cmd];
        actionExec.running = true;
    }

    Process { id: oneShotScan; command: ["sh", "-c", "bluetoothctl --timeout 10 scan on & bluetoothctl --timeout 10 discoverable on; wait"] }
    
    Timer {
        id: postActionPoll
        interval: 1000
        repeat: true
        property int count: 0
        onTriggered: {
            refresh(true);
            count++;
            if (count >= 3) stop();
        }
        function trigger() {
            count = 0;
            restart();
        }
    }

    Process { id: powerExec; onExited: { _actionInProgress = false; root.state = "Idle"; postActionPoll.trigger(); } }
    Process { id: scanExec; onExited: { root.state = "Idle"; postActionPoll.trigger(); } }
    Process { id: actionExec; onExited: { root.state = "Idle"; postActionPoll.trigger(); } }

    // Event-driven Bluetooth Monitor
    Process {
        id: btMonitor
        command: ["bluetoothctl", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: (data) => root.refresh(Variables.quickSettingsOpen)
        }
        onExited: restartBtMon.start()
    }

    Timer {
        id: restartBtMon
        interval: 3000
        onTriggered: btMonitor.running = true
    }

    Timer {
        id: btStartupTimer
        interval: 800
        running: true
        repeat: false
        onTriggered: root.refresh(false)
    }
}