pragma Singleton
import QtQuick
import Quickshell
import "Settings"

QtObject {
    // =====================================================
    // ================= DYNAMIC SCALING ===================
    // =====================================================
    
    // We use 1080 as our reference height and 1920 as reference width (1080p)
    readonly property real referenceHeight: 1080
    readonly property real referenceWidth: 1920
    readonly property real screenHeight: Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080
    readonly property real screenWidth: Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920
    
    // Scale factor: geometric mean of height and width scaling to ensure balanced scaling
    readonly property real scale: Math.sqrt((screenWidth / referenceWidth) * (screenHeight / referenceHeight))
    
    // Responsive break points
    readonly property bool isSmallScreen: screenWidth < 1000 || screenHeight < 700
    readonly property bool isMobile: screenWidth < 500 || screenHeight < 500
    readonly property bool isPortrait: screenHeight > screenWidth

    // Helper to scale values manually if needed
    function scaled(val) { 
        let s = Math.round(val * scale);
        // Ensure minimum sizes for readability on very small scales
        if (val >= 8 && s < 8) return 8;
        return s;
    }
    
    readonly property int appMenuCol: isSmallScreen ? (isPortrait ? 3 : 4) : 6

    // ===== Glassmorphism & Effects =====
    readonly property real menuOpacity: AppearanceSettings.menuOpacity
    readonly property color glassBackground: Qt.alpha(Colors.background, menuOpacity)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.15)
    readonly property real glassBlur: AppearanceSettings.glassBlur
    
    // ===== Animation Defaults =====
    readonly property int animFast: 150
    readonly property int animNormal: 300
    readonly property int animSlow: 500
    readonly property int animEasing: Easing.OutQuint
    readonly property int elasticEasing: Easing.OutBack

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
    readonly property color accentGlow: {
        try {
            return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3);
        } catch(e) {
            return "#4dffb3b3";
        }
    }
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.5)

    // ===== Bar =====
    readonly property int barHeight: scaled(BarSettings.height)
    readonly property int barRadius: scaled(BarSettings.radius)
    readonly property int barMarginLeft: scaled(BarSettings.marginLeft)
    readonly property int barMarginRight: scaled(BarSettings.marginRight)
    readonly property int barMarginTop: scaled(BarSettings.marginTop)
    readonly property int barMarginBottom: scaled(BarSettings.marginBottom)
    readonly property color barColor: "#00000000"
    readonly property color backgroundColor: Colors.surface_container
    readonly property color borderColor: Colors.surface_variant
    readonly property real barOpacity: BarSettings.opacity

    // ===== Workspaces =====
    readonly property string workspaceBackgroundStyle: WorkspaceSettings.backgroundStyle
    readonly property int wsHeight: scaled(WorkspaceSettings.height)
    readonly property int wsActiveWidth: scaled(WorkspaceSettings.activeWidth)
    readonly property int wsInactiveWidth: scaled(WorkspaceSettings.inactiveWidth)
    readonly property int wsSpacing: scaled(WorkspaceSettings.spacing)
    readonly property color wsActiveColor: Colors.primary
    readonly property color wsActiveTextColor: Colors.on_primary
    readonly property color wsOccupiedColor: Colors.secondary
    readonly property color wsEmptyColor: pillColor

    // ===== Pills =====
    readonly property int pillHeight: scaled(PillSettings.height)
    readonly property int pillRadius: scaled(PillSettings.radius)
    readonly property int pillPadding: scaled(PillSettings.padding)
    readonly property int extraPillPadding: scaled(PillSettings.extraPadding)
    readonly property color pillColor: Colors.background
    readonly property int pillSpacing: scaled(PillSettings.spacing)
    readonly property int pillGap: scaled(PillSettings.gap)
    readonly property color pillBorderColor: Colors.outline
    readonly property int pillBorderWidth: PillSettings.borderWidth
    readonly property int pillHoverBorderWidth: PillSettings.hoverBorderWidth
    readonly property color pillHoverColor: Colors.surface_variant
    
    // ===== Typography =====
    readonly property int fontSize: scaled(AppearanceSettings.fontSize)
    readonly property int iconSize: scaled(AppearanceSettings.iconSize)
    readonly property string iconFont: AppearanceSettings.iconFont
    readonly property color fontColor: Colors.on_background
    
    // ===== Menu / Popup Styling =====
    readonly property color menuBackground: Colors.background
    readonly property color menuBorder: Colors.surface_variant
    readonly property color menuHoverBorder: Colors.primary
    readonly property int menuRadius: scaled(AppearanceSettings.menuRadius)
    readonly property int menuPadding: scaled(AppearanceSettings.menuPadding)
    readonly property int menuSpacing: scaled(AppearanceSettings.menuSpacing)
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
    readonly property int high: BatterySettings.high
    readonly property int midHigh: BatterySettings.midHigh
    readonly property int mid: BatterySettings.mid
    readonly property int low: BatterySettings.low
    readonly property int critical: BatterySettings.critical

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
