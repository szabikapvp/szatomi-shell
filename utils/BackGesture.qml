import QtQuick

import qs.config

// Fires once per two-finger swipe to the right on a touchpad
MouseArea {
    id: root

    signal triggered()

    property real distance: 0
    property bool fired: false

    anchors.fill: parent
    acceptedButtons: Qt.NoButton

    onWheel: (wheel) => {
        let dx = wheel.pixelDelta.x != 0 ? wheel.pixelDelta.x : wheel.angleDelta.x / 8
        let dy = wheel.pixelDelta.y != 0 ? wheel.pixelDelta.y : wheel.angleDelta.y / 8
        if (Math.abs(dx) <= Math.abs(dy)) {
            wheel.accepted = false
            return
        }

        // Positive x means scrolling left, which is a right swipe only with natural scrolling.
        // wheel.inverted can't tell us, since Hyprland doesn't report it
        distance += Settings.naturalScroll ? dx : -dx
        resetTimer.restart()

        if (!fired && distance >= Settings.backSwipeThreshold) {
            fired = true
            root.triggered()
        }
    }

    // The gesture ends once scroll events stop arriving
    Timer {
        id: resetTimer
        interval: Settings.backSwipeResetDelay
        onTriggered: {
            root.distance = 0
            root.fired = false
        }
    }
}
