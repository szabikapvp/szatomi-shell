import QtQuick

import qs.services

ButtonTile {
    icon: Network.icon
    text: "Wi-Fi"
    subtext: {
        if (!Network.wifiEnabled) return "Off"
        if (Network.wifiStatus == "connected") return Network.networkName
        if (Network.wifiStatus == "connecting") return "Connecting..."
        return "Not connected"
    }
    active: Network.wifiEnabled

    onClicked: Network.toggleWifi()
}
