import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../components"

import qs.config
import qs.services
import qs.utils

// Battery level with a bolt over it while plugged in. Only meaningful once Battery.available
Item {
    id: root

    // Turns the accent color when the battery runs low
    property bool warn: Battery.low
    property color color: warn ? Colors.primary : Colors.text

    Behavior on color { ColorAnim {} }

    Layout.preferredWidth: Settings.px(18)
    Layout.preferredHeight: Settings.px(18)
    Layout.alignment: Qt.AlignVCenter

    Icon {
        id: body
        anchors.fill: parent
        visible: false
        color: root.color
        icon: Battery.icon
    }

    // The bolt alone, grown into an outline that's cut out of the battery, so the two don't blend together
    Item {
        id: boltShape
        anchors.fill: parent
        visible: false

        Icon {
            icon: "bolt"
            color: root.color
            opacity: bolt.opacity
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: bolt.anchors.horizontalCenterOffset
            size: bolt.size
        }
    }

    DropShadow {
        id: boltOutline
        anchors.fill: boltShape
        source: boltShape
        radius: Settings.px(2)
        samples: 17
        spread: 1.0
        color: root.color
        transparentBorder: true
        visible: false
    }

    OpacityMask {
        anchors.fill: body
        source: body
        maskSource: boltOutline
        invert: true
    }

    Icon {
        id: bolt
        icon: "bolt"
        color: root.color
        opacity: Battery.pluggedIn ? 1 : 0
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -Settings.px(8)
        size: Settings.px(14)

        Behavior on opacity { Fade {} }
    }
}
