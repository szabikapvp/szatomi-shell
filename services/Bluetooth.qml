pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Bluetooth as QsBluetooth

import qs.config

Singleton {
    id: root

    readonly property var adapter: QsBluetooth.Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool blocked: adapter?.state === QsBluetooth.BluetoothAdapterState.Blocked
    readonly property bool discovering: adapter?.discovering ?? false

    // Connected first, then paired, then by name; unnamed unpaired devices are scan noise
    readonly property var devices: (adapter?.devices.values ?? [])
        .filter(d => d.paired || d.deviceName.length > 0)
        .sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name))

    readonly property var connectedDevice: devices.find(d => d.connected) ?? null

    // Address of the last device that failed to pair or connect
    property string failedAddress: ""
    property var pairTarget: null
    property var connectTarget: null

    property string icon: !enabled
        ? "bluetooth-off"
        : connectedDevice
            ? "bluetooth-connected"
            : discovering
                ? "bluetooth-searching"
                : "bluetooth"

    function rank(device) {
        if (device.connected) return 0
        if (device.paired) return 1
        return 2
    }

    // Maps the BlueZ icon name to a device type icon
    function deviceIcon(device): string {
        const type = device.icon ?? ""
        if (type === "audio-headset") return "bt-headset"
        if (type === "audio-headphones") return "bt-headphones"
        if (type.startsWith("audio")) return "bt-speaker"
        if (type === "input-keyboard") return "bt-keyboard"
        if (type === "input-mouse" || type === "input-tablet") return "bt-mouse"
        if (type === "input-gaming") return "bt-gamepad"
        if (type === "phone") return "bt-phone"
        if (type === "computer") return "bt-computer"
        if (type.startsWith("video")) return "bt-display"
        return "bluetooth"
    }

    function isConnecting(device): bool {
        return device.state === QsBluetooth.BluetoothDeviceState.Connecting
    }

    function isDisconnecting(device): bool {
        return device.state === QsBluetooth.BluetoothDeviceState.Disconnecting
    }

    function isBusy(device): bool {
        return device.pairing || isConnecting(device) || isDisconnecting(device)
    }

    function setEnabled(on = true): void {
        if (adapter) adapter.enabled = on
    }

    function toggle(): void {
        setEnabled(!enabled)
    }

    // Discovery drains power, so it stops by itself after a while
    function startScan(): void {
        if (!enabled) return
        adapter.discovering = true
        scanTimer.restart()
    }

    function stopScan(): void {
        scanTimer.stop()
        if (adapter && adapter.discovering) adapter.discovering = false
    }

    // Unpaired devices get paired and trusted first, the connect follows once pairing succeeds
    function connectDevice(device): void {
        failedAddress = ""

        if (!device.paired) {
            pairTarget = device
            device.trusted = true
            device.pair()
        } else {
            connectTarget = device
            device.connect()
        }
    }

    function disconnectDevice(device): void {
        device.disconnect()
    }

    function forgetDevice(device): void {
        if (failedAddress === device.address) failedAddress = ""
        device.forget()
    }

    Timer {
        id: scanTimer
        interval: Settings.bluetoothScanDuration
        onTriggered: root.stopScan()
    }

    Connections {
        target: root.pairTarget

        function onPairedChanged() {
            if (!root.pairTarget.paired) return
            root.connectDevice(root.pairTarget)
            root.pairTarget = null
        }

        // Paired can land right after pairing ends, so the failure check waits a tick
        function onPairingChanged() {
            if (root.pairTarget.pairing) return

            Qt.callLater(() => {
                if (!root.pairTarget || root.pairTarget.paired) return
                root.failedAddress = root.pairTarget.address
                root.pairTarget = null
            })
        }
    }

    Connections {
        target: root.connectTarget

        function onStateChanged() {
            if (root.isConnecting(root.connectTarget)) return

            if (!root.connectTarget.connected) root.failedAddress = root.connectTarget.address
            root.connectTarget = null
        }
    }

    // Leaving the adapter off shouldn't keep a stale scan timer around
    onEnabledChanged: if (!enabled) scanTimer.stop()
}
