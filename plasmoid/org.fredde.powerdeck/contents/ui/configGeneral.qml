import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property int cfg_displayMode
    property bool cfg_showIcon
    property bool cfg_showProfile
    property bool cfg_showCpuTemp
    property bool cfg_showGpuTemp
    property bool cfg_showCpuWatts
    property bool cfg_showGpuWatts
    property bool cfg_showBattery
    property bool cfg_showBatteryWatts
    property bool cfg_showBatteryTime
    property bool cfg_showFans
    property bool cfg_showRefresh
    property bool cfg_showSeparators
    property bool cfg_showMiniBars
    property string cfg_metricOrder
    property string cfg_tempUnit
    property bool cfg_showNotifications
    property bool cfg_monochrome
    property int cfg_monoAccent
    property int cfg_fanCpuMaxRpm
    property int cfg_fanGpuMaxRpm

    readonly property var defaultOrder: [
        "profile", "cpuTemp", "gpuTemp", "cpuWatts",
        "gpuWatts", "battery", "batteryWatts", "batteryTime", "fans", "refresh"
    ]

    readonly property var metricCatalog: [
        { id: "profile",      label: i18n("Profile"),       shortLabel: i18n("Profile"), kind: "profile", tint: "#7d93f0" },
        { id: "cpuTemp",      label: i18n("CPU temp"),      shortLabel: i18n("CPU °"),  kind: "cpu",     tint: "#2dd4bf" },
        { id: "gpuTemp",      label: i18n("GPU temp"),      shortLabel: i18n("GPU °"),  kind: "gpu",     tint: "#a78bfa" },
        { id: "cpuWatts",     label: i18n("CPU power"),     shortLabel: i18n("CPU W"),  kind: "watt",    tint: "#2dd4bf" },
        { id: "gpuWatts",     label: i18n("GPU power"),     shortLabel: i18n("GPU W"),  kind: "watt",    tint: "#a78bfa" },
        { id: "battery",      label: i18n("Battery %"),     shortLabel: i18n("Batt %"), kind: "battery", tint: "#34d399" },
        { id: "batteryWatts", label: i18n("Battery power"), shortLabel: i18n("Batt W"), kind: "battery", tint: "#fb923c" },
        { id: "batteryTime",  label: i18n("Battery time"),  shortLabel: i18n("Time"),   kind: "clock",   tint: "#34d399" },
        { id: "fans",         label: i18n("Fan speeds"),    shortLabel: i18n("Fans"),   kind: "fan",     tint: "#fb923c" },
        { id: "refresh",      label: i18n("Refresh rate"),  shortLabel: i18n("Hz"),     kind: "hz",      tint: "#22d3ee" }
    ]

    readonly property var dataCatalog: {
        var out = []
        for (var i = 0; i < metricCatalog.length; i++) {
            if (metricCatalog[i].id !== "profile")
                out.push(metricCatalog[i])
        }
        return out
    }

    readonly property var extraCatalog: [
        { id: "separators", label: i18n("Separators"),    kind: "dots", tint: "#9aa7bd" },
        { id: "bars",       label: i18n("Mini bars"),     kind: "bars", tint: "#7d93f0" },
        { id: "notify",     label: i18n("Notifications"), kind: "bell", tint: "#f4b73d" }
    ]

    readonly property color muted: "#9aa7bd"
    readonly property color accent: "#7d93f0"
    readonly property color teal: "#2dd4bf"
    readonly property color amber: "#f4b73d"
    readonly property color iconGraphics: "#a78bfa"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    readonly property var accentOptions: [
        { name: i18n("White"),  color: "#e6e9ef" },
        { name: i18n("Green"),  color: "#34d399" },
        { name: i18n("Teal"),   color: "#2dd4bf" },
        { name: i18n("Orange"), color: "#fb923c" },
        { name: i18n("Red"),    color: "#f2596a" },
        { name: i18n("Blue"),   color: "#56b6f0" },
        { name: i18n("Purple"), color: "#a78bfa" }
    ]

    property bool writingOrder: false

    readonly property string showStamp: [
        cfg_showIcon, cfg_showProfile, cfg_showCpuTemp, cfg_showGpuTemp,
        cfg_showCpuWatts, cfg_showGpuWatts, cfg_showBattery, cfg_showBatteryWatts,
        cfg_showBatteryTime, cfg_showFans, cfg_showRefresh,
        cfg_showSeparators, cfg_showMiniBars, cfg_showNotifications, cfg_monochrome
    ].join(",")

    ListModel { id: orderModel }

    function parseOrder(raw) {
        var known = {}
        var out = []
        var parts = String(raw || "").split(",")
        for (var i = 0; i < parts.length; i++) {
            var id = parts[i].trim()
            if (id === "icon")
                id = "profile"
            if (root.defaultOrder.indexOf(id) !== -1 && !known[id]) {
                known[id] = true
                out.push(id)
            }
        }
        for (var j = 0; j < root.defaultOrder.length; j++) {
            if (!known[root.defaultOrder[j]])
                out.push(root.defaultOrder[j])
        }
        return out
    }

    function reloadModel() {
        if (root.writingOrder)
            return
        orderModel.clear()
        var ids = parseOrder(root.cfg_metricOrder)
        for (var i = 0; i < ids.length; i++)
            orderModel.append({ mid: ids[i] })
    }

    function writeOrder() {
        var ids = []
        for (var i = 0; i < orderModel.count; i++)
            ids.push(orderModel.get(i).mid)
        root.writingOrder = true
        root.cfg_metricOrder = ids.join(",")
        root.writingOrder = false
    }

    function moveItem(index, dir) {
        var dest = index + dir
        if (dest < 0 || dest >= orderModel.count)
            return
        orderModel.move(index, dest, 1)
        writeOrder()
    }

    function catalogEntry(id) {
        for (var i = 0; i < root.metricCatalog.length; i++) {
            if (root.metricCatalog[i].id === id)
                return root.metricCatalog[i]
        }
        return { id: id, label: id, shortLabel: id, kind: "cpu", tint: "#9aa7bd" }
    }

    function showFor(id) {
        switch (id) {
        case "icon": return root.cfg_showIcon
        case "name": return root.cfg_showProfile
        case "profile": return root.cfg_showIcon || root.cfg_showProfile
        case "cpuTemp": return root.cfg_showCpuTemp
        case "gpuTemp": return root.cfg_showGpuTemp
        case "cpuWatts": return root.cfg_showCpuWatts
        case "gpuWatts": return root.cfg_showGpuWatts
        case "battery": return root.cfg_showBattery
        case "batteryWatts": return root.cfg_showBatteryWatts
        case "batteryTime": return root.cfg_showBatteryTime
        case "fans": return root.cfg_showFans
        case "refresh": return root.cfg_showRefresh
        case "separators": return root.cfg_showSeparators
        case "bars": return root.cfg_showMiniBars
        case "notify": return root.cfg_showNotifications
        }
        return false
    }

    function setShow(id, on) {
        switch (id) {
        case "icon": root.cfg_showIcon = on; break
        case "name": root.cfg_showProfile = on; break
        case "profile":
            root.cfg_showIcon = on
            root.cfg_showProfile = on
            break
        case "cpuTemp": root.cfg_showCpuTemp = on; break
        case "gpuTemp": root.cfg_showGpuTemp = on; break
        case "cpuWatts": root.cfg_showCpuWatts = on; break
        case "gpuWatts": root.cfg_showGpuWatts = on; break
        case "battery": root.cfg_showBattery = on; break
        case "batteryWatts": root.cfg_showBatteryWatts = on; break
        case "batteryTime": root.cfg_showBatteryTime = on; break
        case "fans": root.cfg_showFans = on; break
        case "refresh": root.cfg_showRefresh = on; break
        case "separators": root.cfg_showSeparators = on; break
        case "bars": root.cfg_showMiniBars = on; break
        case "notify": root.cfg_showNotifications = on; break
        }
    }

    onCfg_metricOrderChanged: reloadModel()
    Component.onCompleted: reloadModel()

    component SectionCard: Rectangle {
        id: card
        default property alias content: inner.data
        property string title

        Layout.fillWidth: true
        implicitHeight: head.implicitHeight + inner.implicitHeight + Kirigami.Units.largeSpacing * 2.5
        radius: Kirigami.Units.smallSpacing * 1.5
        color: root.alpha(Kirigami.Theme.textColor, 0.04)
        border.width: 1
        border.color: root.alpha(Kirigami.Theme.textColor, 0.08)

        QQC2.Label {
            id: head
            x: Kirigami.Units.largeSpacing
            y: Kirigami.Units.largeSpacing
            width: parent.width - Kirigami.Units.largeSpacing * 2
            text: card.title
            color: root.muted
            font.weight: Font.DemiBold
            font.letterSpacing: 1.4
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        ColumnLayout {
            id: inner
            x: Kirigami.Units.largeSpacing
            y: head.y + head.implicitHeight + Kirigami.Units.smallSpacing * 1.5
            width: parent.width - Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.smallSpacing * 1.5
        }
    }

    component ToggleTile: Rectangle {
        id: tile

        property string mid
        property string label
        property string kind
        property color accent
        readonly property bool on: {
            var _ = root.showStamp
            return root.showFor(tile.mid)
        }

        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 4.4
        radius: Kirigami.Units.smallSpacing * 1.4
        color: on ? root.alpha(accent, 0.16) : root.alpha(Kirigami.Theme.textColor, 0.035)
        border.width: on ? 2 : 1
        border.color: on ? root.alpha(accent, 0.55)
                         : root.alpha(Kirigami.Theme.textColor, 0.10)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.smallSpacing * 2
            spacing: Kirigami.Units.smallSpacing * 0.6

            MetricIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                kind: tile.kind
                color: tile.on ? tile.accent : root.muted
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: tile.label
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: tile.on ? Font.DemiBold : Font.Normal
                color: tile.on ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            }
        }

        HoverHandler { id: tileHover }
        TapHandler { onTapped: root.setShow(tile.mid, !tile.on) }

        QQC2.ToolTip.visible: tileHover.hovered
        QQC2.ToolTip.text: tile.on ? i18n("On") : i18n("Off")
    }

    component ChoiceTile: Rectangle {
        id: choice

        property bool selected: false
        property string label
        property string kind
        property color accent: root.accent
        signal picked

        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
        radius: Kirigami.Units.smallSpacing * 1.4
        color: selected ? root.alpha(accent, 0.16) : root.alpha(Kirigami.Theme.textColor, 0.035)
        border.width: selected ? 2 : 1
        border.color: selected ? root.alpha(accent, 0.55)
                               : root.alpha(Kirigami.Theme.textColor, 0.10)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 0.5

            MetricIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                kind: choice.kind
                color: choice.selected ? choice.accent : root.muted
            }

            QQC2.Label {
                text: choice.label
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: choice.selected ? Font.DemiBold : Font.Normal
                color: choice.selected ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            }
        }

        TapHandler { onTapped: choice.picked() }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        SectionCard {
            title: i18n("APPEARANCE")

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                MetricIcon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    kind: "bars"
                    color: root.cfg_monochrome ? root.accentOptions[root.cfg_monoAccent].color : root.accent
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Monochrome palette")
                    font.weight: Font.DemiBold
                }

                QQC2.Switch {
                    checked: root.cfg_monochrome
                    onToggled: root.cfg_monochrome = checked
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Accent")
                color: root.muted
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 1.2
                opacity: root.cfg_monochrome ? 1.0 : 0.55

                Repeater {
                    model: root.accentOptions

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        readonly property bool selected: root.cfg_monoAccent === index

                        implicitWidth: Kirigami.Units.gridUnit * 1.7
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: modelData.color
                        border.width: selected ? 3 : 1
                        border.color: selected
                            ? Kirigami.Theme.textColor
                            : Qt.rgba(Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b, 0.28)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: parent.width * 0.5
                            height: width
                            source: "checkmark"
                            visible: parent.selected
                            color: index === 0 ? "#222428" : "#ffffff"
                            isMask: true
                        }

                        QQC2.ToolTip.visible: swatchHover.hovered
                        QQC2.ToolTip.text: modelData.name
                        HoverHandler { id: swatchHover }
                        TapHandler { onTapped: root.cfg_monoAccent = index }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: root.cfg_monochrome
                text: i18n("White stays fully neutral. A hue tints the active controls and panel glyph.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Display style")
                color: root.muted
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                ChoiceTile {
                    label: i18n("Icons + values")
                    kind: "both"
                    selected: root.cfg_displayMode === 0
                    onPicked: root.cfg_displayMode = 0
                }
                ChoiceTile {
                    label: i18n("Values only")
                    kind: "text"
                    selected: root.cfg_displayMode === 1
                    onPicked: root.cfg_displayMode = 1
                }
                ChoiceTile {
                    label: i18n("Icons only")
                    kind: "profile"
                    selected: root.cfg_displayMode === 2
                    onPicked: root.cfg_displayMode = 2
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Temperature")
                color: root.muted
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                ChoiceTile {
                    label: i18n("Celsius (°C)")
                    kind: "cpu"
                    accent: root.teal
                    selected: root.cfg_tempUnit !== "F"
                    onPicked: root.cfg_tempUnit = "C"
                }
                ChoiceTile {
                    label: i18n("Fahrenheit (°F)")
                    kind: "cpu"
                    accent: root.amber
                    selected: root.cfg_tempUnit === "F"
                    onPicked: root.cfg_tempUnit = "F"
                }
            }
        }

        SectionCard {
            title: i18n("PANEL ITEMS")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: profileInner.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing * 1.4
                color: {
                    var _ = root.showStamp
                    return (root.cfg_showIcon || root.cfg_showProfile)
                        ? root.alpha("#7d93f0", 0.12)
                        : root.alpha(Kirigami.Theme.textColor, 0.03)
                }
                border.width: 1
                border.color: {
                    var _ = root.showStamp
                    return (root.cfg_showIcon || root.cfg_showProfile)
                        ? root.alpha("#7d93f0", 0.4)
                        : root.alpha(Kirigami.Theme.textColor, 0.10)
                }

                ColumnLayout {
                    id: profileInner
                    x: Kirigami.Units.smallSpacing * 1.5
                    y: Kirigami.Units.smallSpacing * 1.5
                    width: parent.width - Kirigami.Units.smallSpacing * 3
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        MetricIcon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            kind: "profile"
                            color: "#7d93f0"
                        }
                        QQC2.Label {
                            text: i18n("Profile")
                            font.weight: Font.DemiBold
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("Icon and name move together")
                            color: Kirigami.Theme.disabledTextColor
                            font: Kirigami.Theme.smallFont
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        ToggleTile {
                            mid: "icon"
                            label: i18n("Icon")
                            kind: "profile"
                            accent: "#7d93f0"
                        }
                        ToggleTile {
                            mid: "name"
                            label: i18n("Name")
                            kind: "text"
                            accent: "#56b6f0"
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.dataCatalog

                    ToggleTile {
                        required property var modelData
                        mid: modelData.id
                        label: modelData.label
                        kind: modelData.kind
                        accent: modelData.tint
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Order")
                color: root.muted
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: orderModel

                    delegate: Rectangle {
                        readonly property int rowIndex: index
                        readonly property string mid: model.mid
                        readonly property var entry: root.catalogEntry(mid)
                        readonly property bool on: {
                            var _ = root.showStamp
                            return root.showFor(mid)
                        }

                        implicitHeight: Kirigami.Units.gridUnit * 1.85
                        implicitWidth: chipRow.implicitWidth + Kirigami.Units.smallSpacing * 1.6
                        radius: height / 2
                        opacity: on ? 1.0 : 0.45
                        color: on ? root.alpha(entry.tint, 0.16)
                                  : root.alpha(Kirigami.Theme.textColor, 0.04)
                        border.width: 1
                        border.color: on ? root.alpha(entry.tint, 0.4)
                                         : root.alpha(Kirigami.Theme.textColor, 0.10)

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 0

                            QQC2.ToolButton {
                                icon.name: "go-previous"
                                enabled: rowIndex > 0
                                implicitWidth: Kirigami.Units.gridUnit * 1.3
                                implicitHeight: implicitWidth
                                display: QQC2.AbstractButton.IconOnly
                                QQC2.ToolTip.text: i18n("Move left")
                                QQC2.ToolTip.visible: hovered
                                onClicked: root.moveItem(rowIndex, -1)
                            }

                            MetricIcon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                kind: entry.kind
                                color: on ? entry.tint : root.muted
                            }

                            QQC2.Label {
                                text: entry.shortLabel
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                font.weight: Font.DemiBold
                                leftPadding: Kirigami.Units.smallSpacing * 0.6
                            }

                            QQC2.ToolButton {
                                icon.name: "go-next"
                                enabled: rowIndex < orderModel.count - 1
                                implicitWidth: Kirigami.Units.gridUnit * 1.3
                                implicitHeight: implicitWidth
                                display: QQC2.AbstractButton.IconOnly
                                QQC2.ToolTip.text: i18n("Move right")
                                QQC2.ToolTip.visible: hovered
                                onClicked: root.moveItem(rowIndex, 1)
                            }
                        }
                    }
                }
            }

            QQC2.Button {
                text: i18n("Reset order")
                onClicked: {
                    root.cfg_metricOrder = root.defaultOrder.join(",")
                    root.reloadModel()
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Tap a tile to show or hide it. Profile icon and name stay together when you reorder. Missing readings hide themselves on the panel.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }

        SectionCard {
            title: i18n("OPTIONS")

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.extraCatalog

                    ToggleTile {
                        required property var modelData
                        mid: modelData.id
                        label: modelData.label
                        kind: modelData.kind
                        accent: modelData.tint
                    }
                }
            }
        }

        SectionCard {
            title: i18n("FANS")

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 0.5

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        MetricIcon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            kind: "cpu"
                            color: root.teal
                        }
                        QQC2.Label {
                            text: i18n("CPU fan max")
                            font.weight: Font.DemiBold
                        }
                    }

                    QQC2.SpinBox {
                        Layout.fillWidth: true
                        from: 2000
                        to: 10000
                        stepSize: 100
                        value: root.cfg_fanCpuMaxRpm
                        onValueModified: root.cfg_fanCpuMaxRpm = value
                        textFromValue: function(value, locale) { return i18n("%1 RPM", value) }
                        valueFromText: function(text, locale) {
                            var n = parseInt(text.replace(/[^0-9]/g, ""), 10)
                            return isNaN(n) ? root.cfg_fanCpuMaxRpm : n
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 0.5

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        MetricIcon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            kind: "gpu"
                            color: root.iconGraphics
                        }
                        QQC2.Label {
                            text: i18n("GPU fan max")
                            font.weight: Font.DemiBold
                        }
                    }

                    QQC2.SpinBox {
                        Layout.fillWidth: true
                        from: 2000
                        to: 10000
                        stepSize: 100
                        value: root.cfg_fanGpuMaxRpm
                        onValueModified: root.cfg_fanGpuMaxRpm = value
                        textFromValue: function(value, locale) { return i18n("%1 RPM", value) }
                        valueFromText: function(text, locale) {
                            var n = parseInt(text.replace(/[^0-9]/g, ""), 10)
                            return isNaN(n) ? root.cfg_fanGpuMaxRpm : n
                        }
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Used to show live speed as a percent of max. Or tap Calibrate on the Fans page — that runs both fans at 100% until the peak holds, records it, then puts your curve back.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }
    }
}
