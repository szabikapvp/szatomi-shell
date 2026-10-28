import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.config
import qs.utils
import "../../components"

// Shows the picked option, and opens a list of all of them below, or above when there's more room there.
// Enter, Space or Down opens it, Up and Down move through it, Enter picks and Escape closes
Item {
    id: root

    // Each as { text, value }
    property var options: []
    property var current
    property string size: "md"

    signal picked(var value)

    readonly property int currentIndex: options.findIndex(option => option.value === current)

    Layout.fillWidth: true
    implicitHeight: Settings.buttonHeight[size]
    implicitWidth: Settings.px(200)

    activeFocusOnTab: true
    Keys.onPressed: (event) => {
        if (![Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space, Qt.Key_Down].includes(event.key)) return
        open()
        event.accepted = true
    }

    FocusRing {}

    Rectangle {
        anchors.fill: parent
        radius: Settings.radiusSm
        color: Qt.alpha(Colors.foreground, mouseArea.pressed || popup.visible ? 0.2 : mouseArea.containsMouse ? 0.15 : 0.1)

        Behavior on color { ColorAnim {} }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Settings.buttonPadding[root.size] * 2
            anchors.rightMargin: Settings.buttonPadding[root.size]
            spacing: Settings.spacing

            Text {
                text: root.options[root.currentIndex]?.text ?? ""
                color: Colors.text
                font.pixelSize: Settings.buttonFontSize[root.size]
                font.family: Settings.fontFamily
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Icon {
                icon: "arrow-right"
                size: Settings.buttonIconSize
                color: Colors.text
                rotation: popup.visible ? -90 : 90

                Behavior on rotation { Anim { fast: true } }
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: popup.visible ? popup.close() : root.open()
    }

    // Kept inside the scrolling list around it, which is where the window takes clicks
    function open() {
        let view = parent
        while (view && view.contentY === undefined) view = view.parent

        const gap = Settings.spacing / 2
        const top = view ? root.mapToItem(view, 0, 0).y : 0
        const below = view ? view.height - top - root.height - gap : Settings.dropdownMaxHeight
        const above = view ? top - gap : 0
        const wanted = Math.min(list.contentHeight + popup.padding * 2, Settings.dropdownMaxHeight)
        const down = below >= wanted || below >= above

        popup.height = Math.min(wanted, down ? below : above)
        popup.y = down ? root.height + gap : -popup.height - gap
        popup.open()
    }

    Popup {
        id: popup

        width: root.width
        padding: Settings.spacing / 2
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onOpened: {
            list.currentIndex = Math.max(0, root.currentIndex)
            list.positionViewAtIndex(list.currentIndex, ListView.Center)
            list.forceActiveFocus()
        }
        // The keyboard goes back to where it came from, unless it already moved on
        onAboutToHide: if (list.activeFocus) root.forceActiveFocus()

        enter: Transition { Fade { property: "opacity"; from: 0; to: 1 } }
        exit: Transition { Fade { property: "opacity"; from: 1; to: 0 } }

        background: Rectangle {
            radius: Settings.radiusSm
            color: Colors.background
            border.width: 1
            border.color: Qt.alpha(Colors.foreground, 0.2)
        }

        contentItem: ListView {
            id: list

            clip: true
            model: root.options
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0

            ScrollBar.vertical: StyledScrollBar {}

            Keys.onPressed: (event) => {
                if (![Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].includes(event.key)) return
                pick(currentIndex)
                event.accepted = true
            }

            function pick(index) {
                popup.close()
                if (index >= 0 && index != root.currentIndex) root.picked(root.options[index].value)
            }

            delegate: Rectangle {
                id: option

                required property int index
                required property var modelData
                readonly property bool chosen: index == root.currentIndex

                width: ListView.view.width
                implicitHeight: Settings.buttonHeight.sm
                radius: Settings.radiusSm
                color: ListView.isCurrentItem ? Qt.alpha(Colors.foreground, optionArea.pressed ? 0.2 : 0.1) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Settings.spacing
                    anchors.rightMargin: Settings.spacing
                    spacing: Settings.spacing

                    Text {
                        text: option.modelData.text
                        color: option.chosen ? Colors.primary : Colors.text
                        font.pixelSize: Settings.buttonFontSize.sm
                        font.family: Settings.fontFamily
                        font.bold: option.chosen
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Icon {
                        visible: option.chosen
                        icon: "check"
                        size: Settings.buttonIconSize
                        color: Colors.primary
                    }
                }

                MouseArea {
                    id: optionArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: list.currentIndex = option.index
                    onClicked: list.pick(option.index)
                }
            }
        }
    }
}
