pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property string wallpaper: ""

    property int fontSize: 16
    property string fontFamily: "Space Grotesk"
    property string headerFont: "Dela Gothic One"

    property int windowSpacing: 8
    property int spacing: 10

    property int radiusSm: 8
    property int radiusMd: 16
    property int radiusLg: 32

    property int spinnerSize: 24

    // BUTTON

    property var buttonPadding: ({ lg: spacing * 2, md: spacing, sm: spacing })
    property var buttonFontSize: ({ lg: fontSize, md: fontSize, sm: fontSize - 2 })
    property int buttonIconSize: 24

    // Heights follow from the padding and the taller of icon and text, so buttons never set one explicitly
    readonly property var buttonHeight: ({
        lg: Math.max(buttonIconSize, buttonMetrics.height) + buttonPadding.lg * 2,
        md: Math.max(buttonIconSize, buttonMetrics.height) + buttonPadding.md * 2,
        sm: Math.max(buttonIconSize, buttonMetricsSm.height) + buttonPadding.sm * 2
    })

    readonly property FontMetrics buttonMetrics: FontMetrics {
        font.family: root.fontFamily
        font.pixelSize: root.buttonFontSize.lg
        font.bold: true
    }

    readonly property FontMetrics buttonMetricsSm: FontMetrics {
        font.family: root.fontFamily
        font.pixelSize: root.buttonFontSize.sm
        font.bold: true
    }

    // SCROLLBAR

    property int scrollbarWidth: 3
    property int scrollbarHoverWidth: 6
    property int scrollbarMargin: 3

    // ANIMATIONS

    property int popDuration: 200
    property int snapDuration: 400
    property int resizeDuration: 200

    property string dateFormat: "MM/dd ddd"
    property string timeFormat: "h:mm"

    // KEYBINDS

    property list<string> backShortcuts: ["Escape"]
    property int backSwipeThreshold: 120
    property int backSwipeResetDelay: 300
    property bool naturalScroll: true // match the compositor's touchpad setting

    // BAR

    property int barHeight: 44
    property string barPosition: "bottom"
    property bool barFloating: false
    property int workspaceCount: 9

    // OSD

    property int osdYPosition: barPosition == "bottom"
        ? barHeight + (windowSpacing * 2)
        : windowSpacing * 2

    // CONTROL CENTER

    property int controlCenterPageHeight: 500
    property int wifiRescanDelay: 1500
    property int bluetoothScanDuration: 20000
}