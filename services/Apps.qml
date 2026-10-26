pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

// Installed apps for the launcher, matched and ranked like wofi's drun:
// any app whose text contains the query, most launched first, then by name.
// The launcher's commands are ranked the same way, counted under their keyword with a > in front
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

    readonly property var apps: byUse(DesktopEntries.applications.values.filter(entry => !entry.noDisplay), entry => entry.id)

    function search(query) {
        return filter(apps, query, entry => [entry.name, entry.genericName, entry.comment, entry.id, ...entry.keywords])
    }

    // Most launched first, then by name
    function byUse(items, idOf) {
        return items.slice().sort((a, b) => (usage.launches[idOf(b)] ?? 0) - (usage.launches[idOf(a)] ?? 0) || a.name.localeCompare(b.name))
    }

    // Items whose texts contain the query, all of them for an empty one
    function filter(items, query, textsOf) {
        const text = query.trim().toLowerCase()
        if (text == "") return items
        return items.filter(item => textsOf(item).join(" ").toLowerCase().includes(text))
    }

    function count(id) {
        const launches = Object.assign({}, usage.launches)
        launches[id] = (launches[id] ?? 0) + 1
        usage.launches = launches
    }

    function launch(entry) {
        // execute() ignores the terminal flag, so terminal apps go through the configured terminal
        if (entry.runInTerminal) Quickshell.execDetached({ command: Settings.launcherTerminal.concat(entry.command), workingDirectory: entry.workingDirectory })
        else entry.execute()
        count(entry.id)
    }
}
