pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int usage: 0
    property real usedGb: 0
    property real totalGb: 0

    // Recent usage, oldest first, one per update
    property var history: []
    readonly property int historyLength: 60

    Process {
        id: proc
        command: ["sh", "-c", "free -b | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                const parts = data.trim().split(/\s+/)
                const total = parseInt(parts[1]) || 1
                const used = parseInt(parts[2]) || 0

                root.usage = Math.round(100 * used / total)
                root.usedGb = used / 1e9
                root.totalGb = total / 1e9
                root.history = root.history.concat([root.usage]).slice(-root.historyLength)
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    function getUsage() {
        return usage
    }
}
