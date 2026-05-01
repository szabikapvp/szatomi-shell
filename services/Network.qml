pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    component Connection: QtObject {
        required property var lastIpcObject
        readonly property string type: lastIpcObject.type
        readonly property string name: lastIpcObject.name
        readonly property string uuid: lastIpcObject.uuid
        readonly property string device: lastIpcObject.device
        readonly property bool active: lastIpcObject.active
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property string bssid: lastIpcObject.bssid
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
        readonly property bool saved: lastIpcObject.saved
    }

    Component { id: connComp; Connection { } }

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property Connection wifiConnectTarget
    readonly property list<Connection> wifiNetworks: []
    readonly property Connection active: wifiNetworks.find(n => n.active) ?? null
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength
    property string icon: root.ethernet
        ? "lan"
        : root.wifiEnabled
            ? (
                Network.networkStrength > 80 ? "wifi-4" :
                Network.networkStrength > 60 ? "wifi-3" :
                Network.networkStrength > 40 ? "wifi-2" :
                Network.networkStrength > 20 ? "wifi-1" :
                "wifi-0"
            )
            : (root.wifiStatus === "connecting")
                ? "wifi-connecting"
                : (root.wifiStatus === "disconnected")
                    ? "wifi-find"
                    : (root.wifiStatus === "disabled")
                        ? "no-wifi"
                        : "wifi-bad"

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

}