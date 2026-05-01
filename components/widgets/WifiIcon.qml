import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import "../../components"
import qs.services

Item {
    id: root
    implicitWidth: 18
    implicitHeight: 18

    // cursorShape: Qt.PointingHandCursor
    // onClicked: Quickshell.execDetached(["kitty", "--class", "nmtui-float", "nmtui"])

    readonly property WifiDevice wifiDevice: {
        for (let i = 0; i < Networking.devices.values.length; i++) {
            const dev = Networking.devices.values[i];
            if (dev.type == DeviceType.Wifi) return dev;
                
        }
        return null;
    }

    readonly property string iconSource: {

        if (!Networking.wifiEnabled) {
            return "no-wifi";
        }

        if (!wifiDevice || !wifiDevice.connected) {
            return "wifi-0";
        }

        return "wifi-4";
    }

    Icon {
        icon: root.iconSource
    }
            
    ToolTip {
        text: {
            if (!Networking.wifiEnabled) return "Wi-Fi Off";
            if (root.wifiDevice && root.wifiDevice.connected) {
                return `asd`;
            }
            return "Disconnected";
        }
    }
}