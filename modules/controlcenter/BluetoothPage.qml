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

    // Discovery only runs while this page is open
    Component.onCompleted: Bluetooth.startScan()
    Component.onDestruction: Bluetooth.stopScan()

    // Scan whenever the adapter comes up while the page is open
    Connections {
        target: Bluetooth
        function onEnabledChanged() {
            if (Bluetooth.enabled && root.visible) Bluetooth.startScan()
        }
    }

    PageHeader {
        title: "Bluetooth"
        onBack: root.back()

        Loading { visible: Bluetooth.discovering && Bluetooth.devices.length > 0 }

        Button {
            disabled: Bluetooth.discovering || !Bluetooth.enabled
            icon: "reload"
            iconOnly: true
            size: "md"
            type: "ghost"
            textColor: Colors.text
            Layout.fillWidth: false

            onClicked: Bluetooth.startScan()
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
        contentHeight: deviceList.implicitHeight

        ScrollBar.vertical: StyledScrollBar {}

        ColumnLayout {
            id: deviceList

            width: scrollView.availableWidth

            Repeater {
                // Diffs each new array, so unchanged devices keep their delegates instead of being rebuilt
                model: ScriptModel {
                    values: Bluetooth.enabled ? Bluetooth.devices : []
                }

                BluetoothItem {
                    required property var modelData
                    device: modelData
                }
            }

            ColumnLayout {
                visible: !Bluetooth.enabled || Bluetooth.devices.length === 0

                Layout.fillWidth: true
                spacing: Settings.spacing

                Text {
                    text: {
                        if (!Bluetooth.available) return "No Bluetooth adapter found"
                        if (Bluetooth.blocked) return "Bluetooth is blocked"
                        if (!Bluetooth.enabled) return "Bluetooth is turned off"
                        if (Bluetooth.discovering) return "Scanning..."
                        return "No devices found"
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
                    visible: Bluetooth.enabled && Bluetooth.discovering
                    Layout.fillWidth: true
                }

                Button {
                    visible: Bluetooth.available && !Bluetooth.enabled
                    disabled: Bluetooth.blocked
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignHCenter
                    size: "md"
                    icon: "bluetooth"
                    text: "Turn on"

                    onClicked: Bluetooth.setEnabled(true)
                }
            }
        }
    }
}
