// ThemeService.qml
import QtQuick
import Quickshell.Io

Singleton {
    id: root

    property string activeTheme: "OneUI-dark"
    property string iconPath: "/usr/share/icons/"

    // This helper function builds the fallback chain for any icon name
    function getIconSource(iconName, fallbackId) {
        if (!iconName)
            return "";

        if (iconName.startsWith("/") || iconName.startsWith("file://"))
            return iconName;

        // Start with the user's preferred theme
        return "file://" + iconPath + activeTheme + "/symbolic/apps/" + iconName + "-symbolic.svg";
    }

    // Run this once at startup
    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"]
        running: true

        stdout: StdioCollector {
            onData: {
                var theme = data.toString().trim().replace(/'/g, "");
                if (theme.length > 0)
                    root.activeTheme = theme;

            }
        }

    }

}
