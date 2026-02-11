import QtQuick
pragma Singleton

QtObject {
    // =====================================================
    // ================= HELPER FUNCTIONS ==================
    // =====================================================

    // ===== Bar =====
    readonly property int barHeight: 30
    readonly property int barRadius: 18
    readonly property int barMarginLeft: 5
    readonly property int barMarginRight: 5
    readonly property int barMarginTop: 5
    readonly property int barMarginBottom: 0
    readonly property color barColor: "#00000000"
    readonly property color backgroundColor: "#111111"
    readonly property color borderColor: "#101010"
    readonly property color accentColor: "#6200ee"
    readonly property real barOpacity: 0.92
    // ===== Pills =====
    readonly property int pillHeight: 28
    readonly property int pillRadius: 14
    readonly property int pillPadding: 16
    readonly property int extraPillPadding: 5
    readonly property color pillColor: "#bd000000"
    readonly property int pillSpacing: 4
    readonly property int pillGap: 6
    readonly property color pillBorderColor: "#ffffff22"
    readonly property int pillBorderWidth: 1
    readonly property int pillHoverBorderWidth: 2
    readonly property color pillHoverColor: "#1a1a1a"
    // ===== Typography =====
    readonly property int fontSize: 13
    readonly property int iconSize: 14
    readonly property string iconFont: "MesloLGS NF"
    readonly property color fontColor: "#ffffff"
    // ===== Accent / Base Colors =====
    readonly property color green: "#15ff00"
    readonly property color yellow: "#ffae00"
    readonly property color blue: '#2b59a4'
    readonly property color red: "#ea255d"
    readonly property color powerRed: "#ff0000"
    // ===== Active States =====
    readonly property color activePillColor: "#6100ffcc"
    readonly property color activeBorderColor: "#ffffff88"
    readonly property color activeTextColor: "#ffffff"
    readonly property color inactiveTextColor: "#ffffff88"
    // ===== Battery thresholds =====
    readonly property int high: 90
    readonly property int midHigh: 70
    readonly property int mid: 50
    readonly property int low: 30
    readonly property int critical: 10
    // ===== Battery colors =====
    readonly property color chargingColor: "#a6e3a1"
    readonly property color conserveColor: '#6de262'
    readonly property color highColor: "#a6e3a1"
    readonly property color midColor: "#f9e2af"
    readonly property color lowColor: "#fab387"
    readonly property color criticalColor: "#f38ba8"
    readonly property color bluetoothColor: '#5058cb'
    // ===== Battery icons (Nerd Font) =====
    readonly property string chargingIcon: "󰂄"
    readonly property string pluggedIcon: ""
    readonly property string iconHigh: "󰁹"
    readonly property string iconMidHigh: "󰂀"
    readonly property string iconMid: "󰁿"
    readonly property string iconLow: "󰁾"
    readonly property string iconCritical: "󰁼"
    // ===== Volume icons =====
    readonly property string volMute: "󰝟"
    readonly property string volLow: "󰕿"
    readonly property string volMid: "󰖀"
    readonly property string volHigh: "󰕾"
    readonly property string btIcon: "󰂯"
    // ===== Network icons =====
    readonly property string netUpIcon: ""
    readonly property string netDownIcon: ""
    // ===== Resources =====
    readonly property color cpuColor: "#f38ba8"
    readonly property color memColor: "#89b4fa"
    readonly property color tempColor: "#a6e3a1"

    function batteryLevel(percent) {
        if (percent <= critical)
            return "critical";

        if (percent <= low)
            return "low";

        if (percent <= mid)
            return "mid";

        if (percent <= midHigh)
            return "midHigh";

        return "high";
    }

    function batteryIcon(percent, charging) {
        if (charging)
            return chargingIcon;

        if (percent <= critical)
            return iconCritical;

        if (percent <= low)
            return iconLow;

        if (percent <= mid)
            return iconMid;

        if (percent <= midHigh)
            return iconMidHigh;

        return iconHigh;
    }

    function batteryColorFor(percent, charging) {
        if (charging)
            return chargingColor;

        if (percent <= critical)
            return criticalColor;

        if (percent <= low)
            return lowColor;

        if (percent <= mid)
            return midColor;

        return highColor;
    }

}
