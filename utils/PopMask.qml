import QtQuick
import Qt5Compat.GraphicalEffects

import qs.config

// Reveals its children from a corner like a growing mask, without moving or resizing them.
// Size changes ease in the same way, keeping the origin corner in place
Item {
    id: root

    default property alias content: inner.data
    property real progress: 0
    property real radius: 0
    readonly property bool running: anim.running

    // Corner to grow from, defaults to the one nearest the parent's edges
    property bool fromRight: parent ? x + width / 2 > parent.width / 2 : true
    property bool fromBottom: parent ? y + height / 2 > parent.height / 2 : true

    // Eases towards the real size, the mask follows it
    property real shownWidth: width
    property real shownHeight: height

    Behavior on shownWidth {
        enabled: root.progress > 0
        NumberAnimation { duration: Settings.resizeDuration; easing.type: Easing.OutCubic }
    }

    Behavior on shownHeight {
        enabled: root.progress > 0
        NumberAnimation { duration: Settings.resizeDuration; easing.type: Easing.OutCubic }
    }

    // While shrinking the content keeps the larger size, so it collapses with the mask instead of vanishing.
    // Windows sized to their content should bind to these, so the surface doesn't cut the animation short
    readonly property real visibleWidth: Math.max(width, shownWidth)
    readonly property real visibleHeight: Math.max(height, shownHeight)

    Item {
        id: inner

        width: root.visibleWidth
        height: root.visibleHeight
        x: root.fromRight ? root.width - width : 0
        y: root.fromBottom ? root.height - height : 0

        // Only mask while animating, so the content renders natively at rest
        layer.enabled: root.progress < 1 || root.shownWidth != root.width || root.shownHeight != root.height
        layer.effect: OpacityMask {
            maskSource: mask
        }
    }

    Item {
        id: mask

        x: inner.x
        y: inner.y
        width: inner.width
        height: inner.height
        visible: false
        layer.enabled: true

        Rectangle {
            width: root.shownWidth * root.progress
            height: root.shownHeight * root.progress
            x: root.fromRight ? mask.width - width : 0
            y: root.fromBottom ? mask.height - height : 0
            radius: root.radius
            antialiasing: true

            // The origin corner sits on the content's own corner, so leave its rounding to the content
            topLeftRadius: !root.fromRight && !root.fromBottom ? 0 : root.radius
            topRightRadius: root.fromRight && !root.fromBottom ? 0 : root.radius
            bottomLeftRadius: !root.fromRight && root.fromBottom ? 0 : root.radius
            bottomRightRadius: root.fromRight && root.fromBottom ? 0 : root.radius
        }
    }

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        duration: Settings.popDuration
    }

    function popIn() {
        anim.to = 1
        anim.easing.type = Easing.OutCubic
        anim.restart()
    }

    // Mirrors popIn, so the easing is reversed too
    function popOut() {
        anim.to = 0
        anim.easing.type = Easing.InCubic
        anim.restart()
    }
}
