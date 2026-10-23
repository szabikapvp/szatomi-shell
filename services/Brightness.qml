pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Singleton {

    property int level: 0
    property int pendingLevel: -1

    readonly property string icon: {
        if (level <= 30) return "brightness-1"
        if (level <= 60) return "brightness-2"
        return "brightness-3"
    }
    
    Process {
        id: brightnessWatcher
        
        Component.onCompleted: running = true

        command: [
            "sh", "-c", 
            "brightnessctl -m | cut -d, -f4 | tr -d '%'; inotifywait -m -q -e modify /sys/class/backlight/*/brightness | while read -r _; do brightnessctl -m | cut -d, -f4 | tr -d '%'; done"
        ]
        
        stdout: SplitParser {
            onRead: msg => {
                const val = parseInt(msg);
                
                if (!isNaN(val)) {
                    level = val;
                }
            }
        }
    }

    function getLevel() {
        return level
    }

    // Slider drags fire faster than brightnessctl runs, so only the latest value waits for the next run
    function setLevel(value) {
        pendingLevel = Math.max(Settings.brightnessMin, Math.min(100, Math.round(value)))
        if (!setter.running) applyPending()
    }

    function applyPending() {
        if (pendingLevel < 0) return
        setter.exec(["brightnessctl", "set", pendingLevel + "%"])
        pendingLevel = -1
    }

    Process {
        id: setter
        onExited: applyPending()
    }
}