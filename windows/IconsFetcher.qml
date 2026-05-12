import QtQuick
import Quickshell
import "../services" as Svc

pragma Singleton

Item {
    id: root

    function getCandidates(appName, desktopEntry, iconName) {
        return Svc.IconsFetcher.getCandidates(appName, desktopEntry, iconName);
    }

    function getIconPath(appName, desktopEntry, iconName) {
        return Svc.IconsFetcher.getIconPath(appName, desktopEntry, iconName);
    }

    function isMainApp(appId, name) {
        return Svc.IconsFetcher.isMainApp(appId, name);
    }
}
