import QtQuick

import qs.config
import qs.utils

// On/off switch
Item {
    id: root

    property bool checked: false
    property bool disabled: false

    signal toggled()

    // Tab reaches it, Enter or Space flips it
    activeFocusOnTab: !disabled
    Keys.onPressed: (event) => {
        if (event.key != Qt.Key_Return && event.key != Qt.Key_Enter && event.key != Qt.Key_Space) return
        root.toggled()
        event.accepted = true
    }

    FocusRing { targetRadius: root.height / 2 }

    implicitHeight: Settings.buttonIconSize + Settings.spacing
    implicitWidth: implicitHeight * 1.75

    opacity: disabled ? 0.4 : 1

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.primary : Qt.alpha(Colors.foreground, 0.15)

        Behavior on color { ColorAnim {} }

        Rectangle {
            readonly property int inset: Settings.spacing / 2

            x: root.checked ? parent.width - width - inset : inset
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - inset * 2
            height: width
            radius: width / 2
            color: Colors.text

            Behavior on x { Anim {} }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
