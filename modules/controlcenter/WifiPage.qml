import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils

ColumnLayout {
    id: root

    signal back()

    height: Settings.controlCenterPageHeight
    spacing: Settings.spacing * 2

    // Radio needs a moment to come up before a rescan succeeds
    Timer {
        id: rescanDelay
        interval: Settings.wifiRescanDelay
        onTriggered: Network.rescanWifi()
    }

    Connections {
        target: Network
        function onWifiEnabledChanged() {
            if (Network.wifiEnabled && root.visible) rescanDelay.restart()
        }
    }

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

            onClicked: root.back()
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

        Loading { visible: Network.wifiScanning && Network.wifiNetworks.length > 0 }

        Button {
            disabled: Network.wifiScanning || !Network.wifiEnabled
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

            // Active network is pinned to the top
            Loader {
                Layout.fillWidth: true
                active: Network.wifiEnabled && Network.active !== null
                visible: active

                sourceComponent: NetworkItem { conn: Network.active }
            }

            Repeater {
                // Diffs each list change, so unchanged networks keep their delegates instead of being rebuilt
                model: ScriptModel {
                    values: [...Network.wifiNetworks]
                }

                NetworkItem {
                    required property var modelData
                    conn: modelData
                    visible: Network.wifiEnabled && !conn.active
                }
            }

            ColumnLayout {
                visible: !Network.wifiEnabled || Network.wifiNetworks.length === 0

                Layout.fillWidth: true
                spacing: Settings.spacing

                Text {
                    text: {
                        if (!Network.wifiEnabled) return "Wi-Fi is turned off"
                        if (Network.wifiScanning) return "Scanning..."
                        return "No networks found"
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
                    visible: Network.wifiEnabled && Network.wifiScanning
                    Layout.fillWidth: true
                }

                Button {
                    visible: !Network.wifiEnabled
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignHCenter
                    size: "md"
                    icon: "wifi-4"
                    text: "Turn on"

                    onClicked: Network.enableWifi(true)
                }
            }
        }
    }
}
