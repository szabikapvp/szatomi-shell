import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.services.network
import qs.config
import "../../components"
import "../../components/widgets"

Item {
    id: root
    property Connection conn

    Layout.preferredWidth: 400
    Layout.fillWidth: true
    
    property string type: "ghost"
    property string size: "md" 
    property string color: Colors.foreground
    property string textColor: Colors.text
    
    property int radius: Settings.radiusMd
    property bool disabled: false

    implicitHeight: buttonRect.height

    signal rightSideClicked()

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
                    if (mouseArea.containsMouse) {
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

        MouseArea {
            id: mouseArea
            
            anchors.fill: buttonRect 
            
            enabled: !disabled
            hoverEnabled: true
            
            cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
            
            onClicked: (mouse) => {
                if (conn.askingPassword && !inputPanel.visible) {
                    inputPanel.visible = true
                } else if (inputPanel.visible) {
                    inputPanel.visible = false
                }else {
                    Network.connectToWifiNetwork(conn)
                }
            }
        }
    
        ColumnLayout {
            id: info

            x: Settings.spacing
            y: Settings.spacing
            
            width: parent.width - (Settings.spacing * 2) 
            spacing: Settings.spacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Settings.spacing * (size == "lg" ? 2 : 1)

                Icon {
                    icon: conn.strength > 80 
                        ? "wifi-4" :
                        conn.strength > 60 ? "wifi-3" :
                        conn.strength > 40 ? "wifi-2" :
                        conn.strength > 20 ? "wifi-1" :
                        "wifi-0"
                    size: 24
                    color: disabled ? Qt.darker(textColor, 1.8) : textColor
                }

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
            }

            RowLayout {
                id: inputPanel
                Layout.fillWidth: true
                
                visible: false 

                TextField {
                    id: passwordField

                    placeholderText: "Password"
                    Layout.fillWidth: true
                    color: Colors.text
                    placeholderTextColor: mouseArea.containsMouse ? Qt.darker(Colors.text, 3) : Qt.darker(Colors.text, 2)
                    padding: Settings.spacing
                    leftPadding: Settings.spacing * 2
                    font.pixelSize: Settings.fontSize - 2
                    font.family: Settings.fontFamily
                    echoMode: TextInput.Password

                    onVisibleChanged: {
                        if (visible) forceActiveFocus()
                    }

                    background: Rectangle {
                        color: Qt.lighter(Colors.background, 1.8)
                        radius: Settings.radiusSm
                    }
                }

                Button {
                    size: "sm"
                    Layout.fillWidth: false
                    text: "Connect"
                    icon: ""

                    onClicked: () => {
                        Network.changePassword(conn, passwordField.text)
                    }
                }
            }
        }
    }
}