import Quickshell
import Quickshell.Io
import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils

PanelWindow {
    id: root
    
    property int panelWidth: 480
    property int marginSize: Settings.windowSpacing

    property var visiblePage: mainPage
    property bool showing: false
    visible: false

    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true
        
        onFileChanged: {
            if (!showing) open()
            else close()
        }
    }

    anchors {
        right: true
        bottom: true
    }

    margins {
        top: marginSize
        bottom: marginSize
    }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    implicitWidth: panelWidth + marginSize
    implicitHeight: visiblePage.height + (Settings.spacing * 4)
    aboveWindows: true

    Shortcut {
        sequence: "Escape"
        onActivated: close()
    }

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

        Keys.onEscapePressed: (event) => {
            slideOut.restart()
            showing = !showing
        }
        
        height: visiblePage.height + (Settings.spacing * 4)
        width: panelWidth
        radius: Settings.radiusLg
        bottomRightRadius: Settings.radiusSm

        color: Colors.background
        border.width: 1
        border.color: Colors.backgroundSubtle

        anchors.bottom: parent.bottom

        ColumnLayout {
            id: mainPage

            visible: root.visiblePage == this

            width: parent.width - (Settings.spacing * 4)
            
            x: Settings.spacing * 2
            y: Settings.spacing * 2

            spacing: Settings.spacing

            RowLayout {
                spacing: Settings.spacing

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
            }

            Button {
                Layout.preferredWidth: parent.width
                icon: "notifications-off"
                text: "Notifications"
                disabled: true
            }
        
            Button {
                Layout.preferredWidth: parent.width
                icon: "settings"
                text: "Settings"
            }
        }

        ColumnLayout {
            id: networksPage

            visible: visiblePage == this
            
            width: parent.width - (Settings.spacing * 4)
            height: 500

            x: Settings.spacing * 2
            y: Settings.spacing * 2
            
            spacing: Settings.spacing * 2

            RowLayout {

                Layout.preferredWidth: parent.width
                
                width: parent.width                 
                spacing: Settings.spacing

                Button {
                    icon: "arrow-left"
                    iconOnly: true
                    size: "md"
                    type: "ghost"
                    textColor: Colors.text
                    Layout.fillWidth: false

                    onClicked: changePage(mainPage)
                }

                Text {
                    text: "Wi-Fi"
                    color: Colors.text
                    font.pixelSize: 24
                    font.family: Settings.fontFamily
                    font.weight: 900
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    verticalAlignment: Text.AlignVCenter
                }

                Loading { visible: Network.wifiScanning }

                Button {
                    disabled: Network.wifiScanning
                    icon: "reload"
                    iconOnly: true
                    size: "md"
                    type: "ghost"
                    textColor: Colors.text
                    Layout.fillWidth: false

                    onClicked: Network.rescanWifi()
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.backgroundSubtle
            }

            ScrollView {
                id: scrollView

                Layout.fillHeight: true
                Layout.fillWidth: true

                clip: true
                contentWidth: availableWidth
                contentHeight: networkList.implicitHeight

                ScrollBar.vertical: ScrollBar {
                    id: vBar
                    
                    visible: size < 1.0

                    policy: ScrollBar.AsNeeded
                    anchors.right: parent.right

                    background: Rectangle {
                        implicitWidth: 6
                        implicitHeight: scrollView.height
                        color: "transparent" 
                    }

                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 3
                        
                        color: {
                            if (vBar.pressed) return Colors.primaryActive 
                            if (vBar.hovered) return Colors.primaryHover
                            return Qt.alpha(Colors.foreground, 0.5)
                        }
                    }
                }

                ColumnLayout {
                    id: networkList

                    width: scrollView.availableWidth

                    Button {
                        Layout.fillWidth: true
                        visible: Network.wifiStatus === "connected"
                        icon: Network.icon
                        text: Network.networkName
                        onClicked: Network.disconnectWifiNetwork()
                    } 

                    Repeater {
                        model: Network.wifiNetworks
                        required property var modelData

                        NetworkItem {
                            conn: modelData
                            visible: Network.wifiEnabled && conn.ssid != Network.networkName
                        }
                    }

                    Text {
                        visible: !Network.wifiEnabled
                        
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
                        Layout.preferredHeight: 64
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Loading {
                        visible: !Network.wifiEnabled
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    function changePage(page) {
        root.visiblePage = page
        
        if (page == networksPage) Network.rescanWifi()
    }

    function close() {
        if (showing && !slideIn.running && !slideOut.running) {

            if (root.activeFocusItem) root.activeFocusItem.focus = false
            slideOut.restart()
            showing = !showing
        }   
    }

    function open() {
        if (!showing && !slideIn.running && !slideOut.running) {
            slideIn.restart()
            root.visiblePage = mainPage
            showing = !showing
        }
    }

    function toggle() {
        if (showing) close()
        else open()
    }
}
