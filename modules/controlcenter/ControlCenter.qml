import Quickshell
import Quickshell.Io
import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils

PanelWindow {
    id: root
    
    property int panelWidth: grid.implicitWidth + panelPadding * 2
    property int panelPadding: Settings.controlCenterPadding
    property int marginSize: Settings.windowSpacing

    // The grid, or a page opened from it
    property Item visiblePage: pageLoader.item ?? mainPage
    property bool showing: false
    visible: panel.progress > 0

    // Pages and editing end once the panel is fully hidden, so nothing changes mid animation
    onVisibleChanged: {
        if (visible) return
        pageLoader.source = ""
        grid.editing = false
    }

    // Resting position for the remembered corner
    property real cornerX: panelState.right ? panel.parent.width - panel.width - marginSize : marginSize
    property real cornerY: panelState.bottom ? panel.parent.height - panel.height - marginSize : marginSize

    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true

        onFileChanged: {
            if (!showing) open()
            else close()
        }
    }

    // Remembers the corner across restarts
    FileView {
        path: Quickshell.statePath("controlcenter.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: panelState
            property bool right: true
            property bool bottom: true
            property var widgets: null
        }
    }

    // Fullscreen so the panel can be dragged anywhere, the mask lets clicks through elsewhere
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region { item: panel }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: Fullscreen.exclusionMode(screen)

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    aboveWindows: true

    Shortcut {
        sequences: Settings.backShortcuts
        onActivated: back()
    }

    // One shared progress drives both axes, so the snap always moves in a straight line
    property real snapProgress: 0
    property point snapFrom

    onSnapProgressChanged: {
        if (!snap.running) return
        panel.x = snapFrom.x + (cornerX - snapFrom.x) * snapProgress
        panel.y = snapFrom.y + (cornerY - snapFrom.y) * snapProgress
    }

    NumberAnimation {
        id: snap

        target: root
        property: "snapProgress"
        from: 0
        to: 1
        duration: Settings.snapDuration
        easing.type: Easing.OutCubic

        // Dragging broke the bindings, restore them so page height changes keep the corner
        onFinished: {
            panel.x = Qt.binding(() => cornerX)
            panel.y = Qt.binding(() => cornerY)
        }
    }

    PopMask {
        id: panel

        x: cornerX
        y: cornerY
        width: panelWidth
        height: visiblePage.height + panelPadding * 2

        fromRight: panelState.right
        fromBottom: panelState.bottom
        radius: Settings.radiusLg

        Rectangle {
            id: osdRect

            anchors.fill: parent

            BackGesture {
                onTriggered: back()
            }

            // Only reachable on empty parts, the content on top takes its own clicks
            MouseArea {
                anchors.fill: parent
                drag.target: panel
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: panel.parent.width - panel.width
                drag.maximumY: panel.parent.height - panel.height
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                pressAndHoldInterval: Settings.controlCenterHoldDuration

                // Holding still on empty space edits the grid, same as holding a widget
                onPressAndHold: if (!pageLoader.item) grid.editing = true

                // Dragging moves the panel from C++, which leaves the corner bindings alive.
                // Break them here, or changing the corner on release jumps the panel there
                drag.onActiveChanged: {
                    if (!drag.active) return
                    panel.x = panel.x
                    panel.y = panel.y
                }

                onReleased: {
                    snapFrom = Qt.point(panel.x, panel.y)
                    panelState.right = panel.x + panel.width / 2 > panel.parent.width / 2
                    panelState.bottom = panel.y + panel.height / 2 > panel.parent.height / 2
                    snap.restart()
                }
            }

            // The small corner faces the screen corner
            radius: Settings.radiusLg
            property int calculatedRadius: Settings.radiusLg + panelPadding
            topLeftRadius: !panelState.right && !panelState.bottom ? Settings.radiusSm : calculatedRadius
            topRightRadius: panelState.right && !panelState.bottom ? Settings.radiusSm : calculatedRadius
            bottomLeftRadius: !panelState.right && panelState.bottom ? Settings.radiusSm : calculatedRadius
            bottomRightRadius: panelState.right && panelState.bottom ? Settings.radiusSm : calculatedRadius

            color: Colors.background
            border.width: 1
            border.color: Colors.backgroundSubtle

            // Pages stay at the panel's corner while a resize animates
            Item {
                x: panel.contentX
                y: panel.contentY
                width: panel.width
                height: panel.height

                ColumnLayout {
                    id: mainPage

                    visible: root.visiblePage == this

                    x: panelPadding
                    y: panelPadding
                    width: parent.width - panelPadding * 2

                    spacing: Settings.spacing * 2

                    PageHeader {
                        visible: grid.editing
                        title: "Edit layout"
                        showBack: false

                        Button {
                            icon: "add"
                            iconOnly: true
                            size: "md"
                            type: "ghost"
                            textColor: Colors.text
                            Layout.fillWidth: false

                            onClicked: openPage(Qt.resolvedUrl("WidgetPicker.qml"), { grid: grid })
                        }

                        Button {
                            icon: "check"
                            iconOnly: true
                            size: "md"
                            type: "ghost"
                            textColor: Colors.text
                            Layout.fillWidth: false

                            onClicked: grid.editing = false
                        }
                    }

                    WidgetGrid {
                        id: grid
                        store: panelState

                        onPageRequested: (page) => openPage(page)
                    }
                }

                // Pages size themselves to this width, the panel follows their height
                Loader {
                    id: pageLoader

                    x: panelPadding
                    y: panelPadding
                    width: parent.width - panelPadding * 2
                }

                Connections {
                    target: pageLoader.item
                    ignoreUnknownSignals: true

                    function onBack() { root.back() }
                    function onCloseRequested() { root.close() }
                }
            }
        }
    }

    function openPage(page, properties = {}) {
        pageLoader.setSource(page, properties)
    }

    // Steps back from a page, then out of editing, then closes
    function back() {
        if (pageLoader.item) pageLoader.source = ""
        else if (grid.editing) grid.editing = false
        else close()
    }

    function close() {
        if (showing && !panel.running) {

            if (root.activeFocusItem) root.activeFocusItem.focus = false
            panel.popOut()
            showing = !showing
        }
    }

    function open() {
        if (!showing && !panel.running) {
            panel.popIn()
            showing = !showing
        }
    }
    function toggle() {
        if (showing) close()
        else open()
    }
}
