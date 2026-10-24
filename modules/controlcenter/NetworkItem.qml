import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.services.network
import qs.config
import qs.utils
import "../../components"
import "../../components/widgets"

Item {
    id: root
    property Connection conn

    Layout.preferredWidth: Settings.px(400)
    Layout.fillWidth: true

    property string type: "ghost"
    property string size: "md"
    property string color: Colors.foreground
    property string textColor: Colors.text

    property int radius: Settings.radiusMd
    property bool disabled: false

    property bool expanded: false
    property bool wrongPassword: false
    readonly property bool connecting: Network.wifiConnectTarget === conn

    implicitHeight: buttonRect.height

    signal rightSideClicked()

    // Open the password field when nmcli asks for secrets, flag it if a password was already tried
    Connections {
        target: root.conn

        function onAskingPasswordChanged() {
            if (!root.conn.askingPassword) return
            root.expanded = true
        }

        function onActiveChanged() {
            root.expanded = false
            root.wrongPassword = false
        }
    }

    function submitPassword() {
        if (passwordField.text.length === 0) return
        wrongPassword = true
        Network.changePassword(conn, passwordField.text)
        passwordField.text = ""
        expanded = false
    }

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

        // Only the header row toggles, so clicks around the password field don't collapse it
        MouseArea {
            id: mouseArea

            width: parent.width
            height: header.implicitHeight + (Settings.spacing * 2)

            enabled: !disabled && !connecting
            hoverEnabled: true

            cursorShape: (disabled || connecting) ? Qt.ArrowCursor : Qt.PointingHandCursor

            onClicked: (mouse) => {
                if (expanded) expanded = false
                else if (conn.active || conn.askingPassword) expanded = true
                else Network.connectToWifiNetwork(conn)
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
                    icon: conn.strength > 80
                        ? "wifi-4" :
                        conn.strength > 60 ? "wifi-3" :
                        conn.strength > 40 ? "wifi-2" :
                        conn.strength > 20 ? "wifi-1" :
                        "wifi-0"
                    size: Settings.px(24)
                    color: disabled ? Qt.darker(textColor, 1.8) : textColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: conn.ssid
                        color: disabled ? Qt.darker(textColor, 1.8) : textColor
                        font.pixelSize: Settings.fontSize
                        font.family: Settings.fontFamily
                        font.bold: conn.active

                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    Text {
                        text: {
                            if (connecting) return "Connecting..."
                            if (conn.active) return Network.wifiStatus === "limited" ? "Connected, no internet" : "Connected"
                            if (conn.askingPassword && wrongPassword) return "Wrong password"
                            return conn.isSecure ? conn.security : "Open"
                        }
                        color: (conn.askingPassword && wrongPassword) ? Colors.primary : Qt.darker(textColor, 1.8)
                        font.pixelSize: Settings.fontSize - Settings.px(4)
                        font.family: Settings.fontFamily

                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                }

                Loading { visible: connecting }
            }

            RowLayout {
                id: inputPanel
                Layout.fillWidth: true

                spacing: Settings.spacing

                visible: expanded && !conn.active

                InputField {
                    id: passwordField

                    size: "sm"
                    placeholderText: "Password"
                    type: "password"

                    onVisibleChanged: {
                        if (visible) forceActiveFocus()
                    }

                    onAccepted: submitPassword()
                }

                Button {
                    size: "sm"
                    Layout.fillWidth: false
                    text: "Connect"
                    icon: ""
                    disabled: passwordField.text.length === 0

                    onClicked: submitPassword()
                }
            }

            Button {
                visible: expanded && conn.active
                size: "sm"
                Layout.fillWidth: false
                text: "Disconnect"
                icon: ""

                onClicked: Network.disconnectWifiNetwork()
            }
        }
    }
}
