import QtQuick
import QtQuick.Layouts
import "../../components/widgets"

import qs.config

// One setting from the schema, with the control its type calls for and a reset once it's changed
Rectangle {
    id: root

    required property var entry
    property bool showCategory: false

    readonly property var current: Settings[entry.key]
    readonly property bool modified: Settings.isModified(entry.key)
    // Small controls sit next to the label, the rest get a line of their own
    readonly property bool inline: entry.type == "bool" || entry.type == "choice"

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Settings.spacing * 3

    radius: Settings.radiusMd
    color: Colors.backgroundSubtle

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
                spacing: 2

                Text {
                    visible: root.showCategory
                    text: root.entry.category
                    color: Colors.primary
                    font.pixelSize: Settings.fontSize - 4
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
                    text: root.entry.description ?? ""
                    color: Qt.alpha(Colors.text, 0.6)
                    font.pixelSize: Settings.fontSize - 2
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
            sourceComponent: root.entry.type == "int" ? slider : textField
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

        RowLayout {
            spacing: Settings.spacing / 2

            Repeater {
                model: root.entry.options

                Button {
                    required property string modelData

                    size: "sm"
                    icon: ""
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    color: root.current == modelData ? Colors.primary : Qt.alpha(Colors.foreground, 0.1)
                    textColor: Colors.text
                    Layout.fillWidth: false

                    onClicked: Settings.set(root.entry.key, modelData)
                }
            }
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

    // Fonts and formats. Typing only saves once the text is usable, anything else goes back to the saved value
    Component {
        id: textField

        ColumnLayout {
            id: editor

            spacing: Settings.spacing

            readonly property bool isFont: root.entry.type == "font"
            // Fonts match regardless of case, and save under their real name
            readonly property string match: isFont
                ? (Settings.schema.fonts.find(family => family.toLowerCase() == field.text.trim().toLowerCase()) ?? "")
                : field.text
            readonly property bool valid: isFont ? match != "" : field.text.trim() != "" && field.text.length <= Settings.schema.maxFormatLength
            readonly property bool edited: field.text != root.current

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

            Text {
                visible: !editor.isFont
                text: "Preview: " + Qt.formatDateTime(new Date(), field.text)
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - 2
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
