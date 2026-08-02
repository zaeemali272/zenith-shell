pragma Singleton
import QtQuick
import Quickshell
import "../windows" as Win

QtObject {
    id: iconsFetcherService

    function getIconCandidates(appName, desktopEntry, iconName) {
        return Win.IconsFetcher.getIconCandidates(appName, desktopEntry, iconName);
    }

    function getValidIcon(appName, desktopEntry, iconName) {
        return Win.IconsFetcher.getValidIcon(appName, desktopEntry, iconName);
    }

    function isMainApp(appId, name) {
        return Win.IconsFetcher.isMainApp(appId, name);
    }
}
