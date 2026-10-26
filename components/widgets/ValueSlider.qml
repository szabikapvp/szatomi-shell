import QtQuick
import QtQuick.Layouts

import qs.config

// Draggable slider for a number from `from` to `to`, snapping to stepSize.
// moved() only fires on release, so values that change the layout don't reflow it under the pointer. live sends it during drags too
Item {
    id: root

    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property bool live: false

    signal moved(real value)

    // Follows the pointer during a drag, otherwise the value
    property bool dragging: false
    property real dragValue: 0
    readonly property real shownValue: dragging ? dragValue : value
    readonly property real ratio: to > from ? (Math.max(from, Math.min(to, shownValue)) - from) / (to - from) : 0

    readonly property int knobSize: Settings.buttonIconSize * 0.75

    implicitHeight: Settings.buttonIconSize
    Layout.fillWidth: true

    // Left and Right move a step, Page Up and Down ten, Home and End to the ends.
    // Up and Down are left to move between controls
    activeFocusOnTab: true
    Keys.onPressed: (event) => {
        let target
        switch (event.key) {
            case Qt.Key_Right: target = value + stepSize; break
            case Qt.Key_Left: target = value - stepSize; break
            case Qt.Key_PageUp: target = value + stepSize * 10; break
            case Qt.Key_PageDown: target = value - stepSize * 10; break
            case Qt.Key_Home: target = from; break
            case Qt.Key_End: target = to; break
            default: return
        }
        target = Math.max(from, Math.min(to, target))
        if (target != value) root.moved(target)
        event.accepted = true
    }

    FocusRing { targetRadius: root.height / 2 }

    Rectangle {
        id: track

        x: root.knobSize / 2
        width: parent.width - root.knobSize
        height: Settings.px(6)
        radius: Settings.px(3)
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.darker(Colors.foreground, 3)

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: Colors.primary
        }
    }

    Rectangle {
        x: track.x + track.width * root.ratio - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.knobSize
        height: width
        radius: width / 2
        color: mouseArea.pressed ? Colors.foregroundHover : Colors.foreground
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Keeps a surrounding scroll view from taking over the drag
        preventStealing: true

        onPressed: (mouse) => {
            root.dragValue = root.valueAt(mouse.x)
            root.dragging = true
            if (root.live) root.moved(root.dragValue)
        }
        onPositionChanged: (mouse) => {
            root.dragValue = root.valueAt(mouse.x)
            if (root.live) root.moved(root.dragValue)
        }
        onReleased: {
            root.dragging = false
            if (root.dragValue != root.value) root.moved(root.dragValue)
        }
        onCanceled: root.dragging = false
    }

    function valueAt(x) {
        const ratio = Math.max(0, Math.min(1, (x - track.x) / track.width))
        const stepped = from + Math.round(ratio * (to - from) / stepSize) * stepSize
        return Math.max(from, Math.min(to, stepped))
    }
}
