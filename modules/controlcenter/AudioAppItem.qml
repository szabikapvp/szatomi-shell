import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../components/widgets"

import qs.config
import qs.services

// One app in the mixer. Quiet apps can be set too, their volume applies once they play
ColumnLayout {
    id: root

    required property var app
    readonly property string appIcon: Audio.appIcon(app)
    readonly property bool playing: app.streams.length > 0

    Layout.fillWidth: true
    spacing: Settings.spacing / 2

    RowLayout {
        Layout.fillWidth: true
        spacing: Settings.spacing

        Image {
            visible: root.appIcon != ""
            source: root.appIcon
            sourceSize.width: Settings.buttonIconSize
            sourceSize.height: Settings.buttonIconSize
            Layout.preferredWidth: Settings.buttonIconSize
            Layout.preferredHeight: Settings.buttonIconSize
            fillMode: Image.PreserveAspectFit
            opacity: root.playing ? 1 : 0.6
        }

        Icon {
            visible: root.appIcon == ""
            icon: "speaker"
            size: Settings.buttonIconSize
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: Audio.appName(root.app)
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.playing ? Audio.appMedia(root.app) || "Playing" : "Not playing"
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(4)
                font.family: Settings.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    VolumeSlider {
        volume: Audio.appVolume(root.app)
        muted: Audio.appMuted(root.app)

        onMoved: (volume) => Audio.setAppVolume(root.app, volume)
        onMuteClicked: Audio.setAppMuted(root.app, !muted)
    }
}
