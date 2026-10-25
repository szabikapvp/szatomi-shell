import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import "../../components/widgets"

import qs.config
import qs.services

// App launcher, works like wofi: type to filter, arrows or Tab to pick, Enter or a click to launch
ColumnLayout {
    id: root

    // Typed before the page opened, so the first key isn't lost
    property string query: ""

    readonly property int preferredWidth: Settings.launcherWidth
    readonly property int panelPadding: Settings.launcherPadding
    readonly property var results: Apps.search(searchField.text)
    // Starts on the best match for every search, like wofi
    property int selected: 0
    onResultsChanged: selected = 0
    onSelectedChanged: list.positionViewAtIndex(selected, ListView.Contain)

    signal back()
    signal closeRequested()

    height: Settings.launcherHeight
    spacing: Settings.spacing

    Component.onCompleted: {
        searchField.text = query
        searchField.forceActiveFocus()
    }

    function launch(index) {
        if (index < 0 || index >= results.length) return
        Apps.launch(results[index])
        closeRequested()
    }

    InputField {
        id: searchField

        // Blends into the panel, lined up with the app icons below
        size: "md"
        backgroundColor: "transparent"
        paddingLeft: Settings.spacing
        icon: "search"
        placeholderText: "Search"
        radius: Settings.radiusLg

        onAccepted: root.launch(root.selected)

        Keys.onPressed: (event) => {
            const page = Math.max(1, Math.floor(list.height / Settings.launcherItemHeight))
            let step

            switch (event.key) {
                case Qt.Key_Down:
                case Qt.Key_Tab:
                    step = 1
                    break
                case Qt.Key_Up:
                case Qt.Key_Backtab:
                    step = -1
                    break
                case Qt.Key_PageDown:
                    step = page
                    break
                case Qt.Key_PageUp:
                    step = -page
                    break
                default:
                    return
            }
            root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + step))
            event.accepted = true
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: StyledScrollBar {}

        // Diffs each search, so apps that still match keep their delegates
        model: ScriptModel {
            values: root.results
        }

        delegate: LauncherItem {
            required property var modelData
            required property int index

            width: ListView.view.width
            entry: modelData
            selected: index == root.selected

            onHovered: root.selected = index
            onClicked: root.launch(index)
        }

        Text {
            visible: list.count == 0
            anchors.fill: parent
            text: "No apps found"
            color: Colors.text
            font.pixelSize: Settings.fontSize
            font.family: Settings.fontFamily
            font.weight: 300
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
