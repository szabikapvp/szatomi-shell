import Quickshell
import Quickshell.Io
import QtQuick
import QtQml
import QtQuick.Layouts
import Quickshell.Wayland
import "../../components/widgets"

import qs.config
import qs.services

PanelWindow {
    id: root
    
    property int panelWidth: 512
    property int marginSize: Settings.barMargin * 2

    property var visiblePage: mainPage
    property bool showing: false
    visible: false

    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true
        
        onFileChanged: {
            
            if (!showing && !slideIn.running && !slideOut.running) {
                slideIn.restart()
                root.visiblePage = mainPage
                showing = !showing
            }

            else if (showing && !slideIn.running && !slideOut.running) {
                slideOut.restart()
                showing = !showing
            }     
        }
    }

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: marginSize
        bottom: marginSize
    }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    color: "transparent"
    implicitWidth: panelWidth + marginSize
    aboveWindows: true

    SequentialAnimation {
        id: slideIn

        PropertyAction {
            target: root
            property: "visible"
            value: true
        }

        NumberAnimation {
            target: osdRect
            property: "x"
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: slideOut

        NumberAnimation {
            target: osdRect
            property: "x"
            to: panelWidth + marginSize
            duration: 300
            easing.type: Easing.OutCubic
        }

        PropertyAction {
            target: root
            property: "visible"
            value: false
        }
    }

    Rectangle {
        id: osdRect
        
        x: panelWidth
        height: root.height
        width: panelWidth
        radius: Settings.radiusLg
        color: Qt.lighter(Colors.background, 2)
        border.width: 1
        border.color: Qt.lighter(Colors.background, 4)

        FlexboxLayout {
            id: mainPage

            visible: root.visiblePage == this

            anchors.fill: parent
            anchors.margins: Settings.gap * 2
            gap: Settings.gap
            wrap: FlexboxLayout.Wrap

            Button {
                id: networkButton
                icon: Network.icon
                text: Network.wifiStatus == "connected" ? Network.networkName : "Wi-Fi"
                rightSide: true
                color: Network.wifiStatus == "connected" ? Colors.primary : Colors.foreground

                onClicked: Network.toggleWifi()

                onRightSideClicked: changePage(networksPage)
            }

            Button {
                icon: "bluetooth-off"
                text: "Bluetooth"
            }

            Button {
                icon: "notifications-off"
                text: "Notifications"
            }
        
            Button {
                Layout.preferredWidth: parent.width
                icon: "settings"
                text: "Settings"
            }
        }

        FlexboxLayout {
            id: networksPage

            visible: visiblePage == this
            
            anchors.fill: parent
            anchors.margins: Settings.gap * 2
            gap: Settings.gap * 2
            wrap: FlexboxLayout.Wrap
                        
            Component.onCompleted: Network.rescanWifi()

            RowLayout {
                
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                spacing: Settings.gap

                Button {
                    icon: "arrow-left"
                    iconOnly: true
                    size: "sm"
                    type: "ghost"
                    textColor: Colors.text
                    Layout.fillWidth: false

                    onClicked: changePage(mainPage)
                }

                Text {
                    text: "Wi-Fi Networks"
                    color: Colors.text
                    font.pixelSize: 24
                    font.family: Settings.fontFamily
                    font.weight: 900
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    verticalAlignment: Text.AlignVCenter
                }

                Button {
                    icon: "reload"
                    iconOnly: true
                    size: "sm"
                    type: "ghost"
                    textColor: Colors.text
                    Layout.fillWidth: false

                    onClicked: Network.rescanWifi()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                height: 2
                color: Qt.darker(Colors.text, 5)
            }

            ColumnLayout {

                Layout.fillWidth: true

                Repeater {
                    model: Network.wifiNetworks

                    Button {
                        visible: !Network.wifiScanning && Network.wifiEnabled
                        type: "ghost"
                        icon: strength > 80 
                            ? "wifi-4" :
                            strength > 60 ? "wifi-3" :
                            strength > 40 ? "wifi-2" :
                            strength > 20 ? "wifi-1" :
                            "wifi-0"

                        text: ssid
                        textColor: Colors.text
                        size: "sm"
                        bold: active
                        Layout.preferredWidth: 500
                    }
                }

                Text {
                    visible: !Network.wifiEnabled || Network.wifiScanning
                    
                    text: {
                        if (!Network.wifiEnabled) return "Wi-Fi is turned off"
                        else if (Network.wifiScanning) return "Scanning..."
                        return ""
                    }

                    color: Colors.text
                    font.pixelSize: Settings.fontSize
                    font.family: Settings.fontFamily
                    font.weight: 300
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    function changePage(page) {
        root.visiblePage = page
        
        if (page == networksPage) Network.rescanWifi()
    }
} 