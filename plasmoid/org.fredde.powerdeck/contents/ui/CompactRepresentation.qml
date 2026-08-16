pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Single-line panel widget, same layout language as CasaOSWidget:
// per-metric visibility, icons+values / values / icons, optional dots.
// Order comes from Plasmoid.configuration.metricOrder so the config
// page can rearrange the chips.
//
// Click handling mirrors KDE's DefaultCompactRepresentation: write
// `deck.expanded` (the PlasmoidItem) instead of `Plasmoid.expanded`.
// A dedicated clickLayer sits above the metrics so Text relayout cannot
// swallow the press. hoverEnabled is off — Plasma owns the tooltip via
// toolTipMainText/SubText on the applet.
Item {
    id: root

    required property var deck

    readonly property var defaultOrder: [
        "profile", "cpuTemp", "gpuTemp", "cpuWatts",
        "gpuWatts", "battery", "batteryWatts", "batteryTime", "fans", "refresh"
    ]

    readonly property var orderedIds: parseOrder(Plasmoid.configuration.metricOrder)

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int displayMode: Plasmoid.configuration.displayMode
    readonly property bool showIcons:  displayMode !== 1
    readonly property bool showValues: displayMode !== 2
    readonly property bool sepsOn: Plasmoid.configuration.showSeparators

    readonly property bool vIcon: Plasmoid.configuration.showIcon || !root.anyOther
    readonly property bool vName: Plasmoid.configuration.showProfile && root.showValues
    readonly property bool vProfileGroup: vIcon || vName
    readonly property bool vCpuTemp: Plasmoid.configuration.showCpuTemp && root.deck.cpuTemp >= 0
    readonly property bool vGpuTemp: Plasmoid.configuration.showGpuTemp && root.deck.gpuTemp >= 0
    readonly property bool vCpuWatts: Plasmoid.configuration.showCpuWatts && root.deck.cpuWatts >= 0
    readonly property bool vGpuWatts: Plasmoid.configuration.showGpuWatts && root.deck.gpuWatts >= 0
    readonly property bool vBatPct: Plasmoid.configuration.showBattery && root.deck.batteryPercent >= 0
    readonly property bool vBatWatts: Plasmoid.configuration.showBatteryWatts && root.deck.batteryWatts >= 0
    readonly property bool vBatTime: Plasmoid.configuration.showBatteryTime && root.deck.batteryMinutes >= 0
    readonly property bool vFans: Plasmoid.configuration.showFans
        && (root.deck.fanCpuRpm >= 0 || root.deck.fanGpuRpm >= 0)
    readonly property bool vHz: Plasmoid.configuration.showRefresh && root.deck.refreshCurrentHz > 0

    readonly property bool anyOther: Plasmoid.configuration.showProfile
        || Plasmoid.configuration.showCpuTemp
        || Plasmoid.configuration.showGpuTemp
        || Plasmoid.configuration.showCpuWatts
        || Plasmoid.configuration.showGpuWatts
        || Plasmoid.configuration.showBattery
        || Plasmoid.configuration.showBatteryWatts
        || Plasmoid.configuration.showBatteryTime
        || Plasmoid.configuration.showFans
        || Plasmoid.configuration.showRefresh

    // Stamps so Repeater bindings re-run when visibility or live data change.
    readonly property string visStamp: [
        vIcon, vName, vProfileGroup, vCpuTemp, vGpuTemp, vCpuWatts, vGpuWatts,
        vBatPct, vBatWatts, vBatTime, vFans, vHz
    ].join(",")

    readonly property string dataStamp: [
        deck.currentProfile, deck.cpuTemp, deck.gpuTemp, deck.cpuWatts, deck.gpuWatts,
        deck.batteryPercent, deck.batteryWatts, deck.batteryState, deck.batteryMinutes,
        deck.fanCpuRpm, deck.fanGpuRpm, deck.refreshCurrentHz,
        showIcons, showValues, Plasmoid.configuration.tempUnit
    ].join("|")

    readonly property int panelIconSize: Math.round(
        Math.min(isVertical ? width : height, Kirigami.Units.gridUnit * 2) * 0.92)

    readonly property color batPctColor: {
        if (deck.batteryState === "charging" || deck.onAC)
            return Theme.green
        if (deck.batteryPercent <= 20)
            return Theme.red
        return Kirigami.Theme.textColor
    }

    readonly property string batFlowText: {
        if (deck.batteryWatts < 0)
            return i18n("—")
        if (deck.batteryState === "charging")
            return i18n("↑%1 W", deck.batteryWatts)
        if (deck.batteryState === "discharging")
            return i18n("↓%1 W", deck.batteryWatts)
        return i18n("%1 W", deck.batteryWatts)
    }

    readonly property string fanText: {
        var cpu = formatRpm(deck.fanCpuRpm)
        var gpu = formatRpm(deck.fanGpuRpm)
        if (cpu.length && gpu.length)
            return cpu + " · " + gpu
        return cpu.length ? cpu : gpu
    }

    readonly property real fanBarPercent: {
        var parts = 0
        var sum = 0
        if (deck.fanCpuRpm >= 0 && deck.fanCpuMaxRpm > 0) {
            sum += Math.min(100, deck.fanCpuRpm * 100 / deck.fanCpuMaxRpm)
            parts++
        }
        if (deck.fanGpuRpm >= 0 && deck.fanGpuMaxRpm > 0) {
            sum += Math.min(100, deck.fanGpuRpm * 100 / deck.fanGpuMaxRpm)
            parts++
        }
        return parts > 0 ? sum / parts : -1
    }

    implicitWidth: isVertical
        ? Math.max(Kirigami.Units.gridUnit * 1.75, verticalCol.implicitWidth + Kirigami.Units.smallSpacing * 2)
        : horizontalRow.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: isVertical
        ? verticalCol.implicitHeight + Kirigami.Units.smallSpacing * 2
        : Kirigami.Units.gridUnit * 1.75

    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight

    function parseOrder(raw) {
        var known = {}
        var out = []
        var parts = String(raw || "").split(",")
        for (var i = 0; i < parts.length; i++) {
            var id = parts[i].trim()
            if (id === "icon")
                id = "profile"
            if (defaultOrder.indexOf(id) !== -1 && !known[id]) {
                known[id] = true
                out.push(id)
            }
        }
        for (var j = 0; j < defaultOrder.length; j++) {
            if (!known[defaultOrder[j]])
                out.push(defaultOrder[j])
        }
        return out
    }

    function formatRpm(n) {
        if (n < 0)
            return ""
        if (n >= 1000)
            return (n / 1000).toFixed(1) + "k"
        return String(n)
    }

    function slotVisible(id) {
        switch (id) {
        case "profile": return vProfileGroup
        case "cpuTemp": return vCpuTemp
        case "gpuTemp": return vGpuTemp
        case "cpuWatts": return vCpuWatts
        case "gpuWatts": return vGpuWatts
        case "battery": return vBatPct
        case "batteryWatts": return vBatWatts
        case "batteryTime": return vBatTime
        case "fans": return vFans
        case "refresh": return vHz
        }
        return false
    }

    function hasVisibleBefore(index) {
        for (var i = 0; i < index; i++) {
            if (slotVisible(orderedIds[i]))
                return true
        }
        return false
    }

    function slotKind(id) {
        switch (id) {
        case "cpuTemp": return "cpu"
        case "gpuTemp": return "gpu"
        case "cpuWatts":
        case "gpuWatts": return "watt"
        case "battery":
        case "batteryWatts":
        case "batteryTime": return "battery"
        case "fans": return "fan"
        case "refresh": return "hz"
        }
        return "cpu"
    }

    function slotText(id, stamp) {
        switch (id) {
        case "cpuTemp": return deck.formatTemp(deck.cpuTemp)
        case "gpuTemp": return deck.formatTemp(deck.gpuTemp)
        case "cpuWatts": return i18n("%1 W", deck.cpuWatts)
        case "gpuWatts": return i18n("%1 W", deck.gpuWatts)
        case "battery": return i18n("%1%", deck.batteryPercent)
        case "batteryWatts": return batFlowText
        case "batteryTime": return deck.formatMinutes(deck.batteryMinutes)
        case "fans": return fanText
        case "refresh": return i18n("%1 Hz", deck.refreshCurrentHz)
        }
        return ""
    }

    function slotAccent(id, stamp) {
        switch (id) {
        case "cpuTemp": return Theme.heatColor(deck.cpuTemp)
        case "gpuTemp": return Theme.heatColor(deck.gpuTemp)
        case "cpuWatts": return Theme.teal
        case "gpuWatts": return Theme.iconGraphics
        case "battery":
        case "batteryTime": return batPctColor
        case "batteryWatts": return Theme.batteryFlowColor(deck.batteryState, deck.batteryWatts)
        case "fans": return Theme.iconFan
        case "refresh": return Theme.iconRefresh
        }
        return Kirigami.Theme.textColor
    }

    function slotPercent(id, stamp) {
        switch (id) {
        case "cpuTemp": return deck.cpuTemp
        case "gpuTemp": return deck.gpuTemp
        case "battery": return deck.batteryPercent
        case "fans": return fanBarPercent
        }
        return -1
    }

    RowLayout {
        id: horizontalRow
        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing * 1.5

        Repeater {
            model: root.orderedIds

            delegate: RowLayout {
                id: hSlot
                required property int index
                required property string modelData

                spacing: Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignVCenter
                visible: {
                    var _ = root.visStamp
                    return root.slotVisible(hSlot.modelData)
                }

                Sep {
                    show: {
                        var _ = root.visStamp
                        return root.sepsOn && root.hasVisibleBefore(hSlot.index)
                    }
                }

                ProfileGlyph {
                    visible: hSlot.modelData === "profile" && root.vIcon
                    readonly property int iconSize: root.panelIconSize
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    Layout.alignment: Qt.AlignVCenter
                    kind: root.deck.glyphKind(root.deck.currentProfile)
                    glyphColor: root.deck.dataFor(root.deck.currentProfile).accent
                    glyphSize: iconSize
                    active: true
                }

                Text {
                    visible: hSlot.modelData === "profile" && root.vName
                    text: {
                        var _ = root.dataStamp
                        return root.deck.dataFor(root.deck.currentProfile).label
                    }
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    renderType: Text.NativeRendering
                    Layout.alignment: Qt.AlignVCenter
                }

                Metric {
                    visible: hSlot.modelData !== "profile"
                    kind: root.slotKind(hSlot.modelData)
                    valueText: root.slotText(hSlot.modelData, root.dataStamp)
                    accent: root.slotAccent(hSlot.modelData, root.dataStamp)
                    percent: root.slotPercent(hSlot.modelData, root.dataStamp)
                    showIcon: root.showIcons
                    showValue: root.showValues
                }
            }
        }
    }

    ColumnLayout {
        id: verticalCol
        visible: root.isVertical
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.orderedIds

            delegate: ColumnLayout {
                id: vSlot
                required property int index
                required property string modelData

                spacing: 3
                Layout.alignment: Qt.AlignHCenter
                visible: {
                    var _ = root.visStamp
                    return root.slotVisible(vSlot.modelData)
                }

                Sep {
                    vertical: true
                    show: {
                        var _ = root.visStamp
                        return root.sepsOn && root.hasVisibleBefore(vSlot.index)
                    }
                }

                ProfileGlyph {
                    visible: vSlot.modelData === "profile" && root.vIcon
                    readonly property int iconSize: root.panelIconSize
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    Layout.alignment: Qt.AlignHCenter
                    kind: root.deck.glyphKind(root.deck.currentProfile)
                    glyphColor: root.deck.dataFor(root.deck.currentProfile).accent
                    glyphSize: iconSize
                    active: true
                }

                Text {
                    visible: vSlot.modelData === "profile" && root.vName
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        var _ = root.dataStamp
                        return root.deck.dataFor(root.deck.currentProfile).label
                    }
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    renderType: Text.NativeRendering
                }

                VMetric {
                    visible: vSlot.modelData !== "profile"
                    kind: root.slotKind(vSlot.modelData)
                    valueText: root.slotText(vSlot.modelData, root.dataStamp)
                    accent: root.slotAccent(vSlot.modelData, root.dataStamp)
                    showIcon: root.showIcons
                    showValue: root.showValues
                }
            }
        }
    }

    MouseArea {
        id: clickLayer
        anchors.fill: parent
        z: 1000
        hoverEnabled: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        property bool wasExpanded: false

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = false
                return
            }
            wasExpanded = root.deck.expanded
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = false
                return
            }
            root.deck.expanded = !wasExpanded
        }
        onReleased: function(mouse) {
            if (mouse.button === Qt.RightButton)
                mouse.accepted = false
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                root.deck.cycleProfile(-1)
            else
                root.deck.cycleProfile(1)
        }
    }

    component Sep: Rectangle {
        property bool show: false
        property bool vertical: false
        visible: show
        implicitWidth: 3
        implicitHeight: 3
        radius: 1.5
        color: Theme.muted
        Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    }

    component Metric: RowLayout {
        id: m
        required property string kind
        required property string valueText
        required property color accent
        property real percent: -1
        property bool showIcon: true
        property bool showValue: true

        Layout.alignment: Qt.AlignVCenter
        spacing: Kirigami.Units.smallSpacing

        MetricIcon {
            visible: m.showIcon
            kind: m.kind
            color: m.accent
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: root.panelIconSize
            Layout.preferredHeight: root.panelIconSize
        }

        Text {
            visible: m.showValue
            text: m.valueText
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            renderType: Text.NativeRendering
        }

        Rectangle {
            visible: Plasmoid.configuration.showMiniBars && m.percent >= 0
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
            Layout.preferredHeight: 4
            radius: 2
            color: Theme.alpha(Kirigami.Theme.textColor, 0.12)
            Layout.leftMargin: 2

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, m.percent / 100))
                height: parent.height
                radius: parent.radius
                color: m.accent
                Behavior on width { NumberAnimation { duration: 400; easing.type: Theme.easeOut } }
            }
        }
    }

    component VMetric: ColumnLayout {
        id: vm
        required property string kind
        required property string valueText
        required property color accent
        property bool showIcon: true
        property bool showValue: true

        Layout.alignment: Qt.AlignHCenter
        spacing: 0

        MetricIcon {
            visible: vm.showIcon
            kind: vm.kind
            color: vm.accent
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.panelIconSize
            Layout.preferredHeight: root.panelIconSize
        }
        Text {
            visible: vm.showValue
            Layout.alignment: Qt.AlignHCenter
            text: vm.valueText
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            renderType: Text.NativeRendering
        }
    }
}
