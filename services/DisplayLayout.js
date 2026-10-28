.pragma library

// Layout math for the display settings. Rects are { x, y, w, h } in Hyprland's logical pixels

// Scales Hyprland takes as they are: multiples of 1/120 that divide the mode into whole logical pixels.
// Common ones are swapped for the closest valid scale, and ones leaving the display shorter than minHeight are left out
function scales(width, height, minHeight, current) {
    const valid = []
    for (let k = 60; k <= 480; k++) {
        if (width * 120 % k == 0 && height * 120 % k == 0 && height * 120 / k >= minHeight) valid.push(k / 120)
    }
    const picked = [1, 1.25, 1.5, 1.75, 2, 2.5, 3]
        .map(scale => valid.reduce((best, s) => Math.abs(s - scale) < Math.abs(best - scale) ? s : best, valid[0]))
        .filter(scale => scale !== undefined)
    if (current) picked.push(current)
    return [...new Set(picked)].sort((a, b) => a - b)
}

function overlaps(a, b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
}

// Every spot touching another display without covering any: each side of each one, lined up with its start,
// center or end, and also slid along the edge to wherever r is, as long as a quarter of the shorter edge is shared
function candidates(r, others) {
    const spots = []
    for (const o of others) {
        const minX = Math.min(r.w, o.w) / 4
        const minY = Math.min(r.h, o.h) / 4
        const ys = [o.y, o.y + (o.h - r.h) / 2, o.y + o.h - r.h]
        const xs = [o.x, o.x + (o.w - r.w) / 2, o.x + o.w - r.w]
        const slideY = Math.max(o.y - r.h + minY, Math.min(o.y + o.h - minY, r.y))
        const slideX = Math.max(o.x - r.w + minX, Math.min(o.x + o.w - minX, r.x))

        for (const x of [o.x - r.w, o.x + o.w]) {
            ys.forEach(y => spots.push({ x: x, y: y, aligned: true }))
            spots.push({ x: x, y: slideY, aligned: false })
        }
        for (const y of [o.y - r.h, o.y + o.h]) {
            xs.forEach(x => spots.push({ x: x, y: y, aligned: true }))
            spots.push({ x: slideX, y: y, aligned: false })
        }
    }
    return spots
        .map(spot => ({ x: Math.round(spot.x), y: Math.round(spot.y), aligned: spot.aligned }))
        .filter(spot => !others.some(o => overlaps({ x: spot.x, y: spot.y, w: r.w, h: r.h }, o)))
}

// Where r lands when dropped: the closest spot, preferring a lined up one within snapDistance
function snap(r, others, snapDistance) {
    let best = null
    let bestScore = Infinity
    for (const spot of candidates(r, others)) {
        const score = Math.hypot(spot.x - r.x, spot.y - r.y) - (spot.aligned ? snapDistance : 0)
        if (score < bestScore) {
            best = spot
            bestScore = score
        }
    }
    return best ? { x: best.x, y: best.y } : { x: r.x, y: r.y }
}

// The next lined up spot in the direction of an arrow key, or null when there's none that way
function step(r, others, dx, dy) {
    let best = null
    let bestScore = Infinity
    for (const spot of candidates(r, others)) {
        if (!spot.aligned) continue
        const along = (spot.x - r.x) * dx + (spot.y - r.y) * dy
        const across = Math.abs(dx ? spot.y - r.y : spot.x - r.x)
        if (along <= 0) continue
        if (along + across * 2 < bestScore) {
            best = spot
            bestScore = along + across * 2
        }
    }
    return best ? { x: best.x, y: best.y } : null
}

// A display that changed size keeps its corner, the ones after it on the right or below move with its edges
function resize(rects, index, w, h) {
    const old = rects[index]
    return rects.map((r, i) => {
        if (i == index) return Object.assign({}, r, { w: w, h: h })
        return Object.assign({}, r, {
            x: r.x >= old.x + old.w ? r.x + w - old.w : r.x,
            y: r.y >= old.y + old.h ? r.y + h - old.h : r.y
        })
    })
}

// Moves everything so the top left display starts at 0, 0
function normalize(rects) {
    if (rects.length == 0) return rects
    const minX = Math.min(...rects.map(r => r.x))
    const minY = Math.min(...rects.map(r => r.y))
    return rects.map(r => Object.assign({}, r, { x: r.x - minX, y: r.y - minY }))
}
