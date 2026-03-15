import ".."
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ================== Props ==================
    property var menuRef
    // ================== State ==================
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
    Component.onCompleted: netExec.running = true

    // ================== UI ==================
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
                text: {
                    if (airplaneMode)
                        return "Airplane Mode";

                    if (mainMouse.containsMouse)
                        return (wifiConnected ? wifiSSID : "Disconnected");

                    return formatSpeed(showUpload ? upSpeed : downSpeed);
                }
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

    // ================== Combined Reader ==================
    Process {
        id: netExec

        // Optimized Shell Command:
        // 1. Get default interface.
        // 2. Print RX/TX.
        // 3. Print SSID with a prefix for easy parsing.
        // 4. Print Airplane status with a prefix.
        command: ["sh", "-c", "IFACE=$(ip route | awk '/default/ {print $5; exit}'); " + "awk -v iface=\"$IFACE\" '$1 ~ iface\":\" {print \"SPEED\", $2, $10}' /proc/net/dev; " + "iwctl station $(ls /sys/class/net | grep ^wl | head -n1) show | grep 'Connected network' | awk '{$1=$2=\"\"; print \"SSID\", $0}'; " + "rfkill list wifi | grep -q 'Soft blocked: yes' && echo 'AIRPLANE ON' || echo 'AIRPLANE OFF'"]
        // Safety: ensure timer restarts even if the command crashes
        onExited: {
            if (!refreshTimer.running)
                refreshTimer.start();

        }

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
                            downSpeed = Math.max(0, Math.floor((rx - rxPrev) / 1024));
                            upSpeed = Math.max(0, Math.floor((tx - txPrev) / 1024));
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
                // Restart the cooldown timer after successful processing
                refreshTimer.start();
            }
        }

    }

    // The "Safe Loop" Timer
    Timer {
        id: refreshTimer

        interval: 3000
        repeat: false // IMPORTANT: Let the Process trigger the next run
        onTriggered: netExec.running = true
    }

}
