import QtQuick

import qs.services

ButtonTile {
    icon: Bluetooth.icon
    text: "Bluetooth"
    subtext: {
        if (!Bluetooth.available) return "Unavailable"
        if (Bluetooth.blocked) return "Blocked"
        if (!Bluetooth.enabled) return "Off"
        return Bluetooth.connectedDevice ? Bluetooth.connectedDevice.name : "On"
    }
    active: Bluetooth.enabled
    disabled: !Bluetooth.available || Bluetooth.blocked

    onClicked: Bluetooth.toggle()
}
