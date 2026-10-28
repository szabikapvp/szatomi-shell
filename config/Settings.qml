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
    // Wallpapers set for one display, by display key, over the one above
    property var wallpapers: value("wallpapers", ({}))
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
    // Least contrast (WCAG ratio) between a generated accent and the text drawn on it. 3 is the minimum for icons and bold text
    property real accentContrast: 3

    // SCALE

    // Every size goes through px(), so the whole shell grows and shrinks together. Sizes are designed at 125%
    property string uiScale: value("uiScale", "125%")
    readonly property real scaleFactor: parseInt(uiScale) / 125

    property int fontSize: px(value("fontSize", 16))
    property string fontFamily: value("fontFamily", "Space Grotesk")
    property string headerFont: value("headerFont", "Dela Gothic One")

    property int windowSpacing: px(value("windowSpacing", 8))
    property int spacing: px(10)

    // Scales every corner radius together
    property int roundness: value("roundness", 100)
    property int radiusSm: px(8 * roundness / 100)
    property int radiusMd: px(16 * roundness / 100)
    property int radiusLg: px(32 * roundness / 100)

    property int spinnerSize: px(24)

    // BUTTON

    property var buttonPadding: ({ lg: spacing * 2, md: spacing, sm: spacing })
    property var buttonFontSize: ({ lg: fontSize, md: fontSize, sm: fontSize - px(2) })
    property int buttonIconSize: px(24)

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

    property int scrollbarWidth: px(3)
    property int scrollbarHoverWidth: px(6)
    property int scrollbarMargin: px(3)

    // ANIMATIONS

    // Motion follows Apple's springs: response is roughly how long a move takes in seconds, a damping ratio of 1
    // settles without overshoot and lower ones bounce. Animation speed scales every one of them
    property int animationSpeed: value("animationSpeed", 100)
    // Fades instead of sliding and growing, and snaps moved things into place
    property bool reduceMotion: value("reduceMotion", false)
    readonly property real motionScale: 100 / animationSpeed

    // Opening panels, moving and resizing things
    readonly property real springResponse: 0.3 * motionScale
    // The control center settling into a corner after a throw. It carries momentum, so it may bounce a little
    readonly property real flickResponse: 0.4 * motionScale
    property real flickDamping: 0.8
    // How far a throw carries, the rate scrolling slows down at. Lower stops sooner
    property real flickDeceleration: 0.998

    // Behaviors can't run a real spring, so they trace the default one's curve over the time it takes to settle,
    // which is 1.273 times its response
    readonly property var springCurve: [0.3, 0.43, 0.105, 1, 1, 1]
    readonly property int motionDuration: Math.round(springResponse * 1273)
    // Hover, press and color feedback
    readonly property int motionFastDuration: Math.round(150 * motionScale)
    // Buttons sink a little while held
    property real pressScale: 0.97

    property string dateFormat: value("dateFormat", "MM/dd ddd")
    property string timeFormat: value("timeFormat", "h:mm")
    property string longDateFormat: value("longDateFormat", "dddd, MMMM d")

    // KEYBINDS

    property list<string> backShortcuts: ["Escape"]
    property int backSwipeThreshold: 120
    property int backSwipeResetDelay: 300
    property bool naturalScroll: value("naturalScroll", true) // match the compositor's touchpad setting

    // SHORTCUTS

    // Written the way Hyprland binds them. SUPER + SUPER_L is a tap of the Super key on its own
    property string shortcutControlCenter: value("shortcutControlCenter", "SUPER + SUPER_L")
    property string shortcutLauncher: value("shortcutLauncher", "SUPER + R")
    property string shortcutSettings: value("shortcutSettings", "SUPER + I")
    property string shortcutWallpaper: value("shortcutWallpaper", "SUPER + W")
    property string shortcutDisplays: value("shortcutDisplays", "SUPER + O")
    // Recording a new shortcut gives up after this long, handing the keyboard back to Hyprland
    property int shortcutRecordTimeout: 10000

    // BAR

    property int barHeight: px(value("barHeight", 44))
    property string barPosition: value("barPosition", "bottom")
    property bool barFloating: value("barFloating", false)
    property int workspaceCount: value("workspaceCount", 9)
    property int tooltipDelay: 500
    // Room around a bar button's content, which its hover highlight fills
    property int barButtonPadding: px(8)

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
    property int controlCenterHoldDuration: 500
    property int controlCenterPageHeight: px(500)
    property int settingsPageSize: px(720)
    property int wifiRescanDelay: 1500
    property int bluetoothScanDuration: 20000

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

    // DISPLAYS

    // Key of the display the bar, the control center and pop-ups show on. Empty picks the built in one, or the first
    property string mainDisplay: value("mainDisplay", "")

    // Changed display settings go back unless kept within this long, in case a display went dark
    property int displayConfirmTimeout: 15000
    // Scales that would leave a display shorter than this aren't offered
    property int displayMinLogicalHeight: 600
    property int displayCanvasHeight: px(220)
    // How close a dragged display has to get to lining up with another before it snaps to it
    property int displaySnapDistance: px(16)
    // Wait after displays are plugged in or out before putting a saved layout back, while Hyprland sets them up
    property int displaySettleDelay: 1500
    // Gap between turning mirrors off and on, since Hyprland drops both done at once
    property int displayMirrorDelay: 300

    // DROPDOWN

    // Tallest an open dropdown list gets before it scrolls
    property int dropdownMaxHeight: px(280)

    // KEYBOARD

    // Outline around whatever the keyboard is on
    property int focusRingWidth: px(2)
    // Gap kept between a control reached with the keyboard and the edge of the list it scrolls into view in
    property int focusScrollMargin: spacing * 2

    // SLIDERS

    property int sliderScrollStep: 5
    property int brightnessMin: value("brightnessMin", 5) // 0% turns some backlights fully off

    // BATTERY

    // At or below this percentage, while unplugged, the bar's battery turns the accent color
    property int batteryLowLevel: 20

    // CPU

    property int cpuHotTemp: 80

    // POWER

    property int powerConfirmTimeout: 3000
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
