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
    property bool isInteracting: false
    
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
    property bool _pendingRefresh: false

    // Primary connected device info
    property string connectedName: ""
    property string connectedAddress: ""
    property int connectedBattery: -1
    property string connectedIcon: "bluetooth"

    function refresh(full, userInitiated) {
        if (statusExec.running) {
            _pendingRefresh = true;
            return;
        }
        if (isInteracting && !userInitiated) return;

        if (userInitiated) {
            _manualRefreshActive = true;
            _manualRefreshFloor.restart();
        }

        let doFull = (full !== undefined) ? full : Variables.quickSettingsOpen;
        
        statusExec.command = ["python3", "-c", `
import subprocess, json, re

def run_cmd(cmd):
    try: return subprocess.check_output(cmd, text=True, timeout=2).strip()
    except: return ''

result = None
do_full = ${doFull ? "True" : "False"}

# 1. Fast path: D-Bus ObjectManager (~3ms)
try:
    raw = subprocess.check_output(
        ['busctl', '--system', 'call', 'org.bluez', '/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects', '--json=short'],
        text=True, timeout=1.2
    )
    obj_data = json.loads(raw)['data'][0]
    
    is_powered = False
    is_scanning = False
    devices = []
    connected_addrs = set()
    conn_name = ''
    conn_addr = ''
    conn_battery = -1
    conn_icon = 'bluetooth'

    for path, ifaces in obj_data.items():
        if 'org.bluez.Adapter1' in ifaces:
            ad = ifaces['org.bluez.Adapter1']
            if 'Powered' in ad and ad['Powered'].get('data'):
                is_powered = True
            if 'Discovering' in ad and ad['Discovering'].get('data'):
                is_scanning = True

    for path, ifaces in obj_data.items():
        if 'org.bluez.Device1' in ifaces:
            dev = ifaces['org.bluez.Device1']
            addr = dev.get('Address', {}).get('data', '')
            name = dev.get('Alias', {}).get('data') or dev.get('Name', {}).get('data', '') or addr
            paired = bool(dev.get('Paired', {}).get('data', False))
            trusted = bool(dev.get('Trusted', {}).get('data', False))
            connected = bool(dev.get('Connected', {}).get('data', False))
            icon = dev.get('Icon', {}).get('data', 'bluetooth')
            batt = -1
            if 'org.bluez.Battery1' in ifaces:
                batt = ifaces['org.bluez.Battery1'].get('Percentage', {}).get('data', -1)
            
            is_addr_fmt = bool(re.match(r'^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$', name))
            has_real_name = bool(name and not is_addr_fmt)
            
            if connected:
                connected_addrs.add(addr)
                if not conn_addr:
                    conn_addr = addr
                    conn_name = name
                    conn_battery = batt
                    conn_icon = icon

            if do_full or connected:
                devices.append({
                    'address': addr,
                    'name': name,
                    'hasName': has_real_name,
                    'paired': paired,
                    'trusted': trusted,
                    'isKnown': paired or trusted,
                    'connected': connected,
                    'icon': icon,
                    'battery': batt
                })

    result = {
        'powered': is_powered,
        'scanning': is_scanning,
        'connected': len(connected_addrs) > 0,
        'connectedName': conn_name,
        'connectedAddress': conn_addr,
        'connectedBattery': conn_battery,
        'connectedIcon': conn_icon,
        'serviceActive': True,
        'isServiceEnabled': True,
        'devices': devices if do_full else None
    }
except Exception:
    pass

# 2. Fallback path if busctl is missing or fails
if result is None:
    show = run_cmd(['bluetoothctl', 'show'])
    is_powered = 'Powered: yes' in show
    is_scanning = 'Discovering: yes' in show
    all_devs_raw = run_cmd(['bluetoothctl', 'devices']) if do_full else ''
    paired_devs_raw = (run_cmd(['bluetoothctl', 'devices', 'Paired']) or run_cmd(['bluetoothctl', 'paired-devices'])) if do_full else ''
    trusted_devs_raw = run_cmd(['bluetoothctl', 'devices', 'Trusted']) if do_full else ''
    connected_devs_raw = run_cmd(['bluetoothctl', 'devices', 'Connected'])

    paired_addrs = set(l.split()[1] for l in paired_devs_raw.splitlines() if len(l.split()) >= 2 and l.startswith('Device ')) if do_full else set()
    trusted_addrs = set(l.split()[1] for l in trusted_devs_raw.splitlines() if len(l.split()) >= 2 and l.startswith('Device ')) if do_full else set()
    connected_addrs = set(l.split()[1] for l in connected_devs_raw.splitlines() if len(l.split()) >= 2 and l.startswith('Device '))

    devices = []
    if do_full:
        seen = set()
        combined_lines = all_devs_raw.splitlines() + paired_devs_raw.splitlines() + trusted_devs_raw.splitlines() + connected_devs_raw.splitlines()
        for line in combined_lines:
            p = line.split()
            if len(p) >= 2 and p[0] == 'Device':
                addr = p[1]
                if addr in seen: continue
                seen.add(addr)
                raw_name = ' '.join(p[2:]) if len(p) > 2 else addr
                is_addr_fmt = bool(re.match(r'^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$', raw_name))
                has_real_name = len(p) > 2 and not is_addr_fmt
                is_p = addr in paired_addrs
                is_t = addr in trusted_addrs
                is_c = addr in connected_addrs
                devices.append({
                    'address': addr,
                    'name': raw_name,
                    'hasName': has_real_name,
                    'paired': is_p,
                    'trusted': is_t,
                    'isKnown': is_p or is_t,
                    'connected': is_c,
                    'icon': 'bluetooth',
                    'battery': -1
                })

    conn_name = ''
    conn_addr = ''
    conn_battery = -1
    conn_icon = 'bluetooth'
    if connected_addrs:
        conn_addr = list(connected_addrs)[0]

    service_active = run_cmd(['systemctl', 'is-active', 'bluetooth.service']) == 'active'
    is_enabled = run_cmd(['systemctl', 'is-enabled', 'bluetooth.service']) == 'enabled' if do_full else True

    result = {
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
    }

print(json.dumps(result))
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
                        if (!root.isInteracting) {
                            updateModel(data.devices);
                        }
                    }
                } catch (e) {}
            }
        }
        onExited: {
            if (root._pendingRefresh) {
                root._pendingRefresh = false;
                root.refresh();
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
            let aKnown = Boolean(a.isKnown || a.paired || a.trusted);
            let bKnown = Boolean(b.isKnown || b.paired || b.trusted);
            if (aKnown !== bKnown) return aKnown ? -1 : 1;
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
        if (!powered || scanning || isPerformingAction || isInteracting) return;
        root.state = "Starting Scan";
        root.scanning = true;
        scanExec.command = ["bluetoothctl", "scan", "on"];
        scanExec.running = true;
    }

    function stopScan() {
        root.scanning = false;
        root.state = "Idle";
        scanExec.running = false;
        scanExec.command = ["bluetoothctl", "scan", "off"];
        scanExec.running = true;
    }

    function action(mode, addr) {
        if (actionExec.running || powerExec.running || startupToggleExec.running) return;
        if (scanExec.running) {
            scanExec.running = false;
        }
        root.state = mode.charAt(0).toUpperCase() + mode.slice(1) + "ing...";

        // Optimistic UI updates - respond in 0ms to user actions!
        if (mode === "connect") {
            let updated = [];
            let devName = "";
            let devIcon = "bluetooth";
            let devBatt = -1;
            for (let i = 0; i < root.devices.length; i++) {
                let d = Object.assign({}, root.devices[i]);
                if (d.address === addr) {
                    d.connected = true;
                    devName = d.name;
                    devIcon = d.icon || "bluetooth";
                    devBatt = d.battery !== undefined ? d.battery : -1;
                }
                updated.push(d);
            }
            root.connected = true;
            root.connectedAddress = addr;
            if (devName) root.connectedName = devName;
            root.connectedIcon = devIcon;
            root.connectedBattery = devBatt;
            updateModel(updated);
        } else if (mode === "disconnect") {
            let updated = [];
            for (let i = 0; i < root.devices.length; i++) {
                let d = Object.assign({}, root.devices[i]);
                if (d.address === addr) {
                    d.connected = false;
                }
                updated.push(d);
            }
            let anyConnected = false;
            let nextConnName = "";
            let nextConnAddr = "";
            let nextConnIcon = "bluetooth";
            let nextConnBatt = -1;
            for (let i = 0; i < updated.length; i++) {
                if (updated[i].connected) {
                    anyConnected = true;
                    nextConnAddr = updated[i].address;
                    nextConnName = updated[i].name;
                    nextConnIcon = updated[i].icon || "bluetooth";
                    nextConnBatt = updated[i].battery !== undefined ? updated[i].battery : -1;
                    break;
                }
            }
            root.connected = anyConnected;
            root.connectedAddress = nextConnAddr;
            root.connectedName = nextConnName;
            root.connectedIcon = nextConnIcon;
            root.connectedBattery = nextConnBatt;
            updateModel(updated);
        } else if (mode === "remove") {
            let updated = [];
            for (let i = 0; i < root.devices.length; i++) {
                if (root.devices[i].address !== addr) {
                    updated.push(root.devices[i]);
                }
            }
            updateModel(updated);
        }

        let cmd = "";
        if (mode === "connect") {
             cmd = `bluetoothctl scan off 2>/dev/null; bluetoothctl trust ${addr} && bluetoothctl connect ${addr}`;
        } else if (mode === "pair") {
             cmd = `bluetoothctl scan off 2>/dev/null; bluetoothctl trust ${addr} && bluetoothctl pair ${addr} && bluetoothctl connect ${addr}`;
        } else if (mode === "disconnect") {
             cmd = `bluetoothctl disconnect ${addr}`;
        } else if (mode === "remove") {
             cmd = `bluetoothctl untrust ${addr}; bluetoothctl disconnect ${addr}; bluetoothctl remove ${addr}`;
        }

        actionExec.command = ["sh", "-c", cmd];
        actionExec.running = true;
    }

    Process { id: oneShotScan; command: ["sh", "-c", "bluetoothctl --timeout 10 scan on & bluetoothctl --timeout 10 discoverable on; wait"] }
    
    Timer {
        id: postActionPoll
        interval: 400
        repeat: true
        property int count: 0
        onTriggered: {
            if (!root.isInteracting) {
                refresh(true);
            }
            VolumeService.update();
            count++;
            if (count >= 4) stop();
        }
        function trigger() {
            count = 0;
            restart();
        }
    }

    Process { id: powerExec; onExited: { _actionInProgress = false; root.state = "Idle"; root.refresh(true); postActionPoll.trigger(); VolumeService.update(); } }
    Process { id: scanExec; onExited: { root.state = "Idle"; root.refresh(true); postActionPoll.trigger(); } }
    Process { id: actionExec; onExited: { root.state = "Idle"; root.refresh(true); postActionPoll.trigger(); VolumeService.update(); } }

    Timer {
        id: debouncedBtRefresh
        interval: 50
        repeat: false
        onTriggered: {
            if (!root.isInteracting) {
                root.refresh(Variables.quickSettingsOpen);
            }
        }
    }

    // Real-time Event-driven D-Bus Bluetooth Monitor
    Process {
        id: btMonitor
        command: ["gdbus", "monitor", "--system", "--dest", "org.bluez"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    debouncedBtRefresh.restart();
                    if (data.indexOf("Connected") !== -1 || data.indexOf("Device1") !== -1) {
                        VolumeService.update();
                    }
                }
            }
        }
        onExited: restartBtMon.start()
    }

    Timer {
        id: restartBtMon
        interval: 2000
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