.pragma library

// Describes every setting the Settings page can change: where it's listed, which control it gets,
// and the range it's held to. To add one, declare it in Settings.qml with value() and describe it here.
// Only what people actually tune belongs here, the rest stays a plain property in Settings.qml.
//
// Types:
//   bool    toggle
//   int     slider from min to max in steps of step, shown with unit
//   choice  one of options
//   font    an installed font family
//   format  a Qt date/time format string, up to maxFormatLength characters
//   path    a file or folder path, ~ allowed
//   color   a #rrggbb color
//   wallpaper  the wallpaper of every display or of one, with a button that opens the selector
//   wallpapers per display wallpapers, by display. Not listed, the wallpaper row sets it
//   mixer      volume of every app that's playing. Stores nothing
//   devices    output devices, or input devices with input: true, each opening its own page. Stores nothing
//   shortcut   a key combo as Hyprland writes it, like SUPER + I, recorded by pressing it
//   display    one of the connected displays, empty for automatic
//   displayMode     extend or mirror, and which display is mirrored. Stores nothing
//   arrangement     where the displays sit next to each other. Stores nothing
//   displays   every connected display, each opening its own page. Stores nothing
//
// group is a small heading the setting is listed under within its category, kept in order here.
// hidden settings are stored and checked like the rest, but never listed.
// overriddenBy names a bool setting that, while on, takes over the setting and greys its row out.
//
// Ranges are picked so that no combination of values breaks the layout on a 1080p screen.

var categories = ["Appearance", "Theme", "Displays", "Bar", "Control center", "Launcher", "Audio", "Animations", "Date & time", "Input"]

var maxFormatLength = 32

// Modifiers, then one key: a name like I, F5 or Page_Up, or code:N for a raw keycode
var shortcutPattern = /^((SUPER|CTRL|ALT|SHIFT) \+ )*[A-Za-z0-9_]+$|^((SUPER|CTRL|ALT|SHIFT) \+ )*code:[0-9]+$/

