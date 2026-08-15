import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Eight-point fan curve. Bars set duty; the °C labels under them
// are editable (scroll or click to type). The EC interpolates.
Item {
    id: root

    property string title: ""
    property int rpm: -1
    property int maxRpm: -1
    property int liveTemp: -1
    property bool interactive: true
    property bool firmwareMode: false
    property bool calibrating: false
    property color accent: Theme.accent
    property bool dragging: false
    property int editingTempIndex: -1

    signal pointsEdited()
    signal pressChanged(bool pressed)
    signal copyRequested()

    readonly property int pointCount: 8
    readonly property int tempMin: 20
    readonly property int tempMax: 110
    readonly property int barHeight: Math.round(Kirigami.Units.gridUnit * 7.2)
    readonly property bool canEdit: interactive && !firmwareMode && !calibrating

    implicitHeight: barHeight + Math.round(Kirigami.Units.gridUnit * 3.4)
    implicitWidth: Kirigami.Units.gridUnit * 16
    Layout.fillWidth: true
    Layout.fillHeight: true

    function setPoints(pts) {
        if (root.dragging || root.editingTempIndex >= 0)
            return
        if (!pts || pts.length === 0) {
            while (pointModel.count > 0)
                pointModel.remove(0)
            curveCanvas.requestPaint()
            return
        }
        var n = Math.min(pts.length, pointCount)
        if (pointModel.count === n) {
            var changed = false
            for (var i = 0; i < n; i++) {
                var t = parseInt(pts[i].t, 10)
                var p = parseInt(pts[i].p, 10)
                if (pointModel.get(i).temp !== t) {
                    pointModel.setProperty(i, "temp", t)
                    changed = true
                }
                if (pointModel.get(i).duty !== p) {
                    pointModel.setProperty(i, "duty", p)
                    changed = true
                }
            }
            if (changed)
                curveCanvas.requestPaint()
            return
        }
        while (pointModel.count > 0)
            pointModel.remove(0)
        for (var j = 0; j < n; j++) {
            pointModel.append({
                temp: parseInt(pts[j].t, 10),
                duty: parseInt(pts[j].p, 10)
            })
        }
        curveCanvas.requestPaint()
    }

    function getPoints() {
        var out = []
        for (var i = 0; i < pointModel.count; i++)
            out.push({ t: pointModel.get(i).temp, p: pointModel.get(i).duty })
        return out
    }

    function curveString() {
        var parts = []
        for (var i = 0; i < pointModel.count; i++)
            parts.push(pointModel.get(i).temp + ":" + pointModel.get(i).duty)
        return parts.join(",")
    }

    function bumpAll(delta) {
        for (var i = 0; i < pointModel.count; i++) {
            var d = pointModel.get(i).duty + delta
            if (d < 0) d = 0
            if (d > 100) d = 100
            pointModel.setProperty(i, "duty", d)
        }
        curveCanvas.requestPaint()
        root.pointsEdited()
    }

    function tempLo(index) {
        return index > 0 ? pointModel.get(index - 1).temp : root.tempMin
    }

    function tempHi(index) {
        return index < pointModel.count - 1 ? pointModel.get(index + 1).temp : root.tempMax
    }

    function setDutyAt(index, duty) {
        var d = Math.max(0, Math.min(100, Math.round(duty)))
        if (index < 0 || index >= pointModel.count)
            return
        if (pointModel.get(index).duty === d)
            return
        pointModel.setProperty(index, "duty", d)
        curveCanvas.requestPaint()
    }

    function setTempAt(index, temp) {
        if (index < 0 || index >= pointModel.count)
            return
        var t = Math.max(tempLo(index), Math.min(tempHi(index), Math.round(temp)))
        if (t < root.tempMin) t = root.tempMin
        if (t > root.tempMax) t = root.tempMax
        if (pointModel.get(index).temp === t)
            return
        pointModel.setProperty(index, "temp", t)
        curveCanvas.requestPaint()
    }

    function accentRgba(a) {
        return "rgba(" + Math.round(root.accent.r * 255) + ","
            + Math.round(root.accent.g * 255) + ","
            + Math.round(root.accent.b * 255) + "," + a + ")"
    }

    ListModel { id: pointModel }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PC3.Label {
                text: root.title
                color: Kirigami.Theme.textColor
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.letterSpacing: 1.1
            }

            Rectangle {
                visible: root.liveTemp >= 0
                implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.05)
                implicitWidth: liveLabel.implicitWidth + Kirigami.Units.smallSpacing * 1.6
                radius: height / 2
                color: Theme.alpha(root.accent, 0.12)
                border.width: 1
                border.color: Theme.alpha(root.accent, 0.35)

                PC3.Label {
                    id: liveLabel
                    anchors.centerIn: parent
                    text: i18n("%1°C", root.liveTemp)
                    color: root.accent
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                }
            }

            Item { Layout.fillWidth: true }

            PC3.Label {
                text: {
                    if (root.rpm < 0)
                        return i18n("— RPM")
                    if (root.maxRpm > 0) {
                        var pct = Math.round(100 * root.rpm / root.maxRpm)
                        if (pct < 0) pct = 0
                        if (pct > 100) pct = 100
                        return i18n("%1 RPM · %2%", root.rpm, pct)
                    }
                    return i18n("%1 RPM", root.rpm)
                }
                color: root.rpm > 0 ? root.accent : Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }

            Rectangle {
                visible: root.canEdit
                implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.05)
                implicitWidth: copyLabel.implicitWidth + Kirigami.Units.smallSpacing * 1.6
                radius: height / 2
                color: Theme.alpha(Kirigami.Theme.textColor, copyHover.containsMouse ? 0.10 : 0.05)
                border.width: 1
                border.color: Theme.alpha(Kirigami.Theme.textColor, 0.16)

                PC3.Label {
                    id: copyLabel
                    anchors.centerIn: parent
                    text: i18n("Copy")
                    color: Kirigami.Theme.disabledTextColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                }

                MouseArea {
                    id: copyHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copyRequested()
                }

                PC3.ToolTip.visible: copyHover.containsMouse
                PC3.ToolTip.delay: 400
                PC3.ToolTip.text: i18n("Copy this curve to the other fan")
            }
        }

        Item {
            id: chart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.barHeight
            Layout.minimumHeight: Math.round(Kirigami.Units.gridUnit * 5.5)
            opacity: root.canEdit ? 1.0 : Theme.offOpacity

            Repeater {
                model: [0.25, 0.5, 0.75]

                Rectangle {
                    required property real modelData
                    width: chart.width
                    height: 1
                    y: Math.round(chart.height * (1 - modelData))
                    color: Theme.alpha(Kirigami.Theme.textColor, modelData === 0.5 ? 0.16 : 0.08)
                }
            }

            Canvas {
                id: curveCanvas
                anchors.fill: parent
                z: 1
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var n = pointModel.count
                    if (n < 2 || width <= 0 || height <= 0)
                        return
                    var gap = Math.max(3, Math.round(width * 0.018))
                    var barW = (width - gap * (n - 1)) / n
                    ctx.beginPath()
                    for (var i = 0; i < n; i++) {
                        var x = i * (barW + gap) + barW / 2
                        var y = height * (1 - pointModel.get(i).duty / 100)
                        if (i === 0)
                            ctx.moveTo(x, y)
                        else
                            ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = root.accentRgba(0.95)
                    ctx.lineWidth = 2
                    ctx.lineJoin = "round"
                    ctx.lineCap = "round"
                    ctx.stroke()
                    ctx.lineTo((n - 1) * (barW + gap) + barW / 2, height)
                    ctx.lineTo(barW / 2, height)
                    ctx.closePath()
                    ctx.fillStyle = root.accentRgba(0.10)
                    ctx.fill()
                }
            }

            Row {
                id: barRow
                anchors.fill: parent
                z: 2
                spacing: Math.max(3, Math.round(width * 0.018))

                Repeater {
                    model: pointModel

                    Item {
                        id: colItem
                        required property int index
                        required property int temp
                        required property int duty

                        width: {
                            var n = Math.max(1, pointModel.count)
                            var gap = barRow.spacing
                            return Math.max(8, (barRow.width - gap * (n - 1)) / n)
                        }
                        height: barRow.height

                        readonly property bool hot: {
                            if (root.liveTemp < 0)
                                return false
                            var next = (index + 1 < pointModel.count)
                                ? pointModel.get(index + 1).temp : 200
                            return root.liveTemp >= temp && root.liveTemp < next
                        }

                        Rectangle {
                            id: track
                            anchors.fill: parent
                            radius: 5
                            color: Theme.alpha(Kirigami.Theme.textColor,
                                hover.containsMouse || root.dragging ? 0.07 : 0.035)
                            border.width: 1
                            border.color: colItem.hot
                                ? Theme.alpha(root.accent, 0.55)
                                : Theme.alpha(Kirigami.Theme.textColor, 0.08)
                        }

                        Rectangle {
                            id: fill
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            height: Math.max(4, (parent.height - 4) * colItem.duty / 100)
                            radius: 4
                            color: Theme.alpha(root.accent, colItem.hot ? 0.88 : 0.62)
                            border.width: 1
                            border.color: Theme.alpha(root.accent, 0.35)

                            Behavior on height {
                                enabled: !root.dragging
                                NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
                            }
                        }

                        Rectangle {
                            visible: colItem.duty > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: fill.y - 3
                            width: Math.max(8, Math.round(parent.width * 0.45))
                            height: 3
                            radius: 1.5
                            color: root.accent
                        }

                        PC3.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: fill.top
                            anchors.bottomMargin: 2
                            visible: colItem.duty >= 8 || hover.containsMouse
                            text: colItem.duty + "%"
                            color: Kirigami.Theme.textColor
                            font.weight: Font.DemiBold
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 2
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            enabled: root.canEdit
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.SizeVerCursor
                            acceptedButtons: Qt.LeftButton

                            function applyAt(my) {
                                var h = height
                                if (h <= 0)
                                    return
                                root.setDutyAt(colItem.index, (1 - my / h) * 100)
                            }

                            onPressed: function(mouse) {
                                root.dragging = true
                                root.pressChanged(true)
                                applyAt(mouse.y)
                            }
                            onPositionChanged: function(mouse) {
                                if (pressed)
                                    applyAt(mouse.y)
                            }
                            onReleased: {
                                root.dragging = false
                                root.pressChanged(false)
                                root.pointsEdited()
                            }
                            onCanceled: {
                                root.dragging = false
                                root.pressChanged(false)
                                root.pointsEdited()
                            }
                        }

                        WheelHandler {
                            enabled: root.canEdit
                            onWheel: function(event) {
                                var d = colItem.duty + (event.angleDelta.y > 0 ? 2 : -2)
                                root.setDutyAt(colItem.index, d)
                                root.pointsEdited()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: !root.canEdit
                z: 20
                radius: 5
                color: Theme.alpha(Kirigami.Theme.backgroundColor, 0.62)

                PC3.Label {
                    anchors.centerIn: parent
                    text: root.calibrating
                        ? i18n("Measuring peak RPM…")
                        : i18n("Firmware control")
                    color: Kirigami.Theme.disabledTextColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
        }

        Row {
            Layout.fillWidth: true
            spacing: Math.max(3, Math.round(width * 0.018))
            enabled: root.canEdit
            opacity: root.canEdit ? 1.0 : Theme.offOpacity

            Repeater {
                model: pointModel

                Item {
                    id: tempCell
                    required property int index
                    required property int temp
                    required property int duty

                    readonly property bool editing: root.editingTempIndex === index

                    width: {
                        var n = Math.max(1, pointModel.count)
                        var gap = parent.spacing
                        return Math.max(8, (parent.width - gap * (n - 1)) / n)
                    }
                    height: Math.round(Kirigami.Units.gridUnit * 1.15)

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Theme.alpha(root.accent,
                            tempCell.editing ? 0.16
                            : tempHover.containsMouse ? 0.10 : 0)
                        border.width: 1
                        border.color: Theme.alpha(root.accent,
                            tempCell.editing || tempHover.containsMouse ? 0.40 : 0)
                    }

                    PC3.Label {
                        visible: !tempCell.editing
                        anchors.centerIn: parent
                        text: i18n("%1°", tempCell.temp)
                        color: tempHover.containsMouse
                            ? root.accent
                            : Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        font.weight: tempHover.containsMouse ? Font.DemiBold : Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                    }

                    PC3.TextField {
                        id: tempField
                        visible: tempCell.editing
                        anchors.fill: parent
                        anchors.margins: 1
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 0
                        bottomPadding: 0
                        leftPadding: 0
                        rightPadding: 0
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        font.weight: Font.DemiBold
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator {
                            bottom: root.tempMin
                            top: root.tempMax
                        }

                        function commit() {
                            var n = parseInt(text.replace(/[^0-9]/g, ""), 10)
                            if (!isNaN(n))
                                root.setTempAt(tempCell.index, n)
                            root.editingTempIndex = -1
                            root.pressChanged(false)
                            root.pointsEdited()
                        }

                        onVisibleChanged: {
                            if (visible) {
                                text = String(tempCell.temp)
                                forceActiveFocus()
                                selectAll()
                            }
                        }
                        onAccepted: commit()
                        onEditingFinished: {
                            if (root.editingTempIndex === tempCell.index)
                                commit()
                        }
                        Keys.onEscapePressed: {
                            root.editingTempIndex = -1
                            root.pressChanged(false)
                        }
                    }

                    MouseArea {
                        id: tempHover
                        anchors.fill: parent
                        enabled: root.canEdit && !tempCell.editing
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            root.editingTempIndex = tempCell.index
                            root.pressChanged(true)
                        }
                    }

                    WheelHandler {
                        enabled: root.canEdit && !tempCell.editing
                        onWheel: function(event) {
                            root.setTempAt(tempCell.index,
                                tempCell.temp + (event.angleDelta.y > 0 ? 1 : -1))
                            root.pointsEdited()
                            event.accepted = true
                        }
                    }

                    PC3.ToolTip.visible: tempHover.containsMouse && !tempCell.editing
                    PC3.ToolTip.delay: 500
                    PC3.ToolTip.text: i18n("Scroll or click to set temperature")
                }
            }
        }
    }
}
