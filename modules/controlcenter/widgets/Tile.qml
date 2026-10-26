import QtQuick
import "../../../components/widgets"

import qs.config

// Base for every control center widget. The grid sets its size in cells and listens to its signals
Rectangle {
    id: root

    property int columns: 1
    property int rows: 1

    // The grid sizes a tile only after creating it, so animations wait for that first layout
    property bool settled: false
    Component.onCompleted: Qt.callLater(() => settled = true)

    // Asks the grid to start editing
    signal held()
    // Asks the control center to open this widget's page
    signal pageRequested()
    // Enter or Space, the keyboard's click
    signal activated()
    // An arrow along adjustAxis, 1 towards more
    signal stepped(int direction)

    // Tiles that do something take the keyboard. Shift+Enter or the menu key opens the page, like a right click
    property bool interactive: false
    // "vertical" or "horizontal" for tiles whose arrows change a value, the other arrows still move between tiles
    property string adjustAxis: ""

    activeFocusOnTab: interactive
    Keys.onPressed: (event) => {
        const enter = event.key == Qt.Key_Return || event.key == Qt.Key_Enter || event.key == Qt.Key_Space
        const vertical = event.key == Qt.Key_Up || event.key == Qt.Key_Down
        const horizontal = event.key == Qt.Key_Left || event.key == Qt.Key_Right

        if (event.key == Qt.Key_Menu || enter && (event.modifiers & Qt.ShiftModifier)) root.pageRequested()
        else if (enter) root.activated()
        else if (vertical && adjustAxis == "vertical") root.stepped(event.key == Qt.Key_Up ? 1 : -1)
        else if (horizontal && adjustAxis == "horizontal") root.stepped(event.key == Qt.Key_Right ? 1 : -1)
        else return
        event.accepted = true
    }

    radius: Settings.radiusLg
    color: Colors.backgroundSubtle

    // Sits below the content, so holds on parts without their own mouse handling still reach the grid
    MouseArea {
        anchors.fill: parent
        pressAndHoldInterval: Settings.controlCenterHoldDuration
        onPressAndHold: root.held()
    }

    FocusRing {}
}
