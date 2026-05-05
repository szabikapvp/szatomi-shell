import QtQuick
import QtQuick.Controls
import Quickshell
import "../../components"
import "../../modules/controlcenter"
import qs.services

Item {
    id: root
    width: 18
    height: 18

/*    MouseArea {
        
        anchors.fill: parent
        
        cursorShape: Qt.PointingHandCursor
        onClicked: () => {
            
        }
    } */

    Icon {
        icon: Network.icon
    }
}