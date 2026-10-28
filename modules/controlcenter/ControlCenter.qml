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
    // Showing too, since reopening right as it closes can swing the spring just past closed for a frame
    visible: showing || panel.progress > 0

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
        resetPages()
        keyboardGrabbed = false
    }

    function resetPages() {
        pageLoader.source = ""
        grid.editing = false
        directPage = false
    }

    // Resting position for the remembered snap point: a corner, or the middle of the top or bottom edge
    property real cornerX: panelState.center
        ? (panel.parent.width - panel.width) / 2
        : panelState.right ? panel.parent.width - panel.width - marginSize : marginSize
    property real cornerY: panelState.bottom ? panel.parent.height - panel.height - marginSize : marginSize

    // Shortcuts from Settings. Touching these files does the same, for scripts
    Connections {
        target: Shortcuts
        function onTriggered(action) { root.runShortcut(action) }
    }

    FileView {
        path: "/tmp/toggle_menu"
        watchChanges: true
        onFileChanged: root.runShortcut("controlcenter")
    }

    FileView {
        path: "/tmp/toggle_launcher"
        watchChanges: true
        onFileChanged: root.runShortcut("launcher")
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

    // After a drag the panel rides these into its corner. One per axis, so each keeps its own speed from the throw
    property bool snapping: false

    Spring {
        id: snapX
        to: root.cornerX
        // Outside a snap it just tracks the corner, without running frames for nobody
        instant: !root.snapping || Settings.reduceMotion
        response: Settings.flickResponse
        dampingRatio: Settings.flickDamping
        onSettled: root.endSnap()
    }

    Spring {
        id: snapY
        to: root.cornerY
        // Outside a snap it just tracks the corner, without running frames for nobody
        instant: !root.snapping || Settings.reduceMotion
        response: Settings.flickResponse
        dampingRatio: Settings.flickDamping
        onSettled: root.endSnap()
    }

    // Dragging broke the corner bindings, restore them so page height changes keep the corner
    function endSnap() {
        if (!snapping) return
        if (!snapX.running) panel.x = Qt.binding(() => cornerX)
        if (!snapY.running) panel.y = Qt.binding(() => cornerY)
        snapping = snapX.running || snapY.running
    }

    // Leaves the panel where it is, mid snap, so it can be caught
    function holdSnap() {
        snapping = false
        snapX.stop()
        snapY.stop()
        panel.x = panel.x
        panel.y = panel.y
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
        // Matches the panel's own corners, or they'd change shape when the mask lets go
        radius: Settings.radiusLg + panelPadding

        Rectangle {
            id: osdRect

            anchors.fill: parent

            BackGesture {
                onTriggered: back()
            }

            // Only reachable on empty parts, the content on top takes its own clicks
            MouseArea {
                // Where the panel was over the last moments of the drag, for the speed it's thrown at
                property var trail: []

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
                drag.onActiveChanged: if (drag.active) holdSnap()

                // Catches a snapping panel right where it is, before any drag starts
                onPressed: {
                    trail = []
                    if (snapping) holdSnap()
                }

                onPositionChanged: {
                    if (!drag.active) return
                    const now = Date.now()
                    trail = trail.filter(point => now - point.t < 100).concat([{ x: panel.x, y: panel.y, t: now }])
                }

                // Switching workspaces can take the pointer away mid drag, which cancels instead of releasing
                onReleased: snapToNearest()
                onCanceled: snapToNearest()

                // Carries on at the drag's speed into whichever of left, center and right the throw would land
                // closest to, the way a flicked list coasts
                function snapToNearest() {
                    const now = Date.now()
                    const first = trail.find(point => now - point.t < 100) ?? { x: panel.x, y: panel.y, t: now - 1 }
                    const elapsed = Math.max(now - first.t, 1) / 1000

                    // Starts from where the panel is, before the corner moves
                    snapping = true
                    snapX.value = panel.x
                    snapY.value = panel.y
                    snapX.velocity = (panel.x - first.x) / elapsed
                    snapY.velocity = (panel.y - first.y) / elapsed
                    panel.x = Qt.binding(() => snapX.value)
                    panel.y = Qt.binding(() => snapY.value)

                    const landX = panel.x + project(snapX.velocity)
                    const landY = panel.y + project(snapY.velocity)
                    const restX = [marginSize, (panel.parent.width - panel.width) / 2, panel.parent.width - panel.width - marginSize]
                    const nearest = restX.reduce((best, x, i) => Math.abs(landX - x) < Math.abs(landX - restX[best]) ? i : best, 0)
                    panelState.center = nearest == 1
                    panelState.right = nearest == 2
                    panelState.bottom = landY + panel.height / 2 > panel.parent.height / 2

                    // The corner may not have changed, which wouldn't start them on its own
                    snapX.animate()
                    snapY.animate()
                }

                // Distance a throw coasts before stopping, Apple's scroll deceleration
                function project(velocity) {
                    const rate = Settings.flickDeceleration
                    return velocity / 1000 * rate / (1 - rate)
                }
            }

            // The corner facing the screen corner stays small, the one the panel grows from
            radius: Settings.radiusLg
            topLeftRadius: panel.isOrigin(false, false) ? Settings.radiusSm : panel.radius
            topRightRadius: panel.isOrigin(true, false) ? Settings.radiusSm : panel.radius
            bottomLeftRadius: panel.isOrigin(false, true) ? Settings.radiusSm : panel.radius
            bottomRightRadius: panel.isOrigin(true, true) ? Settings.radiusSm : panel.radius

            color: Colors.background
            border.width: 1
            border.color: Colors.backgroundSubtle

            // Pages stay at the panel's corner while a resize animates
            Item {
                x: panel.contentX
                y: panel.contentY
                width: panel.width
                height: panel.height

                // Arrows no control used move through the controls like Tab and Shift+Tab
                Keys.onPressed: (event) => {
                    const forward = event.key == Qt.Key_Down || event.key == Qt.Key_Right
                    if (!forward && event.key != Qt.Key_Up && event.key != Qt.Key_Left) return
                    Window.activeFocusItem?.nextItemInFocusChain(forward)?.forceActiveFocus()
                    event.accepted = true
                }

                ColumnLayout {
                    id: mainPage

                    visible: root.visiblePage == this

                    x: panelPadding
                    y: panelPadding
                    width: parent.width - panelPadding * 2

                    spacing: Settings.spacing * 2

                    // Typing on the grid opens the launcher with the typed key, control characters don't count.
                    // Tab or an arrow before any tile has the keyboard goes to the first one
                    Keys.onPressed: (event) => {
                        const navigation = [Qt.Key_Tab, Qt.Key_Backtab, Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)
                        if (navigation && !grid.editing) {
                            grid.focusFirst()
                            event.accepted = true
                            return
                        }

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

                        onPageRequested: (page, properties) => openPage(page, properties)
                    }
                }

                // Pages size themselves to this width, the panel follows their height
                Loader {
                    id: pageLoader

                    x: panelPadding
                    y: panelPadding
                    width: parent.width - panelPadding * 2

                    // A page isn't in the window yet while it's being created, so focusing from there doesn't stick.
                    // It names what should take the keyboard instead, or takes it itself so Tab starts on it
                    onLoaded: (item.initialFocus ?? item).forceActiveFocus()
                }

                Connections {
                    target: pageLoader.item
                    ignoreUnknownSignals: true

                    function onBack() { root.back() }
                    function onCloseRequested() { root.close() }
                    function onPageRequested(page, properties) { root.openPage(page, properties) }
                }
            }
        }
    }

    function openPage(page, properties = {}) {
        pageLoader.setSource(page, properties)
    }

    // Steps back from a page, then out of editing, then closes
    function back() {
        // Pages opened from another page go back to it
        // Urls are objects in JS, so an empty one only reads as false through its text
        if (pageLoader.item?.parentPage?.toString()) openPage(pageLoader.item.parentPage, pageLoader.item.parentProperties ?? {})
        else if (pageLoader.item && directPage) close()
        else if (pageLoader.item) {
            pageLoader.source = ""
            mainPage.forceActiveFocus()
        }
        else if (grid.editing) grid.editing = false
        else close()
    }

    // Both reverse a panel that's still moving the other way, so nothing waits on an animation
    function close() {
        if (showing) {

            // The window itself has no activeFocusItem, only its items do
            if (panel.Window.activeFocusItem) panel.Window.activeFocusItem.focus = false
            panel.popOut()
            showing = !showing
        }
    }

    function open() {
        if (!showing) {
            // Reopened mid close it still holds the last page, but opening always starts on the grid.
            // Pages focus themselves, the grid listens for typing
            resetPages()
            mainPage.forceActiveFocus()
            panel.popIn()
            showing = !showing
        }
    }

    // Opens straight to a page, or closes when that page is already showing
    function togglePage(page, properties = {}) {
        if (showing && pageLoader.source.toString() === page.toString()) {
            close()
            return
        }

        // open() starts on the grid, so the page is only marked direct after it
        const opening = !showing
        open()
        if (opening) directPage = true
        openPage(page, properties)
    }

    // Came from the keyboard, so the panel takes it like the launcher does
    function runShortcut(action) {
        if (action == "controlcenter") {
            if (showing) {
                close()
                return
            }
            keyboardGrabbed = true
            open()
            return
        }

        keyboardGrabbed = true
        switch (action) {
            case "launcher": togglePage(launcherPage); break
            case "settings": togglePage(Qt.resolvedUrl("SettingsPage.qml")); break
            case "wallpaper": togglePage(Qt.resolvedUrl("WallpaperPage.qml")); break
            case "displays": togglePage(Qt.resolvedUrl("SettingsPage.qml"), { category: "Displays" }); break
        }
    }

    function toggle() {
        if (showing) close()
        else open()
    }
}
