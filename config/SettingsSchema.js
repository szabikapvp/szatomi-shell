.pragma library

// Describes every setting the Settings page can change: where it's listed, which control it gets,
// and the range it's held to. To add one, declare it in Settings.qml with value() and describe it here.
//
// Types:
//   bool    toggle
//   int     slider from min to max in steps of step, shown with unit
//   choice  one of options
//   font    an installed font family
//   format  a Qt date/time format string, up to maxFormatLength characters
//
// Ranges are picked so that no combination of values breaks the layout on a 1080p screen.

var categories = ["Appearance", "Layout", "Bar", "Control center", "Animations", "Date & time", "Input", "System"]

var maxFormatLength = 32

var entries = [
    // APPEARANCE
    { key: "fontFamily", category: "Appearance", label: "Font", description: "Used for all regular text", type: "font" },
    { key: "headerFont", category: "Appearance", label: "Display font", description: "Used for large numbers like the clock", type: "font" },
    { key: "fontSize", category: "Appearance", label: "Font size", description: "Buttons and the control center grid grow with it", type: "int", min: 12, max: 20, step: 1, unit: "px" },
    { key: "buttonIconSize", category: "Appearance", label: "Icon size", type: "int", min: 16, max: 28, step: 1, unit: "px" },
    { key: "radiusSm", category: "Appearance", label: "Small corner radius", type: "int", min: 0, max: 16, step: 1, unit: "px" },
    { key: "radiusMd", category: "Appearance", label: "Medium corner radius", type: "int", min: 0, max: 24, step: 1, unit: "px" },
    { key: "radiusLg", category: "Appearance", label: "Large corner radius", description: "Also rounds the control center panel", type: "int", min: 0, max: 40, step: 1, unit: "px" },
    { key: "spinnerSize", category: "Appearance", label: "Loading indicator size", type: "int", min: 16, max: 32, step: 1, unit: "px" },

    // LAYOUT
    { key: "windowSpacing", category: "Layout", label: "Window spacing", description: "Gap between floating panels and the screen edges", type: "int", min: 0, max: 16, step: 1, unit: "px" },
    { key: "spacing", category: "Layout", label: "Spacing", description: "Gap between elements, also sets button padding", type: "int", min: 6, max: 12, step: 1, unit: "px" },
    { key: "scrollbarWidth", category: "Layout", label: "Scrollbar width", type: "int", min: 2, max: 6, step: 1, unit: "px" },
    { key: "scrollbarHoverWidth", category: "Layout", label: "Scrollbar hover width", type: "int", min: 4, max: 10, step: 1, unit: "px" },
    { key: "scrollbarMargin", category: "Layout", label: "Scrollbar margin", type: "int", min: 0, max: 6, step: 1, unit: "px" },

    // BAR
    { key: "barPosition", category: "Bar", label: "Position", type: "choice", options: ["top", "bottom"] },
    { key: "barFloating", category: "Bar", label: "Floating", description: "Detach the bar from the screen edge", type: "bool" },
    { key: "barHeight", category: "Bar", label: "Height", type: "int", min: 36, max: 60, step: 1, unit: "px" },
    { key: "workspaceCount", category: "Bar", label: "Workspaces", description: "Number of workspace dots", type: "int", min: 1, max: 10, step: 1, unit: "" },

    // CONTROL CENTER
    { key: "controlCenterColumns", category: "Control center", label: "Columns", description: "Widgets that no longer fit are hidden until there's room again", type: "int", min: 3, max: 5, step: 1, unit: "" },
    { key: "controlCenterMaxRows", category: "Control center", label: "Rows", description: "Most rows the grid can grow to", type: "int", min: 2, max: 6, step: 1, unit: "" },
    { key: "controlCenterHoldDuration", category: "Control center", label: "Hold to edit", description: "How long to hold before the grid starts editing", type: "int", min: 300, max: 1500, step: 50, unit: "ms" },
    { key: "controlCenterPageHeight", category: "Control center", label: "Page height", description: "Height of the Wi-Fi and Bluetooth pages", type: "int", min: 400, max: 700, step: 10, unit: "px" },
    { key: "settingsPageSize", category: "Control center", label: "Settings page size", type: "int", min: 600, max: 800, step: 10, unit: "px" },
    { key: "sliderScrollStep", category: "Control center", label: "Slider scroll step", description: "How much one scroll moves a volume or brightness slider", type: "int", min: 1, max: 20, step: 1, unit: "%" },

    // ANIMATIONS
    { key: "popDuration", category: "Animations", label: "Pop duration", description: "Opening and closing panels", type: "int", min: 50, max: 500, step: 10, unit: "ms" },
    { key: "resizeDuration", category: "Animations", label: "Resize duration", description: "Panels changing size, widgets moving", type: "int", min: 50, max: 500, step: 10, unit: "ms" },
    { key: "snapDuration", category: "Animations", label: "Snap duration", description: "The control center snapping into place after a drag", type: "int", min: 100, max: 800, step: 10, unit: "ms" },

    // DATE & TIME
    { key: "timeFormat", category: "Date & time", label: "Time format", description: "For example h:mm or HH:mm", type: "format" },
    { key: "dateFormat", category: "Date & time", label: "Date format", description: "Shown in the bar, for example MM/dd ddd", type: "format" },
    { key: "longDateFormat", category: "Date & time", label: "Long date format", description: "Shown on the clock widget, for example dddd, MMMM d", type: "format" },

    // INPUT
    { key: "naturalScroll", category: "Input", label: "Natural scrolling", description: "Match the compositor's touchpad setting", type: "bool" },
    { key: "backSwipeThreshold", category: "Input", label: "Back swipe distance", description: "How far to swipe right with two fingers to go back", type: "int", min: 60, max: 300, step: 10, unit: "px" },
    { key: "backSwipeResetDelay", category: "Input", label: "Back swipe reset", description: "Pause that ends a swipe", type: "int", min: 100, max: 1000, step: 50, unit: "ms" },

    // SYSTEM
    { key: "brightnessMin", category: "System", label: "Minimum brightness", description: "Lowest level the brightness slider can set", type: "int", min: 5, max: 30, step: 1, unit: "%" },
    { key: "wifiRescanDelay", category: "System", label: "Wi-Fi rescan delay", description: "Wait after turning Wi-Fi on before scanning", type: "int", min: 500, max: 5000, step: 100, unit: "ms" },
    { key: "bluetoothScanDuration", category: "System", label: "Bluetooth scan duration", type: "int", min: 5000, max: 60000, step: 1000, unit: "ms" },
    { key: "powerConfirmTimeout", category: "System", label: "Power confirm timeout", description: "How long Restart and Shut down wait for the second click", type: "int", min: 1000, max: 10000, step: 500, unit: "ms" }
]

// Symbol and emoji fonts render text unreadable, which would also hide the way back
var unreadableFont = /emoji|symbol|icon|awesome|dingbat|wingding|webding|math/i

var fonts = Qt.fontFamilies().filter(family => !unreadableFont.test(family))

function find(key) {
    return entries.find(entry => entry.key === key) ?? null
}

// The value made safe for its setting, or undefined when there's nothing usable to make of it
function sanitize(entry, value) {
    switch (entry.type) {
        case "bool":
            return typeof value === "boolean" ? value : undefined

        case "int": {
            const number = Number(value)
            if (typeof value === "boolean" || !isFinite(number)) return undefined
            const stepped = entry.min + Math.round((number - entry.min) / entry.step) * entry.step
            return Math.max(entry.min, Math.min(entry.max, stepped))
        }

        case "choice":
            return entry.options.includes(value) ? value : undefined

        case "font":
            return fonts.includes(value) ? value : undefined

        case "format":
            return typeof value === "string" && value.trim() !== "" && value.length <= maxFormatLength ? value : undefined
    }
    return undefined
}
