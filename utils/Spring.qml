import QtQuick

import qs.config

// A value that springs towards `to` from wherever it is, keeping its velocity, so it can be redirected mid-flight
// without a jolt. Tuned like Apple's springs: response is roughly how long it takes in seconds, a damping ratio
// of 1 settles without overshoot and lower ones bounce. Only runs while moving
FrameAnimation {
    id: root

    property real to: 0
    property real value: 0
    // Units per second. Set it before animate() to carry a gesture's speed into the spring
    property real velocity: 0
    property real response: Settings.springResponse
    property real dampingRatio: 1
    // Close enough to rest, in the animated unit. A tenth of a pixel can't be seen
    property real epsilon: 0.1
    // Jumps straight to the target, like a disabled Behavior
    property bool instant: Settings.reduceMotion

    // At rest on the target, after moving there or jumping. Not sent when stopped midway
    signal settled()

    Component.onCompleted: value = to
    onToChanged: animate()

    // Solved exactly for each frame's length, so it moves the same at any refresh rate. A stall, like a page
    // being built, only counts as a slow frame, so it can't skip the animation
    onTriggered: {
        const omega = 2 * Math.PI / Math.max(response, 0.001)
        const t = Math.min(frameTime, 1 / 30)
        const x = value - to
        let nx, nv

        if (dampingRatio >= 1) {
            const decay = Math.exp(-omega * t)
            const b = velocity + omega * x
            nx = (x + b * t) * decay
            nv = (b - omega * (x + b * t)) * decay
        } else {
            const zw = dampingRatio * omega
            const wd = omega * Math.sqrt(1 - dampingRatio * dampingRatio)
            const decay = Math.exp(-zw * t)
            const b = (velocity + zw * x) / wd
            const cos = Math.cos(wd * t)
            const sin = Math.sin(wd * t)
            nx = decay * (x * cos + b * sin)
            nv = decay * ((wd * b - zw * x) * cos - (zw * b + wd * x) * sin)
        }

        // Rests once neither what's left nor the next frame's step would show
        if (Math.abs(nx) + Math.abs(nv) * t < epsilon) {
            jump()
            return
        }
        velocity = nv
        value = to + nx
    }

    // Heads for the target from the current value and velocity
    function animate() {
        if (instant) jump()
        else start()
    }

    function jump() {
        stop()
        velocity = 0
        value = to
        settled()
    }
}
