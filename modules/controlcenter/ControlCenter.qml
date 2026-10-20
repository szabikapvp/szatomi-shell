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
    visible: panel.progress > 0

    // Resting position for the remembered corner
    property real cornerX: panelState.right ? panel.parent.width - panel.width - marginSize : marginSize
    property real cornerY: panelState.bottom ? panel.parent.height - panel.height - marginSize : marginSize

    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true

        onFileChanged: {
            if (!showing) open()
            else close()
        }
    }

    // Remembers the corner across restarts
    FileView {
        path: Quickshell.statePath("controlcenter.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: panelState
            property bool right: true
            property bool bottom: true
        }
    }

    // Fullscreen so the panel can be dragged anywhere, the mask lets clicks through elsewhere
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region { item: panel }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: Fullscreen.exclusionMode(screen)

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    aboveWindows: true

    Shortcut {
        sequences: Settings.backShortcuts
        onActivated: back()
    }

    // One shared progress drives both axes, so the snap always moves in a straight line
    property real snapProgress: 0
    property point snapFrom

    onSnapProgressChanged: {
        if (!snap.running) return
        panel.x = snapFrom.x + (cornerX - snapFrom.x) * snapProgress
        panel.y = snapFrom.y + (cornerY - snapFrom.y) * snapProgress
    }

    NumberAnimation {
        id: snap

        target: root
        property: "snapProgress"
        from: 0
        to: 1
        duration: Settings.snapDuration
        easing.type: Easing.OutCubic

        // Dragging broke the bindings, restore them so page height changes keep the corner
        onFinished: {
            panel.x = Qt.binding(() => cornerX)
            panel.y = Qt.binding(() => cornerY)
        }
    }

    PopMask {
        id: panel

        x: cornerX
        y: cornerY
        width: panelWidth
        height: visiblePage.height + (Settings.spacing * 4)

        fromRight: panelState.right
        fromBottom: panelState.bottom
        radius: Settings.radiusLg

        Rectangle {
            id: osdRect

            anchors.fill: parent

            BackGesture {
                onTriggered: back()
            }

            // Only reachable on empty parts, the content on top takes its own clicks
            MouseArea {
                anchors.fill: parent
                drag.target: panel
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: panel.parent.width - panel.width
                drag.maximumY: panel.parent.height - panel.height
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                // Dragging moves the panel from C++, which leaves the corner bindings alive.
                // Break them here, or changing the corner on release jumps the panel there
                drag.onActiveChanged: {
                    if (!drag.active) return
                    panel.x = panel.x
                    panel.y = panel.y
                }

                onReleased: {
                    snapFrom = Qt.point(panel.x, panel.y)
                    panelState.right = panel.x + panel.width / 2 > panel.parent.width / 2
                    panelState.bottom = panel.y + panel.height / 2 > panel.parent.height / 2
                    snap.restart()
                }
            }

            // The small corner faces the screen corner
            radius: Settings.radiusLg
            topLeftRadius: !panelState.right && !panelState.bottom ? Settings.radiusSm : Settings.radiusLg
            topRightRadius: panelState.right && !panelState.bottom ? Settings.radiusSm : Settings.radiusLg
            bottomLeftRadius: !panelState.right && panelState.bottom ? Settings.radiusSm : Settings.radiusLg
            bottomRightRadius: panelState.right && panelState.bottom ? Settings.radiusSm : Settings.radiusLg

            color: Colors.background
            border.width: 1
            border.color: Colors.backgroundSubtle

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
        if (showing && !panel.running) {

            if (root.activeFocusItem) root.activeFocusItem.focus = false
            Bluetooth.stopScan()
            panel.popOut()
            showing = !showing
        }
    }

    function open() {
        if (!showing && !panel.running) {
            panel.popIn()
            root.visiblePage = mainPage
            showing = !showing
        }
    }

    function toggle() {
        if (showing) close()
        else open()
    }
}
