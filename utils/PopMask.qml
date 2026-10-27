import QtQuick

import qs.config

// Reveals its children from a corner, or the middle of the top or bottom edge, like a growing mask,
// without moving or resizing them. Size changes ease in the same way, keeping the origin in place
Item {
    id: root

    default property alias content: inner.data
    // How open it is, 0 to 1. A spring, so opening and closing can reverse each other mid-flight. Reversing can
    // swing it slightly past either end, which drawing ignores
    readonly property real progress: Math.max(0, Math.min(1, pop.value))
    property real radius: 0

    // Corner to grow from, defaults to the one nearest the parent's edges
    property bool fromRight: parent ? x + width / 2 > parent.width / 2 : true
    property bool fromBottom: parent ? y + height / 2 > parent.height / 2 : true
    // Grows from the middle of the edge instead, overriding fromRight
    property bool fromCenter: false

    // Springs towards the real size, the mask follows it. Hidden, it just takes the new size
    readonly property real shownWidth: widthSpring.value
    readonly property real shownHeight: heightSpring.value

    // Reduce motion fades the content in place instead of growing the mask
    readonly property bool fading: Settings.reduceMotion

    Spring {
        id: pop
        epsilon: 0.001
        instant: false
    }

    Spring {
        id: widthSpring
        to: root.width
        instant: root.progress == 0 || Settings.reduceMotion
    }

    Spring {
        id: heightSpring
        to: root.height
        instant: root.progress == 0 || Settings.reduceMotion
    }

    // While shrinking the content holds its larger size until the mask is done, so it collapses with the mask
    // instead of vanishing, and isn't laid out again every frame.
    // Windows sized to their content should bind to these, so the surface doesn't cut the animation short
    property real heldWidth: width
    property real heldHeight: height
    onWidthChanged: heldWidth = Math.max(width, shownWidth)
    onHeightChanged: heldHeight = Math.max(height, shownHeight)

    readonly property real visibleWidth: shownWidth == width ? width : Math.max(width, heldWidth)
    readonly property real visibleHeight: shownHeight == height ? height : Math.max(height, heldHeight)

    // Where the real size sits inside the content, at the origin corner. Place the actual contents here,
    // so they don't jump when a held size is released
    readonly property real contentX: fromCenter ? (visibleWidth - width) / 2 : fromRight ? visibleWidth - width : 0
    readonly property real contentY: fromBottom ? visibleHeight - height : 0

    // Only mask while animating, so the content renders natively at rest
    readonly property bool masking: progress < 1 || shownWidth != width || shownHeight != height

    Item {
        id: inner

        width: root.visibleWidth
        height: root.visibleHeight
        x: root.fromCenter ? (root.width - width) / 2 : root.fromRight ? root.width - width : 0
        y: root.fromBottom ? root.height - height : 0
    }

    // Kept alive instead of a toggled layer.effect, which rebuilds the effect at the start of every animation
    ShaderEffectSource {
        id: contentSource

        sourceItem: inner
        hideSource: root.masking
        live: root.masking && root.progress > 0
        visible: false
    }

    ShaderEffect {
        x: inner.x
        y: inner.y
        width: inner.width
        height: inner.height
        visible: root.masking
        opacity: root.fading ? root.progress : 1

        readonly property real maskWidth: root.shownWidth * (root.fading ? 1 : root.progress)
        readonly property real maskHeight: root.shownHeight * (root.fading ? 1 : root.progress)

        property var source: contentSource
        property size itemSize: Qt.size(width, height)
        property vector4d maskRect: Qt.vector4d(
            root.fromCenter ? (width - maskWidth) / 2 : root.fromRight ? width - maskWidth : 0,
            root.fromBottom ? height - maskHeight : 0,
            maskWidth, maskHeight)

        // The origin corner sits on the content's own corner, so leave its rounding to the content
        property vector4d radii: Qt.vector4d(
            root.isOrigin(false, false) ? 0 : root.radius,
            root.isOrigin(true, false) ? 0 : root.radius,
            root.isOrigin(true, true) ? 0 : root.radius,
            root.isOrigin(false, true) ? 0 : root.radius)

        fragmentShader: Qt.resolvedUrl("shaders/popmask.frag.qsb")
    }

    // The corner it grows from. Growing from an edge's middle has none, so every corner stays round
    function isOrigin(right, bottom) {
        return !fromCenter && fromBottom == bottom && fromRight == right
    }

    function popIn() {
        pop.to = 1
    }

    function popOut() {
        pop.to = 0
    }
}
