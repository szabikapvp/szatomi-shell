import QtQuick
import QtQuick.Layouts
import "../../components/widgets"
import "widgets"

import qs.config
import qs.services

ColumnLayout {
    id: root

    signal back()
    signal closeRequested()

    // Actions that end the session need a second click
    property string armed: ""

    readonly property var actions: [
        { action: "shutdown", icon: "power", text: "Shut down", confirm: true },
        { action: "restart", icon: "reload", text: "Restart", confirm: true },
        { action: "sleep", icon: "sleep", text: "Sleep", confirm: false },
        { action: "logout", icon: "logout", text: "Log out", confirm: true },
        { action: "lock", icon: "lock", text: "Lock", confirm: false }
    ]
    // As large as a grid cell, smaller when the page is too narrow for all of them in a row
    readonly property int buttonSize: Math.min(Settings.controlCenterCellSize, (width - row.spacing * (actions.length - 1)) / actions.length)

    spacing: Settings.spacing * 2

    Timer {
        id: disarm
        interval: Settings.powerConfirmTimeout
        onTriggered: root.armed = ""
    }

    PageHeader {
        title: "Power"
        onBack: root.back()
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.backgroundSubtle
    }

    RowLayout {
        id: row

        Layout.fillWidth: true
        spacing: Settings.spacing

        Repeater {
            model: root.actions

            ColumnLayout {
                id: item

                required property var modelData
                readonly property bool isArmed: root.armed == modelData.action

                // Equal columns, whatever the label lengths
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: Settings.spacing / 2

                ButtonTile {
                    icon: item.modelData.icon
                    active: item.isArmed
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.buttonSize
                    Layout.preferredHeight: root.buttonSize

                    onClicked: root.run(item.modelData)
                }

                Text {
                    text: item.isArmed ? "Confirm" : item.modelData.text
                    color: item.isArmed ? Colors.primary : Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    font.bold: item.isArmed
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    function run(item) {
        if (item.confirm && armed != item.action) {
            armed = item.action
            disarm.restart()
            return
        }

        root.closeRequested()
        Power.run(item.action)
    }
}
