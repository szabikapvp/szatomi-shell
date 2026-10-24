import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Networking
import "./modules/bar"
import "./modules/popup"
import "./modules/controlcenter"
import "./modules/powermenu"
import "./components/widgets"
import qs.services
import qs.config

ShellRoot {

    PanelWindow {

        id: wallpaperWindow

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
            source: Settings.wallpaper            
            fillMode: Image.PreserveAspectCrop 
        }
    }

    SliderPopup {
        icon: BrightnessIcon {}
        prop: Brightness.getLevel()
        suppressed: controlCenterWindow.showing
    }

    SliderPopup {
        icon: VolumeIcon {}
        prop: Audio.getLevel()
        suppressed: controlCenterWindow.showing
    }

    ControlCenter { id: controlCenterWindow }

    PowerMenu {}

    Variants {
        model: Quickshell.screens
        Bar { controlCenter: controlCenterWindow }
    }
}
