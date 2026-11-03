import QtQuick

import qs.config
import qs.utils

// The shell of the control center and the bar menus: a bordered background that grows out of a corner or an edge.
// The corner it grows from stays small. Content is laid out at the panel's real size
PopMask {
    id: root

    default property alias items: page.data

    // Two-finger swipe to the right
    signal back()

    Rectangle {
        id: frame

        anchors.fill: parent

        topLeftRadius: root.isOrigin(false, false) ? Settings.radiusSm : root.radius
        topRightRadius: root.isOrigin(true, false) ? Settings.radiusSm : root.radius
        bottomLeftRadius: root.isOrigin(false, true) ? Settings.radiusSm : root.radius
        bottomRightRadius: root.isOrigin(true, true) ? Settings.radiusSm : root.radius

        color: Colors.background
        border.width: 1
        border.color: Colors.backgroundSubtle

        BackGesture {
            onTriggered: root.back()
        }

        // Stays at the panel's corner while a resize animates
        Item {
            id: page

            x: root.contentX
            y: root.contentY
            width: root.width
            height: root.height
        }
    }
}
