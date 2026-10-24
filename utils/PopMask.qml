import QtQuick

import qs.config

// Reveals its children from a corner, or the middle of the top or bottom edge, like a growing mask,
// without moving or resizing them. Size changes ease in the same way, keeping the origin in place
Item {
    id: root

    default property alias content: inner.data
    property real progress: 0
    property real radius: 0
    readonly property bool running: anim.running

    // Corner to grow from, defaults to the one nearest the parent's edges
    property bool fromRight: parent ? x + width / 2 > parent.width / 2 : true
    property bool fromBottom: parent ? y + height / 2 > parent.height / 2 : true
    // Grows from the middle of the edge instead, overriding fromRight
    property bool fromCenter: false
    // Grows from its very middle, overriding all of the above
    property bool fromMiddle: false
    readonly property bool centerX: fromCenter || fromMiddle

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
    readonly property real contentX: centerX ? (visibleWidth - width) / 2 : fromRight ? visibleWidth - width : 0
    readonly property real contentY: fromMiddle ? (visibleHeight - height) / 2 : fromBottom ? visibleHeight - height : 0

    // Only mask while animating, so the content renders natively at rest
    readonly property bool masking: progress < 1 || shownWidth != width || shownHeight != height

    Item {
        id: inner

        width: root.visibleWidth
        height: root.visibleHeight
        x: root.centerX ? (root.width - width) / 2 : root.fromRight ? root.width - width : 0
        y: root.fromMiddle ? (root.height - height) / 2 : root.fromBottom ? root.height - height : 0
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

        readonly property real maskWidth: root.shownWidth * root.progress
        readonly property real maskHeight: root.shownHeight * root.progress

        property var source: contentSource
        property size itemSize: Qt.size(width, height)
        property vector4d maskRect: Qt.vector4d(
            root.centerX ? (width - maskWidth) / 2 : root.fromRight ? width - maskWidth : 0,
            root.fromMiddle ? (height - maskHeight) / 2 : root.fromBottom ? height - maskHeight : 0,
            maskWidth, maskHeight)

        // The origin corner sits on the content's own corner, so leave its rounding to the content
        property vector4d radii: Qt.vector4d(
            root.isOrigin(false, false) ? 0 : root.radius,
            root.isOrigin(true, false) ? 0 : root.radius,
            root.isOrigin(true, true) ? 0 : root.radius,
            root.isOrigin(false, true) ? 0 : root.radius)

        fragmentShader: Qt.resolvedUrl("shaders/popmask.frag.qsb")
    }

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        duration: Settings.popDuration
    }

    // The corner it grows from. Growing from a middle has none, so every corner stays round
    function isOrigin(right, bottom) {
        return !centerX && fromBottom == bottom && fromRight == right
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
