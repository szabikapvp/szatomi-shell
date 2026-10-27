import QtQuick
import QtQuick.Controls

import qs.config
import qs.utils

// Thin overlay scrollbar: sits on top of the content and fades out when idle
ScrollBar {
    id: root

    property bool expanded: hovered || pressed

    visible: size < 1.0
    policy: ScrollBar.AsNeeded

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    padding: Settings.scrollbarMargin

    opacity: active ? 1 : 0

    Behavior on opacity { Fade {} }

    background: null

    // Fixed hit area, the visible thumb grows inside it on hover
    contentItem: Item {
        implicitWidth: Settings.scrollbarHoverWidth

        Rectangle {
            anchors.right: parent.right
            height: parent.height
            width: root.expanded ? Settings.scrollbarHoverWidth : Settings.scrollbarWidth
            radius: width / 2

            color: {
                if (root.pressed) return Colors.primaryActive
                if (root.hovered) return Colors.primaryHover
                return Qt.alpha(Colors.foreground, 0.5)
            }

            Behavior on width { Anim { fast: true } }

            Behavior on color {
                ColorAnim {}
            }
        }
    }
}
