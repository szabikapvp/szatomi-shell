import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.config

Item {

    property var prop: volumeLevel

    Layout.fillWidth: true
    height: Settings.px(6)

    Rectangle {
        anchors.fill: parent
        radius: Settings.px(3)
        color: Qt.darker(Colors.foreground, 3)
    }

    Rectangle {
        width: Math.min(parent.width, parent.width / 100 * prop)
        height: Settings.px(6)
        radius: Settings.px(3)
        color: Colors.primary

        Behavior on width {
            NumberAnimation { duration: 50 }
        }
    }

}