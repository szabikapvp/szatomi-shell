import QtQuick
import Quickshell

PropertyAnimation {
    id: root

    property string style: "smooth"

    duration: {
        if (style === "bouncy") return 400
        if (style === "snappy") return 150
        return 250
    }

    easing.type: {
        if (style === "bouncy") return Easing.OutBounce
        if (style === "snappy") return Easing.OutExpo
        return Easing.InOutQuad
    }
}