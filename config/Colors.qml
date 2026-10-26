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
    property color primary: generated ? readable(accent(pywal.colors), pywal.special.foreground) : Settings.colorPrimary
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

    // Pastel palettes give an accent about as light as the text on it, so its lightness is moved
    // away from the text's, keeping the hue, until the two reach Settings.accentContrast
    function readable(color, textColor) {
        // pywal's colors arrive as strings
        const text = Qt.color(textColor)
        const away = luminance(text) > luminance(color) ? -0.02 : 0.02
        let result = color
        while (contrast(result, text) < Settings.accentContrast && result.hslLightness > 0 && result.hslLightness < 1)
            result = Qt.hsla(result.hslHue, result.hslSaturation, Math.max(0, Math.min(1, result.hslLightness + away)), 1)
        return result
    }

    // WCAG relative luminance and contrast ratio
    function luminance(value) {
        const color = Qt.color(value)
        const linear = value => value <= 0.03928 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4)
        return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
    }

    function contrast(a, b) {
        const la = luminance(a)
        const lb = luminance(b)
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
    }
}
