pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The palette, from the colors in Settings, or from pywal's palette for the wallpaper when autoColors is on
QtObject {
    id: root

    // Parsed colors.json, null until it loads. Also tells which wallpaper pywal last ran on
    property var pywal: null
    readonly property bool generated: Settings.autoColors && pywal !== null

    property color background: generated ? pywal.special.background : Settings.colorBackground
    property color foreground: generated ? pywal.special.foreground : Settings.colorForeground
    property color primary: generated ? accent(pywal.colors) : Settings.colorPrimary
    property color secondary: pywal?.colors.color6 ?? "#f38ba8"
    property color text: generated ? pywal.special.foreground : Settings.colorText

    // lighter() can't brighten pure black, so tint with the foreground instead
    property color backgroundSubtle: Qt.tint(background, Qt.alpha(foreground, 0.07))

    property color foregroundHover: Qt.darker(foreground, hover)
    property color foregroundActive: Qt.darker(foreground, active)
    property color primaryHover: Qt.darker(primary, hover)
    property color primaryActive: Qt.darker(primary, active)
    property color secondaryHover: Qt.darker(secondary, hover)
    property color secondaryActive: Qt.darker(secondary, active)
    property color textHover: Qt.darker(text, hover)
    property color textActive: Qt.darker(text, active)

    property double hover: 1.5
    property double active: 2

    property FileView pywalWatcher: FileView {
        path: "/home/tomi/.cache/wal/colors.json"
        watchChanges: true
        // Loaded before the first frame, so a generated palette doesn't flash in after the custom one
        blockLoading: true

        onFileChanged: reload()

        onLoaded: {
            try {
                root.pywal = JSON.parse(text())
            } catch (e) {
                console.log("Could not load or parse Pywal colors: " + e)
            }
        }
    }

    Component.onCompleted: pywalWatcher.text()

    // The most saturated of the palette's main colors, so the accent stands out on any wallpaper
    function accent(colors) {
        return [1, 2, 3, 4, 5, 6]
            .map(i => Qt.color(colors["color" + i]))
            .reduce((best, color) => color.hslSaturation > best.hslSaturation ? color : best)
    }
}
