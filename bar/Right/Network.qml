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
    readonly property bool airplaneMode: WifiService.isAirplane

    function formatSpeed(kb) {
        if (kb < 1024)
            return kb + " KB/s";
        return (kb / 1024).toFixed(1) + " MB/s";
    }

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: pill.width

    Pill {
        id: pill

        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                showUpload = !showUpload;
            else if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("network"); 
        }

        Behavior on color { ColorAnimation { duration: 300 } }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            Text {
                text: airplaneMode ? "󰀞" : (!wifiConnected ? "󰤮" : (showUpload ? Theme.netUpIcon : Theme.netDownIcon))
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: airplaneMode ? Theme.powerRed : (!wifiConnected ? Theme.powerRed : Theme.accentColor)
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: airplaneMode ? "OFF" : (!wifiConnected ? "DISC" : (pill.containsMouse ? (wifiSSID ? wifiSSID : "Connected") : formatSpeed(showUpload ? upSpeed : downSpeed)))
                font.pixelSize: Theme.fontSize
                font.weight: (airplaneMode || !wifiConnected) ? Font.Bold : Font.Normal
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
        interval: (pill.containsMouse || Variables.quickSettingsOpen) ? Variables.fastInterval : Variables.mediumInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!netExec.running) {
                netExec.running = true;
            }
        }
    }
}