var entries = [
    // APPEARANCE
    { key: "uiScale", category: "Appearance", group: "Size", label: "Scale", description: "Size of everything in the shell", type: "choice", options: ["75%", "100%", "125%", "150%"] },
    { key: "fontSize", category: "Appearance", group: "Size", label: "Font size", description: "Buttons and the control center grid grow with it", type: "int", min: 12, max: 20, step: 1, unit: "px" },
    { key: "fontFamily", category: "Appearance", group: "Fonts", label: "Font", description: "Used for all regular text", type: "font" },
    { key: "headerFont", category: "Appearance", group: "Fonts", label: "Display font", description: "Used for large numbers like the clock", type: "font" },
    { key: "roundness", category: "Appearance", group: "Shape", label: "Roundness", description: "Corners of panels, buttons and cards", type: "int", min: 0, max: 125, step: 5, unit: "%" },
    { key: "windowSpacing", category: "Appearance", group: "Shape", label: "Window spacing", description: "Gap between floating panels and the screen edges", type: "int", min: 0, max: 16, step: 1, unit: "px" },

    // THEME
    { key: "wallpaper", category: "Theme", group: "Wallpaper", label: "Wallpaper", type: "wallpaper" },
    { key: "wallpapers", category: "Theme", label: "Display wallpapers", type: "wallpapers", hidden: true },
    { key: "wallpaperFolder", category: "Theme", group: "Wallpaper", label: "Wallpaper folder", description: "Where the wallpaper selector looks for images", type: "path" },
    { key: "autoColors", category: "Theme", group: "Colors", label: "Colors from wallpaper", description: "Generate the palette with pywal whenever the main display's wallpaper changes", type: "bool" },
    { key: "colorBackground", category: "Theme", group: "Colors", label: "Background", description: "Panels and the bar", type: "color", overriddenBy: "autoColors" },
    { key: "colorForeground", category: "Theme", group: "Colors", label: "Foreground", description: "Hover and pressed highlights, slider fills", type: "color", overriddenBy: "autoColors" },
    { key: "colorPrimary", category: "Theme", group: "Colors", label: "Accent", description: "Active toggles and highlights", type: "color", overriddenBy: "autoColors" },
    { key: "colorText", category: "Theme", group: "Colors", label: "Text", description: "Text and icons", type: "color", overriddenBy: "autoColors" },

    // DISPLAYS
    { key: "displayMode", category: "Displays", group: "Layout", label: "Multiple displays", type: "displayMode" },
    { key: "arrangement", category: "Displays", group: "Layout", label: "Arrangement", description: "Drag the displays to match where they sit. Arrow keys move the selected one, Enter opens it", type: "arrangement" },
    { key: "mainDisplay", category: "Displays", group: "Layout", label: "Main display", description: "Where the bar, the control center and pop-ups show up", type: "display" },
    { key: "displays", category: "Displays", group: "Connected", label: "Displays", description: "Pick one for its resolution, refresh rate, scale and rotation", type: "displays" },
    { key: "brightnessMin", category: "Displays", group: "Brightness", label: "Minimum brightness", description: "Lowest level the brightness slider can set", type: "int", min: 5, max: 30, step: 1, unit: "%" },

    // BAR
    { key: "barPosition", category: "Bar", group: "Placement", label: "Position", type: "choice", options: ["top", "bottom"] },
    { key: "barFloating", category: "Bar", group: "Placement", label: "Floating", description: "Detach the bar from the screen edge", type: "bool" },
    { key: "barHeight", category: "Bar", group: "Placement", label: "Height", type: "int", min: 36, max: 60, step: 1, unit: "px" },
    { key: "workspaceCount", category: "Bar", group: "Workspaces", label: "Workspaces", description: "Number of workspace dots", type: "int", min: 1, max: 10, step: 1, unit: "" },

    // CONTROL CENTER
    { key: "controlCenterColumns", category: "Control center", group: "Grid", label: "Columns", description: "Widgets that no longer fit are hidden until there's room again", type: "int", min: 3, max: 5, step: 1, unit: "" },
    { key: "controlCenterMaxRows", category: "Control center", group: "Grid", label: "Rows", description: "Most rows the grid can grow to", type: "int", min: 2, max: 6, step: 1, unit: "" },

    // LAUNCHER
    { key: "launcherWidth", category: "Launcher", group: "Size", label: "Width", type: "int", min: 360, max: 800, step: 10, unit: "px" },
    { key: "launcherHeight", category: "Launcher", group: "Size", label: "Height", type: "int", min: 300, max: 700, step: 10, unit: "px" },

    // AUDIO
    { key: "audioMixer", category: "Audio", group: "Apps", label: "Volume mixer", description: "Apps that play or can play sound. Quiet ones start at the volume set here", type: "mixer" },
    { key: "audioOutputs", category: "Audio", group: "Devices", label: "Output devices", description: "Pick one to set its volume, balance, profile and port", type: "devices" },
    { key: "audioInputs", category: "Audio", group: "Devices", label: "Input devices", description: "Pick one to set its volume, profile and port, or test its level", type: "devices", input: true },

    // ANIMATIONS
    { key: "animationSpeed", category: "Animations", group: "Motion", label: "Speed", description: "How quickly everything moves, higher is faster", type: "int", min: 50, max: 200, step: 10, unit: "%" },
    { key: "reduceMotion", category: "Animations", group: "Motion", label: "Reduce motion", description: "Fade instead of sliding and growing", type: "bool" },

    // DATE & TIME
    { key: "timeFormat", category: "Date & time", group: "Formats", label: "Time format", description: "For example h:mm or HH:mm", type: "format" },
    { key: "dateFormat", category: "Date & time", group: "Formats", label: "Date format", description: "Shown in the bar, for example MM/dd ddd", type: "format" },
    { key: "longDateFormat", category: "Date & time", group: "Formats", label: "Long date format", description: "Shown on the clock widget, for example dddd, MMMM d", type: "format" },

    // INPUT
    { key: "naturalScroll", category: "Input", group: "Scrolling", label: "Natural scrolling", description: "Match the compositor's touchpad setting", type: "bool" },
    { key: "shortcutControlCenter", category: "Input", group: "Shortcuts", label: "Control center", description: "Opens or closes the control center", type: "shortcut" },
    { key: "shortcutLauncher", category: "Input", group: "Shortcuts", label: "App launcher", description: "Type > in it for commands", type: "shortcut" },
    { key: "shortcutSettings", category: "Input", group: "Shortcuts", label: "Settings", description: "Opens the settings", type: "shortcut" },
    { key: "shortcutWallpaper", category: "Input", group: "Shortcuts", label: "Change wallpaper", description: "Opens the wallpaper selector", type: "shortcut" },
    { key: "shortcutDisplays", category: "Input", group: "Shortcuts", label: "Display settings", description: "Opens the display settings", type: "shortcut" }
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

        case "display":
            return typeof value === "string" ? value : undefined

        case "wallpapers": {
            if (typeof value !== "object" || value === null || Array.isArray(value)) return undefined
            const valid = {}
            for (const display in value) if (typeof value[display] === "string" && value[display] !== "") valid[display] = value[display]
            return valid
        }

        case "path":
        case "wallpaper":
            return typeof value === "string" && value.trim() !== "" ? value.trim() : undefined

        case "shortcut":
            return typeof value === "string" && shortcutPattern.test(value) ? value : undefined

        case "color":
            return typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value) ? value.toLowerCase() : undefined
    }
    return undefined
}
