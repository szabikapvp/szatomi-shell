pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

// Installed apps for the launcher, matched and ranked like wofi's drun:
// any app whose text contains the query, most launched first, then by name
Singleton {
    id: root

    // Launch counts by desktop entry id, kept across restarts
    FileView {
        id: file

        path: Quickshell.statePath("apps.json")
        // Deferred, since writing right away drops further changes made in the same tick
        onAdapterUpdated: Qt.callLater(file.writeAdapter)

        adapter: JsonAdapter {
            id: usage
            property var launches: ({})
        }
    }

    readonly property var apps: DesktopEntries.applications.values
        .filter(entry => !entry.noDisplay)
        .sort((a, b) => (usage.launches[b.id] ?? 0) - (usage.launches[a.id] ?? 0) || a.name.localeCompare(b.name))

    function search(query) {
        const text = query.trim().toLowerCase()
        if (text == "") return apps
        return apps.filter(entry => [entry.name, entry.genericName, entry.comment, entry.id, ...entry.keywords]
            .join(" ").toLowerCase().includes(text))
    }

    function launch(entry) {
        // execute() ignores the terminal flag, so terminal apps go through the configured terminal
        if (entry.runInTerminal) Quickshell.execDetached({ command: Settings.launcherTerminal.concat(entry.command), workingDirectory: entry.workingDirectory })
        else entry.execute()

        const launches = Object.assign({}, usage.launches)
        launches[entry.id] = (launches[entry.id] ?? 0) + 1
        usage.launches = launches
    }
}
