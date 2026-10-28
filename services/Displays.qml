pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.config
import "DisplayLayout.js" as Arrange

// Every connected display, and the layouts saved for each set of them. Changes are applied right away as Hyprland
// monitor rules at runtime. Ones that can leave a display dark go back on their own unless kept. A config reload
// drops runtime rules, so the saved layout for the connected set is applied again after every one
Singleton {
    id: root

    // From hyprctl monitors all, disabled ones included
    property var monitors: []
    // The settings each display has right now, in the shape apply() takes
    readonly property var current: monitors.map(config)
    // What was last applied until Hyprland shows it, so quick changes build on each other instead of on stale values
    property var expected: null
    readonly property var shown: expected ?? current
    // On and not mirroring, so taking up room in the layout
    readonly property var arranged: inLayout(shown)
    // While mirroring, the display every other one copies
    readonly property string mirrorSource: shown.find(config => !config.disabled && config.mirror != "")?.mirror ?? ""
    // Plain values, so lists that depend on them only change when these do, not on every change to a display
    readonly property int arrangedCount: arranged.length
    readonly property int onCount: shown.filter(config => !config.disabled).length
    readonly property bool mirroring: mirrorSource != ""

    // Shown on each screen while something about displays is open, and how many such things are open
    property int identifiers: 0
    readonly property bool identifying: identifiers > 0

    // Where the bar, the control center and pop-ups go: the picked display, or the built in one, or the first
    readonly property var mainScreen: {
        const screens = Quickshell.screens
        const name = current.find(config => config.key == Settings.mainDisplay)?.name
        return screens.find(screen => screen.name == name)
            ?? screens.find(screen => /^(eDP|LVDS|DSI)/.test(screen.name))
            ?? screens[0]
            ?? null
    }
    // Which displays are connected, layouts are saved per set so a dock and a projector each get their own
    readonly property string setKey: monitors.map(key).sort().join("\n")
    readonly property bool saved: state.layouts[setKey] !== undefined

    // Set for the layout last applied by the shell, so it's only applied again when the set changes
    property string appliedKey: ""

    // While changes wait to be kept: the settings to go back to, the ones to save, and how long is left
    property var previous: null
    property var changed: null
    readonly property bool pending: previous !== null
    property int remaining: 0

    // The display that stands out among the names shown on each screen
    property string highlighted: ""

    FileView {
        id: stateFile

        path: Quickshell.statePath("displays.json")
        blockLoading: true
        // Deferred, since writing right away drops further changes made in the same tick
        onAdapterUpdated: Qt.callLater(stateFile.writeAdapter)

        adapter: JsonAdapter {
            id: state
            property var layouts: ({})
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") root.appliedKey = ""
            if (["configreloaded", "monitoradded", "monitorremoved"].includes(event.name)) settle.restart()
        }
    }

    // A display that was just plugged in is still being set up by Hyprland, changing it right away makes it flicker.
    // Several events come in a row, so this waits for the last one
    Timer {
        id: settle
        interval: Settings.displaySettleDelay
        onTriggered: root.refresh()
    }

    Process {
        id: reader

        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).sort((a, b) => a.name.localeCompare(b.name))
                } catch (error) {
                    return
                }
                // A read from before the change landed would bring back the old values for a moment
                if (!refreshLater.running) root.expected = null
                root.restore()
            }
        }
    }

    Component.onCompleted: refresh()

    // Hyprland changes modes after hyprctl returns, so read them back a moment later
    Timer {
        id: refreshLater
        interval: 500
        onTriggered: root.refresh()
    }

    function refresh() {
        reader.running = true
    }

    // Puts the saved layout for this set back, when there is one and it isn't what Hyprland shows already.
    // shortcut: rules applied for another set stay until the next config reload, since reloading here would modeset
    // a display mid hotplug. Upgrade once Hyprland can drop a single monitor rule
    function restore() {
        if (pending || setKey == appliedKey) return
        appliedKey = setKey
        const layout = state.layouts[setKey]
        if (!layout) return
        const configs = current.map(config => layout[config.key] ? Object.assign({}, config, layout[config.key]) : config)
        if (configs.some((config, i) => rule(config) != rule(current[i]))) run(configs)
    }

    // ALL CHANGES

    // Applies the settings of every display. Risky ones wait to be kept, the rest are saved right away,
    // or with the risky ones when those are kept
    function apply(configs, risky) {
        if (risky) {
            if (!pending) previous = current
            remaining = Settings.displayConfirmTimeout
            countdown.restart()
        }
        changed = configs
        appliedKey = setKey
        run(configs)
        if (!pending) save(configs)
    }

    function keep() {
        if (!pending) return
        countdown.stop()
        save(changed)
        previous = null
    }

    // Only what can change is saved, the rest comes from the display each time
    function save(configs) {
        const layouts = Object.assign({}, state.layouts)
        layouts[setKey] = configs.reduce((layout, config) => {
            layout[config.key] = {
                width: config.width, height: config.height, refresh: config.refresh, x: config.x, y: config.y,
                scale: config.scale, transform: config.transform, disabled: config.disabled, mirror: config.mirror
            }
            return layout
        }, {})
        state.layouts = layouts
    }

    function revert() {
        if (!pending) return
        countdown.stop()
        run(previous)
        previous = null
    }

    // Forgets the layout for this set and lets the Hyprland config decide again
    function useConfig() {
        if (pending) revert()
        const layouts = Object.assign({}, state.layouts)
        delete layouts[setKey]
        state.layouts = layouts
        appliedKey = ""
        Quickshell.execDetached(["hyprctl", "reload"])
    }

    Timer {
        id: countdown

        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining -= interval
            if (root.remaining <= 0) root.revert()
        }
    }

    // One hyprctl call, so every display changes together. Mirrors follow in a second one: Hyprland won't mirror
    // onto a display that stops being a mirror itself in the same call, as when the source is swapped.
    // Displays that only turn into mirrors then still take up room in between, so anything that would land on
    // them waits to the right of the layout and moves to its spot along with the mirrors
    function run(configs) {
        // What was last sent, since Hyprland may not show it yet after a quick change
        const before = shown
        expected = configs
        const leaving = before.filter(config => !config.disabled && config.mirror == "" && configs.find(other => other.key == config.key)?.mirror)
            .map(config => rect(config))
        const first = configs.filter(config => config.mirror == "")
        const blocked = first.filter(config => !config.disabled && leaving.some(r => Arrange.overlaps(rect(config), r)))
        let spot = Math.max(0, ...leaving.concat(inLayout(first).map(config => rect(config))).map(r => r.x + r.w))
        const waiting = first.map(config => {
            if (!blocked.includes(config)) return config
            const placed = Object.assign({}, config, { x: spot, y: 0 })
            spot += rect(config).w
            return placed
        })

        Quickshell.execDetached(["hyprctl", "eval", waiting.map(rule).join("\n")])
        mirrorLater.rules = configs.filter(config => config.mirror != "").concat(blocked).map(rule)
        if (mirrorLater.rules.length) mirrorLater.restart()
        refreshLater.restart()
    }

    Timer {
        id: mirrorLater

        property var rules: []

        interval: Settings.displayMirrorDelay
        onTriggered: {
            Quickshell.execDetached(["hyprctl", "eval", rules.join("\n")])
            refreshLater.restart()
        }
    }

    // EDITING

    // Each takes a display's key and applies the change on top of what's shown

    // Moving can't leave anything dark, so it's saved right away
    function moveTo(key, spot) {
        const config = shown.find(config => config.key == key)
        if (!config || config.x == spot.x && config.y == spot.y) return
        apply(normalized(shown.map(config => config.key == key ? Object.assign({}, config, { x: spot.x, y: spot.y }) : config)), false)
    }

    // One that changes size moves the displays after it along with its edges
    function change(key, patch) {
        const config = shown.find(config => config.key == key)
        if (!config) return
        const updated = Object.assign({}, config, patch)
        let configs = shown.map(other => other == config ? updated : other)
        const index = arranged.indexOf(config)
        const after = rect(updated)
        if (index >= 0 && inLayout([updated]).length) {
            const rects = Arrange.resize(arranged.map(other => rect(other)), index, after.w, after.h)
            configs = configs.map(other => {
                const i = arranged.indexOf(other == updated ? config : other)
                return i < 0 ? other : Object.assign({}, other, { x: rects[i].x, y: rects[i].y })
            })
        }
        apply(normalized(configs), true)
    }

    // Joins in mirroring when that's on, otherwise goes next to the others. The last one in use stays on
    function setEnabled(key, on) {
        if (on) change(key, Object.assign({ disabled: false, mirror: mirrorSource }, mirrorSource == "" ? freeSpot(shown, key) : {}))
        else if (!isLastOn(key)) change(key, { disabled: true })
    }

    function isLastOn(key) {
        return arranged.length == 1 && arranged[0].key == key
    }

    // Where each display sat before mirroring started, so extending again puts them back
    property var extendedSpots: ({})

    // Every display that's on copies the source. Without one they all go back to extending: where they sat
    // before, or when that no longer fits, one at a time to the right of the rest
    function setMirrorSource(key) {
        let configs = shown
        if (key == "") {
            const back = configs.map(config => config.mirror != "" || extendedSpots[config.key] ? Object.assign({}, config, { mirror: "" }, extendedSpots[config.key] ?? {}) : config)
            const rects = inLayout(back).map(config => rect(config))
            const fits = back.every(config => config.disabled || extendedSpots[config.key])
                && !rects.some((r, i) => rects.some((other, j) => i < j && Arrange.overlaps(r, other)))
            if (fits) configs = normalized(back)
            else for (const copy of configs.filter(config => config.mirror != ""))
                configs = normalized(configs.map(config => config.key == copy.key ? Object.assign({}, config, { mirror: "" }, freeSpot(configs, config.key)) : config))
        } else {
            if (!mirroring) extendedSpots = arranged.reduce((spots, config) => {
                spots[config.key] = { x: config.x, y: config.y }
                return spots
            }, {})
            configs = normalized(configs.map(config => config.disabled ? config : Object.assign({}, config, { mirror: config.key == key ? "" : key })))
        }
        apply(configs, true)
    }

    // Built in first, since it's what a laptop user looks at
    function defaultSource() {
        const on = shown.filter(config => !config.disabled)
        return (on.find(config => config.builtin) ?? on[0])?.key ?? ""
    }

    // Keeps the refresh rate when the new resolution has it, otherwise takes the fastest. A scale that wouldn't
    // divide the new size evenly moves to the closest one that does
    function setResolution(key, value) {
        const config = shown.find(config => config.key == key)
        const [width, height] = value.split("x").map(Number)
        const rates = config.modes.filter(mode => mode.width == width && mode.height == height).map(mode => mode.refresh)
        const refresh = rates.includes(config.refresh) ? config.refresh : Math.max(...rates)
        const valid = scales(Object.assign({}, config, { width: width, height: height, scale: 0 }))
        const scale = valid.reduce((best, s) => Math.abs(s - config.scale) < Math.abs(best - config.scale) ? s : best, valid[0] ?? 1)
        change(key, { width: width, height: height, refresh: refresh, scale: scale })
    }

    function inLayout(configs) {
        return configs.filter(config => !config.disabled && config.mirror == "")
    }

    // The rest of the layout, for snapping a display against
    function others(key) {
        return arranged.filter(config => config.key != key).map(config => rect(config))
    }

    // To the right of the rest of the layout
    function freeSpot(configs, key) {
        const rects = inLayout(configs).filter(config => config.key != key).map(config => rect(config))
        return rects.length == 0 ? { x: 0, y: 0 } : { x: Math.max(...rects.map(r => r.x + r.w)), y: Math.min(...rects.map(r => r.y)) }
    }

    // Shifted so the layout starts at 0, 0 like Hyprland's own
    function normalized(configs) {
        const placed = inLayout(configs)
        const rects = Arrange.normalize(placed.map(config => rect(config)))
        return configs.map(config => {
            const i = placed.indexOf(config)
            return i < 0 ? config : Object.assign({}, config, { x: rects[i].x, y: rects[i].y })
        })
    }

    // ONE DISPLAY

    // Rules match by description, so a display keeps its settings on any port. Identical twins without a serial
    // can't be told apart that way, so those go by port
    function key(monitor) {
        const twins = monitors.filter(other => other.description == monitor.description).length
        return monitor.description != "" && twins == 1 ? "desc:" + monitor.description : monitor.name
    }

    function config(monitor) {
        const modes = monitor.availableModes.map(mode => {
            const parts = mode.match(/^(\d+)x(\d+)@([\d.]+)Hz$/)
            return { width: Number(parts[1]), height: Number(parts[2]), refresh: Number(parts[3]) }
        })
        // Disabled displays may have no size, they come back at their preferred mode
        const preferred = modes[0] ?? { width: monitor.width, height: monitor.height, refresh: monitor.refreshRate }
        const mirrored = monitors.find(other => String(other.id) == monitor.mirrorOf || other.name == monitor.mirrorOf)

        return {
            key: key(monitor),
            name: monitor.name,
            label: label(monitor),
            builtin: /^(eDP|LVDS|DSI)/.test(monitor.name),
            modes: modes,
            width: monitor.width || preferred.width,
            height: monitor.height || preferred.height,
            // Two decimals, like the modes list
            refresh: Math.round((monitor.refreshRate || preferred.refresh) * 100) / 100,
            x: monitor.x,
            y: monitor.y,
            // On the 1/120 steps Hyprland uses, so it matches the offered scales exactly
            scale: Math.round((monitor.scale || 1) * 120) / 120,
            transform: monitor.transform,
            disabled: monitor.disabled,
            mirror: mirrored ? key(mirrored) : "",
            // Kept as they are, so applying a layout doesn't drop HDR, 10 bit or adaptive sync set in the config
            extra: Object.assign({
                cm: monitor.colorManagementPreset ?? "srgb",
                sdrbrightness: monitor.sdrBrightness ?? 1,
                sdrsaturation: monitor.sdrSaturation ?? 1
            }, monitor.currentFormat?.includes("2101010") ? { bitdepth: 10 } : {}, monitor.vrr ? { vrr: 1 } : {})
        }
    }

    // Hyprland merges a rule into the last one for the same display, so a field left out keeps its old value.
    // Mirror and disabled are always written, or turning either off would never stick
    function rule(config) {
        const fields = { output: config.key, disabled: config.disabled }
        if (!config.disabled) {
            const mirror = monitors.find(monitor => key(monitor) == config.mirror)
            Object.assign(fields, {
                mode: config.width + "x" + config.height + "@" + config.refresh,
                position: mirror ? "auto" : config.x + "x" + config.y,
                scale: config.scale,
                transform: config.transform,
                mirror: mirror?.name ?? ""
            }, config.extra)
        }
        return "hl.monitor({ " + Object.keys(fields).map(field => field + " = " + JSON.stringify(fields[field])).join(", ") + " })"
    }

    // The size a display takes up in the layout, after scale and rotation
    function rect(config) {
        const turned = config.transform % 2 == 1
        return {
            x: config.x,
            y: config.y,
            w: Math.round((turned ? config.height : config.width) / config.scale),
            h: Math.round((turned ? config.width : config.height) / config.scale)
        }
    }

    // A name people know the display by, like AOC 24G2W1G3. Laptop panels report a part number, so they're just built in
    function label(monitor) {
        if (/^(eDP|LVDS|DSI)/.test(monitor.name)) return "Built-in display"
        const model = /^(0x)?[0-9a-f]*$/i.test(monitor.model) ? "" : monitor.model.replace(/[^A-Za-z0-9)]+$/, "")
        // The brand's first word, unless the model already starts with it
        const brand = (monitor.make ?? "").split(" ")[0]
        const name = !model ? monitor.make || monitor.name
            : model.toLowerCase().startsWith(brand.toLowerCase()) ? model : brand + " " + model
        return monitors.filter(other => other != monitor && other.description == monitor.description).length > 0
            ? name + " (" + monitor.name + ")" : name
    }

    function scales(config) {
        const turned = config.transform % 2 == 1
        return Arrange.scales(config.width, config.height, Settings.displayMinLogicalHeight * (turned ? config.height / config.width : 1), config.scale)
    }
}
