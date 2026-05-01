import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../components"

import qs.services

Item {

    Layout.preferredWidth: 18
    Layout.preferredHeight: 18
    
    Layout.alignment: Qt.AlignVCenter

    Icon {
        id: bottomIcon
        anchors.fill: parent
        visible: false

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
            visible: Battery.isCharging()
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -8
            size: 14
        }
    }

    DropShadow {
        id: outlineMask
        anchors.fill: topLayer
        source: topLayer
        radius: 2
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
        visible: Battery.isCharging()
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -8
        size: 14
    }



}