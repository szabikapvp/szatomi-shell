pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../components/"

Singleton {
    id: root

    // Bound so their volumes and properties are known. Unbound nodes aren't ready and have no properties yet
    PwObjectTracker {
        objects: root.audioNodes
    }

    readonly property var audioNodes: Pipewire.nodes.values.filter(node => node.audio)
    readonly property var outputs: audioNodes.filter(node => node.isSink && !node.isStream)
    readonly property var inputs: audioNodes.filter(node => !node.isSink && !node.isStream)
    // Playback only, recording streams are left out
    readonly property var streams: audioNodes.filter(node => node.type == PwNodeType.AudioOutStream)

    // Binaries of the apps connected to the sound server, which can start playing any time.
    // Pipewire only lists these through pw-dump, so they're read on refreshClients()
    property var clients: []

    // Every app that's playing or connected, with its streams. Connected apps without a desktop entry
    // are background tools, those only show while they play
    readonly property var apps: {
        const apps = {}
        const add = key => {
            if (!apps[key]) apps[key] = { key: key, entry: findEntry(key), streams: [] }
            return apps[key]
        }

        for (const key of clients) add(key)
        for (const stream of streams) {
            const key = appKey(stream)
            if (key != "") add(key).streams.push(stream)
        }

        return Object.values(apps)
            .filter(app => app.streams.length > 0 || app.entry)
            .sort((a, b) => b.streams.length - a.streams.length || appName(a).localeCompare(appName(b)))
    }

    Process {
        id: clientDump

        command: ["pw-dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found
                try {
                    found = JSON.parse(text)
                        .filter(object => object.type == "PipeWire:Interface:Client" && object.info?.props?.["client.api"] == "pipewire-pulse")
                        .map(object => object.info.props["application.process.binary"] ?? "")
                        .filter((key, i, keys) => key != "" && keys.indexOf(key) == i)
                        .sort()
                } catch (error) {
                    return
                }
                // A new list would rebuild every app's row, even mid drag
                if (JSON.stringify(found) != JSON.stringify(root.clients)) root.clients = found
            }
        }
    }

    function refreshClients() {
        clientDump.running = true
    }

    // Each app's last volume, kept across restarts so apps that aren't playing can be set too
    FileView {
        id: appFile

        path: Quickshell.statePath("audio.json")
        // Drags change it many times a second
        onAdapterUpdated: saveLater.restart()

        adapter: JsonAdapter {
            id: appState
            property var volumes: ({})
        }
    }

    Timer {
        id: saveLater
        interval: 1000
        onTriggered: appFile.writeAdapter()
    }

    // A new stream gets the volume its app was given while quiet. After that, whatever it changes to is remembered
    Variants {
        model: root.streams

        QtObject {
            required property PwNode modelData

            // The node goes null just before its stream is dropped, so the app is fixed once known
            property string key
            readonly property bool ready: (modelData?.ready ?? false) && root.appKey(modelData) != ""
            property bool restored: false
            readonly property real volume: modelData?.audio.volume ?? 0
            readonly property bool muted: modelData?.audio.muted ?? false

            onReadyChanged: restore()
            Component.onCompleted: restore()
            onVolumeChanged: if (restored && modelData?.ready) root.remember(key, { volume: volume })
            onMutedChanged: if (restored && modelData?.ready) root.remember(key, { muted: muted })

            function restore() {
                if (!ready || restored) return
                key = root.appKey(modelData)
                const saved = appState.volumes[key]
                if (saved) {
                    root.setVolume(modelData, saved.volume)
                    modelData.audio.muted = saved.muted
                } else root.remember(key, { volume: volume, muted: muted })
                restored = true
            }
        }
    }

    property bool isMuted: Pipewire.defaultAudioSink?.audio.muted ?? false
    readonly property int reportedLevel: Pipewire.defaultAudioSink?.audio.volume != null
        ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0

    // Touchpads and drags ask for changes far faster than Pipewire applies them, and sending every one
    // queues them up so the volume trails behind. So the latest request is shown right away
    // and sent at most once per writeInterval
    property real targetLevel: -1
    property bool writePending: false
    readonly property int writeInterval: 50

    readonly property int level: targetLevel >= 0 ? Math.round(targetLevel) : reportedLevel

    readonly property string icon: {
        if (isMuted) return "volume-mute"
        if (level < 20) return "volume-0"
        if (level < 50) return "volume-1"
        return "volume-2"
    }

    function getLevel() {
        return level
    }

    function adjust(delta) {
        setLevel((targetLevel >= 0 ? targetLevel : reportedLevel) + delta)
    }

    function setLevel(value) {
        targetLevel = Math.max(0, Math.min(100, value))
        targetReset.restart()

        if (writeThrottle.running) {
            writePending = true
        } else {
            write()
            writeThrottle.start()
        }
    }

    function write() {
        if (Pipewire.defaultAudioSink?.audio) setVolume(Pipewire.defaultAudioSink, targetLevel / 100)
    }

    // Sets a node's volume, or one channel's with channel. The whole node scales every channel alike, so the balance stays
    function setVolume(node, volume, channel = -1) {
        const volumes = Array.from(node.audio.volumes)
        if (channel >= 0) volumes[channel] = volume
        else {
            const current = node.audio.volume
            volumes.forEach((value, i) => volumes[i] = current > 0 ? value * volume / current : volume)
        }
        node.audio.volumes = volumes
    }

    function isDefault(node) {
        return node != null && node == (node.isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource)
    }

    function setDefault(node) {
        if (node.isSink) Pipewire.preferredDefaultAudioSink = node
        else Pipewire.preferredDefaultAudioSource = node
    }

    // Profiles and ports belong to the device behind a node, which only pw-cli can change
    function setProfile(deviceId, index) {
        Quickshell.execDetached(["pw-cli", "set-param", deviceId, "Profile", `{ index: ${index}, save: true }`])
    }

    function setRoute(deviceId, index, device) {
        Quickshell.execDetached(["pw-cli", "set-param", deviceId, "Route", `{ index: ${index}, device: ${device}, save: true }`])
    }

    // Streams are grouped by the program behind them
    function appKey(stream) {
        return stream.properties["application.process.binary"] || stream.properties["application.name"] || ""
    }

    // Binaries don't always match their desktop entry, like brave for brave-origin
    function findEntry(key) {
        return DesktopEntries.heuristicLookup(key)
            ?? DesktopEntries.applications.values.find(entry => entry.id.toLowerCase().startsWith(key.toLowerCase()))
            ?? null
    }

    function appName(app) {
        return app.entry?.name || app.streams[0]?.properties["application.name"] || app.key
    }

    function appIcon(app) {
        const name = app.entry?.icon || app.streams[0]?.properties["application.icon-name"] || app.key
        return Quickshell.iconPath(name, true)
    }

    // What's playing, empty while quiet
    function appMedia(app) {
        return app.streams.map(stream => stream.properties["media.name"]).filter(name => name).join(", ")
    }

    function appVolume(app) {
        return app.streams[0]?.audio.volume ?? appState.volumes[app.key]?.volume ?? 1
    }

    function appMuted(app) {
        return app.streams.length > 0 ? app.streams.every(stream => stream.audio.muted) : appState.volumes[app.key]?.muted ?? false
    }

    function setAppVolume(app, volume) {
        app.streams.forEach(stream => setVolume(stream, volume))
        remember(app.key, { volume: volume })
    }

    function setAppMuted(app, muted) {
        app.streams.forEach(stream => stream.audio.muted = muted)
        remember(app.key, { muted: muted })
    }

    function remember(key, change) {
        if (key == "") return
        const volumes = Object.assign({}, appState.volumes)
        volumes[key] = Object.assign({ volume: 1, muted: false }, volumes[key], change)
        appState.volumes = volumes
    }

    function nodeName(node) {
        return node.description || node.nickname || node.name
    }

    function nodeIcon(node) {
        const formFactor = node.properties["device.form-factor"] ?? ""
        if (formFactor == "headphone") return "headphones"
        if (formFactor == "headset" || formFactor == "hands-free") return "headset"
        if (!node.isSink) return "mic"
        if (node.name.includes("hdmi")) return "computer"
        return "speaker"
    }

    readonly property bool micMuted: Pipewire.defaultAudioSource?.audio.muted ?? false

    function toggleMicMute() {
        if (Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.muted = !micMuted
    }

    function toggleMute() {
        if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = !isMuted
    }

    Timer {
        id: writeThrottle
        interval: writeInterval
        onTriggered: {
            if (!writePending) return
            writePending = false
            write()
            restart()
        }
    }

    // Once requests stop and the last one has gone out, the shown level follows Pipewire again
    Timer {
        id: targetReset
        interval: 500
        onTriggered: targetLevel = -1
    }
}
