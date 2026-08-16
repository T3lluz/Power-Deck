pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

// Canvas-drawn metric icon. Shapes are painted in QML so the color
// binding is instant and we do not depend on Kirigami.Icon SVG masks.
//
// Kinds: cpu gpu battery charge discharge watt fan hz
//        profile text clock dots bars bell both
Item {
    id: root

    property string kind: "cpu"
    property color color: Kirigami.Theme.textColor
    property real strokeWidth: 1.6
    property real contentScale: 0.8

    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small

    Canvas {
        id: cv
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var scale = Math.min(width, height) / 24 * root.contentScale
            ctx.translate((width  - 24 * scale) / 2,
                          (height - 24 * scale) / 2)
            ctx.scale(scale, scale)

            ctx.strokeStyle = root.color
            ctx.fillStyle   = root.color
            ctx.lineWidth   = root.strokeWidth
            ctx.lineCap     = "round"
            ctx.lineJoin    = "round"

            switch (root.kind) {
            case "cpu":       drawCpu(ctx);       break
            case "gpu":       drawGpu(ctx);       break
            case "battery":   drawBattery(ctx);   break
            case "charge":    drawCharge(ctx);    break
            case "discharge": drawDischarge(ctx); break
            case "watt":      drawWatt(ctx);      break
            case "fan":       drawFan(ctx);       break
            case "hz":        drawHz(ctx);        break
            case "profile":   drawProfile(ctx);   break
            case "text":      drawText(ctx);      break
            case "clock":     drawClock(ctx);     break
            case "dots":      drawDots(ctx);      break
            case "bars":      drawBars(ctx);      break
            case "bell":      drawBell(ctx);      break
            case "both":      drawBoth(ctx);      break
            }
        }

        function roundRect(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }

        function drawCpu(ctx) {
            roundRect(ctx, 5, 5, 14, 14, 1.8)
            ctx.stroke()
            roundRect(ctx, 9, 9, 6, 6, 1)
            ctx.fill()
            ctx.lineWidth = 1.8
            var pins = [9, 15]
            for (var i = 0; i < pins.length; i++) {
                var p = pins[i]
                ctx.beginPath(); ctx.moveTo(p, 5);  ctx.lineTo(p, 2.5);  ctx.stroke()
                ctx.beginPath(); ctx.moveTo(p, 19); ctx.lineTo(p, 21.5); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(5, p);  ctx.lineTo(2.5, p);  ctx.stroke()
                ctx.beginPath(); ctx.moveTo(19, p); ctx.lineTo(21.5, p); ctx.stroke()
            }
        }

        function drawGpu(ctx) {
            roundRect(ctx, 2.5, 6.5, 18, 10, 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(9.5, 11.5, 2.8, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(15.5, 9.5);  ctx.lineTo(18.5, 9.5)
            ctx.moveTo(15.5, 12);   ctx.lineTo(18.5, 12)
            ctx.moveTo(15.5, 14.5); ctx.lineTo(17.5, 14.5)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(5.5, 16.5);  ctx.lineTo(5.5, 18.5)
            ctx.moveTo(9, 16.5);    ctx.lineTo(9, 18.5)
            ctx.moveTo(12.5, 16.5); ctx.lineTo(12.5, 18.5)
            ctx.stroke()
        }

        function drawBattery(ctx) {
            roundRect(ctx, 2.5, 7, 16.5, 10, 2.2)
            ctx.stroke()
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(21, 10.5)
            ctx.lineTo(21, 13.5)
            ctx.stroke()
            roundRect(ctx, 4.9, 9.4, 8.7, 5.2, 1.3)
            ctx.fill()
        }

        function drawCharge(ctx) {
            ctx.lineWidth = 1.8
            ctx.beginPath(); ctx.moveTo(5, 2.5); ctx.lineTo(19, 2.5); ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 5)
            ctx.lineTo(7, 11)
            ctx.lineTo(17, 11)
            ctx.closePath()
            ctx.fill()
            ctx.lineWidth = 2.4
            ctx.beginPath(); ctx.moveTo(12, 8); ctx.lineTo(12, 20); ctx.stroke()
        }

        function drawDischarge(ctx) {
            ctx.lineWidth = 2.4
            ctx.beginPath(); ctx.moveTo(12, 4); ctx.lineTo(12, 16); ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 19)
            ctx.lineTo(7, 13)
            ctx.lineTo(17, 13)
            ctx.closePath()
            ctx.fill()
            ctx.lineWidth = 1.8
            ctx.beginPath(); ctx.moveTo(5, 21.5); ctx.lineTo(19, 21.5); ctx.stroke()
        }

        function drawWatt(ctx) {
            ctx.beginPath()
            ctx.moveTo(13.5, 3)
            ctx.lineTo(6.5, 13.2)
            ctx.lineTo(11.2, 13.2)
            ctx.lineTo(10.2, 21)
            ctx.lineTo(17.8, 10.2)
            ctx.lineTo(12.8, 10.2)
            ctx.closePath()
            ctx.fill()
        }

        function drawFan(ctx) {
            ctx.beginPath()
            ctx.arc(12, 12, 8.4, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 12, 1.35, 0, Math.PI * 2)
            ctx.fill()
            for (var i = 0; i < 3; i++) {
                ctx.save()
                ctx.translate(12, 12)
                ctx.rotate(i * Math.PI * 2 / 3)
                ctx.beginPath()
                ctx.moveTo(0.6, -1.6)
                ctx.bezierCurveTo(5.5, -8.2, 10.2, -5.4, 2.2, 0.8)
                ctx.stroke()
                ctx.restore()
            }
        }

        function drawHz(ctx) {
            ctx.beginPath()
            ctx.moveTo(2.5, 12)
            ctx.lineTo(5.5, 12)
            ctx.lineTo(7.5, 7)
            ctx.lineTo(10.5, 17)
            ctx.lineTo(13, 10)
            ctx.lineTo(14.5, 12)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(16.5, 9)
            ctx.lineTo(20.5, 9)
            ctx.lineTo(16.5, 15)
            ctx.lineTo(20.5, 15)
            ctx.stroke()
        }

        function drawProfile(ctx) {
            ctx.beginPath()
            ctx.arc(12, 13.2, 7.2, Math.PI * 0.85, Math.PI * 0.15)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 13.2)
            ctx.lineTo(16.4, 8.2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 13.2, 1.3, 0, Math.PI * 2)
            ctx.fill()
        }

        function drawText(ctx) {
            ctx.beginPath(); ctx.moveTo(5, 7);  ctx.lineTo(19, 7);  ctx.stroke()
            ctx.beginPath(); ctx.moveTo(5, 12); ctx.lineTo(16, 12); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(5, 17); ctx.lineTo(13, 17); ctx.stroke()
        }

        function drawClock(ctx) {
            ctx.beginPath()
            ctx.arc(12, 12, 8, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 12)
            ctx.lineTo(12, 7.2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 12)
            ctx.lineTo(16.2, 13.6)
            ctx.stroke()
        }

        function drawDots(ctx) {
            for (var i = 0; i < 3; i++) {
                ctx.beginPath()
                ctx.arc(6 + i * 6, 12, 1.7, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        function drawBars(ctx) {
            roundRect(ctx, 4.5, 13, 4, 6.5, 0.8)
            ctx.fill()
            roundRect(ctx, 10, 7.5, 4, 12, 0.8)
            ctx.fill()
            roundRect(ctx, 15.5, 10, 4, 9.5, 0.8)
            ctx.fill()
        }

        function drawBell(ctx) {
            ctx.beginPath()
            ctx.moveTo(6.5, 14.5)
            ctx.quadraticCurveTo(6.2, 7.2, 12, 6)
            ctx.quadraticCurveTo(17.8, 7.2, 17.5, 14.5)
            ctx.lineTo(5.5, 14.5)
            ctx.lineTo(18.5, 14.5)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 16.6, 1.6, 0, Math.PI)
            ctx.stroke()
        }

        function drawBoth(ctx) {
            roundRect(ctx, 3.5, 5.5, 7.5, 7.5, 1.4)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(13.2, 7)
            ctx.lineTo(20.5, 7)
            ctx.moveTo(13.2, 11)
            ctx.lineTo(18.5, 11)
            ctx.moveTo(3.5, 16.5)
            ctx.lineTo(20.5, 16.5)
            ctx.moveTo(3.5, 19.5)
            ctx.lineTo(15, 19.5)
            ctx.stroke()
        }
    }

    onColorChanged: cv.requestPaint()
    onKindChanged: cv.requestPaint()
    onContentScaleChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()
}
