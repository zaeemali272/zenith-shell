pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#c2c1ff"
    readonly property color on_primary: "#2a2a60"
    readonly property color primary_container: "#414178"
    readonly property color on_primary_container: "#e2dfff"
    
    readonly property color secondary: "#c6c4dd"
    readonly property color on_secondary: "#2f2f42"
    readonly property color secondary_container: "#454559"
    readonly property color on_secondary_container: "#e2e0f9"
    
    readonly property color tertiary: "#e9b9d2"
    readonly property color on_tertiary: "#47263a"
    readonly property color tertiary_container: "#5f3c51"
    readonly property color on_tertiary_container: "#ffd8eb"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#131318"
    readonly property color on_background: "#e4e1e9"
    
    readonly property color surface: "#131318"
    readonly property color on_surface: "#e4e1e9"
    readonly property color surface_variant: "#47464f"
    readonly property color on_surface_variant: "#c8c5d0"
    
    readonly property color outline: "#918f9a"
    readonly property color outline_variant: "#47464f"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#0e0e13"
    readonly property color surface_container_low: "#1b1b21"
    readonly property color surface_container: "#1f1f25"
    readonly property color surface_container_high: "#2a292f"
    readonly property color surface_container_highest: "#35343a"
    
    readonly property color accent: "#c2c1ff"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
