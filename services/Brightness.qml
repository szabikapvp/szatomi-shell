pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {

    property int level: 0
    
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
}