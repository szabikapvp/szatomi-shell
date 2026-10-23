import QtQuick

import qs.config

// Base for every control center widget. The grid sets its size in cells and listens to its signals
Rectangle {
    id: root

    property int columns: 1
    property int rows: 1

    // Asks the grid to start editing
    signal held()
    // Asks the control center to open this widget's page
    signal pageRequested()

    radius: Settings.radiusLg
    color: Colors.backgroundSubtle

    // Sits below the content, so holds on parts without their own mouse handling still reach the grid
    MouseArea {
        anchors.fill: parent
        pressAndHoldInterval: Settings.controlCenterHoldDuration
        onPressAndHold: root.held()
    }
}
