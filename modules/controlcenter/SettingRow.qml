import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils

// One setting from the schema, with the control its type calls for and a reset once it's changed
Rectangle {
    id: root

    required property var entry
    property bool showCategory: false

    // Asks the control center to open a page, like the wallpaper selector
    signal pageRequested(url page, var properties)

    readonly property var current: Settings.stored(entry.key)
    readonly property bool modified: Settings.isModified(entry.key)
    // Taken over by another setting while that one is on
    readonly property bool overridden: entry.overriddenBy !== undefined && Settings.stored(entry.overriddenBy) === true
    // Small controls sit next to the label, the rest get a line of their own
    readonly property bool inline: entry.type == "bool" || entry.type == "choice"

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Settings.spacing * 3

    radius: Settings.radiusMd
    color: Colors.backgroundSubtle

    enabled: !overridden
    opacity: overridden ? 0.5 : 1

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Settings.spacing * 1.5
        anchors.verticalCenter: parent.verticalCenter

        spacing: Settings.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Settings.spacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Settings.px(2)

                Text {
                    visible: root.showCategory
                    text: root.entry.category
                    color: Colors.primary
                    font.pixelSize: Settings.fontSize - Settings.px(4)
                    font.family: Settings.fontFamily
                    font.bold: true
                }

                Text {
                    text: root.entry.label
                    color: Colors.text
                    font.pixelSize: Settings.fontSize
                    font.family: Settings.fontFamily
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: text != ""
                    text: root.overridden ? "Generated from the wallpaper" : root.entry.description ?? ""
                    color: Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            Button {
                visible: root.modified
                icon: "reload"
                iconOnly: true
                size: "sm"
                type: "ghost"
                textColor: Colors.text
                Layout.fillWidth: false

                onClicked: Settings.reset(root.entry.key)
            }

            Text {
                visible: root.entry.type == "int"
                text: Math.round(below.item?.shownValue ?? root.current) + (root.entry.unit ? " " + root.entry.unit : "")
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: true
            }

            Loader {
                active: root.inline
                sourceComponent: root.entry.type == "bool" ? toggle : choice
            }
        }

        Loader {
            id: below

            active: !root.inline
            // An inactive Loader still takes up layout spacing
            visible: active
            Layout.fillWidth: true
            sourceComponent: ({
                int: slider, wallpaper: wallpaperEditor, mixer: mixer, devices: devices, shortcut: shortcut,
                displayMode: displayMode, arrangement: arrangement, display: displayPicker, displays: displayList
            })[root.entry.type] ?? textField
        }
    }

    Component {
        id: toggle
        
        Toggle {
            checked: root.current
            onToggled: Settings.set(root.entry.key, !root.current)
        }
    }

    Component {
        id: choice

        Choices {
            options: root.entry.options.map(option => ({ text: option.charAt(0).toUpperCase() + option.slice(1), value: option }))
            current: root.current
            onPicked: (value) => Settings.set(root.entry.key, value)
        }
    }

    Component {
        id: slider

        ValueSlider {
            from: root.entry.min
            to: root.entry.max
            stepSize: root.entry.step
            value: root.current

            onMoved: (value) => Settings.set(root.entry.key, value)
        }
    }

    // The wallpaper of every display or of the one picked, and the way to the selector
    Component {
        id: wallpaperEditor

        ColumnLayout {
            spacing: Settings.spacing

            // Each display can have its own once there are several. The selector sets the one picked here
            Dropdown {
                visible: Displays.arrangedCount > 1
                options: [{ text: "All displays", value: "" }].concat(Displays.arranged.map(config => ({ text: config.label, value: config.key })))
                current: Wallpaper.target
                onPicked: (value) => Wallpaper.target = value
            }

            ClippingRectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: width * 9 / 16

                radius: Settings.radiusSm
                color: Colors.background

                Image {
                    anchors.fill: parent
                    source: Wallpaper.selected ? "file://" + Wallpaper.selected : ""
                    sourceSize.width: width
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Settings.spacing

                Text {
                    text: Wallpaper.selected ? Wallpaper.selected.split("/").pop() : "No wallpaper"
                    color: Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                Loading { visible: Wallpaper.generating }

                Button {
                    size: "sm"
                    icon: ""
                    text: "Change"
                    Layout.fillWidth: false

                    onClicked: root.pageRequested(Qt.resolvedUrl("WallpaperPage.qml"), { fromSettings: true })
                }
            }
        }
    }

    // The combo as key caps. Change hands the keyboard to the row until a usable combo is pressed,
    // Escape cancels, and anything unusable is explained without saving
    Component {
        id: shortcut

        ColumnLayout {
            id: recorder

            readonly property bool recording: Shortcuts.recording == root.entry.key
            readonly property string problem: Shortcuts.messageKey == root.entry.key ? Shortcuts.message : ""
            readonly property bool blocked: Shortcuts.configRead && Shortcuts.usedByConfig(root.current)

            spacing: Settings.spacing

            Keys.onPressed: (event) => {
                if (!recording || event.isAutoRepeat) return
                Shortcuts.press(event)
                event.accepted = true
            }
            Keys.onReleased: (event) => {
                if (!recording || event.isAutoRepeat) return
                Shortcuts.release(event)
                event.accepted = true
            }

            // Clicking or tabbing away cancels, so the keyboard never stays taken
            onActiveFocusChanged: if (!activeFocus && recording) Shortcuts.stopRecording()
            Component.onDestruction: if (recording) Shortcuts.stopRecording()

            RowLayout {
                Layout.fillWidth: true
                spacing: Settings.spacing / 2

                Repeater {
                    model: recorder.recording ? [] : Shortcuts.keys(root.current)

                    Rectangle {
                        required property string modelData

                        implicitWidth: Math.max(implicitHeight, capText.implicitWidth + Settings.spacing * 2)
                        implicitHeight: Settings.buttonHeight.sm
                        radius: Settings.radiusSm
                        color: Qt.alpha(Colors.foreground, 0.1)
                        border.width: 1
                        border.color: Qt.alpha(Colors.foreground, 0.2)
                        opacity: recorder.blocked ? 0.5 : 1

                        Text {
                            id: capText
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Colors.text
                            font.pixelSize: Settings.fontSize - Settings.px(2)
                            font.family: Settings.fontFamily
                            font.bold: true
                        }
                    }
                }

                Text {
                    visible: recorder.recording
                    text: "Press the new shortcut · Esc to cancel"
                    color: Colors.primary
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.preferredHeight: Settings.buttonHeight.sm
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Button {
                    size: "sm"
                    icon: ""
                    text: recorder.recording ? "Cancel" : "Change"
                    type: recorder.recording ? "ghost" : "primary"
                    textColor: recorder.recording ? Colors.text : Colors.background
                    Layout.fillWidth: false

                    onClicked: {
                        if (recorder.recording) {
                            Shortcuts.stopRecording()
                            return
                        }
                        Shortcuts.startRecording(root.entry.key)
                        recorder.forceActiveFocus()
                    }
                }
            }

            Text {
                visible: text != ""
                text: recorder.problem != "" ? recorder.problem
                    : recorder.blocked ? "Your Hyprland config already uses " + Shortcuts.format(root.current) + ", so this one is off until it's changed"
                    : ""
                color: Colors.primary
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }

    // Every app that plays or could play sound, each with its own volume
    Component {
        id: mixer

        ColumnLayout {
            spacing: Settings.spacing * 1.5

            // Apps connect and disconnect without Pipewire saying so, so look again every so often
            Timer {
                running: true
                repeat: true
                triggeredOnStart: true
                interval: Settings.audioClientRefresh
                onTriggered: Audio.refreshClients()
            }

            Repeater {
                // Matched by app, so a row stays put while its streams come and go
                model: ScriptModel {
                    values: Audio.apps
                    objectProp: "key"
                }

                AudioAppItem {
                    required property var modelData
                    app: modelData
                }
            }

            Text {
                visible: Audio.apps.length === 0
                text: "No apps are using sound"
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                Layout.fillWidth: true
            }
        }
    }

    // Outputs or inputs, each opening its own page
    Component {
        id: devices

        ColumnLayout {
            id: deviceList

            readonly property var nodes: root.entry.input ? Audio.inputs : Audio.outputs

            spacing: 0

            Repeater {
                model: ScriptModel { values: deviceList.nodes }

                AudioDeviceItem {
                    required property var modelData
                    node: modelData

                    onClicked: root.pageRequested(Qt.resolvedUrl("AudioDevicePage.qml"), {
                        nodeName: node.name,
                        deviceId: node.properties["device.id"] ?? "",
                        input: !node.isSink
                    })
                }
            }

            Text {
                visible: deviceList.nodes.length === 0
                text: "No devices found"
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                Layout.fillWidth: true
            }
        }
    }

    // Extending or mirroring, and which display the others mirror
    Component {
        id: displayMode

        ColumnLayout {
            spacing: Settings.spacing / 2

            Choices {
                options: [{ text: "Extend", value: false }, { text: "Mirror", value: true }]
                current: Displays.mirroring
                onPicked: (value) => Displays.setMirrorSource(value ? Displays.defaultSource() : "")
            }

            Text {
                visible: Displays.mirroring
                text: "Picture from"
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                Layout.topMargin: Settings.spacing / 2
            }

            Choices {
                visible: Displays.mirroring
                options: Displays.shown.filter(config => !config.disabled).map(config => ({ text: config.label, value: config.key }))
                current: Displays.mirrorSource
                onPicked: (value) => Displays.setMirrorSource(value)
            }
        }
    }

    Component {
        id: arrangement

        DisplayArrangement {
            onOpened: (key) => root.pageRequested(Qt.resolvedUrl("DisplayPage.qml"), { key: key })
        }
    }

    // Automatic follows whichever display is built in, or the first, so unplugging the picked one never strands the bar
    Component {
        id: displayPicker

        Dropdown {
            options: [{ text: "Automatic", value: "" }].concat(Displays.arranged.map(config => ({ text: config.label, value: config.key })))
            // One that isn't connected right now leaves it automatic
            current: Displays.arranged.some(config => config.key == root.current) ? root.current : ""
            onPicked: (value) => Settings.set(root.entry.key, value)
        }
    }

    // Every connected display, each opening its own page, and the way back to the Hyprland config
    Component {
        id: displayList

        ColumnLayout {
            spacing: 0

            Repeater {
                model: Displays.shown

                DisplayItem {
                    required property var modelData
                    config: modelData

                    onClicked: root.pageRequested(Qt.resolvedUrl("DisplayPage.qml"), { key: config.key })
                }
            }

            Text {
                visible: Displays.shown.length === 0
                text: "No displays found"
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                Layout.fillWidth: true
            }

            RowLayout {
                visible: Displays.saved
                Layout.fillWidth: true
                Layout.topMargin: Settings.spacing
                spacing: Settings.spacing

                Text {
                    text: "Changes are saved for this set of displays"
                    color: Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - Settings.px(2)
                    font.family: Settings.fontFamily
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Button {
                    size: "sm"
                    icon: ""
                    text: "Use Hyprland config"
                    type: "ghost"
                    color: Colors.foreground
                    textColor: Colors.text
                    Layout.fillWidth: false

                    onClicked: Displays.useConfig()
                }
            }
        }
    }

    // Fonts, formats, paths and colors. Typing only saves once the text is usable, anything else goes back to the saved value
    Component {
        id: textField

        ColumnLayout {
            id: editor

            spacing: Settings.spacing

            readonly property bool isFont: root.entry.type == "font"
            readonly property bool isColor: root.entry.type == "color"
            // Fonts match regardless of case, and save under their real name. Colors take the # as optional
            readonly property string match: isFont
                ? (Settings.schema.fonts.find(family => family.toLowerCase() == field.text.trim().toLowerCase()) ?? "")
                : isColor ? "#" + field.text.trim().replace(/^#/, "") : field.text
            readonly property bool valid: Settings.schema.sanitize(root.entry, match) !== undefined
            readonly property bool edited: field.text != root.current

            RowLayout {
                Layout.fillWidth: true
                spacing: Settings.spacing

                // Shows what's typed once it's a color, the saved one until then
                Rectangle {
                    visible: editor.isColor
                    Layout.preferredWidth: Settings.buttonHeight.md
                    Layout.preferredHeight: Settings.buttonHeight.md
                    radius: Settings.radiusSm
                    color: editor.valid ? editor.match : root.current
                    border.width: 1
                    border.color: Qt.alpha(Colors.foreground, 0.2)
                }

                InputField {
                    id: field

                    size: "md"
                    text: root.current
                    textColor: editor.valid ? Colors.text : Colors.primary
                    rightIcon: editor.edited ? (editor.valid ? "check" : "close") : ""

                    onAccepted: editor.commit()
                    onRightIconClicked: editor.commit()
                    onActiveFocusChanged: if (!activeFocus) editor.commit()
                }
            }

            Text {
                visible: root.entry.type == "format"
                text: "Preview: " + Qt.formatDateTime(new Date(), field.text)
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Installed fonts containing what's typed
            Flow {
                visible: editor.isFont && field.activeFocus && editor.edited
                spacing: Settings.spacing / 2
                Layout.fillWidth: true

                Repeater {
                    model: {
                        const query = field.text.trim().toLowerCase()
                        return query == "" ? [] : Settings.schema.fonts.filter(family => family.toLowerCase().includes(query)).slice(0, 6)
                    }

                    Button {
                        required property string modelData

                        size: "sm"
                        icon: ""
                        text: modelData
                        type: "ghost"
                        color: Colors.foreground
                        textColor: Colors.text
                        Layout.fillWidth: false

                        onClicked: {
                            field.text = modelData
                            editor.commit()
                        }
                    }
                }
            }

            function commit() {
                if (edited && valid) Settings.set(root.entry.key, match)
                // Brings back the binding, which also undoes anything unusable
                field.text = Qt.binding(() => root.current)
            }
        }
    }
}
