import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

import qs.config

Item {
    id: root

    property string color: Colors.text
    property string icon: "disk" 
    property int size: Settings.px(18)

    Layout.preferredWidth: size
    Layout.preferredHeight: size

    width: size
    height: size
    
    Layout.alignment: Qt.AlignVCenter

    Image {
        id: iconId
        source: icon != "" ? Qt.resolvedUrl("../icons/" + icon + ".svg") : ""
        width: size
        height: size
        fillMode: Image.PreserveAspectFit
        anchors.centerIn: parent
        visible: false
    }
    ColorOverlay {
        anchors.fill: iconId
        source: iconId
        color: root.color
    }
}