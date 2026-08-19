// bar/Right/Network.qml
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var menuRef
    property bool showUpload: false
    property real rxPrev: 0
    property real txPrev: 0
    property int downSpeed: 0
    property int upSpeed: 0

    readonly property bool wifiConnected: WifiService.currentState === "connected"
    readonly property string wifiSSID: WifiService.currentSsid
    readonly property bool airplaneMode: HardwareService.hasWifi && WifiService.isAirplane

    // A machine with no wifi adapter -- a desktop, or most VMs -- is not
    // "disconnected" just because there is no SSID. It is on ethernet, and the
    // widget showed DISC over a perfectly working network.
    readonly property bool wiredOnly: !HardwareService.hasWifi && HardwareService.hasEthernet
    readonly property bool wiredUp: wiredOnly && WifiService.ipv4Address !== ""
    readonly property bool online: wifiConnected || wiredUp

    function formatSpeed(kb) {
        if (kb < 1024)
            return kb + " KB/s";
        return (kb / 1024).toFixed(1) + " MB/s";
    }

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: outerContainer.width

    // Outer Glass Container matching Resources & QuickSettingsCluster exactly
    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.scaled(20)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    showUpload = !showUpload;
                else if (mouse.button === Qt.LeftButton)
                    QuickSettingsService.toggle("network"); 
            }
        }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.scaled(6)

            Text {
                text: airplaneMode ? "󰀞" : (!online ? "󰤮" : (showUpload ? Theme.netUpIcon : Theme.netDownIcon))
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: airplaneMode ? Theme.powerRed : (!wifiConnected ? Theme.powerRed : Theme.accentColor)
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: airplaneMode ? "OFF" : (!online ? "DISC" : (outerContainer.containsMouse ? (outerContainer.wiredOnly ? "Wired" : (wifiSSID ? wifiSSID : "Connected")) : formatSpeed(showUpload ? upSpeed : downSpeed)))
                font.pixelSize: Theme.fontSize
                font.family: "JetBrains Mono"
                font.weight: (airplaneMode || !wifiConnected) ? Font.Bold : Font.DemiBold
                color: airplaneMode ? Theme.powerRed : (!wifiConnected ? Theme.powerRed : Theme.fontColor)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Process {
        id: netExec
        command: ["awk", "/:/ && $1 !~ /lo/ && $2 > 0 {gsub(/:/,\"\"); print \"SPEED\", $2, $10; exit}", "/proc/net/dev"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const parts = text.trim().split(/\s+/);
                if (parts[0] === "SPEED") {
                    const rx = parseFloat(parts[1]);
                    const tx = parseFloat(parts[2]);
                    const dt = (refreshTimer.interval / 1000.0);
                    if (rxPrev > 0 && dt > 0) {
                        downSpeed = Math.max(0, Math.floor(((rx - rxPrev) / 1024) / dt));
                        upSpeed = Math.max(0, Math.floor(((tx - txPrev) / 1024) / dt));
                    }
                    rxPrev = rx;
                    txPrev = tx;
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: (outerContainer.containsMouse || Variables.quickSettingsOpen) ? Variables.fastInterval : Variables.mediumInterval
        running: true
        repeat: true
        onTriggered: {
            netExec.running = false;
            netExec.running = true;
        }
    }
}
