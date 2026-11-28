// One lock surface per screen: the screen's own contents blurred behind a
// rounded card that spins in from a lock glyph and holds the clock, profile
// picture, password field and a few live panels. Layout and motion follow
// caelestia-dots/shell's lock; the widgets are Zenith's own services.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../services"
import "../../Settings"

WlSessionLockSurface {
    id: root

    readonly property bool unlocking: unlockAnim.running
    readonly property real screenH: screen ? screen.height : 1080
    readonly property real screenW: screen ? screen.width : 1920

    // Spread layout: full-bleed transparent canvas over the blurred background
    readonly property real cardH: Math.round(screenH * 0.94)
    readonly property real cardW: Math.round(screenW * 0.97)
    readonly property real centerScale: Math.min(1.05, screenH / 1200)
    readonly property int centerWidth: Math.round(440 * centerScale)
    readonly property int padding: Theme.scaled(16)

    color: "transparent"

    // Keyboard goes to the surface as a whole, not to a deeply nested item:
    // a FocusScope at the root owns focus from the first frame and hands every
    // key to LockService, so there is nothing to click and nothing to lose.
    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Component.onCompleted: forceActiveFocus()
        Keys.onPressed: (event) => {
            if (root.unlocking) return;
            LockService.handleKey(event);
            event.accepted = true;
        }
        MouseArea {
            anchors.fill: parent
            onClicked: keys.forceActiveFocus()
        }
    }

    Connections {
        target: LockService
        function onUnlockRequested() { unlockAnim.start(); }
    }

    // ---- Background: the screen itself, blurred, dimmed ------------------
    Item {
        id: background
        anchors.fill: parent
        opacity: 0
        scale: 1.06

        // The compositor hands the keyboard to the lock only after its first
        // frame is committed, and keys typed before that are dropped. A
        // full-resolution 64px blur made that first frame slow enough to eat
        // the start of a quickly typed password. Blurring at half size is
        // smooth Gaussian-like without banding.
        layer.enabled: IdleSettings.blurBackground
        layer.textureSize: Qt.size(Math.max(1, Math.round(width / 2)), Math.max(1, Math.round(height / 2)))
        layer.smooth: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.85
            blurMax: 40
            blurMultiplier: 1.0
        }

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.screen
            live: false
        }

        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.18) }
    }

    // ---- Card ------------------------------------------------------------
    Item {
        id: card

        readonly property int iconSize: Theme.scaled(96)
        readonly property int collapsedSize: iconSize + padding * 2
        readonly property int collapsedRadius: collapsedSize / 4

        anchors.centerIn: parent
        implicitWidth: collapsedSize
        implicitHeight: collapsedSize
        rotation: 180
        scale: 0

        Rectangle {
            id: cardBg
            anchors.fill: parent
            color: Qt.alpha(Colors.surface, 0.92)
            radius: card.collapsedRadius
            border.color: Theme.glassBorder
            border.width: 1
            opacity: 1
        }

        Text {
            id: lockIcon
            anchors.centerIn: parent
            text: "󰌾"
            font.family: Theme.iconFont
            font.pixelSize: card.iconSize
            color: Colors.primary
            rotation: 180
        }

        LockContent {
            id: content
            anchors.centerIn: parent
            width: root.cardW - root.padding * 2
            height: root.cardH - root.padding * 2
            surface: root
            opacity: 0
            scale: 0.90
        }
    }

    // ---- Motion -----------------------------------------------------------
    ParallelAnimation {
        id: initAnim
        running: true

        NumberAnimation { target: background; property: "opacity"; to: 1; duration: Theme.animSlow; easing.type: Easing.OutQuart }
        NumberAnimation { target: background; property: "scale"; to: 1.0; duration: Theme.animSlow + 80; easing.type: Easing.OutQuart }

        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation { target: card; property: "scale"; to: 1.08; duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                NumberAnimation { target: card; property: "rotation"; to: 360; duration: 220; easing.type: Easing.OutCubic }
            }
            ParallelAnimation {
                NumberAnimation { target: card; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: lockIcon; property: "scale"; to: 1.35; duration: 180; easing.type: Easing.OutQuad }
                NumberAnimation { target: lockIcon; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: cardBg; property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: cardBg; property: "radius"; to: Theme.cardRadius * 2; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: card; property: "implicitWidth"; to: root.cardW; duration: 240; easing.type: Easing.OutQuart }
                NumberAnimation { target: card; property: "implicitHeight"; to: root.cardH; duration: 240; easing.type: Easing.OutQuart }
                NumberAnimation { target: content; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
                NumberAnimation { target: content; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.08 }
            }
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ScriptAction {
            script: {
                lockIcon.text = "󰌿";
                lockIcon.scale = 0.6;
                lockIcon.rotation = -18;
            }
        }

        ParallelAnimation {
            NumberAnimation { target: content; property: "scale"; to: 1.05; duration: 180; easing.type: Easing.InCubic }
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InQuad }
            NumberAnimation { target: card; property: "implicitWidth"; to: card.collapsedSize; duration: 220; easing.type: Easing.InOutQuart }
            NumberAnimation { target: card; property: "implicitHeight"; to: card.collapsedSize; duration: 220; easing.type: Easing.InOutQuart }
            NumberAnimation { target: cardBg; property: "radius"; to: card.collapsedRadius; duration: 220; easing.type: Easing.InOutQuart }
            NumberAnimation { target: cardBg; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: lockIcon; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: lockIcon; property: "scale"; to: 1.1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            NumberAnimation { target: lockIcon; property: "rotation"; to: 0; duration: 200; easing.type: Easing.OutBack }
            NumberAnimation { target: background; property: "scale"; to: 1.05; duration: 300; easing.type: Easing.InOutCubic }
            NumberAnimation { target: background; property: "opacity"; to: 0; duration: 280; easing.type: Easing.InCubic }
            SequentialAnimation {
                PauseAnimation { duration: 160 }
                ParallelAnimation {
                    NumberAnimation { target: card; property: "scale"; to: 0.7; duration: 140; easing.type: Easing.InBack }
                    NumberAnimation { target: card; property: "opacity"; to: 0; duration: 140; easing.type: Easing.InQuad }
                }
            }
        }
        ScriptAction { script: LockService.locked = false }
    }
}
