import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.config
import qs.utils
import "../../components"
import "../../components/widgets"

Item {
    id: root
    property var device

    Layout.preferredWidth: Settings.px(400)
    Layout.fillWidth: true

    property string type: "ghost"
    property string size: "md"
    property string color: Colors.foreground
    property string textColor: Colors.text

    property int radius: Settings.radiusMd
    property bool disabled: false

    property bool expanded: false
    readonly property bool busy: Bluetooth.isBusy(device)
    readonly property bool failed: Bluetooth.failedAddress === device.address

    implicitHeight: buttonRect.height

    Rectangle {
        id: buttonRect

        width: parent.width

        height: info.implicitHeight + (Settings.spacing * 2)

        color: {
            switch (root.type) {
                case "primary":
                    if (disabled) return Qt.darker(root.color, 2)
                    if (mouseArea.containsMouse) {
                        if (mouseArea.pressed) return Qt.darker(root.color, 1.8)
                        else return Qt.darker(root.color, 1.3)
                    } else return root.color

                case "ghost":
                    if (disabled) return "transparent"
                    if (mouseArea.containsMouse || expanded) {
                        if (mouseArea.pressed) return Qt.alpha(root.color, 0.2)
                        else return Qt.alpha(root.color, 0.1)
                    } else return "transparent"
            }
        }

        radius: root.radius

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        // Connected devices expand to their actions, everything else connects on click
        MouseArea {
            id: mouseArea

            width: parent.width
            height: header.implicitHeight + (Settings.spacing * 2)

            enabled: !disabled && !busy
            hoverEnabled: true

            cursorShape: (disabled || busy) ? Qt.ArrowCursor : Qt.PointingHandCursor

            onClicked: (mouse) => {
                if (expanded) expanded = false
                else if (device.connected) expanded = true
                else Bluetooth.connectDevice(device)
            }
        }

        ColumnLayout {
            id: info

            x: Settings.spacing
            y: Settings.spacing

            width: parent.width - (Settings.spacing * 2)
            spacing: Settings.spacing

            RowLayout {
                id: header
                Layout.fillWidth: true
                spacing: Settings.spacing * (size == "lg" ? 2 : 1)

                Icon {
                    icon: Bluetooth.deviceIcon(device)
                    size: Settings.px(24)
                    color: disabled ? Qt.darker(textColor, 1.8) : textColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: device.name
                        color: disabled ? Qt.darker(textColor, 1.8) : textColor
                        font.pixelSize: Settings.fontSize
                        font.family: Settings.fontFamily
                        font.bold: device.connected

                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    Text {
                        text: {
                            if (device.pairing) return "Pairing..."
                            if (Bluetooth.isConnecting(device)) return "Connecting..."
                            if (Bluetooth.isDisconnecting(device)) return "Disconnecting..."
                            if (device.connected) return device.batteryAvailable
                                ? "Connected · " + Math.round(device.battery * 100) + "%"
                                : "Connected"
                            if (failed) return device.paired ? "Couldn't connect" : "Couldn't pair"
                            return device.paired ? "Paired" : "Not paired"
                        }
                        color: failed ? Colors.primary : Qt.darker(textColor, 1.8)
                        font.pixelSize: Settings.fontSize - Settings.px(4)
                        font.family: Settings.fontFamily

                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                }

                Loading { visible: busy }
            }

            RowLayout {
                visible: device.paired && (expanded || failed) && !busy
                spacing: Settings.spacing

                Button {
                    visible: device.connected
                    size: "sm"
                    Layout.fillWidth: false
                    text: "Disconnect"
                    icon: ""

                    onClicked: Bluetooth.disconnectDevice(device)
                }

                Button {
                    size: "sm"
                    type: "ghost"
                    textColor: Colors.text
                    Layout.fillWidth: false
                    text: "Forget"
                    icon: ""

                    onClicked: Bluetooth.forgetDevice(device)
                }
            }
        }
    }
}
