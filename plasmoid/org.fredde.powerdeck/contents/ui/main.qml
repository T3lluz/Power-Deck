pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // card container that visually groups one section of controls
    component SectionCard: Rectangle {
        default property alias content: cardColumn.data

        Layout.fillWidth: true
        implicitHeight: cardColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.smallSpacing * 1.5
        color: Theme.alpha(Kirigami.Theme.textColor, 0.045)
        border.width: 1
        border.color: Theme.alpha(Kirigami.Theme.textColor, 0.08)

        ColumnLayout {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
        }
    }

    // compact pill showing one temperature reading, tinted by heat level
    component TempPill: Rectangle {
        id: pill

        property string sensorLabel
        property int temp: -1
        readonly property color heat: temp < 0 ? Kirigami.Theme.disabledTextColor
            : temp >= 85 ? Theme.red
            : temp >= 70 ? Theme.amber
            : Theme.teal

        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.4)
        radius: height / 2
        color: Theme.alpha(heat, 0.10)
        border.width: 1
        border.color: Theme.alpha(heat, 0.3)

        Behavior on border.color {
            ColorAnimation { duration: Theme.durSlow }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.durSlow }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            PC3.Label {
                text: pill.sensorLabel
                color: Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
            }

            PC3.Label {
                text: pill.temp >= 0 ? i18n("%1°C", pill.temp) : i18n("—")
                color: pill.heat
                font.weight: Font.Bold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }
        }
    }

    property string currentProfile: "unknown"
    property string previousProfile: "unknown"
    property bool isSwitching: false

    property bool animeOn: false
    property bool animeDisplayOn: false
    property string animeShape: "banner"
    property bool animeBatteryOff: true

    property bool kbdIdleOn: false
    property int kbdTimeout: 60
    property bool kbdKeepAc: false
    property int kbdBrightness: 1
    property bool kbdSliderPressed: false

    property bool fnLockOn: false

    property int cpuTemp: -1
    property int gpuTemp: -1

    property int chargeLimit: 100
    property bool chargeSliderPressed: false

    property string refreshMode: "high"
    property int refreshLowHz: 60
    property int refreshHighHz: 60
    property int refreshCurrentHz: 60

    readonly property string binDir: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().substring(7) + "/.local/bin"
    readonly property string scriptPath: binDir + "/ghelper-profile"
    readonly property string animeScriptPath: binDir + "/anime-ctl"
    readonly property string kbdScriptPath: binDir + "/kbd-idle-ctl"
    readonly property string fnScriptPath: binDir + "/fnlock-ctl"
    readonly property string refreshScriptPath: binDir + "/refresh-ctl"
    readonly property string tempScriptPath: binDir + "/temp-ctl"
    readonly property string chargeScriptPath: binDir + "/charge-ctl"
    readonly property var profiles: ["extreme", "power", "balanced", "performance"]

    readonly property var profileData: ({
        "extreme": {
            label: i18n("EXTREME"),
            name: i18n("Extreme Saver"),
            desc: i18n("60 Hz · max savings"),
            icon: Qt.resolvedUrl("../images/extreme.svg"),
            accent: Theme.teal,
            burst: "pulse"
        },
        "power": {
            label: i18n("POWER"),
            name: i18n("Power Saver"),
            desc: i18n("Low power · quiet"),
            icon: Qt.resolvedUrl("../images/power.svg"),
            accent: Theme.green,
            burst: "charge"
        },
        "balanced": {
            label: i18n("BALANCED"),
            name: i18n("Balanced"),
            desc: i18n("Everyday use"),
            icon: Qt.resolvedUrl("../images/balanced.svg"),
            accent: Theme.blue,
            burst: "sweep"
        },
        "performance": {
            label: i18n("PERFORMANCE"),
            name: i18n("Performance"),
            desc: i18n("Max performance"),
            icon: Qt.resolvedUrl("../images/performance.svg"),
            accent: Theme.amber,
            burst: "dash"
        }
    })

    function dataFor(profile) {
        return profileData[profile] || {
            label: i18n("…"),
            name: i18n("Unknown"),
            desc: i18n("Reading profile…"),
            icon: Qt.resolvedUrl("../images/balanced.svg"),
            accent: Theme.red
        }
    }

    Plasmoid.icon: "preferences-system-power-management"
    Plasmoid.status: PlasmaCore.Types.PassiveStatus

    toolTipMainText: i18n("Power Deck — %1", dataFor(currentProfile).name)
    toolTipSubText: i18n("CPU %1 · GPU %2 · %3 Hz",
        cpuTemp >= 0 ? i18n("%1°C", cpuTemp) : i18n("—"),
        gpuTemp >= 0 ? i18n("%1°C", gpuTemp) : i18n("—"),
        refreshCurrentHz)

    switchWidth: Kirigami.Units.gridUnit * 19
    switchHeight: fullRepresentationItem && fullRepresentationItem.implicitHeight > 0
        ? fullRepresentationItem.implicitHeight
        : Kirigami.Units.gridUnit * 12

    Plasma5Support.DataSource {
        id: execDataSource
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) {
                var output = data["stdout"].trim()
                if (sourceName.indexOf("anime-ctl") !== -1) {
                    if (sourceName.indexOf("status") !== -1) {
                        var parts = output.split(" ")
                        if (parts.length >= 2) {
                            root.animeOn = (parts[0] === "on")
                            if (parts[1] === "banner" || parts[1] === "logo") {
                                root.animeShape = parts[1]
                            }
                            if (parts.length >= 3) {
                                root.animeBatteryOff = (parts[2] === "yes")
                            }
                            if (parts.length >= 4) {
                                root.animeDisplayOn = (parts[3] === "on")
                            } else {
                                root.animeDisplayOn = root.animeOn
                            }
                        }
                    }
                } else if (sourceName.indexOf("kbd-idle-ctl") !== -1) {
                    if (sourceName.indexOf("status") !== -1) {
                        var kparts = output.split(" ")
                        if (kparts.length >= 2) {
                            root.kbdIdleOn = (kparts[0] === "on")
                            var t = parseInt(kparts[1])
                            if (!isNaN(t) && t > 0) root.kbdTimeout = t
                            if (kparts.length >= 3) {
                                root.kbdKeepAc = (kparts[2] === "yes")
                            }
                            if (kparts.length >= 4) {
                                var b = parseInt(kparts[3])
                                if (!isNaN(b) && b >= 0 && b <= 3 && !root.kbdSliderPressed) {
                                    root.kbdBrightness = b
                                }
                            }
                        }
                    }
                } else if (sourceName.indexOf("refresh-ctl") !== -1) {
                    if (sourceName.indexOf("status") !== -1) {
                        var rparts = output.split(" ")
                        if (rparts.length >= 4) {
                            if (rparts[0] === "auto" || rparts[0] === "low" || rparts[0] === "high") {
                                root.refreshMode = rparts[0]
                            }
                            var lo = parseInt(rparts[1])
                            var hi = parseInt(rparts[2])
                            var cur = parseInt(rparts[3])
                            if (!isNaN(lo) && lo > 0) root.refreshLowHz = lo
                            if (!isNaN(hi) && hi > 0) root.refreshHighHz = hi
                            if (!isNaN(cur) && cur > 0) root.refreshCurrentHz = cur
                        }
                    }
                } else if (sourceName.indexOf("temp-ctl") !== -1) {
                    var tparts = output.split(" ")
                    if (tparts.length >= 2) {
                        var ct = parseInt(tparts[0])
                        var gt = parseInt(tparts[1])
                        root.cpuTemp = isNaN(ct) ? -1 : ct
                        root.gpuTemp = isNaN(gt) ? -1 : gt
                    }
                } else if (sourceName.indexOf("charge-ctl") !== -1) {
                    if (sourceName.indexOf("status") !== -1) {
                        var cl = parseInt(output)
                        if (!isNaN(cl) && cl >= 20 && cl <= 100 && !root.chargeSliderPressed) {
                            root.chargeLimit = cl
                        }
                    }
                } else if (sourceName.indexOf("fnlock-ctl") !== -1) {
                    if (sourceName.indexOf("status") !== -1) {
                        if (output === "on" || output === "off") {
                            root.fnLockOn = (output === "on")
                        }
                    }
                } else if (root.profiles.indexOf(output) !== -1) {
                    // Ignore polled status while a switch is in flight,
                    // otherwise a stale poll reverts the user's choice.
                    if (!isSwitching) {
                        previousProfile = currentProfile
                        currentProfile = output
                    }
                }
            }
            disconnectSource(sourceName)
        }
    }

    function setProfile(profile) {
        if (profile === currentProfile) return
        isSwitching = true
        execDataSource.connectSource(scriptPath + " " + profile)
        previousProfile = currentProfile
        currentProfile = profile
        switchReset.restart()
    }

    function cycleProfile(direction) {
        var idx = profiles.indexOf(currentProfile)
        if (idx === -1) idx = 2
        idx = (idx + direction + profiles.length) % profiles.length
        setProfile(profiles[idx])
    }

    function setAnimePower(on) {
        animeOn = on
        execDataSource.connectSource(animeScriptPath + (on ? " on" : " off"))
    }

    function setAnimeShape(shape) {
        if (shape === animeShape) return
        animeShape = shape
        execDataSource.connectSource(animeScriptPath + " " + shape)
    }

    function setAnimeBatteryOff(on) {
        animeBatteryOff = on
        execDataSource.connectSource(animeScriptPath + " battery-off " + (on ? "on" : "off"))
    }

    function setKbdIdle(on) {
        kbdIdleOn = on
        execDataSource.connectSource(kbdScriptPath + (on ? " on" : " off"))
    }

    function setKbdTimeout(seconds) {
        if (seconds === kbdTimeout || seconds < 5) return
        kbdTimeout = seconds
        execDataSource.connectSource(kbdScriptPath + " timeout " + seconds)
    }

    function setKbdKeepAc(on) {
        kbdKeepAc = on
        execDataSource.connectSource(kbdScriptPath + " keep-ac " + (on ? "on" : "off"))
    }

    function setKbdBrightness(level) {
        if (level === kbdBrightness) return
        kbdBrightness = level
        execDataSource.connectSource(kbdScriptPath + " brightness " + level)
    }

    function setFnLock(on) {
        fnLockOn = on
        execDataSource.connectSource(fnScriptPath + (on ? " on" : " off"))
    }

    function setChargeLimit(limit) {
        if (limit === chargeLimit) return
        chargeLimit = limit
        execDataSource.connectSource(chargeScriptPath + " " + limit)
    }

    function setRefreshMode(mode) {
        refreshMode = mode
        execDataSource.connectSource(refreshScriptPath + " " + mode)
    }

    function refreshAnime() {
        // sync is idempotent: it only touches asusctl when the physical
        // display state disagrees with the saved preference + power source.
        execDataSource.connectSource(animeScriptPath + " sync")
        execDataSource.connectSource(animeScriptPath + " status")
    }

    function refreshProfile() {
        execDataSource.connectSource(scriptPath + " status")
        refreshAnime()
        execDataSource.connectSource(kbdScriptPath + " status")
        execDataSource.connectSource(fnScriptPath + " status")
        execDataSource.connectSource(refreshScriptPath + " status")
        execDataSource.connectSource(tempScriptPath)
        execDataSource.connectSource(chargeScriptPath + " status")
    }

    Timer {
        id: switchReset
        interval: 4000
        repeat: false
        onTriggered: { isSwitching = false }
    }

    compactRepresentation: Item {
        implicitWidth: compactRow.implicitWidth + Kirigami.Units.largeSpacing * 3
        implicitHeight: Kirigami.Units.gridUnit * 1.75
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) cycleProfile(-1)
                else cycleProfile(1)
            }

            RowLayout {
                id: compactRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing

                ProfileIconBadge {
                    iconSource: dataFor(currentProfile).icon
                    accentColor: dataFor(currentProfile).accent
                    badgeSize: Kirigami.Units.iconSizes.smallMedium
                    active: true
                }

                PC3.Label {
                    text: dataFor(currentProfile).label
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: fullRep
        collapseMarginsHint: true

        Layout.preferredWidth: Kirigami.Units.gridUnit * 19
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: menuColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing * 1.5

            // ================= header =================
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 1.5

                ProfileIconBadge {
                    iconSource: dataFor(currentProfile).icon
                    accentColor: dataFor(currentProfile).accent
                    badgeSize: Math.round(Kirigami.Units.gridUnit * 2.1)
                    active: true
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("POWER DECK")
                        color: Theme.alpha(Theme.red, 0.9)
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2.2
                        elide: Text.ElideRight
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: dataFor(currentProfile).name
                        color: Kirigami.Theme.textColor
                        font.weight: Font.Bold
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
                        elide: Text.ElideRight
                    }
                }

                // live refresh-rate readout
                Rectangle {
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.3)
                    Layout.preferredWidth: hzLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                    radius: height / 2
                    color: Theme.alpha(Theme.red, 0.12)
                    border.width: 1
                    border.color: Theme.alpha(Theme.red, 0.35)

                    PC3.Label {
                        id: hzLabel
                        anchors.centerIn: parent
                        text: i18n("%1 Hz", root.refreshCurrentHz)
                        color: Theme.redBright
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
            }

            // ================= thermals =================
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                TempPill {
                    sensorLabel: i18n("CPU")
                    temp: root.cpuTemp
                }

                TempPill {
                    sensorLabel: i18n("GPU")
                    temp: root.gpuTemp
                }
            }

            // ================= profiles =================
            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.profiles

                    ProfileCard {
                        required property string modelData
                        profileName: dataFor(modelData).name
                        profileDesc: dataFor(modelData).desc
                        iconSource: dataFor(modelData).icon
                        accentColor: dataFor(modelData).accent
                        burstEffect: dataFor(modelData).burst || "pulse"
                        isActive: currentProfile === modelData
                        onClicked: setProfile(modelData)
                    }
                }
            }

            // ================= AniMe Matrix =================
            SectionCard {
                SectionHeader {
                    title: i18n("ANIME MATRIX")
                    iconSource: Qt.resolvedUrl("../images/anime.svg")
                    active: root.animeDisplayOn

                    RogSwitch {
                        checked: root.animeOn
                        onToggled: function(checked) { setAnimePower(checked) }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    enabled: root.animeOn
                    opacity: root.animeOn ? 1.0 : Theme.offOpacity
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easeOut }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        AnimeChip {
                            label: i18n("Banner")
                            isActive: root.animeShape === "banner"
                            chipEnabled: root.animeOn
                            // dimmed but still selected while the display is
                            // suspended on battery power
                            opacity: !root.animeOn ? Theme.offOpacity
                                : root.animeDisplayOn ? 1.0 : 0.55
                            onClicked: setAnimeShape("banner")
                        }

                        AnimeChip {
                            label: i18n("Logo")
                            isActive: root.animeShape === "logo"
                            chipEnabled: root.animeOn
                            opacity: !root.animeOn ? Theme.offOpacity
                                : root.animeDisplayOn ? 1.0 : 0.55
                            onClicked: setAnimeShape("logo")
                        }
                    }

                    RogCheck {
                        Layout.fillWidth: true
                        text: i18n("Turn off on battery")
                        checked: root.animeBatteryOff
                        onToggled: function(checked) { setAnimeBatteryOff(checked) }
                    }
                }
            }

            // ================= keyboard =================
            SectionCard {
                SectionHeader {
                    title: i18n("KEYBOARD BACKLIGHT")
                    iconSource: Qt.resolvedUrl("../images/kbd.svg")
                    active: true
                }

                // brightness
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PC3.Label {
                        text: i18n("Brightness")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }

                    PC3.Slider {
                        id: kbdBriSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 3
                        stepSize: 1
                        snapMode: PC3.Slider.SnapAlways
                        value: root.kbdBrightness
                        onPressedChanged: root.kbdSliderPressed = pressed
                        onMoved: setKbdBrightness(Math.round(value))
                    }

                    PC3.Label {
                        Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 2)
                        text: root.kbdBrightness === 0 ? i18n("Off")
                            : root.kbdBrightness === 1 ? i18n("30%")
                            : root.kbdBrightness === 2 ? i18n("60%")
                            : i18n("100%")
                        color: Kirigami.Theme.textColor
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // idle timer toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("Turn off when idle")
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        elide: Text.ElideRight
                    }

                    RogSwitch {
                        checked: root.kbdIdleOn
                        onToggled: function(checked) { setKbdIdle(checked) }
                    }
                }

                // idle timer details
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    enabled: root.kbdIdleOn
                    opacity: root.kbdIdleOn ? 1.0 : Theme.offOpacity
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easeOut }
                    }

                    PC3.Label {
                        text: i18n("After")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }

                    PC3.SpinBox {
                        Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 5.5)
                        from: 5
                        to: 3600
                        stepSize: 5
                        editable: true
                        value: root.kbdTimeout
                        textFromValue: function(value, locale) {
                            return i18n("%1 s", value)
                        }
                        valueFromText: function(text, locale) {
                            var n = parseInt(text.replace(/[^0-9]/g, ""))
                            return isNaN(n) ? root.kbdTimeout : n
                        }
                        onValueModified: setKbdTimeout(value)
                    }

                    Item { Layout.fillWidth: true }

                    RogCheck {
                        Layout.rightMargin: Kirigami.Units.smallSpacing
                        text: i18n("Keep on AC")
                        checked: root.kbdKeepAc
                        onToggled: function(checked) { setKbdKeepAc(checked) }
                    }
                }

                // FN-lock
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing * 0.5
                    spacing: Kirigami.Units.smallSpacing

                    ProfileIconBadge {
                        iconSource: Qt.resolvedUrl("../images/fn.svg")
                        accentColor: Theme.red
                        badgeSize: Math.round(Kirigami.Units.gridUnit * 1.2)
                        active: root.fnLockOn
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("FN-lock — F-keys act as media keys")
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        elide: Text.ElideRight
                    }

                    RogSwitch {
                        checked: root.fnLockOn
                        onToggled: function(checked) { setFnLock(checked) }
                    }
                }
            }

            // ================= refresh rate =================
            SectionCard {
                SectionHeader {
                    title: i18n("REFRESH RATE")
                    iconSource: Qt.resolvedUrl("../images/hz.svg")
                    active: true

                    PC3.Label {
                        text: i18n("%1 Hz", root.refreshCurrentHz)
                        color: Theme.redBright
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    AnimeChip {
                        label: i18n("Auto")
                        isActive: root.refreshMode === "auto"
                        onClicked: setRefreshMode("auto")
                    }

                    AnimeChip {
                        // Hidden on panels with a single refresh rate.
                        visible: root.refreshLowHz !== root.refreshHighHz
                        label: i18n("%1 Hz", root.refreshLowHz)
                        isActive: root.refreshMode === "low"
                        onClicked: setRefreshMode("low")
                    }

                    AnimeChip {
                        label: i18n("%1 Hz", root.refreshHighHz)
                        isActive: root.refreshMode === "high"
                        onClicked: setRefreshMode("high")
                    }
                }
            }

            // ================= battery =================
            SectionCard {
                SectionHeader {
                    title: i18n("CHARGE LIMIT")
                    iconSource: Qt.resolvedUrl("../images/battery.svg")
                    active: true

                    PC3.Label {
                        text: root.chargeLimit >= 100
                            ? i18n("Full")
                            : i18n("%1%", root.chargeLimit)
                        color: root.chargeLimit >= 100 ? Theme.redBright : Theme.green
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PC3.Label {
                        text: i18n("80%")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }

                    PC3.Slider {
                        Layout.fillWidth: true
                        from: 80
                        to: 100
                        stepSize: 5
                        snapMode: PC3.Slider.SnapAlways
                        value: root.chargeLimit < 80 ? 80 : root.chargeLimit
                        onPressedChanged: root.chargeSliderPressed = pressed
                        onMoved: setChargeLimit(Math.round(value))
                    }

                    PC3.Label {
                        text: i18n("100%")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
            }

            // ================= footer =================
            PC3.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Scroll on the panel icon to cycle profiles")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                opacity: 0.5
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    Component.onCompleted: {
        refreshProfile()
        refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 3000
        repeat: true
        onTriggered: refreshProfile()
    }
}
