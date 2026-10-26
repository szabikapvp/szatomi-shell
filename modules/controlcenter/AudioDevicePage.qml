import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../components"
import "../../components/widgets"

import qs.config
import qs.services

// One output or input device: default, volume, balance, profile, port, and a level meter for inputs
ColumnLayout {
    id: root

    signal back()

    // Opened from the Audio settings, so back returns there
    readonly property url parentPage: Qt.resolvedUrl("SettingsPage.qml")
    readonly property var parentProperties: ({ category: "Audio" })

    readonly property int preferredWidth: Settings.settingsPageSize
    height: preferredWidth
    spacing: Settings.spacing * 2

    property string nodeName
    property string deviceId
    property bool input: false

    // A profile change replaces the node, so it's found again through its device
    readonly property PwNode node: (input ? Audio.inputs : Audio.outputs)
        .find(node => node.name == nodeName) ?? (input ? Audio.inputs : Audio.outputs)
        .find(node => deviceId != "" && node.properties["device.id"] == deviceId) ?? null

    // The device's EnumProfile, Profile, EnumRoute and Route params, from pw-dump. Empty for virtual devices
    property var params: ({})
    readonly property int profile: params.Profile?.[0]?.index ?? -1
    readonly property int cardDevice: Number(node?.properties["card.profile.device"] ?? -1)
    readonly property var profiles: (params.EnumProfile ?? [])
        .filter(entry => entry.name != "off" && (entry.available != "no" || entry.index == profile))
    readonly property var routes: (params.EnumRoute ?? [])
        .filter(entry => entry.direction == (input ? "Input" : "Output") && entry.devices.includes(cardDevice) && entry.profiles.includes(profile))
    readonly property int route: (params.Route ?? []).find(entry => entry.device == cardDevice)?.index ?? -1

    // Kept for the title while a profile leaves the device out
    property string name
    onNodeChanged: {
        if (node) name = Audio.nodeName(node)
        refresh()
    }
    Component.onCompleted: refresh()

    function refresh() {
        if (deviceId != "") dump.running = true
    }

    Process {
        id: dump

        command: ["pw-dump", root.deviceId]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.params = JSON.parse(text)[0]?.info?.params ?? {}
                } catch (error) {
                    root.params = {}
                }
            }
        }
    }

    // pw-cli returns before the device has switched, so read it back a moment later
    Timer {
        id: refreshLater
        interval: 300
        onTriggered: root.refresh()
    }

    PageHeader {
        path: "Settings / Audio / " + (root.input ? "Input" : "Output")
        title: root.node ? Audio.nodeName(root.node) : root.name
        onBack: root.back()
    }

    StyledScrollView {
        id: scrollView

        Layout.fillWidth: true
        Layout.fillHeight: true

        contentHeight: list.implicitHeight

        ColumnLayout {
            id: list

            width: scrollView.availableWidth
            spacing: Settings.spacing

            Text {
                visible: !root.node

                text: root.profiles.length > 0 ? "Not part of this profile, pick another one below" : "This device is no longer available"
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.weight: 300
                Layout.fillWidth: true
                Layout.preferredHeight: Settings.px(64)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Loader {
                active: root.node != null
                visible: active
                Layout.fillWidth: true

                sourceComponent: ColumnLayout {
                    id: details

                    spacing: Settings.spacing

                    readonly property PwNode node: root.node
                    readonly property bool isDefault: Audio.isDefault(node)

                    Section {
                        title: "Default device"
                        description: details.isDefault
                            ? "Apps " + (root.input ? "record from" : "play on") + " this device"
                            : "Apps that follow the default switch over to this device"

                        Button {
                            disabled: details.isDefault
                            size: "sm"
                            icon: ""
                            text: disabled ? "Default" : "Set as default"
                            Layout.fillWidth: false

                            onClicked: Audio.setDefault(root.node)
                        }
                    }

                    Section {
                        title: "Volume"

                        VolumeSlider {
                            volume: root.node.audio.volume
                            muted: root.node.audio.muted
                            icon: root.input ? "mic" : "volume-2"

                            onMoved: (volume) => Audio.setVolume(root.node, volume)
                            onMuteClicked: root.node.audio.muted = !root.node.audio.muted
                        }

                        // Live level of what the device picks up
                        Slider {
                            visible: root.input
                            prop: Math.min(100, peaks.peak * 100)
                            Layout.preferredHeight: Settings.px(6)
                            Layout.topMargin: Settings.spacing / 2
                        }

                        PwNodePeakMonitor {
                            id: peaks
                            node: root.node
                            enabled: root.input
                        }
                    }

                    Section {
                        visible: root.node.audio.channels.length > 1
                        title: "Balance"
                        description: "Volume of each channel"

                        Repeater {
                            model: root.node.audio.channels

                            RowLayout {
                                required property int index
                                required property var modelData

                                spacing: Settings.spacing
                                Layout.fillWidth: true

                                Text {
                                    // FrontLeft reads as Front Left
                                    text: PwAudioChannel.toString(modelData).replace(/([a-z])([A-Z])/g, "$1 $2")
                                    color: Colors.text
                                    font.pixelSize: Settings.fontSize - Settings.px(2)
                                    font.family: Settings.fontFamily
                                    elide: Text.ElideRight
                                    Layout.preferredWidth: list.width / 5
                                }

                                VolumeSlider {
                                    showMute: false
                                    volume: root.node.audio.volumes[index] ?? 0

                                    onMoved: (volume) => Audio.setVolume(root.node, volume, index)
                                }
                            }
                        }

                        Button {
                            size: "sm"
                            icon: ""
                            text: "Center"
                            type: "ghost"
                            textColor: Colors.text
                            Layout.fillWidth: false

                            // Setting the overall volume gives every channel the same level
                            onClicked: root.node.audio.volume = root.node.audio.volume
                        }
                    }
                }
            }

            // Outside the node's part, so a profile without this device can still be switched back
            Section {
                visible: root.profiles.length > 0
                title: "Profile"
                description: "How the device is set up, which can change the other devices it offers"

                Repeater {
                    model: root.profiles

                    Button {
                        required property var modelData
                        readonly property bool selected: modelData.index == root.profile

                        size: "sm"
                        icon: selected ? "check" : ""
                        text: modelData.description
                        type: selected ? "primary" : "ghost"
                        color: selected ? Qt.alpha(Colors.foreground, 0.1) : Colors.foreground
                        textColor: Colors.text

                        onClicked: {
                            Audio.setProfile(root.deviceId, modelData.index)
                            refreshLater.restart()
                        }
                    }
                }
            }

            Section {
                visible: root.routes.length > 1
                title: "Port"
                description: "Where on the device the sound " + (root.input ? "comes from" : "goes to")

                Repeater {
                    model: root.routes

                    Button {
                        required property var modelData
                        readonly property bool selected: modelData.index == root.route

                        disabled: modelData.available == "no"
                        size: "sm"
                        icon: selected ? "check" : ""
                        text: modelData.description + (disabled ? " (unplugged)" : "")
                        type: selected ? "primary" : "ghost"
                        color: selected ? Qt.alpha(Colors.foreground, 0.1) : Colors.foreground
                        textColor: Colors.text

                        onClicked: {
                            Audio.setRoute(root.deviceId, modelData.index, root.cardDevice)
                            refreshLater.restart()
                        }
                    }
                }
            }

            Section {
                visible: root.node != null
                title: "Details"

                Repeater {
                    model: [
                        ["Name", root.node?.name],
                        ["Driver", root.node?.properties["device.api"]],
                        ["Bus", root.node?.properties["device.bus"]],
                        ["Channels", root.node?.audio.channels.length]
                    ].filter(row => row[1])

                    RowLayout {
                        required property var modelData

                        spacing: Settings.spacing
                        Layout.fillWidth: true

                        Text {
                            text: modelData[0]
                            color: Qt.alpha(Colors.text, 0.6)
                            font.pixelSize: Settings.fontSize - Settings.px(2)
                            font.family: Settings.fontFamily
                            Layout.preferredWidth: list.width / 5
                        }

                        Text {
                            text: modelData[1]
                            color: Colors.text
                            font.pixelSize: Settings.fontSize - Settings.px(2)
                            font.family: Settings.fontFamily
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // A titled card like a settings row, children stack below the title
    component Section: Rectangle {
        id: section

        property string title
        property string description
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: column.implicitHeight + Settings.spacing * 3

        radius: Settings.radiusMd
        color: Colors.backgroundSubtle

        ColumnLayout {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Settings.spacing * 1.5
            anchors.verticalCenter: parent.verticalCenter

            spacing: Settings.spacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Settings.px(2)

                Text {
                    text: section.title
                    color: Colors.text
                    font.pixelSize: Settings.fontSize
                    font.family: Settings.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    visible: text != ""
                    text: section.description
                    color: Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                id: body

                Layout.fillWidth: true
                spacing: Settings.spacing / 2
            }
        }
    }
}
