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
        netExec.running = true;
        netWatcher.running = true;
    }

    // THE RULE: Watch for network or airplane mode changes
    Process {
        id: netWatcher

        command: ["sh", "-c", "inotifywait -q -e modify /sys/class/net/*/operstate /dev/rfkill"]
        running: false
        onExited: {
            netExec.running = true;
            safetyTimer.start();
        }
    }

    Timer {
        id: safetyTimer

        interval: 500
        onTriggered: netWatcher.running = true
    }

    Pill {
        id: pill

        anchors.fill: parent
        implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        color: airplaneMode ? Theme.accentColor : Theme.pillColor

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
                text: airplaneMode ? "Airplane Mode" : (mainMouse.containsMouse ? (wifiConnected ? wifiSSID : "Disconnected") : formatSpeed(showUpload ? upSpeed : downSpeed))
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: mainMouse.containsMouse ? -1 : 55 // Fixed 80px for speed, auto for SSID
                Layout.fillWidth: mainMouse.containsMouse // Let it grow only when showing SSID
                font.pixelSize: Theme.fontSize
                color: airplaneMode ? Theme.backgroundColor : Theme.activeTextColor
                font.bold: airplaneMode
            }

        }

    }

    MouseArea {
        id: mainMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                menuRef.active = !menuRef.active;
            else if (mouse.button === Qt.RightButton)
                showUpload = !showUpload;
        }
    }

    Process {
        id: netExec

        command: ["sh", "-c", "IFACE=$(ip route | awk '/default/ {print $5; exit}'); " + "awk -v iface=\"$IFACE\" '$1 ~ iface\":\" {print \"SPEED\", $2, $10}' /proc/net/dev; " + "iwctl station $(ls /sys/class/net | grep ^wl | head -n1) show | grep 'Connected network' | awk '{$1=$2=\"\"; print \"SSID\", $0}'; " + "rfkill list wifi | grep -q 'Soft blocked: yes' && echo 'AIRPLANE ON' || echo 'AIRPLANE OFF'"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) {
                    refreshTimer.start();
                    return ;
                }
                const lines = text.trim().split("\n");
                let foundSsid = false;
                lines.forEach((line) => {
                    const parts = line.trim().split(/\s+/);
                    if (parts[0] === "SPEED") {
                        const rx = parseFloat(parts[1]);
                        const tx = parseFloat(parts[2]);
                        if (rxPrev > 0) {
                            // FIXED CALCULATION: Divide by 3 to get average KB per second
                            downSpeed = Math.max(0, Math.floor(((rx - rxPrev) / 1024) / 3));
                            upSpeed = Math.max(0, Math.floor(((tx - txPrev) / 1024) / 3));
                        }
                        rxPrev = rx;
                        txPrev = tx;
                    } else if (parts[0] === "SSID") {
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
                refreshTimer.start();
            }
        }

    }

    Timer {
        id: refreshTimer

        interval: 3000 // Set to 3 seconds as requested
        onTriggered: netExec.running = true
    }

}