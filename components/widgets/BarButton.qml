import QtQuick
import QtQuick.Layouts

import qs.config

// Clickable spot on the bar with a tooltip. Children are laid out in a row and should take `tint` as
// their color, which lights up on hover and press
Item {
    id: root

    default property alias content: row.data
    property string tooltip
    property bool tooltipReady: false
    readonly property color tint: area.pressed ? Colors.primaryActive : area.containsMouse ? Colors.primary : Colors.text

    signal clicked(var mouse)
    // One per notch, positive when scrolling up
    signal scrolled(real notches)

    implicitWidth: row.implicitWidth + Settings.spacing
    Layout.fillHeight: true

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Settings.spacing / 2
    }

    MouseArea {
        id: area

        anchors.fill: parent
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
