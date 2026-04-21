pragma Singleton
import QtQuick
import Quickshell

QtObject {
    // =====================================================
    // ================= DYNAMIC SCALING ===================
    // =====================================================
    
    // We use 1080 as our reference height (1080p)
    readonly property real referenceHeight: 1080
    readonly property real screenHeight: Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080
    
    // Scale factor: e.g., 0.66 for 720p, 1.0 for 1080p, 2.0 for 4K
    readonly property real scale: screenHeight / referenceHeight

    // Helper to scale values manually if needed
    function scaled(val) { return Math.round(val * scale); }
    
    
    readonly property int appMenuCol: 6

    // ===== Colors (Catppuccin Mocha inspired) =====
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color surface0: '#242532'
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay2: "#9399b2"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color text: "#cdd6f4"
    readonly property color lavender: "#b4befe"
    readonly property color blue: "#89b4fa"
    readonly property color sapphire: "#74c7ec"
    readonly property color sky: "#89dceb"
    readonly property color teal: "#94e2d5"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color maroon: "#eba0ac"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color flamingo: "#f2cdcd"
    readonly property color rosewater: "#f5e0dc"

    // ===== Bar =====
    readonly property int barHeight: scaled(30)
    readonly property int barRadius: scaled(18)
    readonly property int barMarginLeft: scaled(5)
    readonly property int barMarginRight: scaled(5)
    readonly property int barMarginTop: scaled(5)
    readonly property int barMarginBottom: 0
    readonly property color barColor: "#00000000"
    readonly property color backgroundColor: mantle
    readonly property color borderColor: surface0
    readonly property color accentColor: mauve
    readonly property real barOpacity: 0.92

    // ===== Workspaces =====
    readonly property string workspaceBackgroundStyle: "full" // "full" or "pills"
    readonly property int wsHeight: scaled(10)
    readonly property int wsActiveWidth: scaled(28)
    readonly property int wsInactiveWidth: scaled(10)
    readonly property int wsSpacing: scaled(6)
    readonly property color wsActiveColor: '#ff5757'
    readonly property color wsActiveTextColor: '#111111'
    readonly property color wsOccupiedColor: lavender
    readonly property color wsEmptyColor: pillColor

    // ===== Pills =====
    readonly property int pillHeight: scaled(28)
    readonly property int pillRadius: scaled(14)
    readonly property int pillPadding: scaled(16)
    readonly property int extraPillPadding: scaled(5)
    readonly property color pillColor: "#bd000000"
    readonly property int pillSpacing: scaled(4)
    readonly property int pillGap: scaled(6)
    readonly property color pillBorderColor: "#ffffff22"
    readonly property int pillBorderWidth: 1
    readonly property int pillHoverBorderWidth: 2
    readonly property color pillHoverColor: surface0
    
    // ===== Typography =====
    readonly property int fontSize: scaled(13)
    readonly property int iconSize: scaled(14)
    readonly property string iconFont: "MesloLGS NF"
    readonly property color fontColor: text
    
    // ===== Menu / Popup Styling =====
    readonly property color menuBackground: "#11111b"
    readonly property color menuBorder: surface0
    readonly property color menuHoverBorder: '#00b4befe'
    readonly property int menuRadius: scaled(24)
    readonly property int menuPadding: scaled(20)
    readonly property int menuSpacing: scaled(15)
    readonly property color menuActiveTab: blue
    readonly property color menuInactiveTab: "transparent"
    
    // ===== Widget Specific Colors =====
    readonly property color cpuColor: red
    readonly property color memColor: blue
    readonly property color tempColor: green
    readonly property color bluetoothColor: blue
    readonly property color volumeColor: blue
    readonly property color powerRed: red
    readonly property color powerYellow: yellow
    readonly property color powerGreen: green
    readonly property color mediaPeach: peach
    readonly property color mediaGray: surface2

    // ===== Active States =====
    readonly property color activePillColor: surface0
    readonly property color activeBorderColor: '#130d21'
    readonly property color activeTextColor: '#9c9c9c'
    readonly property color inactiveTextColor: overlay1

    // ===== Battery thresholds =====
    readonly property int high: 90
    readonly property int midHigh: 70
    readonly property int mid: 50
    readonly property int low: 30
    readonly property int critical: 10

    // ===== Battery colors =====
    readonly property color chargingColor: green
    readonly property color conserveColor: green
    readonly property color highColor: green
    readonly property color midColor: yellow
    readonly property color lowColor: peach
    readonly property color criticalColor: red

    // ===== Icons (Nerd Font) =====
    readonly property string chargingIcon: "󰂄"
    readonly property string pluggedIcon: ""
    readonly property string iconHigh: "󰁹"
    readonly property string iconMidHigh: "󰂀"
    readonly property string iconMid: "󰁿"
    readonly property string iconLow: "󰁾"
    readonly property string iconCritical: "󰁼"
    readonly property string volMute: "󰝟"
    readonly property string volLow: "󰕿"
    readonly property string volMid: "󰖀"
    readonly property string volHigh: "󰕾"
    readonly property string btIcon: "󰂯"
    readonly property string netUpIcon: ""
    readonly property string netDownIcon: ""

    function batteryLevel(percent) {
        if (percent <= critical) return "critical";
        if (percent <= low) return "low";
        if (percent <= mid) return "mid";
        if (percent <= midHigh) return "midHigh";
        return "high";
    }

    function batteryIcon(percent, charging) {
        if (percent === undefined) return iconHigh;
        if (charging) return chargingIcon;
        if (percent <= critical) return iconCritical;
        if (percent <= low) return iconLow;
        if (percent <= mid) return iconMid;
        if (percent <= midHigh) return iconMidHigh;
        return iconHigh;
    }

    function batteryColorFor(percent, charging) {
        if (percent === undefined) return highColor;
        if (charging) return chargingColor;
        if (percent <= critical) return criticalColor;
        if (percent <= low) return lowColor;
        if (percent <= mid) return midColor;
        return highColor;
    }
}
