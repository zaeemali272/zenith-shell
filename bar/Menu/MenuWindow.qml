// Shared scaffolding for every menu surface.
//
// ControlCenter, QuickSettingsMenu and MediaPlayerPopup were each carrying
// their own copy of: overlay layer, screen-filling anchors, an input mask over
// the card, and register/unregister with MenuService. Identical code in three
// files means a mistake gets made three times -- which is exactly what
// happened with the "dismiss on outer click" MouseArea, present and wrong in
// all three until it was fixed in all three.
//
// Usage:
//
//     MenuWindow {
//         id: root
//         card: mainContent          // the thing that takes input
//         namespaceName: "whatever"  // layer-shell namespace
//
//         Rectangle { id: mainContent /* ... */ }
//     }
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"

PanelWindow {
    id: menuWindow

    // The visible card. Input is masked to it; everything outside is not this
    // window's business.
    property Item card: null

    property string namespaceName: "zenith-menu"

    // A surface that should not participate in "close all open menus" can opt
    // out; the dynamic island does its own lifecycle.
    property bool managedByMenuService: true

    // Raised when the menu should close itself -- a click outside it, or Escape.
    signal dismissed()

    // Set while the menu is in the middle of something that must not be
    // interrupted. Changing WlrLayershell.keyboardFocus reconfigures the
    // surface, and that reconfigure can clear the focus grab -- so entering a
    // WiFi password, which flips keyboardFocus to Exclusive, looked exactly
    // like a click outside and closed the whole panel.
    property bool dismissInhibited: false

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: menuWindow.namespaceName

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Only the card receives input. Clicks anywhere else pass through to
    // DismissOverlay, which is what actually closes menus.
    //
    // Do not add a dismiss MouseArea to this window. Because of this mask the
    // compositor only delivers events that land on the card, so such a handler
    // can only ever fire *inside* the menu -- it closes the menu on every click
    // that misses a control, which is the opposite of dismissing it.
    mask: Region {
        item: menuWindow.card
    }

    // Closing on an outside click is a focus grab, not a full-screen click
    // catcher. DismissOverlay only maps once a menu has registered, so on the
    // same layer it lands on top of the very menu it is meant to sit behind --
    // whether it receives the click at all comes down to surface stacking
    // order, which is why this behaved differently depending on which menu was
    // opened. A grab asks the compositor directly and does not care about
    // stacking. TrayMenu already worked this way.
    HyprlandFocusGrab {
        id: focusGrab
        active: menuWindow.visible
        windows: [menuWindow]
        onCleared: {
            if (menuWindow.visible && !menuWindow.dismissInhibited)
                menuWindow.dismissed();
        }
    }

    // Escape closes, from anywhere in the menu.
    //
    // A Shortcut rather than a focused Item with Keys.onEscapePressed: an item
    // that takes focus to listen for a key takes it away from the search
    // fields, password boxes and task inputs inside these menus, which would
    // break typing everywhere while looking perfectly fine in a test that only
    // clicks.
    Shortcut {
        sequences: ["Escape"]
        enabled: menuWindow.visible
        onActivated: menuWindow.dismissed()
    }

    // Registration lives in a Connections rather than an onVisibleChanged
    // handler on purpose: a subclass that declares its own onVisibleChanged
    // would shadow a handler defined here, and silently stop registering.
    // Both run when it is done this way.
    Connections {
        target: menuWindow
        enabled: menuWindow.managedByMenuService
        function onVisibleChanged() {
            if (menuWindow.visible)
                MenuService.register(menuWindow);
            else
                MenuService.unregister(menuWindow);
        }
    }

    Component.onDestruction: {
        if (menuWindow.managedByMenuService)
            MenuService.unregister(menuWindow);
    }
}
