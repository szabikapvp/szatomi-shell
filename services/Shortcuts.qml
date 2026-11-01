pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.config

// The shell's keyboard shortcuts. They're bound in Hyprland at runtime, so they can change without touching
// its config, and each one fires a global shortcut Quickshell listens to. A config reload drops runtime binds,
// so they're bound again after every one. Combos Hyprland's own config already uses are left unbound
Singleton {
    id: root

    // Setting key of each shortcut, by the action the control center runs
    readonly property var actions: ({
        controlcenter: "shortcutControlCenter",
        launcher: "shortcutLauncher",
        settings: "shortcutSettings",
        wallpaper: "shortcutWallpaper",
        displays: "shortcutDisplays"
    })

    signal triggered(string action)

    // Binds from Hyprland's config as { modmask, key, keycode }, read with hyprctl. Ours are left out
    property var configBinds: []
    property bool configRead: false
    // Combos bound right now, so a change can unbind the old one
    property var bound: []

    readonly property var wanted: Object.keys(actions)
        .map(action => ({ action: action, combo: Settings[actions[action]] }))
        .filter(shortcut => !usedByConfig(shortcut.combo))
    onWantedChanged: if (configRead) Qt.callLater(apply)

    // Setting key of the shortcut being recorded, empty otherwise
    property string recording: ""
    // Why the last recorded combo wasn't taken, shown on that shortcut's row
    property string message: ""
    property string messageKey: ""
    // A modifier pressed on its own, which becomes the shortcut if it's let go without another key
    property int heldModifier: 0

    Variants {
        model: Object.keys(root.actions)

        // A Super tap is a release bind, which Hyprland skips when another key went down meanwhile, so Super + R
        // doesn't also fire it. It only sends a release, which counts when no press came before it
        GlobalShortcut {
            required property string modelData
            property bool down: false

            appid: "quickshell"
            name: modelData
            onPressed: {
                down = true
                root.triggered(modelData)
            }
            onReleased: {
                if (!down) root.triggered(modelData)
                down = false
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.bound = []
                root.readBinds()
            }
            // Escape leaves the recording submap from Hyprland's side, which also works if the shell is stuck
            else if (event.name == "submap" && event.data == "" && root.recording != "") root.recording = ""
        }
    }

    Process {
        id: bindsReader

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.configBinds = JSON.parse(text)
                        .filter(bind => bind.submap == "" && !bind.description.startsWith("quickshell:"))
                        .map(bind => ({ modmask: bind.modmask, key: bind.key.toLowerCase(), keycode: bind.keycode }))
                } catch (error) {
                    return
                }
                root.configRead = true
                root.apply()
            }
        }
    }

    Component.onCompleted: readBinds()

    function readBinds() {
        bindsReader.running = true
    }

    // One hyprctl call, so the unbinds land before the binds. Wanted combos are unbound too, since a restarted shell
    // doesn't know what the last one bound, and binding again would fire the shortcut twice
    function apply() {
        const combos = [...new Set(bound.concat(wanted.map(shortcut => shortcut.combo)))]
        const lua = combos.map(combo => `hl.unbind(${JSON.stringify(combo)})`)
            .concat(wanted.map(shortcut => `hl.bind(${JSON.stringify(shortcut.combo)}, hl.dsp.global("quickshell:${shortcut.action}"), { description = "quickshell:${shortcut.action}"${isTap(shortcut.combo) ? ", release = true" : ""} })`))
            // Nothing but Escape is bound while recording, so the keys reach the shell instead of running binds
            .concat([`hl.define_submap("quickshell-record", function() hl.unbind("ESCAPE") hl.bind("ESCAPE", hl.dsp.submap("reset")) end)`])
        Quickshell.execDetached(["hyprctl", "eval", lua.join("\n")])
        bound = wanted.map(shortcut => shortcut.combo)
    }

    // RECORDING

    Timer {
        id: recordTimeout
        interval: Settings.shortcutRecordTimeout
        onTriggered: root.stopRecording()
    }

    function startRecording(key) {
        recording = key
        message = ""
        heldModifier = 0
        readBinds()
        recordTimeout.restart()
        Quickshell.execDetached(["hyprctl", "eval", `hl.dispatch(hl.dsp.submap("quickshell-record"))`])
    }

    function stopRecording() {
        if (recording == "") return
        recording = ""
        recordTimeout.stop()
        Quickshell.execDetached(["hyprctl", "eval", `hl.dispatch(hl.dsp.submap("reset"))`])
    }

    // Feed every key press and release while recording. Saves the first usable combo, or says what's wrong with it
    function press(event) {
        recordTimeout.restart()
        const modifier = modifierName(event.key)
        if (modifier) {
            heldModifier = event.key
            return
        }
        heldModifier = 0
        take(modifiersOf(event.modifiers).concat([keyName(event)]).join(" + "))
    }

    function release(event) {
        if (event.key != heldModifier) return
        heldModifier = 0
        // Only Super works alone, the others are pressed while typing all the time
        if (modifierName(event.key) == "SUPER") take("SUPER + SUPER_L")
        else fail(display(modifierName(event.key)) + " alone can't be a shortcut, hold it and press another key")
    }

    function take(combo) {
        const problem = check(combo, recording)
        if (problem != "") {
            fail(problem)
            return
        }
        Settings.set(recording, combo)
        message = ""
        stopRecording()
    }

    function fail(text) {
        message = text
        messageKey = recording
    }

    // Empty when the combo can be used for the shortcut stored under key
    function check(combo, key) {
        const parts = combo.split(" + ")
        const name = parts[parts.length - 1]
        const bare = parts.length == 1

        if (name == "") return "That key can't be used in a shortcut"
        if (bare && !/^F[0-9]+$|^Print$/.test(name)) return "Add Super, Ctrl or Alt, so typing " + display(name) + " still works"
        if (parts.length == 2 && parts[0] == "SHIFT") return "Shift alone would get in the way of typing, add Super, Ctrl or Alt"

        const other = Object.values(actions).find(other => other != key && Settings[other] == combo)
        if (other) return format(combo) + " already opens " + Settings.schema.entries.find(entry => entry.key == other).label.toLowerCase()
        if (usedByConfig(combo)) return format(combo) + " is already used in your Hyprland config"
        return ""
    }

    function usedByConfig(combo) {
        const parts = combo.split(" + ")
        const name = parts.pop().toLowerCase()
        const modmask = parts.reduce((mask, modifier) => mask | ({ SHIFT: 1, CTRL: 4, ALT: 8, SUPER: 64 })[modifier], 0)
        return configBinds.some(bind => bind.modmask == modmask && (bind.key == name || name == "code:" + bind.keycode))
    }

    // NAMES

    function modifierName(key) {
        switch (key) {
            case Qt.Key_Super_L:
            case Qt.Key_Super_R:
            case Qt.Key_Meta: return "SUPER"
            case Qt.Key_Control: return "CTRL"
            case Qt.Key_Alt: return "ALT"
            case Qt.Key_Shift: return "SHIFT"
        }
        return ""
    }

    function modifiersOf(modifiers) {
        return [[Qt.MetaModifier, "SUPER"], [Qt.ControlModifier, "CTRL"], [Qt.AltModifier, "ALT"], [Qt.ShiftModifier, "SHIFT"]]
            .filter(pair => modifiers & pair[0]).map(pair => pair[1])
    }

    // The key's name for Hyprland. Keys whose symbol changes with Shift, like 1 turning into !, go by keycode instead
    function keyName(event) {
        const key = event.key
        if (key >= Qt.Key_A && key <= Qt.Key_Z || key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key)
        if (key >= Qt.Key_F1 && key <= Qt.Key_F24) return "F" + (key - Qt.Key_F1 + 1)

        const named = {
            [Qt.Key_Return]: "RETURN", [Qt.Key_Enter]: "KP_Enter", [Qt.Key_Space]: "SPACE", [Qt.Key_Tab]: "TAB",
            [Qt.Key_Backspace]: "BACKSPACE", [Qt.Key_Delete]: "DELETE", [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
            [Qt.Key_Print]: "Print", [Qt.Key_Comma]: "comma", [Qt.Key_Period]: "period", [Qt.Key_Slash]: "slash",
            [Qt.Key_Minus]: "minus", [Qt.Key_Equal]: "equal", [Qt.Key_Semicolon]: "semicolon",
            [Qt.Key_Apostrophe]: "apostrophe", [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright",
            [Qt.Key_Backslash]: "backslash", [Qt.Key_QuoteLeft]: "grave"
        }
        if (named[key]) return named[key]
        return event.nativeScanCode > 0 ? "code:" + event.nativeScanCode : ""
    }

    function isTap(combo) {
        return /^SUPER \+ SUPER_[LR]$/.test(combo)
    }

    // Each part of a combo as it's shown on a key cap. A Super tap is just Super
    function keys(combo) {
        return isTap(combo) ? [display("SUPER")] : combo.split(" + ").map(display)
    }

    function format(combo) {
        return keys(combo).join(" + ")
    }

    function display(name) {
        const names = {
            SUPER: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift", RETURN: "Enter", KP_Enter: "Enter", SPACE: "Space",
            TAB: "Tab", BACKSPACE: "Backspace", DELETE: "Delete", Page_Up: "Page Up", Page_Down: "Page Down",
            Left: "←", Right: "→", Up: "↑", Down: "↓", comma: ",", period: ".", slash: "/", minus: "-", equal: "=",
            semicolon: ";", apostrophe: "'", bracketleft: "[", bracketright: "]", backslash: "\\", grave: "`"
        }
        if (names[name]) return names[name]
        if (name.startsWith("code:")) return "Key " + name.slice(5)
        return name.length == 1 ? name.toUpperCase() : name
    }
}
