import QtQuick
import Quickshell
import "../windows" as Win

pragma Singleton

Item {
    id: root

    function getIconPath(appName, desktopEntry, iconName) {
        return Win.IconsFetcher.getIconPath(appName, desktopEntry, iconName);
    }
}
