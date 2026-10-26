pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import "SettingsSchema.js" as Schema

// Defaults for every setting. Those wrapped in value() can be changed on the Settings page,
// see SettingsSchema.js for their ranges
QtObject {
    id: root

    // THEME

    // An absolute path, empty until one is picked, which shows the wallpaper pywal last set
    property string wallpaper: value("wallpaper", "")
    property string wallpaperFolder: value("wallpaperFolder", "~/Pictures/wallpapers")
    property bool autoColors: value("autoColors", false)

    // Used while autoColors is off
    property color colorBackground: value("colorBackground", "#0a0a0a")
    property color colorForeground: value("colorForeground", "#f4f1f2")
    property color colorPrimary: value("colorPrimary", "#d71921")
    property color colorText: value("colorText", "#f4f1f2")

    property int wallpaperPageWidth: px(1200)
    property int wallpaperThumbHeight: px(200)
    property real wallpaperScrollSpeed: 3

    // SCALE

    // Every size goes through px(), so the whole shell grows and shrinks together. Sizes are designed at 125%
    property string uiScale: value("uiScale", "125%")
    readonly property real scaleFactor: parseInt(uiScale) / 125

    property int fontSize: px(value("fontSize", 16))
    property string fontFamily: value("fontFamily", "Space Grotesk")
    property string headerFont: value("headerFont", "Dela Gothic One")

    property int windowSpacing: px(value("windowSpacing", 8))
    property int spacing: px(value("spacing", 10))

    property int radiusSm: px(value("radiusSm", 8))
    property int radiusMd: px(value("radiusMd", 16))
    property int radiusLg: px(value("radiusLg", 32))

    property int spinnerSize: px(value("spinnerSize", 24))

    // BUTTON

    property var buttonPadding: ({ lg: spacing * 2, md: spacing, sm: spacing })
    property var buttonFontSize: ({ lg: fontSize, md: fontSize, sm: fontSize - px(2) })
    property int buttonIconSize: px(value("buttonIconSize", 24))

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

    property int scrollbarWidth: px(value("scrollbarWidth", 3))
    property int scrollbarHoverWidth: px(value("scrollbarHoverWidth", 6))
    property int scrollbarMargin: px(value("scrollbarMargin", 3))

    // ANIMATIONS

    property int popDuration: value("popDuration", 200)
    property int snapDuration: value("snapDuration", 400)
    property int resizeDuration: value("resizeDuration", 200)

    property string dateFormat: value("dateFormat", "MM/dd ddd")
    property string timeFormat: value("timeFormat", "h:mm")
    property string longDateFormat: value("longDateFormat", "dddd, MMMM d")

    // KEYBINDS

    property list<string> backShortcuts: ["Escape"]
    property int backSwipeThreshold: value("backSwipeThreshold", 120)
    property int backSwipeResetDelay: value("backSwipeResetDelay", 300)
    property bool naturalScroll: value("naturalScroll", true) // match the compositor's touchpad setting

    // BAR

    property int barHeight: px(value("barHeight", 44))
    property string barPosition: value("barPosition", "bottom")
    property bool barFloating: value("barFloating", false)
    property int workspaceCount: value("workspaceCount", 9)
    property int tooltipDelay: value("tooltipDelay", 500)

    // OSD

    property int osdYPosition: barPosition == "bottom"
        ? barHeight + (windowSpacing * 2)
        : windowSpacing * 2

    // CONTROL CENTER

    property int controlCenterColumns: value("controlCenterColumns", 4)
    property int controlCenterMaxRows: value("controlCenterMaxRows", 6)
    // Rows fit a large button with room around it, so the grid follows the font size
    property int controlCenterCellSize: buttonHeight.lg + spacing * 3
    property int controlCenterPadding: spacing * 4
    property int controlCenterHoldDuration: value("controlCenterHoldDuration", 500)
    property int controlCenterPageHeight: px(value("controlCenterPageHeight", 500))
    property int settingsPageSize: px(value("settingsPageSize", 720))
    property int wifiRescanDelay: value("wifiRescanDelay", 1500)
    property int bluetoothScanDuration: value("bluetoothScanDuration", 20000)

    // LAUNCHER

    property int launcherWidth: px(value("launcherWidth", 440))
    property int launcherHeight: px(value("launcherHeight", 360))
    property int launcherFontSize: fontSize + px(2)
    // App icons stay twice the height of their name
    property int launcherIconSize: launcherFontSize * 2
    readonly property int launcherItemHeight: launcherIconSize + spacing * 2
    // Tighter than the control center, the panel's corners shrink with it
    property int launcherPadding: spacing * 4
    // Apps marked to run in a terminal are started through this, with their command appended
    property list<string> launcherTerminal: ["kitty", "-e"]

    // AUDIO

    // How often the volume mixer looks for apps that connected or quit
    property int audioClientRefresh: 3000

    // KEYBOARD

    // Outline around whatever the keyboard is on
    property int focusRingWidth: px(2)
    // Gap kept between a control reached with the keyboard and the edge of the list it scrolls into view in
    property int focusScrollMargin: spacing * 2

    // SLIDERS

    property int sliderScrollStep: value("sliderScrollStep", 5)
    property int brightnessMin: value("brightnessMin", 5) // 0% turns some backlights fully off

    // CPU

    property int cpuHotTemp: value("cpuHotTemp", 80)

    // POWER

    property int powerConfirmTimeout: value("powerConfirmTimeout", 3000)
    property var powerCommands: ({
        lock: ["hyprlock"],
        sleep: ["systemctl", "suspend"],
        logout: ["hyprctl", "dispatch", "hl.dsp.exit()"],
        restart: ["systemctl", "reboot"],
        shutdown: ["systemctl", "poweroff"]
    })

    // SAVED CHANGES

    readonly property var schema: ({ categories: Schema.categories, entries: Schema.entries, fonts: Schema.fonts, maxFormatLength: Schema.maxFormatLength, sanitize: Schema.sanitize })

    readonly property FileView store: FileView {
        id: file

        path: Quickshell.statePath("settings.json")
        blockLoading: true
        // Deferred, since writing right away drops further changes made in the same tick
        onAdapterUpdated: Qt.callLater(file.writeAdapter)

        adapter: JsonAdapter {
            id: saved
            property var overrides: ({})
        }
    }

    // Reading the text forces the first load right away. It is queued otherwise, so the shell would start
    // with the defaults and then jump
    Component.onCompleted: file.text()

    // Defaults as declared above, noted down as each setting is read
    readonly property var defaults: ({})

    // The saved value if there's a usable one, made safe for its range, otherwise the default
    function value(key, fallback) {
        defaults[key] = fallback
        const entry = Schema.find(key)
        const override = saved.overrides?.[key]
        if (!entry || override === undefined) return fallback
        return Schema.sanitize(entry, override) ?? fallback
    }

    function px(size) {
        return Math.round(size * scaleFactor)
    }

    // The value as saved, before scaling, for the Settings page to show and change
    function stored(key) {
        return value(key, defaults[key])
    }

    function set(key, newValue) {
        const entry = Schema.find(key)
        const safe = entry ? Schema.sanitize(entry, newValue) : undefined
        if (safe === undefined) return false

        // Only changes are saved, so a setting set back to its default counts as unchanged
        if (safe === defaults[key]) {
            reset(key)
            return true
        }

        const overrides = Object.assign({}, saved.overrides)
        overrides[key] = safe
        saved.overrides = overrides
        return true
    }

    function reset(key) {
        const overrides = Object.assign({}, saved.overrides)
        delete overrides[key]
        saved.overrides = overrides
    }

    function isModified(key) {
        return saved.overrides?.[key] !== undefined
    }
}
