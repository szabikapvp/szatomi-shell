import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import "../../components/widgets"

import qs.config
import qs.services

PanelWindow {
    id: root
    
    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true
        
        onFileChanged: {
            root.visible = !root.visible
        }
    }

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        right: Settings.barMargin
        top: Settings.barMargin
        bottom: Settings.barMargin
    }

    WlrLayershell.layer: WlrLayer.Overlay
    // exclusiveZone: 0

    visible: true
    color: "transparent"
    implicitWidth: 512
    aboveWindows: true

    Rectangle {
        
        anchors.fill: parent
        
        radius: Settings.radiusMd
        color: Colors.background

        FlexboxLayout {

            anchors.fill: parent
            anchors.margins: Settings.gap * 4
            gap: Settings.gap
            wrap: FlexboxLayout.Wrap

            Button {
                icon: Network.icon
                text: "Wi-Fi"
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
    }
} 