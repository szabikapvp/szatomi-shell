import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../components"

import qs.config

// Fills from the bottom when taller than wide, from the left otherwise.
// Click or drag to set the value, scroll to nudge it
Tile {
    id: root

    property real value: 0 // 0 to 100
    property string icon

    signal moved(real value)

    readonly property bool vertical: rows > columns
    readonly property int inset: (Math.min(width, height) - Settings.buttonIconSize) / 2

    // The service lags behind the pointer, so a drag shows its own value until released
    property bool dragging: false
    property real dragValue: 0
    readonly property real shownValue: dragging ? dragValue : value

    readonly property real length: vertical ? height : width
    readonly property real fillLength: length * Math.max(0, Math.min(100, shownValue)) / 100

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: mask }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.vertical ? parent.width : root.fillLength
            height: root.vertical ? root.fillLength : parent.height
            color: Colors.foreground

            Behavior on width { enabled: root.settled && !root.dragging; NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: root.settled && !root.dragging; NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }
    }

    Icon {
        x: root.vertical ? (root.width - width) / 2 : root.inset
        y: root.vertical ? root.height - root.inset - height : (root.height - height) / 2
        icon: root.icon
        size: Settings.buttonIconSize
        color: root.covers(root.inset + size / 2) ? Colors.background : Colors.text
    }

    // Only on the long side, where there's room for it
    Text {
        visible: root.vertical ? root.rows > 1 : root.columns > 1

        x: root.vertical ? (root.width - width) / 2 : root.width - root.inset - width
        y: root.vertical ? root.inset : (root.height - height) / 2

        text: Math.round(root.shownValue) + "%"
        color: root.covers(root.length - root.inset - (root.vertical ? height : width) / 2) ? Colors.background : Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.bold: true
    }

    MouseArea {
        id: mouseArea

        property point pressPos
        property bool moving: false

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        pressAndHoldInterval: Settings.controlCenterHoldDuration

        onPressed: (mouse) => {
            pressPos = Qt.point(mouse.x, mouse.y)
            moving = false
        }

        // Waits for a real drag, so a still press can still turn into a hold
        onPositionChanged: (mouse) => {
            if (!moving && Math.hypot(mouse.x - pressPos.x, mouse.y - pressPos.y) < Qt.styleHints.startDragDistance) return
            moving = true
            root.dragging = true
            root.setFrom(mouse)
        }

        onClicked: (mouse) => root.setFrom(mouse)
        onReleased: root.dragging = false
        onCanceled: root.dragging = false
        onPressAndHold: if (!moving) root.held()

        onWheel: (wheel) => {
            // Sideways scrolls belong to the back gesture
            if (Math.abs(wheel.angleDelta.y) <= Math.abs(wheel.angleDelta.x)) {
                wheel.accepted = false
                return
            }
            root.moved(Math.max(0, Math.min(100, root.value + Math.sign(wheel.angleDelta.y) * Settings.sliderScrollStep)))
        }
    }

    // Whether the fill reaches a point, measured from where it starts
    function covers(position) {
        return fillLength > position
    }

    function setFrom(mouse) {
        const ratio = vertical ? 1 - mouse.y / height : mouse.x / width
        dragValue = Math.max(0, Math.min(100, ratio * 100))
        moved(dragValue)
    }
}
