import QtQuick
import QtQuick.Layouts
import "../../components/widgets"

import qs.config
import qs.services

// One display: whether it's used, its resolution, refresh rate, scale and rotation, and what it is.
// Changes apply right away, ones that could leave it dark ask to be kept
ColumnLayout {
    id: root

    signal back()

    // Opened from the Displays settings, so back returns there
    readonly property url parentPage: Qt.resolvedUrl("SettingsPage.qml")
    readonly property var parentProperties: ({ category: "Displays" })

    readonly property int preferredWidth: Settings.settingsPageSize
    height: preferredWidth
    spacing: Settings.spacing * 2

    required property string key
    readonly property var config: Displays.shown.find(config => config.key == key) ?? null
    readonly property var monitor: Displays.monitors.find(monitor => monitor.name == config?.name) ?? null
    readonly property bool on: config != null && !config.disabled
    readonly property bool copying: config != null && config.mirror != ""

    // Kept for the title once the display is unplugged
    property string label
    onConfigChanged: if (config) label = config.label

    // Its screen shows its name while this is open
    Component.onCompleted: Displays.identifiers++
    Component.onDestruction: Displays.identifiers--
    Binding { target: Displays; property: "highlighted"; value: root.config?.name ?? "" }

    PageHeader {
        path: "Settings / Displays"
        title: root.config?.label ?? root.label
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
                visible: !root.config

                text: "This display is no longer connected"
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.weight: 300
                Layout.fillWidth: true
                Layout.preferredHeight: Settings.px(64)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            GroupLabel {
                visible: root.config != null
                text: "Display"
                Layout.topMargin: 0
            }

            Section {
                visible: root.config != null

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Settings.spacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Settings.px(2)

                        Text {
                            text: "Use this display"
                            color: Colors.text
                            font.pixelSize: Settings.fontSize
                            font.family: Settings.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Text {
                            text: !Displays.isLastOn(root.key) ? (root.copying ? "Mirroring " + (Displays.shown.find(other => other.key == root.config.mirror)?.label ?? "") : "Turn it off to use the others only")
                                : Displays.mirroring ? "The others mirror it, so it stays on"
                                : "It's the only display in use, so it stays on"
                            color: Qt.alpha(Colors.text, 0.6)
                            font.pixelSize: Settings.fontSize - Settings.px(2)
                            font.family: Settings.fontFamily
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }

                    Toggle {
                        checked: root.on
                        disabled: Displays.isLastOn(root.key)
                        onToggled: Displays.setEnabled(root.key, !checked)
                    }
                }
            }

            GroupLabel {
                visible: root.on
                text: "Picture"
            }

            Section {
                visible: root.on
                title: "Resolution"

                Dropdown {
                    // Displays list their native mode first
                    options: (root.config?.modes ?? [])
                        .filter((mode, i, modes) => modes.findIndex(other => other.width == mode.width && other.height == mode.height) == i)
                        .map((mode, i) => ({ text: mode.width + " × " + mode.height + (i == 0 ? " · Recommended" : ""), value: mode.width + "x" + mode.height }))
                    current: root.config ? root.config.width + "x" + root.config.height : ""
                    onPicked: (value) => Displays.setResolution(root.key, value)
                }
            }

            Section {
                visible: root.on
                title: "Refresh rate"

                Dropdown {
                    // A rate set in the Hyprland config can be one the display doesn't list, it's still shown as it is
                    options: (root.config?.modes ?? [])
                        .filter(mode => mode.width == root.config.width && mode.height == root.config.height)
                        .map(mode => mode.refresh)
                        .concat(root.config ? [root.config.refresh] : [])
                        .filter((refresh, i, rates) => rates.indexOf(refresh) == i)
                        .sort((a, b) => b - a)
                        .map(refresh => ({
                            text: (Number.isInteger(refresh) ? refresh : refresh.toFixed(2)) + " Hz"
                                + (root.config.modes.some(mode => mode.refresh == refresh && mode.width == root.config.width) ? "" : " (custom)"),
                            value: refresh
                        }))
                    current: root.config?.refresh
                    onPicked: (value) => Displays.change(root.key, { refresh: value })
                }
            }

            // A display mirroring another shows that one's picture, so it has no scale or rotation of its own
            Section {
                visible: root.on && !root.copying
                title: "Scale"
                description: "Size of everything on this display. Only sizes that keep text sharp are offered"

                Choices {
                    options: root.config ? Displays.scales(root.config).map(scale => ({ text: Math.round(scale * 100) + "%", value: scale })) : []
                    current: root.config?.scale
                    onPicked: (value) => Displays.change(root.key, { scale: value })
                }
            }

            Section {
                visible: root.on && !root.copying
                title: "Rotation"

                Choices {
                    options: ["Normal", "90°", "180°", "270°"].map((text, i) => ({ text: text, value: i }))
                        .concat(root.config?.transform >= 4 ? [{ text: "Flipped", value: root.config.transform }] : [])
                    current: root.config?.transform
                    onPicked: (value) => Displays.change(root.key, { transform: value })
                }
            }

            GroupLabel {
                visible: root.monitor != null
                text: "About"
            }

            Section {
                visible: root.monitor != null

                Repeater {
                    model: [
                        ["Port", root.monitor?.name],
                        ["Maker", root.monitor?.make],
                        ["Model", root.monitor?.model],
                        ["Serial", root.monitor?.serial],
                        // Physical size is in millimetres, people know screens by their diagonal in inches
                        ["Size", root.monitor?.physicalWidth > 0
                            ? (Math.hypot(root.monitor.physicalWidth, root.monitor.physicalHeight) / 25.4).toFixed(1) + "″" : ""]
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
}
