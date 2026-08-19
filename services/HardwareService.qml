// services/HardwareService.qml
//
// What this machine physically has. The shell uses it to leave out controls
// for hardware that is not present -- a Bluetooth panel on a desktop with no
// adapter, or a battery readout in a VM, is a dead button that makes the whole
// bar feel broken.
//
// Read once at startup from sysfs via scripts/detect_hardware.sh. None of this
// changes while the machine is running, so there is nothing to poll.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

QtObject {
    id: service

    // Optimistic defaults: until the probe returns, show everything. Hiding a
    // widget and then bringing it back looks like a glitch; the reverse is not
    // noticeable.
    property bool hasBattery: true
    property bool hasBluetooth: true
    property bool hasWifi: true
    property bool hasEthernet: true
    property bool hasBacklight: true
    property bool isVM: false
    property string virtType: "none"
    property bool isPortable: true
    property bool detected: false

    // Network is only worth a panel if there is something to configure.
    readonly property bool hasNetworking: hasWifi || hasEthernet

    property Process _probe: Process {
        running: true
        command: ["bash", PathSettings.scriptsDir + "/detect_hardware.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(String(text).trim());
                    service.hasBattery   = !!r.battery;
                    service.hasBluetooth = !!r.bluetooth;
                    service.hasWifi      = !!r.wifi;
                    service.hasEthernet  = !!r.ethernet;
                    service.hasBacklight = !!r.backlight;
                    service.isVM         = !!r.vm;
                    service.virtType     = String(r.virt || "none");
                    service.isPortable   = !!r.portable;
                    service.detected     = true;
                } catch (e) {
                    // Leave the optimistic defaults: showing a control that
                    // does nothing is a smaller failure than hiding one that
                    // works.
                    service.detected = false;
                }
            }
        }
    }
}
