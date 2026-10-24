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

    Component.onCompleted: Network.rescanWifi()

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

    PageHeader {
        title: "Wi-Fi"
        onBack: root.back()

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

        ScrollBar.vertical: StyledScrollBar {}

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
                    Layout.preferredHeight: Settings.px(64)
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
