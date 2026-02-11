// bar/Menu/TrayMenu.qml
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

QsMenuAnchor {
    id: root

    function openFor(item, visualParent) {
        if (!item || !item.hasMenu)
            return ;

        if (root.active && currentItem === item) {
            root.close();
            currentItem = null;
            return ;
        }
        root.menu = item.menu;
        root.anchor.window = visualParent.QsWindow.window;
        root.anchor.rect = visualParent.mapToItem(null, 0, 0, visualParent.width, visualParent.height);
        root.anchor.edges = Edges.Bottom;
        root.anchor.gravity = Edges.Bottom;
        root.open();
    }

}
