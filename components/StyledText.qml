import QtQuick

import qs.config

// Text in the shell's font and colors, used for every label. Digits are tabular, all the same width, so numbers that
// change, like percentages, never change the size of what holds them
Text {
    id: root

    // Clocks turn it off for the font's own digits and sit in a fixed width instead
    property bool tabular: true

    // Bounds hug the glyphs instead of the line, which leaves room above and below them. Lets large numbers line up
    // with the edges of what's beside them
    property bool trimmed: false

    color: Colors.text
    font.family: Settings.fontFamily
    font.pixelSize: Settings.fontSize
    font.features: tabular ? { "tnum": 1 } : {}

    topPadding: trimmed ? -(ink.tightBoundingRect.y + line.ascent) : 0
    bottomPadding: trimmed ? ink.tightBoundingRect.y + ink.tightBoundingRect.height - line.descent : 0

    // Only measure when trimmed, so plain labels aren't laid out twice
    TextMetrics {
        id: ink
        font: root.font
        text: root.trimmed ? root.text : ""
    }

    FontMetrics {
        id: line
        font: root.font
    }
}
