import QtQuick
import QtQuick.Layouts
import "../../../components"

import qs.config

// A live reading with a graph of its recent history, for things like CPU temperature or memory use
Tile {
    id: root

    property string icon
    property string label
    // Small text in the top right corner
    property string detail
    // The big reading
    property string value
    // Turns the reading and graph red
    property bool alert: false

    property var history: []
    property int historyLength: 60
    // Fixed scale, so the graph's height means the same thing every time
    property real graphMin: 0
    property real graphMax: 100

    readonly property color accent: alert ? Colors.primary : Colors.foreground

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Settings.spacing * 2
        spacing: Settings.spacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Settings.spacing / 2

            Icon {
                icon: root.icon
                size: Settings.fontSize
                color: Qt.alpha(Colors.text, 0.6)
            }

            Text {
                text: root.label
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - 2
                font.family: Settings.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: root.detail
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - 2
                font.family: Settings.fontFamily
            }
        }

        Text {
            text: root.value
            color: root.alert ? Colors.primary : Colors.text
            font.family: Settings.headerFont
            font.pixelSize: Settings.fontSize * 3
        }

        Canvas {
            id: graph

            Layout.fillWidth: true
            Layout.fillHeight: true

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: root
                function onHistoryChanged() { graph.requestPaint() }
                function onAccentChanged() { graph.requestPaint() }
            }

            // A line through the history, filled down to the bottom. New readings enter on the right
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const history = root.history
                if (history.length < 2) return

                const stepX = width / (root.historyLength - 1)
                const startX = width - (history.length - 1) * stepX
                const yFor = value => height * (1 - (Math.max(root.graphMin, Math.min(root.graphMax, value)) - root.graphMin) / (root.graphMax - root.graphMin))

                ctx.beginPath()
                history.forEach((value, i) => i == 0 ? ctx.moveTo(startX, yFor(value)) : ctx.lineTo(startX + i * stepX, yFor(value)))
                ctx.lineWidth = 2
                ctx.lineJoin = "round"
                ctx.strokeStyle = root.accent
                ctx.stroke()

                ctx.lineTo(width, height)
                ctx.lineTo(startX, height)
                ctx.closePath()
                ctx.fillStyle = Qt.alpha(root.accent, 0.15)
                ctx.fill()
            }
        }
    }
}
