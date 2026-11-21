pragma Singleton
import "."
import QtQuick
import Quickshell.Io

Item {
    id: hyprlandSettings
    
    property int gapsIn: 2
    property int gapsOut: 6
    property int gapsWorkspaces: 20
    property int borderSize: 2
    property int rounding: 13
    property int shadowRange: 12
    property real blurVibrancy: 0.5
    property int barMargins: 10
    
    // Logic to apply changes in real-time
    onGapsInChanged: applyLua("general.gaps_in", gapsIn)
    onGapsOutChanged: applyLua("general.gaps_out", gapsOut)
    onGapsWorkspacesChanged: applyLua("general.gaps_workspaces", gapsWorkspaces)
    onBorderSizeChanged: applyLua("general.border_size", borderSize)
    onRoundingChanged: applyLua("decoration.rounding", rounding)
    onShadowRangeChanged: applyLua("decoration.shadow.range", shadowRange)
    onBlurVibrancyChanged: applyLua("decoration.blur.vibrancy", blurVibrancy)
    onBarMarginsChanged: {
        BarSettings.marginTop = barMargins;
        BarSettings.marginLeft = barMargins;
        BarSettings.marginRight = barMargins;
    }
    
    function applyLua(path, value) {
        let parts = path.split(".");
        let luaStr = "";
        if (parts.length === 2) {
            luaStr = "hl.config({ " + parts[0] + " = { " + parts[1] + " = " + value + " } })";
        } else if (parts.length === 3) {
            luaStr = "hl.config({ " + parts[0] + " = { " + parts[1] + " = { " + parts[2] + " = " + value + " } } })";
        }
        
        let keywordKey = path.replace(".", ":");
        let cmd = "hyprctl eval '" + luaStr + "' >/dev/null 2>&1 || hyprctl keyword " + keywordKey + " " + value + " >/dev/null 2>&1";
        execProc.command = ["sh", "-c", cmd];
        execProc.running = false;
        execProc.running = true;
    }
    
    Process { id: execProc }
}
