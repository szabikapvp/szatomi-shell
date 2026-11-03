//@ pragma IconTheme Adwaita

import Quickshell
import QtQuick
import "./modules/bar"
import "./modules/popup"
import "./modules/controlcenter"
import "./modules/barmenu"
import "./components/widgets"
import qs.services

ShellRoot {

    // Each display shows its own wallpaper, or the one for all of them
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: wallpaperWindow

            required property var modelData
            readonly property string wallpaper: Wallpaper.forScreen(modelData.name)

            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            aboveWindows: false
            exclusionMode: ExclusionMode.Ignore

            Image {
                anchors.fill: parent
                source: wallpaperWindow.wallpaper ? "file://" + wallpaperWindow.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
            }
        }
    }

    // The bar, the control center and pop-ups live on the main display
    SliderPopup {
        screen: Displays.mainScreen
        icon: BrightnessIcon {}
        prop: Brightness.getLevel()
        suppressed: controlCenterWindow.showing
    }

    SliderPopup {
        screen: Displays.mainScreen
        icon: VolumeIcon {}
        prop: Audio.getLevel()
        suppressed: controlCenterWindow.showing || barMenu.currentPage === mainBar.volumeMenu.toString()
    }

    ControlCenter {
        id: controlCenterWindow
        screen: Displays.mainScreen
        bar: mainBar
    }

    Bar {
        id: mainBar
        modelData: Displays.mainScreen
        controlCenter: controlCenterWindow
        menu: barMenu
    }

    BarMenu {
        id: barMenu
        screen: Displays.mainScreen
        bar: mainBar
        controlCenter: controlCenterWindow
    }

    Variants {
        model: Quickshell.screens
        DisplayBadge {}
    }

    Variants {
        model: Quickshell.screens
        DisplayConfirm {}
    }
}
