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
        sequences: Settings.backShortcuts
        onActivated: back()
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

        BackGesture {
            onTriggered: back()
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
                Layout.fillWidth: true
                spacing: Settings.spacing

                Button {
                    id: networkButton
                    Layout.preferredWidth: 1
                    icon: Network.icon
                    text: Network.wifiStatus == "connected" ? Network.networkName : "Wi-Fi"
                    rightSide: true
                    color: Network.wifiStatus == "connected" ? Colors.primary : Colors.foreground

                    onClicked: Network.toggleWifi()

                    onRightSideClicked: changePage(networksPage)
                }

                Button {
                    Layout.preferredWidth: 1
                    icon: Bluetooth.icon
                    text: Bluetooth.connectedDevice ? Bluetooth.connectedDevice.name : "Bluetooth"
                    rightSide: true
                    color: Bluetooth.connectedDevice ? Colors.primary : Colors.foreground
                    disabled: !Bluetooth.available || Bluetooth.blocked

                    onClicked: Bluetooth.toggle()

                    onRightSideClicked: changePage(bluetoothPage)
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

        WifiPage {
            id: networksPage

            visible: visiblePage == this
            
            width: parent.width - (Settings.spacing * 4)

            x: Settings.spacing * 2
            y: Settings.spacing * 2
            
            onBack: changePage(mainPage)
        }

        BluetoothPage {
            id: bluetoothPage

            visible: visiblePage == this

            width: parent.width - (Settings.spacing * 4)

            x: Settings.spacing * 2
            y: Settings.spacing * 2

            onBack: changePage(mainPage)
        }
    }

    function changePage(page) {
        root.visiblePage = page
        
        if (page == networksPage) Network.rescanWifi()

        // Discovery only runs while the Bluetooth page is open
        if (page == bluetoothPage) Bluetooth.startScan()
        else Bluetooth.stopScan()
    }

    // Step back to the main page before closing
    function back() {
        if (visiblePage != mainPage) changePage(mainPage)
        else close()
    }

    function close() {
        if (showing && !slideIn.running && !slideOut.running) {

            if (root.activeFocusItem) root.activeFocusItem.focus = false
            Bluetooth.stopScan()
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
