import QtQuick
import QtQuick.Layouts

import qs.config
import qs.utils

// Clickable spot on the bar with a tooltip, styled like a ghost Button: a pill lights up behind it on hover and
// press, and fills with the accent while what it opens is showing. Children are laid out in a row
Item {
    id: root

    default property alias content: row.data
    property string tooltip
    property bool tooltipReady: false
    // What it opens is showing
    property bool active: false

    signal clicked(var mouse)
    // One per notch, positive when scrolling up
    signal scrolled(real notches)

    implicitWidth: row.implicitWidth + Settings.barButtonPadding * 2
    Layout.fillHeight: true

    // Sinks the moment it's pressed, before the click lands
    scale: area.pressed ? Settings.pressScale : 1
    Behavior on scale { Anim { fast: true } }

    // Reaches a little past the bar's padding, so it doesn't hug what's inside
    Rectangle {
        id: highlight

        anchors.fill: parent
        anchors.topMargin: -Settings.barButtonPadding / 2
        anchors.bottomMargin: -Settings.barButtonPadding / 2
        radius: height / 2

        color: root.active
            ? (area.pressed ? Colors.primaryActive : area.containsMouse ? Colors.primaryHover : Colors.primary)
            : Qt.alpha(Colors.foreground, area.pressed ? 0.2 : area.containsMouse ? 0.1 : 0)

        Behavior on color { ColorAnim {} }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Settings.spacing / 2
    }

    MouseArea {
        id: area

        anchors.fill: highlight
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => root.clicked(mouse)

        // Fractions of a notch pass straight through, so touchpads scroll smoothly instead of in jumps.
        // Touchpads (the ones reporting pixels) follow the natural scrolling setting, so up is always up
        onWheel: (wheel) => {
            if (Math.abs(wheel.angleDelta.y) <= Math.abs(wheel.angleDelta.x)) return
            const natural = Settings.naturalScroll && wheel.pixelDelta.y != 0
            root.scrolled(wheel.angleDelta.y / 120 * (natural ? -1 : 1))
        }

        onContainsMouseChanged: {
            root.tooltipReady = false
            if (containsMouse) hoverDelay.restart()
            else hoverDelay.stop()
        }
    }

    Timer {
        id: hoverDelay
        interval: Settings.tooltipDelay
        onTriggered: root.tooltipReady = true
    }

    Tooltip {
        target: root
        text: root.tooltip
        shown: area.containsMouse && !area.pressed && root.tooltipReady
        above: Settings.barPosition == "bottom"
        // Clears the bar's padding as well as the usual gap
        offset: Settings.spacing + Settings.windowSpacing
    }
}
