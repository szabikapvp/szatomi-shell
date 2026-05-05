import QtQuick
import Quickshell

Item {

    height: childrenRect.height

    AnimatedImage {
        anchors.centerIn: parent
        id: gif
        source: "file:///home/tomi/.config/quickshell/img/loading.gif"
    }
}