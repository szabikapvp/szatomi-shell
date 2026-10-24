import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../components"

import qs.config
import qs.services

Item {
    id: root

    property color color: Colors.text

    Layout.preferredWidth: Settings.px(18)
    Layout.preferredHeight: Settings.px(18)
    
    Layout.alignment: Qt.AlignVCenter

    Icon {
        id: bottomIcon
        anchors.fill: parent
        visible: false
        color: root.color

        icon: {
            if (Battery.getLevel() <= 15) return "battery-0"
            if (Battery.getLevel() <= 30) return "battery-1"
            if (Battery.getLevel() <= 45) return "battery-2"
            if (Battery.getLevel() <= 50) return "battery-3"
            if (Battery.getLevel() <= 65) return "battery-4"
            if (Battery.getLevel() <= 80) return "battery-5"
            if (Battery.getLevel() <= 95) return "battery-6"
            if (Battery.getLevel() <= 100) return "battery-7"
            return "battery-0"
        }
    }

    Item {
        id: topLayer
        anchors.fill: parent

        Icon {
            icon: "bolt"
            color: root.color
            visible: Battery.isCharging()
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -Settings.px(8)
            size: Settings.px(14)
        }
    }

    DropShadow {
        id: outlineMask
        anchors.fill: topLayer
        source: topLayer
        radius: Settings.px(2)
        samples: 17
        spread: 1.0    
        color: "blue"
        transparentBorder: true
        visible: false
    }

    OpacityMask {
        anchors.fill: bottomIcon
        source: bottomIcon
        maskSource: outlineMask
        invert: true
    }

    Icon {
        icon: "bolt"
        color: root.color
        visible: Battery.isCharging()
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -Settings.px(8)
        size: Settings.px(14)
    }



}