import QtQuick
import Quickshell

// Fallback logic component that re-imports the Theme to ensure availability
// even when launched in isolated --path mode.
Item {
    id: root

    // Access the singleton 'Theme' or return a safe fallback
    readonly property var theme: {
        try {
            return Theme;
        } catch (e) {
            console.warn("[ThemeLoader]: Theme singleton not found, returning fallback.");
            return {
                scaled: function(v) { return v; },
                setAccent: function(i) { console.log("Theme.setAccent is unavailable"); },
                menuBackground: "#11111b",
                surface1: "#313244",
                text: "#cdd6f4",
                subtext0: "#a6adc8",
                primary: "#89b4fa",
                secondary: "#b4befe",
                tertiary: "#94e2d5"
            };
        }
    }
}
