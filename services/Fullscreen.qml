pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {

    // Falls back to the focused monitor for windows without an explicit screen
    function active(screen) {
        let monitor = screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
        return monitor?.activeWorkspace?.hasFullscreen ?? false
    }

    // The bar is covered in fullscreen, so its reserved space would leave a gap
    function exclusionMode(screen) {
        return active(screen) ? ExclusionMode.Ignore : ExclusionMode.Normal
    }
}
