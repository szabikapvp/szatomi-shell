import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils
import "../../services/DisplayLayout.js" as Arrange

// The displays in use, drawn where they sit. Dragging one snaps it next to another, arrow keys step it from
// spot to spot, and a click or Enter opens its page. Each screen shows its name while this is open
Item {
    id: canvas

    signal opened(string key)

    Layout.fillWidth: true
    // Implicit too, since the settings row loads it and a Loader goes by implicit size
    implicitHeight: Settings.displayCanvasHeight

    Component.onCompleted: Displays.identifiers++
    Component.onDestruction: Displays.identifiers--

    // Held while dragging, so the rest stay put as the bounds change
    property var frozen: null
    readonly property var bounds: frozen ?? measure()
    readonly property real fit: Math.min((width - Settings.spacing * 2) / bounds.w, (height - Settings.spacing * 2) / bounds.h)
    readonly property real offsetX: (width - bounds.w * fit) / 2 - bounds.x * fit
    readonly property real offsetY: (height - bounds.h * fit) / 2 - bounds.y * fit

    function measure() {
        const rects = Displays.arranged.map(config => Displays.rect(config))
        if (rects.length == 0) return { x: 0, y: 0, w: 1, h: 1 }
        const x = Math.min(...rects.map(r => r.x))
        const y = Math.min(...rects.map(r => r.y))
        return {
            x: x,
            y: y,
            w: Math.max(...rects.map(r => r.x + r.w)) - x,
            h: Math.max(...rects.map(r => r.y + r.h)) - y
        }
    }

    Repeater {
        // By key, so a tile keeps the keyboard while its display moves
        model: ScriptModel { values: Displays.arranged.map(config => config.key) }

        Rectangle {
            id: tile

            required property string modelData
            readonly property var config: Displays.shown.find(config => config.key == modelData) ?? null
            readonly property var rect: config ? Displays.rect(config) : ({ x: 0, y: 0, w: 0, h: 0 })
            readonly property bool lit: activeFocus || mouseArea.containsMouse
            property bool dragging: false
            property real dragX: 0
            property real dragY: 0

            x: canvas.offsetX + rect.x * canvas.fit + dragX
            y: canvas.offsetY + rect.y * canvas.fit + dragY
            width: rect.w * canvas.fit
            height: rect.h * canvas.fit
            z: dragging ? 1 : 0

            Behavior on x { enabled: !tile.dragging; Anim {} }
            Behavior on y { enabled: !tile.dragging; Anim {} }
            Behavior on width { Anim {} }
            Behavior on height { Anim {} }

            radius: Settings.radiusSm
            color: dragging ? Colors.primary : Qt.alpha(Colors.foreground, lit ? 0.2 : 0.1)
            border.width: 1
            border.color: Qt.alpha(Colors.foreground, 0.2)

            Behavior on color { ColorAnim {} }

            // The screen it stands for stands out while it's pointed at or has the keyboard
            onLitChanged: {
                if (lit) Displays.highlighted = config?.name ?? ""
                else if (Displays.highlighted == config?.name) Displays.highlighted = ""
            }

            activeFocusOnTab: true
            Keys.onPressed: (event) => {
                if ([Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].includes(event.key)) {
                    canvas.opened(modelData)
                    event.accepted = true
                    return
                }
                const direction = ({ [Qt.Key_Left]: [-1, 0], [Qt.Key_Right]: [1, 0], [Qt.Key_Up]: [0, -1], [Qt.Key_Down]: [0, 1] })[event.key]
                if (!direction) return
                const spot = Arrange.step(tile.rect, Displays.others(modelData), direction[0], direction[1])
                if (spot) Displays.moveTo(modelData, spot)
                event.accepted = true
            }

            FocusRing {}

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - Settings.spacing
                spacing: 0

                Text {
                    text: tile.config?.label ?? ""
                    color: Colors.text
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    font.bold: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                Text {
                    text: (tile.config?.name ?? "") + (Displays.mainScreen?.name == tile.config?.name ? " · Main" : "")
                    color: Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - Settings.px(4)
                    font.family: Settings.fontFamily
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: mouseArea

                // Where the press started, in the canvas, since the tile moves under the pointer
                property point start

                anchors.fill: parent
                hoverEnabled: true
                // The list around would take over a drag that goes up or down
                preventStealing: true
                cursorShape: tile.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                onPressed: (mouse) => {
                    tile.forceActiveFocus()
                    start = mapToItem(canvas, mouse.x, mouse.y)
                }
                onPositionChanged: (mouse) => {
                    if (!pressed) return
                    const point = mapToItem(canvas, mouse.x, mouse.y)
                    // Only a real drag moves it, so a slightly shaky click still opens the page
                    if (!tile.dragging && Math.hypot(point.x - start.x, point.y - start.y) < Settings.displaySnapDistance / 2) return
                    if (!tile.dragging) {
                        canvas.frozen = canvas.bounds
                        tile.dragging = true
                    }
                    tile.dragX = point.x - start.x
                    tile.dragY = point.y - start.y
                }
                onReleased: tile.dragging ? drop() : canvas.opened(tile.modelData)
                onCanceled: if (tile.dragging) drop()

                // Lands touching the closest display, lined up with it when close enough
                function drop() {
                    const dropped = Object.assign({}, tile.rect, {
                        x: tile.rect.x + tile.dragX / canvas.fit,
                        y: tile.rect.y + tile.dragY / canvas.fit
                    })
                    const fit = canvas.fit
                    tile.dragging = false
                    canvas.frozen = null
                    Displays.moveTo(tile.modelData, Arrange.snap(dropped, Displays.others(tile.modelData), Settings.displaySnapDistance / fit))
                    tile.dragX = 0
                    tile.dragY = 0
                }
            }
        }
    }
}
