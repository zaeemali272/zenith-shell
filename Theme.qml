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

    // ===== Colors (Dynamic from Matugen) =====
    readonly property color base: Colors.background
    readonly property color mantle: Colors.surface
    readonly property color crust: Colors.surface_variant
    readonly property color surface0: Colors.surface_variant
    readonly property color surface1: Colors.surface_variant
    readonly property color surface2: Colors.outline
    readonly property color overlay0: Colors.outline
    readonly property color overlay1: Colors.outline
    readonly property color overlay2: Colors.outline
    readonly property color subtext0: Colors.on_surface_variant
    readonly property color subtext1: Colors.on_surface_variant
    readonly property color text: Colors.on_background
    readonly property color lavender: Colors.secondary
    readonly property color blue: Colors.primary
    readonly property color green: Colors.tertiary
    readonly property color yellow: Colors.secondary_container
    readonly property color red: Colors.error
    readonly property color mauve: Colors.primary
    readonly property color accentColor: Colors.primary

    // ===== Bar =====
    readonly property int barHeight: scaled(30)
    readonly property int barRadius: scaled(18)
    readonly property int barMarginLeft: scaled(5)
    readonly property int barMarginRight: scaled(5)
    readonly property int barMarginTop: scaled(5)
    readonly property int barMarginBottom: 0
    readonly property color barColor: "#00000000"
    readonly property color backgroundColor: Colors.surface_container
    readonly property color borderColor: Colors.surface_variant
    readonly property real barOpacity: 0.92

    // ===== Workspaces =====
    readonly property string workspaceBackgroundStyle: "pills" // "full" or "pills"
    readonly property int wsHeight: scaled(10)
    readonly property int wsActiveWidth: scaled(28)
    readonly property int wsInactiveWidth: scaled(10)
    readonly property int wsSpacing: scaled(6)
    readonly property color wsActiveColor: Colors.primary
    readonly property color wsActiveTextColor: Colors.on_primary
    readonly property color wsOccupiedColor: Colors.secondary
    readonly property color wsEmptyColor: pillColor

    // ===== Pills =====
    readonly property int pillHeight: scaled(28)
    readonly property int pillRadius: scaled(14)
    readonly property int pillPadding: scaled(16)
    readonly property int extraPillPadding: scaled(5)
    readonly property color pillColor: "#bd000000"
    readonly property int pillSpacing: scaled(4)
    readonly property int pillGap: scaled(6)
    readonly property color pillBorderColor: Colors.outline
    readonly property int pillBorderWidth: 1
    readonly property int pillHoverBorderWidth: 2
    readonly property color pillHoverColor: Colors.surface_variant
    
    // ===== Typography =====
    readonly property int fontSize: scaled(13)
    readonly property int iconSize: scaled(14)
    readonly property string iconFont: "MesloLGS NF"
    readonly property color fontColor: Colors.on_background
    
    // ===== Menu / Popup Styling =====
    readonly property color menuBackground: Colors.background
    readonly property color menuBorder: Colors.surface_variant
    readonly property color menuHoverBorder: Colors.primary
    readonly property int menuRadius: scaled(24)
    readonly property int menuPadding: scaled(20)
    readonly property int menuSpacing: scaled(15)
    readonly property color menuActiveTab: Colors.primary
    readonly property color menuInactiveTab: "transparent"
    
    // ===== Widget Specific Colors =====
    readonly property color cpuColor: Colors.error
    readonly property color memColor: Colors.primary
    readonly property color tempColor: Colors.tertiary
    readonly property color bluetoothColor: Colors.primary
    readonly property color volumeColor: Colors.primary
    readonly property color powerRed: Colors.error
    readonly property color powerYellow: Colors.secondary_container
    readonly property color powerGreen: Colors.tertiary
    readonly property color mediaPeach: Colors.secondary
    readonly property color mediaGray: Colors.outline

    // ===== Active States =====
    readonly property color activePillColor: Colors.surface_variant
    readonly property color activeBorderColor: Colors.primary
    readonly property color activeTextColor: Colors.on_surface
    readonly property color inactiveTextColor: Colors.outline

    // ===== Battery thresholds =====
    readonly property int high: 90
    readonly property int midHigh: 70
    readonly property int mid: 50
    readonly property int low: 30
    readonly property int critical: 10

    // ===== Battery colors =====
    readonly property color chargingColor: Colors.tertiary
    readonly property color conserveColor: Colors.tertiary
    readonly property color highColor: Colors.tertiary
    readonly property color midColor: Colors.secondary_container
    readonly property color lowColor: Colors.secondary
    readonly property color criticalColor: Colors.error

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

    function setAccent(index) {
        AccentService.setAccent(index);
    }
}
