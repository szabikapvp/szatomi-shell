import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import "../../components/widgets"

import qs.config
import qs.services

// App launcher, works like wofi: type to filter, arrows or Tab to pick, Enter or a click to launch.
// Starting with ">" searches the shell's commands instead
ColumnLayout {
    id: root

    // Typed before the page opened, so the first key isn't lost
    property string query: ""

    readonly property int preferredWidth: Settings.launcherWidth
    readonly property int panelPadding: Settings.launcherPadding
    readonly property bool commandMode: searchField.text.startsWith(">")
    readonly property var results: commandMode ? commands.search(searchField.text.slice(1)) : Apps.search(searchField.text)
    // Starts on the best match for every search, like wofi
    property int selected: 0
    onResultsChanged: {
        selected = 0
        armed = ""
    }

    // Keyword of the command waiting for a second Enter
    property string armed: ""

    onSelectedChanged: list.positionViewAtIndex(selected, ListView.Contain)

    signal back()
    signal closeRequested()
    signal pageRequested(url page, var properties)

    Commands { id: commands }

    ScriptModel {
        id: appModel
        values: root.commandMode ? [] : root.results
    }

    ScriptModel {
        id: commandModel
        values: root.commandMode ? root.results : []
    }

    Timer {
        id: disarm
        interval: Settings.powerConfirmTimeout
        onTriggered: root.armed = ""
    }

    height: Settings.launcherHeight
    spacing: Settings.spacing

    readonly property Item initialFocus: searchField
    Component.onCompleted: searchField.text = query

    function launch(index) {
        if (index < 0 || index >= results.length) return
        if (commandMode) {
            run(results[index])
            return
        }
        Apps.launch(results[index])
        closeRequested()
    }

    function run(command) {
        if (command.confirm && armed != command.keyword) {
            armed = command.keyword
            disarm.restart()
            return
        }

        Apps.count(">" + command.keyword)
        if (command.page) pageRequested(command.page, command.pageProperties ?? {})
        else {
            command.run()
            closeRequested()
        }
    }

    InputField {
        id: searchField

        // Blends into the panel, lined up with the app icons below
        size: "md"
        backgroundColor: "transparent"
        paddingLeft: Settings.spacing
        icon: "search"
        placeholderText: "Search apps, or type > for commands"
        radius: Settings.radiusLg
        focusRing: false

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

        // Diffs each search, so items that still match keep their delegates. Each mode has its own model,
        // so switching rebuilds the list instead of diffing app rows into command rows
        model: root.commandMode ? commandModel : appModel

        delegate: LauncherItem {
            required property var modelData
            required property int index

            width: ListView.view.width
            // Old rows can update once more before the list swaps models, so each row checks what it holds
            readonly property bool isCommand: modelData.keyword !== undefined

            selected: index == root.selected
            text: modelData.name
            image: isCommand ? "" : Quickshell.iconPath(modelData.icon, "application-x-executable")
            icon: isCommand ? modelData.icon : ""
            detail: !isCommand ? "" : root.armed == modelData.keyword ? "Enter again to confirm" : ">" + modelData.keyword
            detailColor: root.armed == modelData.keyword ? Colors.primary : Qt.alpha(Colors.text, 0.6)

            onHovered: root.selected = index
            onClicked: root.launch(index)
        }

        Text {
            visible: list.count == 0
            anchors.fill: parent
            text: root.commandMode ? "No commands found" : "No apps found"
            color: Colors.text
            font.pixelSize: Settings.fontSize
            font.family: Settings.fontFamily
            font.weight: 300
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
