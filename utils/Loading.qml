import QtQuick
import QtQuick.Shapes
import Quickshell

import qs.config

Item {
    id: root

    property int size: Settings.spinnerSize
    property color color: Colors.primary
    property real thickness: Math.max(2, size / 10)

    property real arcStart: 0
    property real arcSweep: 10
    property real arcOffset: 0

    implicitWidth: size
    implicitHeight: size

    Shape {
        id: ring

        anchors.centerIn: parent
        width: root.size
        height: root.size

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: (root.size - root.thickness) / 2
                startAngle: root.arcOffset + root.arcStart
                sweepAngle: root.arcSweep
            }
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 1600
            loops: Animation.Infinite
            running: root.visible
        }
    }

    // Head stretches the arc, then the tail catches up; the offset carries over so the loop has no jump
    SequentialAnimation {
        loops: Animation.Infinite
        running: root.visible

        NumberAnimation {
            target: root
            property: "arcSweep"
            from: 10
            to: 260
            duration: 700
            easing.type: Easing.InOutSine
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "arcStart"
                from: 0
                to: 250
                duration: 700
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: root
                property: "arcSweep"
                from: 260
                to: 10
                duration: 700
                easing.type: Easing.InOutSine
            }
        }

        ScriptAction {
            script: {
                root.arcOffset = (root.arcOffset + 250) % 360
                root.arcStart = 0
            }
        }
    }
}
