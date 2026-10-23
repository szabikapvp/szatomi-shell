import QtQuick

import qs.config

// Every widget the control center can show. To add one, make a tile in this folder and list it here.
// Sizes are [columns, rows]; when a widget is added, the first size that fits is used
QtObject {
    readonly property var buttonSizes: range(1, Settings.controlCenterColumns).map(w => [w, 1])
    readonly property var sliderSizes: range(2, Settings.controlCenterMaxRows).map(h => [1, h]).concat(buttonSizes)
    readonly property var panelSizes: [[2, 2], [4, 2], [2, 4]]

    readonly property var entries: [
        { type: "wifi", name: "Wi-Fi", icon: "wifi-4", tile: Qt.resolvedUrl("WifiTile.qml"), page: Qt.resolvedUrl("../WifiPage.qml"), sizes: buttonSizes },
        { type: "bluetooth", name: "Bluetooth", icon: "bluetooth", tile: Qt.resolvedUrl("BluetoothTile.qml"), page: Qt.resolvedUrl("../BluetoothPage.qml"), sizes: buttonSizes },
        { type: "power", name: "Power", icon: "power", tile: Qt.resolvedUrl("PowerTile.qml"), page: Qt.resolvedUrl("../PowerPage.qml"), sizes: buttonSizes },
        { type: "volume", name: "Volume", icon: "volume-2", tile: Qt.resolvedUrl("VolumeTile.qml"), sizes: sliderSizes },
        { type: "brightness", name: "Brightness", icon: "brightness-3", tile: Qt.resolvedUrl("BrightnessTile.qml"), sizes: sliderSizes },
        { type: "clock", name: "Clock", icon: "clock", tile: Qt.resolvedUrl("ClockTile.qml"), sizes: panelSizes },
        { type: "calendar", name: "Calendar", icon: "calendar", tile: Qt.resolvedUrl("CalendarTile.qml"), sizes: panelSizes }
    ]

    // Used until the layout is first edited
    readonly property var defaultLayout: [
        { type: "wifi", x: 0, y: 0, w: 2, h: 1 },
        { type: "bluetooth", x: 2, y: 0, w: 2, h: 1 },
        { type: "clock", x: 0, y: 1, w: 2, h: 2 },
        { type: "volume", x: 2, y: 1, w: 1, h: 3 },
        { type: "brightness", x: 3, y: 1, w: 1, h: 3 },
        { type: "power", x: 0, y: 3, w: 2, h: 1 }
    ]

    function find(type) {
        return entries.find(entry => entry.type === type) ?? null
    }

    function range(from, to) {
        return Array.from({ length: Math.max(0, to - from + 1) }, (_, i) => from + i)
    }
}
