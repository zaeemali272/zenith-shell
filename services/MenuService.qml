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
        let index = openMenus.indexOf(menu);
        if (index !== -1) {
            let newMenus = [...openMenus];
            newMenus.splice(index, 1);
            openMenus = newMenus;
        }
    }

    function closeAll() {
        let menusToClose = [...openMenus];
        for (let menu of menusToClose) {
            if (menu && menu.visible) {
                menu.visible = false;
            }
        }
        openMenus = [];
    }
}
