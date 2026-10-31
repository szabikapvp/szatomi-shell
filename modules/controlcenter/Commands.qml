import QtQuick

import qs.services

// What the launcher runs when the search starts with ">". Each one either does something right away (run),
// or opens a page that does on a single pick (page). Ones that end the session ask for a second Enter (confirm)
QtObject {
    readonly property var entries: [
        { keyword: "wallpaper", name: "Change wallpaper", icon: "wallpaper", keywords: ["background", "theme"], page: Qt.resolvedUrl("WallpaperPage.qml") },
        { keyword: "volume-mixer", name: "Volume mixer", icon: "tune", keywords: ["audio", "sound", "apps", "output", "input"], page: Qt.resolvedUrl("SettingsPage.qml"), pageProperties: { category: "Audio" } },
        { keyword: "mute", name: Audio.isMuted ? "Unmute sound" : "Mute sound", icon: Audio.isMuted ? "volume-2" : "volume-mute", keywords: ["audio", "volume", "sound"], run: () => Audio.toggleMute() },
        { keyword: "mute-mic", name: Audio.micMuted ? "Unmute microphone" : "Mute microphone", icon: "mic", keywords: ["audio", "input", "microphone"], run: () => Audio.toggleMicMute() },
        { keyword: "displays", name: "Display settings", icon: "bt-display", keywords: ["monitor", "screen", "resolution", "refresh", "scale", "rotate", "mirror", "main"], page: Qt.resolvedUrl("SettingsPage.qml"), pageProperties: { category: "Displays" } },
        { keyword: "wifi", name: "Connect to Wi-Fi", icon: "wifi-4", keywords: ["network", "internet"], page: Qt.resolvedUrl("WifiPage.qml") },
        { keyword: "toggle-wifi", name: Network.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on", icon: Network.wifiEnabled ? "no-wifi" : "wifi-4", keywords: ["network", "internet", "airplane"], run: () => Network.toggleWifi() },
        { keyword: "bluetooth", name: "Connect Bluetooth device", icon: "bluetooth", keywords: ["headphones", "pair"], page: Qt.resolvedUrl("BluetoothPage.qml") },
        { keyword: "toggle-bluetooth", name: Bluetooth.enabled ? "Turn Bluetooth off" : "Turn Bluetooth on", icon: Bluetooth.enabled ? "bluetooth-off" : "bluetooth", keywords: ["airplane"], run: () => Bluetooth.toggle() },
        { keyword: "lock", name: "Lock", icon: "lock", keywords: ["power", "screen"], run: () => Power.run("lock") },
        { keyword: "sleep", name: "Sleep", icon: "sleep", keywords: ["power", "suspend"], run: () => Power.run("sleep") },
        { keyword: "logout", name: "Log out", icon: "logout", keywords: ["power", "exit", "session"], run: () => Power.run("logout"), confirm: true },
        { keyword: "restart", name: "Restart", icon: "reload", keywords: ["power", "reboot"], run: () => Power.run("restart"), confirm: true },
        { keyword: "shutdown", name: "Shut down", icon: "power", keywords: ["power", "off", "poweroff"], run: () => Power.run("shutdown"), confirm: true }
    ]

    function search(query) {
        return Apps.byUse(Apps.filter(entries, query, command => [command.keyword, command.name, ...command.keywords]), command => ">" + command.keyword)
    }
}
