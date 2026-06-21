import QtQuick

// AniMe Matrix glyph: a 3x3 grid of dots that idle dim and, at random,
// slowly blink up to full brightness — never more than a couple at a time —
// a soft, living echo of the LED matrix on the lid. Every dot is its own
// item with its own brightness, so each one lights independently. The whole
// glyph is painted in `glyphColor`, so the monochrome theme greys it out by
// just feeding a neutral color.
//
// `layer.enabled` flattens the dots onto one surface *before* the glyph's
// own opacity is applied, so the icon dims uniformly when inactive.
Item {
    id: glyph

    property color glyphColor: Theme.iconAnime
    property real glyphSize: 22
    // dims the whole glyph a touch when the section is not active
    property bool active: true
    // drives the idle blinking; pause it when the matrix is off
    property bool animate: true

    // peak brightness a dot reaches mid-blink
    readonly property real peakA: 1.0
    // cap on how many dots may be mid-blink at once, so it stays calm
    readonly property int maxConcurrent: 2

    implicitWidth: glyphSize
    implicitHeight: glyphSize

    opacity: active ? 1.0 : 0.55
    layer.enabled: true
    layer.smooth: true

    Behavior on opacity { NumberAnimation { duration: Theme.durMed } }
    Behavior on glyphColor { ColorAnimation { duration: Theme.durMed } }

    // populated once the dots exist; the timer picks from here
    property var dots: []
    property int busyCount: 0

    // When the setting flips off, stop every blink and settle the dots back
    // to their resting brightness so nothing is left frozen mid-glow.
    onAnimateChanged: {
        if (!animate) {
            for (var i = 0; i < dots.length; i++)
                dots[i].settle()
        }
    }

    // Light up one random idle dot, as long as we're under the concurrency
    // cap — keeps the motion slow and sparse instead of a flickering swarm.
    function blinkRandom() {
        if (!animate || dots.length === 0 || busyCount >= maxConcurrent)
            return
        var idle = []
        for (var i = 0; i < dots.length; i++)
            if (!dots[i].busy) idle.push(dots[i])
        if (idle.length === 0) return
        idle[Math.floor(Math.random() * idle.length)].blink()
    }

    // ---- 24x24 design space, scaled to fit (matches anime.svg) ----
    Item {
        id: design
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: glyph.glyphSize / 24
        transformOrigin: Item.Center

        // A single matrix dot. `rest` keeps the original staggered SVG
        // pattern at idle; `blink` swells it to full and eases back.
        component Dot: Rectangle {
            id: dot
            width: 3.4; height: 3.4
            radius: 1.7
            antialiasing: true
            color: glyph.glyphColor

            property real rest: 0.35
            property bool busy: false

            opacity: rest

            function blink() { blinkAnim.restart() }

            // stop any in-flight blink and ease back to rest
            function settle() {
                blinkAnim.stop()
                if (busy) { busy = false; glyph.busyCount-- }
                settleAnim.restart()
            }

            NumberAnimation {
                id: settleAnim
                target: dot; property: "opacity"
                to: dot.rest
                duration: Theme.durMed
                easing.type: Easing.InOutSine
            }

            SequentialAnimation {
                id: blinkAnim
                ScriptAction { script: { dot.busy = true; glyph.busyCount++ } }
                NumberAnimation {
                    target: dot; property: "opacity"
                    to: glyph.peakA
                    duration: 700 + Math.random() * 500
                    easing.type: Easing.InOutSine
                }
                PauseAnimation { duration: 180 + Math.random() * 320 }
                NumberAnimation {
                    target: dot; property: "opacity"
                    to: dot.rest
                    duration: 800 + Math.random() * 700
                    easing.type: Easing.InOutSine
                }
                ScriptAction { script: { dot.busy = false; glyph.busyCount-- } }
            }
        }

        // 3x3 grid, centers at 5 / 12 / 19 (x = center - radius). Rest values
        // echo the diagonal brightness pattern of the original icon.
        Dot { id: d0; x: 3.3;  y: 3.3;  rest: 0.50 }
        Dot { id: d1; x: 10.3; y: 3.3;  rest: 0.38 }
        Dot { id: d2; x: 17.3; y: 3.3;  rest: 0.24 }
        Dot { id: d3; x: 3.3;  y: 10.3; rest: 0.38 }
        Dot { id: d4; x: 10.3; y: 10.3; rest: 0.50 }
        Dot { id: d5; x: 17.3; y: 10.3; rest: 0.38 }
        Dot { id: d6; x: 3.3;  y: 17.3; rest: 0.24 }
        Dot { id: d7; x: 10.3; y: 17.3; rest: 0.38 }
        Dot { id: d8; x: 17.3; y: 17.3; rest: 0.50 }
    }

    Component.onCompleted: dots = [d0, d1, d2, d3, d4, d5, d6, d7, d8]

    // Staggered, slightly irregular cadence so blinks never lock into a
    // visible rhythm.
    Timer {
        running: glyph.animate
        repeat: true
        interval: 550 + Math.round(Math.random() * 450)
        onTriggered: {
            glyph.blinkRandom()
            interval = 550 + Math.round(Math.random() * 450)
        }
    }
}
