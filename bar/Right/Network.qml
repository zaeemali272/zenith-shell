import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property var menuRef
    property bool showUpload: false
    property real rxPrev: 0
    property real txPrev: 0
    property int downSpeed: 0
    property int upSpeed: 0
    property bool wifiConnected: false
    property string wifiSSID: ""
    property bool airplaneMode: false

    function formatSpeed(kb) {
        if (kb < 1024)
            return kb + " KB/s";

        return (kb / 1024).toFixed(1) + " MB/s";
    }

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.implicitWidth
    Component.onCompleted: {
        statusExec.running = true;
        netExec.running = true;
    }

    // THE RULE: Watch for network or airplane mode changes
    Process {
        id: netWatcher
        command: ["sh", "-c", "inotifywait -q -m -e modify /sys/class/net/*/operstate /dev/rfkill"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                statusExec.running = true;
            }
        }
    }

    Process {
        id: statusExec
        command: ["sh", "-c",
            `iwctl station $(ls /sys/class/net | grep ^wl | head -n1) show | grep 'Connected network' | awk '{$1=$2=""; print "SSID", $0}'; ` +
            `rfkill list wifi | grep -q 'Soft blocked: yes' && echo 'AIRPLANE ON' || echo 'AIRPLANE OFF'`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const lines = text.trim().split("\n");
                let foundSsid = false;
                lines.forEach((line) => {
                    const parts = line.trim().split(/\s+/);
                    if (parts[0] === "SSID") {
                        wifiSSID = parts.slice(1).join(" ").trim();
                        wifiConnected = true;
                        foundSsid = true;
                    } else if (parts[0] === "AIRPLANE") {
                        airplaneMode = (parts[1] === "ON");
                    }
                });
                if (!foundSsid) {
                    wifiConnected = false;
                    wifiSSID = "";
                }
            }
        }
    }

    Pill {
        id: pill

        anchors.fill: parent
        implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        color: airplaneMode ? Theme.accentColor : Theme.pillColor

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                showUpload = !showUpload;
            else if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("network", root.mapToItem(null, 0, 0, root.width, root.height)); 
        }

        onEntered: {
            if (QuickSettingsService.qsVisible || CenterState.qsVisible)
                QuickSettingsService.hoverOpen("network", root.mapToItem(null, 0, 0, root.width, root.height));
        }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: 6

            Text {
                text: airplaneMode ? "󰀝" : (showUpload ? Theme.netUpIcon : Theme.netDownIcon)
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: airplaneMode ? Theme.backgroundColor : Theme.activeTextColor
            }

            Text {
                text: airplaneMode ? "Airplane Mode" : (pill.containsMouse ? (wifiConnected ? wifiSSID : "Disconnected") : formatSpeed(showUpload ? upSpeed : downSpeed))
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: pill.containsMouse ? -1 : 55 
                Layout.fillWidth: pill.containsMouse 
                font.pixelSize: Theme.fontSize
                color: airplaneMode ? Theme.backgroundColor : Theme.activeTextColor
                font.bold: airplaneMode
            }
        }
    }

    Process {
        id: netExec

        command: ["sh", "-c",
            `IFACE=$(ip route | awk '/default/ {print $5; exit}'); ` +
            `awk -v iface="$IFACE" '$1 ~ iface":" {print "SPEED", $2, $10}' /proc/net/dev`
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const parts = text.trim().split(/\s+/);
                if (parts[0] === "SPEED") {
                    const rx = parseFloat(parts[1]);
                    const tx = parseFloat(parts[2]);
                    if (rxPrev > 0) {
                        downSpeed = Math.max(0, Math.floor(((rx - rxPrev) / 1024) / 5));
                        upSpeed = Math.max(0, Math.floor(((tx - txPrev) / 1024) / 5));
                    }
                    rxPrev = rx;
                    txPrev = tx;
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 5000 
        running: true
        repeat: true
        onTriggered: netExec.running = true
    }

}
