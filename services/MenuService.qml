import QtQuick
import Quickshell

pragma Singleton

QtObject {
    id: root

    property var openMenus: []

    function register(menu) {
        if (!openMenus.includes(menu)) {
            let newMenus = [...openMenus, menu];
            openMenus = newMenus;
        }
    }

    function unregister(menu) {
        if (!menu) return;
        let index = openMenus.indexOf(menu);
        if (index !== -1) {
            let newMenus = [...openMenus];
            newMenus.splice(index, 1);
            openMenus = newMenus;
        }
    }

    function closeAll() {
        let menusToClose = [...openMenus];
        openMenus = [];
        for (let menu of menusToClose) {
            if (menu) {
                try {
                    menu.visible = false;
                } catch(e) {}
            }
        }
        if (typeof DynamicIslandService !== "undefined") {
            DynamicIslandService.close();
        }
        if (typeof CenterState !== "undefined") {
            CenterState.close();
        }
        if (typeof QuickSettingsService !== "undefined") {
            QuickSettingsService.close();
        }
    }
}

