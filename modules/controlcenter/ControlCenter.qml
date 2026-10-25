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
    
    // Pages can ask for their own width, the rest match the grid
    property int panelWidth: (pageLoader.item?.preferredWidth ?? grid.implicitWidth) + panelPadding * 2
    // Pages can ask for their own padding too
    property int panelPadding: pageLoader.item?.panelPadding ?? Settings.controlCenterPadding
    property int marginSize: Settings.windowSpacing

    // The grid, or a page opened from it
    property Item visiblePage: pageLoader.item ?? mainPage
    property bool showing: false
    visible: panel.progress > 0

    readonly property url launcherPage: Qt.resolvedUrl("LauncherPage.qml")
    readonly property bool launcherOpen: pageLoader.source.toString() === launcherPage.toString()
    // Kept until the panel hides, since Hyprland drops the focus when a layer stops being exclusive
    property bool keyboardGrabbed: false
    onLauncherOpenChanged: if (launcherOpen) keyboardGrabbed = true
    // Opened straight to a page, so going back closes instead of showing a grid nobody asked for
    property bool directPage: false

    // Pages and editing end once the panel is fully hidden, so nothing changes mid animation
    onVisibleChanged: {
        if (visible) return
        pageLoader.source = ""
        grid.editing = false
        keyboardGrabbed = false
        directPage = false
    }

    // Resting position for the remembered snap point: a corner, or the middle of the top or bottom edge
    property real cornerX: panelState.center
        ? (panel.parent.width - panel.width) / 2
        : panelState.right ? panel.parent.width - panel.width - marginSize : marginSize
    property real cornerY: panelState.bottom ? panel.parent.height - panel.height - marginSize : marginSize

    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true

        onFileChanged: {
            if (!showing) open()
            else close()
        }
    }

    FileView {
        path: "/tmp/toggle_launcher"
        watchChanges: true

        onFileChanged: togglePage(launcherPage)
    }

    // Remembers the snap point across restarts
    FileView {
        id: stateFile

        path: Quickshell.statePath("controlcenter.json")
        // Deferred, since writing right away drops the other changes a snap makes in the same tick
        onAdapterUpdated: Qt.callLater(stateFile.writeAdapter)

        adapter: JsonAdapter {
            id: panelState
            property bool right: true
            property bool bottom: true
            property bool center: false
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

    // The launcher can open from a shortcut, so it takes the keyboard right away like wofi
    WlrLayershell.keyboardFocus: keyboardGrabbed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

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
        fromCenter: panelState.center
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

                // Switching workspaces can take the pointer away mid drag, which cancels instead of releasing
                onReleased: snapToNearest()
                onCanceled: snapToNearest()

                // Snaps to whichever of left, center and right rests closest
                function snapToNearest() {
                    snapFrom = Qt.point(panel.x, panel.y)
                    const restX = [marginSize, (panel.parent.width - panel.width) / 2, panel.parent.width - panel.width - marginSize]
                    const nearest = restX.reduce((best, x, i) => Math.abs(panel.x - x) < Math.abs(panel.x - restX[best]) ? i : best, 0)
                    panelState.center = nearest == 1
                    panelState.right = nearest == 2
                    panelState.bottom = panel.y + panel.height / 2 > panel.parent.height / 2
                    snap.restart()
                }
            }

            // The corner facing the screen corner stays small, the one the panel grows from
            radius: Settings.radiusLg
            property int calculatedRadius: Settings.radiusLg + panelPadding
            topLeftRadius: panel.isOrigin(false, false) ? Settings.radiusSm : calculatedRadius
            topRightRadius: panel.isOrigin(true, false) ? Settings.radiusSm : calculatedRadius
            bottomLeftRadius: panel.isOrigin(false, true) ? Settings.radiusSm : calculatedRadius
            bottomRightRadius: panel.isOrigin(true, true) ? Settings.radiusSm : calculatedRadius

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

                    // Typing on the grid opens the launcher with the typed key, control characters don't count
                    Keys.onPressed: (event) => {
                        const code = event.text.charCodeAt(0)
                        if (grid.editing || !(code > 32 && code != 127)) return
                        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
                        openPage(launcherPage, { query: event.text })
                        event.accepted = true
                    }

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
        if (pageLoader.item && directPage) close()
        else if (pageLoader.item) {
            pageLoader.source = ""
            mainPage.forceActiveFocus()
        }
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
            // Pages focus themselves, the grid listens for typing
            if (!pageLoader.item) mainPage.forceActiveFocus()
            panel.popIn()
            showing = !showing
        }
    }

    // Opens straight to a page, or closes when that page is already showing
    function togglePage(page) {
        if (showing && pageLoader.source.toString() === page.toString()) {
            close()
            return
        }

        // Mid animation the panel ignores open() and close(), so leave the page alone too
        if (panel.running) return
        if (!showing) directPage = true
        open()
        openPage(page)
    }

    function toggle() {
        if (showing) close()
        else open()
    }
}
