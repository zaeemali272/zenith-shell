// Drop-in smooth, accelerated wheel scrolling for Flickable, ListView, GridView or ScrollView.
//
// Replaces Qt's sluggish discrete wheel steps with high-speed, physics-smoothed
// cubic interpolation, dynamic multi-notch momentum, and Wayland precision touchpad support.
//
// Usage: put `FastWheel {}` inside any scrollable container.
import QtQuick

Item {
    id: fastWheel
    visible: false

    property var view: parent

    // Base scroll distance per standard 120-unit wheel notch
    property real baseStep: 180

    // Acceleration multiplier when user spins rapidly
    property real maxMultiplier: 3.0

    readonly property bool usable: view !== null
                                   && view !== undefined
                                   && view.contentY !== undefined
                                   && view.contentHeight !== undefined

    property real targetY: usable ? view.contentY : 0
    property real targetX: usable ? view.contentX : 0
    property real lastWheelTime: 0
    property real speedMultiplier: 1.0

    NumberAnimation {
        id: animY
        target: fastWheel.view
        property: "contentY"
        duration: 170
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: animX
        target: fastWheel.view
        property: "contentX"
        duration: 170
        easing.type: Easing.OutCubic
    }

    // Keep internal target synchronized when content moves from other sources
    Connections {
        target: fastWheel.usable ? fastWheel.view : null
        function onContentYChanged() {
            if (!animY.running) {
                fastWheel.targetY = fastWheel.view.contentY;
            }
        }
        function onContentXChanged() {
            if (!animX.running) {
                fastWheel.targetX = fastWheel.view.contentX;
            }
        }
        function onMovementStarted() {
            animY.stop();
            animX.stop();
        }
    }

    WheelHandler {
        id: wheelHandler
        target: null
        enabled: fastWheel.usable

        onWheel: (event) => {
            if (!fastWheel.usable) return;

            // If user drags with touch or mouse, let native gesture take over
            if (fastWheel.view.dragging || fastWheel.view.flicking) {
                animY.stop();
                animX.stop();
                return;
            }

            var now = Date.now();
            var dt = now - fastWheel.lastWheelTime;
            fastWheel.lastWheelTime = now;

            // Velocity boost for rapid consecutive wheel rotations
            if (dt < 100) {
                fastWheel.speedMultiplier = Math.min(fastWheel.maxMultiplier, fastWheel.speedMultiplier + 0.4);
            } else if (dt > 280) {
                fastWheel.speedMultiplier = 1.0;
            }

            var dy = 0;
            var dx = 0;
            var isTouchpad = false;

            // Wayland precision touchpad detection
            if (event.pixelDelta && (event.pixelDelta.y !== 0 || event.pixelDelta.x !== 0)) {
                isTouchpad = true;
                dy = event.pixelDelta.y * 1.6;
                dx = event.pixelDelta.x * 1.6;
            } else {
                var notchesY = event.angleDelta.y / 120.0;
                var notchesX = event.angleDelta.x / 120.0;
                dy = notchesY * fastWheel.baseStep * fastWheel.speedMultiplier;
                dx = notchesX * fastWheel.baseStep * fastWheel.speedMultiplier;
            }

            // Vertical scroll
            if (dy !== 0 && fastWheel.view.contentHeight > fastWheel.view.height) {
                var maxY = Math.max(0, fastWheel.view.contentHeight - fastWheel.view.height);
                var startY = animY.running ? fastWheel.targetY : fastWheel.view.contentY;
                fastWheel.targetY = Math.max(0, Math.min(maxY, startY - dy));

                animY.stop();
                animY.from = fastWheel.view.contentY;
                animY.to = fastWheel.targetY;
                animY.duration = isTouchpad ? 70 : 170;
                animY.start();
            }

            // Horizontal scroll
            if (dx !== 0 && fastWheel.view.contentWidth > fastWheel.view.width) {
                var maxX = Math.max(0, fastWheel.view.contentWidth - fastWheel.view.width);
                var startX = animX.running ? fastWheel.targetX : fastWheel.view.contentX;
                fastWheel.targetX = Math.max(0, Math.min(maxX, startX - dx));

                animX.stop();
                animX.from = fastWheel.view.contentX;
                animX.to = fastWheel.targetX;
                animX.duration = isTouchpad ? 70 : 170;
                animX.start();
            }
        }
    }
}
