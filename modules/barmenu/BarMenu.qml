import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../components"

import qs.config
import qs.utils

// A small panel that drops out of the bar under the button that opened it. Only one shows at a time, never next to
// the control center. Clicking anywhere else or on the same button again closes it
PanelWindow {
    id: root

    // Clicks on the bar don't count as outside, so its buttons can switch or close the menu
    property var bar
    property var controlCenter

    property bool showing: false
    // The page showing, empty while closed, so the button that opened it can light up
    readonly property string currentPage: showing ? pageLoader.source.toString() : ""
    // Middle of the button it drops from
    property real originX: 0

    readonly property int padding: pageLoader.item?.panelPadding ?? Settings.barMenuPadding
    // Pages name the rounding of what sits in their corners, the panel's corners wrap it at the padding's distance
    readonly property real innerRadius: pageLoader.item?.innerRadius ?? Settings.radiusMd

    // Showing too, since reopening right as it closes can swing the spring just past closed for a frame
    visible: showing || panel.progress > 0
    onVisibleChanged: if (!visible) pageLoader.source = ""

    // Fills the space next to the bar, the mask lets clicks through elsewhere
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region { item: panel }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Normal
    color: "transparent"

    HyprlandFocusGrab {
        windows: [root, root.bar]
        active: root.showing
        onCleared: root.close()
    }

    Connections {
        target: root.controlCenter
        function onShowingChanged() { if (root.controlCenter.showing) root.close() }
    }

    Shortcut {
        sequences: Settings.backShortcuts
        onActivated: root.back()
    }

    // Where the panel's middle rests: under the button, kept on screen. The screen's width rather than the window's,
    // which is 0 while hidden and only arrives once it shows, so the panel would slide in from the edge
    readonly property real restX: Math.max(Settings.windowSpacing + panel.width / 2,
        Math.min(screen.width - Settings.windowSpacing - panel.width / 2, originX))

    // Moves the middle rather than the left edge, so a page of another size grows and shrinks evenly around it
    // while sliding to the next button. Opening starts right under the button, even while still closing elsewhere
    Spring {
        id: slideX
        to: root.restX
        instant: !root.showing || Settings.reduceMotion
    }

    Panel {
        id: panel

        x: slideX.value - width / 2
        y: fromBottom ? parent.height - height - Settings.windowSpacing : Settings.windowSpacing
        width: (pageLoader.item?.width ?? 0) + root.padding * 2
        height: (pageLoader.item?.height ?? 0) + root.padding * 2

        fromCenter: true
        fromBottom: Settings.barPosition == "bottom"
        radius: root.innerRadius + root.padding

        onBack: root.back()

        Loader {
            id: pageLoader

            x: root.padding
            y: root.padding

            onLoaded: (item.initialFocus ?? item).forceActiveFocus()
        }

        Connections {
            target: pageLoader.item
            ignoreUnknownSignals: true

            function onCloseRequested() { root.close() }
            function onPageRequested(page, properties) { pageLoader.setSource(page, properties) }
            // Anything deeper than a menu lives in the control center
            function onControlCenterRequested(page, properties) {
                root.close()
                root.controlCenter?.togglePage(page, properties)
            }
        }
    }

    // Opens page under the bar item, closes it when it's already showing, or moves over from another button
    function toggle(page, item, properties = {}) {
        if (currentPage === page.toString()) {
            close()
            return
        }

        originX = item.mapToItem(null, item.width / 2, 0).x + bar.margins.left
        pageLoader.setSource(page, properties)
        if (showing) return

        controlCenter?.close()
        panel.popIn()
        showing = true
    }

    // Pages opened from another one go back to it
    function back() {
        if (pageLoader.item?.parentPage?.toString()) pageLoader.setSource(pageLoader.item.parentPage, pageLoader.item.parentProperties ?? {})
        else close()
    }

    function close() {
        if (!showing) return
        panel.popOut()
        showing = false
    }
}
