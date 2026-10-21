import QtQuick
import Quickshell

import qs.config

Item {
    id: root

    property int size: Settings.spinnerSize
    property color color: Colors.primary

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: blob

        anchors.centerIn: parent
        width: root.size
        height: root.size / 2
        radius: 0
        color: root.color

        // Wide rect -> square -> circle -> pill -> back to wide rect
        SequentialAnimation {
            loops: Animation.Infinite
            running: root.visible

            NumberAnimation { target: blob; property: "width"; to: root.size / 2; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: blob; property: "radius"; to: root.size / 4; duration: 300; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 200 }
            NumberAnimation { target: blob; property: "width"; to: root.size; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: blob; property: "radius"; to: 0; duration: 300; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 200 }
        }
    }
}
