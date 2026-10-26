import QtQuick

import qs.config

// Outline shown around its parent while the keyboard is on it. Also scrolls the parent into view
// when it sits in a scrolling list, so tabbing never lands on something offscreen
Rectangle {
    id: root

    // The item whose focus is shown, usually the parent
    property Item target: parent
    property real targetRadius: target?.radius ?? Settings.radiusSm

    // Lists that keep the keyboard themselves set it for their current item
    property bool shown: target?.activeFocus ?? false

    anchors.fill: target
    anchors.margins: -Settings.focusRingWidth * 2
    radius: targetRadius + Settings.focusRingWidth * 2
    z: 10

    color: "transparent"
    border.width: Settings.focusRingWidth
    border.color: Colors.primary
    visible: shown

    onShownChanged: if (shown) reveal()

    function reveal() {
        // The closest Flickable, the only kind of item with a contentY
        let view = target.parent
        while (view && view.contentY === undefined) view = view.parent
        if (!view) return

        const margin = Settings.focusScrollMargin
        const pos = target.mapToItem(view.contentItem, 0, 0)
        if (view.contentHeight > view.height) {
            if (pos.y - margin < view.contentY) view.contentY = Math.max(0, pos.y - margin)
            else if (pos.y + target.height + margin > view.contentY + view.height)
                view.contentY = Math.min(view.contentHeight - view.height, pos.y + target.height + margin - view.height)
        }
        if (view.contentWidth > view.width) {
            if (pos.x - margin < view.contentX) view.contentX = Math.max(0, pos.x - margin)
            else if (pos.x + target.width + margin > view.contentX + view.width)
                view.contentX = Math.min(view.contentWidth - view.width, pos.x + target.width + margin - view.width)
        }
    }
}
