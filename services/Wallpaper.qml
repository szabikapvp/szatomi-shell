pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

// The current wallpaper, and the pywal palette that follows it while autoColors is on
Singleton {
    id: root

    // The folder setting with ~ expanded
    readonly property string folder: Settings.wallpaperFolder.replace(/^~(?=\/|$)/, Quickshell.env("HOME"))
    // Picked in the selector, otherwise whatever pywal last set
    readonly property string current: Settings.wallpaper || (Colors.pywal?.wallpaper ?? "")
    readonly property bool generating: wal.running

    // The wallpaper wal last started on, to catch up when the wallpaper changes mid run
    property string generatedFor: ""

    function set(path) {
        Settings.set("wallpaper", path)
        if (Settings.autoColors) generate()
    }

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
