pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

// The wallpaper of every display, or of single ones, and the pywal palette that follows the main display's
// while autoColors is on
Singleton {
    id: root

    // The folder setting with ~ expanded
    readonly property string folder: Settings.wallpaperFolder.replace(/^~(?=\/|$)/, Quickshell.env("HOME"))
    // For every display: picked in the selector, otherwise whatever pywal last set
    readonly property string all: Settings.wallpaper || (Colors.pywal?.wallpaper ?? "")
    // The main display's, which the colors come from
    readonly property string current: of(Displays.current.find(config => config.name == Displays.mainScreen?.name)?.key ?? "")
    readonly property bool generating: wal.running

    // Key of the display the selector sets the wallpaper for, empty for all of them
    property string target: ""
    readonly property string selected: of(target)

    // The wallpaper wal last started on, to catch up when the wallpaper changes mid run
    property string generatedFor: ""

    // The wallpaper of a display by its key, its own if it has one
    function of(key) {
        return (key != "" && Settings.wallpapers[key]) || all
    }

    function forScreen(name) {
        return of(Displays.current.find(config => config.name == name)?.key ?? "")
    }

    // Setting it for all displays drops the ones set for single displays
    function set(path) {
        if (target == "") {
            Settings.set("wallpaper", path)
            Settings.reset("wallpapers")
        } else {
            const wallpapers = Object.assign({}, Settings.wallpapers)
            wallpapers[target] = path
            Settings.set("wallpapers", wallpapers)
        }
    }

    // Follows the main display's wallpaper, however it changed, unless pywal already has its palette
    onCurrentChanged: if (Settings.autoColors && Colors.pywal?.wallpaper != current) generate()

    function generate() {
        if (wal.running || current == "") return
        generatedFor = current
        // -n leaves the wallpaper to the shell, the terminals and the rest still get the new colors
        wal.exec(["wal", "-i", current, "-n", "-q"])
    }

    Process {
        id: wal

        onExited: if (Settings.autoColors && root.generatedFor != root.current) root.generate()
    }

    // Turning it on generates a palette for the current wallpaper, unless pywal already has one
    Connections {
        target: Settings

        function onAutoColorsChanged() {
            if (Settings.autoColors && Colors.pywal?.wallpaper != root.current) root.generate()
        }
    }
}
