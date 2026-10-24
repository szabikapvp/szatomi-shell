import QtQuick
import "../../components"
import "widgets"

import qs.config

// Places widgets on a fixed column grid, and lets the user move, resize, add and remove them while editing.
// A layout is a list of { type, x, y, w, h }, measured in cells
Item {
    id: root

    // The JsonAdapter the layout is saved in, as its `widgets` property
    required property var store
    property bool editing: false

    signal pageRequested(url page)

    readonly property Catalog catalog: Catalog {}

    readonly property int columns: Settings.controlCenterColumns
    readonly property int maxRows: Settings.controlCenterMaxRows
    readonly property int cellSize: Settings.controlCenterCellSize
    readonly property int gap: Settings.spacing
    readonly property int pitch: cellSize + gap

    // The saved layout, minus anything that doesn't fit anymore, like a widget whose sizes changed
    readonly property var widgets: sanitize(savedLayout())

    // Layout a drag is heading towards, saved on release
    property var preview: null
    readonly property var shown: preview ?? widgets
    property string activeType: ""

    // Editing shows every row, so there's room to move things into
    readonly property int rows: editing ? maxRows : Math.max(1, ...shown.map(w => w.y + w.h))

    implicitWidth: columns * pitch - gap
    implicitHeight: rows * pitch - gap

    // Empty slots to aim at while editing
    Repeater {
        model: root.columns * root.maxRows

        Rectangle {
            required property int index

            x: (index % root.columns) * root.pitch
            y: Math.floor(index / root.columns) * root.pitch
            width: root.cellSize
            height: root.cellSize
            radius: width / 2

            color: Qt.alpha(Colors.foreground, 0.04)
            opacity: root.editing ? 1 : 0
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Settings.popDuration } }
        }
    }

    // Where the widget being moved will land
    Rectangle {
        readonly property var target: root.shown.find(w => w.type === root.activeType) ?? null

        visible: target !== null
        x: target ? target.x * root.pitch : 0
        y: target ? target.y * root.pitch : 0
        width: target ? target.w * root.pitch - root.gap : 0
        height: target ? target.h * root.pitch - root.gap : 0
        radius: Settings.radiusLg
        color: Qt.alpha(Colors.foreground, 0.1)

        Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    }

    Text {
        anchors.centerIn: parent
        visible: root.widgets.length === 0 && !root.editing

        text: "Hold to add widgets"
        color: Qt.alpha(Colors.text, 0.6)
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.weight: 300
    }

    // One cell per catalog entry, so a widget keeps its tile while it moves around
    Repeater {
        model: root.catalog.entries

        Item {
            id: cell

            required property var modelData
            readonly property string type: modelData.type
            readonly property var placement: root.shown.find(w => w.type === type) ?? null

            // Last spot on the grid, kept while fading out after a removal
            property var rect: ({ x: 0, y: 0, w: 1, h: 1 })
            onPlacementChanged: if (placement) rect = placement
            Component.onCompleted: if (placement) rect = placement

            property bool dragging: false
            property point dragPos

            x: dragging ? dragPos.x : rect.x * root.pitch
            y: dragging ? dragPos.y : rect.y * root.pitch
            width: rect.w * root.pitch - root.gap
            height: rect.h * root.pitch - root.gap
            z: dragging ? 1 : 0
            scale: dragging ? 1.05 : 1

            opacity: placement ? 1 : 0
            visible: opacity > 0

            // Off while fading in, so a new widget appears in place instead of flying there
            Behavior on x { enabled: cell.opacity == 1 && !cell.dragging; NumberAnimation { duration: Settings.resizeDuration; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: cell.opacity == 1 && !cell.dragging; NumberAnimation { duration: Settings.resizeDuration; easing.type: Easing.OutCubic } }
            Behavior on width { enabled: cell.opacity == 1; NumberAnimation { duration: Settings.resizeDuration; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: cell.opacity == 1; NumberAnimation { duration: Settings.resizeDuration; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Settings.popDuration } }

            Loader {
                id: tile

                anchors.fill: parent
                // Not cell.visible, which also turns false while the panel is hidden and would rebuild every tile on open
                active: cell.opacity > 0
                source: cell.modelData.tile
                // Editing takes over the mouse
                enabled: !root.editing

                onLoaded: {
                    item.columns = Qt.binding(() => cell.rect.w)
                    item.rows = Qt.binding(() => cell.rect.h)
                }
            }

            Connections {
                target: tile.item

                function onHeld() { root.editing = true }
                function onPageRequested() { if (cell.modelData.page) root.pageRequested(cell.modelData.page) }
            }

            // Move
            MouseArea {
                property point grabPos

                anchors.fill: parent
                enabled: root.editing
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: (mouse) => {
                    grabPos = Qt.point(mouse.x, mouse.y)
                    root.activeType = cell.type
                }

                onPositionChanged: (mouse) => {
                    const pointer = mapToItem(root, mouse.x, mouse.y)
                    cell.dragPos = Qt.point(pointer.x - grabPos.x, pointer.y - grabPos.y)
                    cell.dragging = true
                    root.propose(root.moved(cell.type, Math.round(cell.dragPos.x / root.pitch), Math.round(cell.dragPos.y / root.pitch)))
                }

                onReleased: {
                    cell.dragging = false
                    root.commit()
                }

                onCanceled: {
                    cell.dragging = false
                    root.cancel()
                }
            }

            // Remove
            EditHandle {
                x: -width / 4
                y: -height / 4
                icon: "close"
                shown: root.editing && !cell.dragging

                onClicked: root.remove(cell.type)
            }

            // Resize, only when there's more than one size to pick from
            EditHandle {
                x: cell.width - width * 3 / 4
                y: cell.height - height * 3 / 4
                icon: "resize"
                shown: root.editing && !cell.dragging && root.sizesOf(cell.modelData).length > 1
                cursorShape: Qt.SizeFDiagCursor

                onPressed: root.activeType = cell.type

                // Measured from the widget's top left cell, so the pointer picks the size it's over
                onPositionChanged: (mouse) => {
                    const pointer = mapToItem(root, mouse.x, mouse.y)
                    const self = root.widgets.find(w => w.type === cell.type)
                    root.propose(root.resized(cell.type,
                        (pointer.x - self.x * root.pitch + root.gap / 2) / root.pitch,
                        (pointer.y - self.y * root.pitch + root.gap / 2) / root.pitch))
                }

                onReleased: root.commit()
                onCanceled: root.cancel()
            }
        }
    }

    // Small round button on a widget's corner while editing
    component EditHandle: Rectangle {
        id: handle

        property string icon
        property bool shown: false
        property alias cursorShape: handleArea.cursorShape

        signal clicked()
        signal pressed()
        signal positionChanged(var mouse)
        signal released()
        signal canceled()

        width: Settings.buttonIconSize + Settings.spacing
        height: width
        radius: width / 2
        z: 1

        color: Colors.foreground
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: Settings.popDuration } }

        Icon {
            anchors.centerIn: parent
            icon: handle.icon
            size: Settings.buttonIconSize * 2 / 3
            color: Colors.background
        }

        MouseArea {
            id: handleArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: handle.clicked()
            onPressed: handle.pressed()
            onPositionChanged: (mouse) => handle.positionChanged(mouse)
            onReleased: handle.released()
            onCanceled: handle.canceled()
        }
    }

    // LAYOUT RULES

    function sizesOf(entry) {
        return entry.sizes.filter(size => size[0] <= columns && size[1] <= maxRows)
    }

    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
    }

    // Inside the grid and clear of every widget in the layout, except the one being placed
    function fits(rect, layout) {
        return rect.x >= 0 && rect.y >= 0 && rect.x + rect.w <= columns && rect.y + rect.h <= maxRows
            && !layout.some(other => other.type !== rect.type && overlaps(rect, other))
    }

    // Layouts read back from the file are array-like sequences rather than arrays, so they're copied into one
    function savedLayout() {
        const saved = store.widgets
        const isList = saved !== null && typeof saved === "object" && typeof saved.length === "number"
        return isList ? Array.from(saved) : catalog.defaultLayout
    }

    // Keeps known widgets once each, at an allowed size, on free cells
    function sanitize(layout) {
        const result = []

        for (const widget of layout) {
            const entry = catalog.find(widget.type)
            if (!entry || result.some(other => other.type === widget.type)) continue

            const rect = { type: widget.type, x: widget.x, y: widget.y, w: widget.w, h: widget.h }
            const allowed = sizesOf(entry).some(size => size[0] === rect.w && size[1] === rect.h)
            if (allowed && fits(rect, result)) result.push(rect)
        }

        return result
    }

    // The layout with a widget moved, or null if it doesn't fit there.
    // Landing exactly on a widget of the same size swaps the two
    function moved(type, x, y) {
        const self = widgets.find(w => w.type === type)
        const rect = Object.assign({}, self, {
            x: Math.max(0, Math.min(columns - self.w, x)),
            y: Math.max(0, Math.min(maxRows - self.h, y))
        })

        if (fits(rect, widgets)) return widgets.map(w => w.type === type ? rect : w)

        const other = widgets.find(w => w.type !== type && w.x === rect.x && w.y === rect.y && w.w === self.w && w.h === self.h)
        if (!other) return null

        const swapped = Object.assign({}, other, { x: self.x, y: self.y })
        return widgets.map(w => w.type === type ? rect : w.type === other.type ? swapped : w)
    }

    // The layout with a widget at the allowed size closest to the wanted one that still fits
    function resized(type, wantedW, wantedH) {
        const self = widgets.find(w => w.type === type)
        const distance = rect => Math.hypot(rect.w - wantedW, rect.h - wantedH)

        const best = sizesOf(catalog.find(type))
            .map(size => Object.assign({}, self, { w: size[0], h: size[1] }))
            .filter(rect => fits(rect, widgets))
            .reduce((a, b) => distance(b) < distance(a) ? b : a, self)

        return widgets.map(w => w.type === type ? best : w)
    }

    // First free spot, trying the widget's sizes in order
    function spotFor(type) {
        for (const size of sizesOf(catalog.find(type))) {
            for (let y = 0; y + size[1] <= maxRows; y++) {
                for (let x = 0; x + size[0] <= columns; x++) {
                    const rect = { type: type, x: x, y: y, w: size[0], h: size[1] }
                    if (fits(rect, widgets)) return rect
                }
            }
        }
        return null
    }

    // EDITING

    function add(type) {
        const rect = spotFor(type)
        if (rect) save(widgets.concat([rect]))
    }

    function remove(type) {
        save(widgets.filter(w => w.type !== type))
    }

    // Keeps the last layout that fit, so dragging over a blocked spot doesn't snap back
    function propose(layout) {
        if (layout) preview = layout
    }

    function commit() {
        if (preview) save(preview)
        cancel()
    }

    function cancel() {
        preview = null
        activeType = ""
    }

    function save(layout) {
        store.widgets = layout
    }
}
