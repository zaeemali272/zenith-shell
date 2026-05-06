pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#fcb0d6"
    readonly property color on_primary: "#521d3c"
    readonly property color primary_container: "#6c3453"
    readonly property color on_primary_container: "#ffd8e9"
    
    readonly property color secondary: "#dfbdcc"
    readonly property color on_secondary: "#402a35"
    readonly property color secondary_container: "#58404c"
    readonly property color on_secondary_container: "#fdd9e8"
    
    readonly property color tertiary: "#f3ba9b"
    readonly property color on_tertiary: "#4a2811"
    readonly property color tertiary_container: "#643d25"
    readonly property color on_tertiary_container: "#ffdbc9"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#181115"
    readonly property color on_background: "#eedfe3"
    
    readonly property color surface: "#181115"
    readonly property color on_surface: "#eedfe3"
    readonly property color surface_variant: "#504349"
    readonly property color on_surface_variant: "#d4c2c8"
    
    readonly property color outline: "#9c8d93"
    readonly property color outline_variant: "#504349"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#130c0f"
    readonly property color surface_container_low: "#21191d"
    readonly property color surface_container: "#251d21"
    readonly property color surface_container_high: "#30282b"
    readonly property color surface_container_highest: "#3b3236"
    
    readonly property color accent: "#fcb0d6"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
