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

    property string currentProfile: "unknown"
    property string previousProfile: "unknown"
    property bool isSwitching: false

    property bool animeOn: true
    property bool animeDisplayOn: true
    property string animeShape: "banner"
    property bool animeBatteryOff: true

    property bool kbdIdleOn: false
    property int kbdTimeout: 60
    property bool kbdKeepAc: false
    property int kbdBrightness: 1
    property bool kbdSliderPressed: false

    property bool fnLockOn: true

    readonly property string binDir: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().substring(7) + "/.local/bin"
    readonly property string scriptPath: binDir + "/ghelper-profile"
    readonly property string animeScriptPath: binDir + "/anime-ctl"
    readonly property string kbdScriptPath: binDir + "/kbd-idle-ctl"
    readonly property string fnScriptPath: binDir + "/fnlock-ctl"
    readonly property color fnAccent: "#fb923c"
    readonly property var profiles: ["extreme", "power", "balanced", "performance"]
    readonly property color animeAccent: "#c084fc"
    readonly property color kbdAccent: "#67e8f9"

    readonly property var profileData: ({
        "extreme": {
            label: i18n("EXTREME"),
            name: i18n("Extreme Saver"),
            desc: i18n("60 Hz, max savings"),
            icon: Qt.resolvedUrl("../images/extreme.svg"),
            accent: "#2dd4bf"
        },
        "power": {
            label: i18n("POWER"),
            name: i18n("Power Saver"),
            desc: i18n("Low power, quiet fans"),
            icon: Qt.resolvedUrl("../images/power.svg"),
            accent: "#6ee7b7"
        },
        "balanced": {
            label: i18n("BALANCED"),
            name: i18n("Balanced"),
            desc: i18n("Everyday use"),
            icon: Qt.resolvedUrl("../images/balanced.svg"),
            accent: "#60a5fa"
        },
        "performance": {
            label: i18n("TURBO"),
            name: i18n("Performance"),
            desc: i18n("Maximum performance"),
            icon: Qt.resolvedUrl("../images/performance.svg"),
            accent: "#fbbf24"
        }
    })

    function dataFor(profile) {
        return profileData[profile] || {
            label: i18n("…"),
            name: i18n("Unknown"),
            desc: i18n("Reading profile…"),
            icon: Qt.resolvedUrl("../images/balanced.svg"),
            accent: Kirigami.Theme.highlightColor
        }
    }

    function animeShapeName(shape) {
        return shape === "logo" ? i18n("ROG Logo") : i18n("ROG Banner")
    }

    Plasmoid.icon: "preferences-system-power-management"
    Plasmoid.status: PlasmaCore.Types.PassiveStatus

    switchWidth: Kirigami.Units.gridUnit * 17
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

    function refreshAnime() {
        if (animeBatteryOff && animeOn) {
            execDataSource.connectSource(animeScriptPath + " sync")
        }
        execDataSource.connectSource(animeScriptPath + " status")
    }

    function refreshProfile() {
        execDataSource.connectSource(scriptPath + " status")
        refreshAnime()
        execDataSource.connectSource(kbdScriptPath + " status")
        execDataSource.connectSource(fnScriptPath + " status")
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

        Layout.preferredWidth: Kirigami.Units.gridUnit * 17
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.maximumWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: menuColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            // ---- Power profile header ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 1.5

                ProfileIconBadge {
                    iconSource: dataFor(currentProfile).icon
                    accentColor: dataFor(currentProfile).accent
                    badgeSize: Math.round(Kirigami.Units.gridUnit * 2)
                    active: true
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("POWER PROFILE")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        font.letterSpacing: 1.2
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: dataFor(currentProfile).name
                        color: Kirigami.Theme.textColor
                        font.weight: Font.Bold
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.2)
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }
                }
            }

            // ---- Profile grid (2x2) ----
            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing * 0.5
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
                        isActive: currentProfile === modelData
                        onClicked: setProfile(modelData)
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                opacity: 0.4
            }

            // ---- AniMe + Keyboard side by side ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 1.5

                // AniMe column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        ProfileIconBadge {
                            iconSource: Qt.resolvedUrl("../images/anime.svg")
                            accentColor: root.animeAccent
                            badgeSize: Math.round(Kirigami.Units.gridUnit * 1.4)
                            active: root.animeDisplayOn
                        }

                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("ANIME")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.letterSpacing: 1.2
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                        }

                        PC3.Switch {
                            checked: root.animeOn
                            onToggled: setAnimePower(checked)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        AnimeChip {
                            label: i18n("Banner")
                            isActive: root.animeDisplayOn && root.animeShape === "banner"
                            chipEnabled: root.animeOn
                            accentColor: root.animeAccent
                            onClicked: setAnimeShape("banner")
                        }

                        AnimeChip {
                            label: i18n("Logo")
                            isActive: root.animeDisplayOn && root.animeShape === "logo"
                            chipEnabled: root.animeOn
                            accentColor: root.animeAccent
                            onClicked: setAnimeShape("logo")
                        }
                    }

                    PC3.CheckBox {
                        Layout.fillWidth: true
                        text: i18n("Off on battery")
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        checked: root.animeBatteryOff
                        onToggled: setAnimeBatteryOff(checked)
                    }
                }

                Kirigami.Separator {
                    Layout.fillHeight: true
                    opacity: 0.4
                }

                // Keyboard column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        ProfileIconBadge {
                            iconSource: Qt.resolvedUrl("../images/kbd.svg")
                            accentColor: root.kbdAccent
                            badgeSize: Math.round(Kirigami.Units.gridUnit * 1.4)
                            active: root.kbdIdleOn
                        }

                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("LIGHT TIMER")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.letterSpacing: 1.2
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                        }

                        PC3.Switch {
                            checked: root.kbdIdleOn
                            onToggled: setKbdIdle(checked)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        enabled: root.kbdIdleOn
                        opacity: root.kbdIdleOn ? 1.0 : 0.35

                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("Turn off after")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            horizontalAlignment: Text.AlignLeft
                        }

                        PC3.SpinBox {
                            Layout.fillWidth: true
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
                    }

                    PC3.CheckBox {
                        Layout.fillWidth: true
                        text: i18n("Keep on AC")
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        checked: root.kbdKeepAc
                        onToggled: setKbdKeepAc(checked)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true

                            PC3.Label {
                                Layout.fillWidth: true
                                text: i18n("Brightness")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                horizontalAlignment: Text.AlignLeft
                            }

                            PC3.Label {
                                text: root.kbdBrightness === 0 ? i18n("Off")
                                    : root.kbdBrightness === 1 ? i18n("30%")
                                    : root.kbdBrightness === 2 ? i18n("60%")
                                    : i18n("100%")
                                color: Kirigami.Theme.textColor
                                font.weight: Font.DemiBold
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }
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
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                opacity: 0.4
            }

            // ---- FN-lock row ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 1.5

                ProfileIconBadge {
                    iconSource: Qt.resolvedUrl("../images/fn.svg")
                    accentColor: root.fnAccent
                    badgeSize: Math.round(Kirigami.Units.gridUnit * 1.4)
                    active: root.fnLockOn
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: i18n("FN-lock")
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize + 1
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }

                PC3.Switch {
                    checked: root.fnLockOn
                    onToggled: setFnLock(checked)
                }
            }

            PC3.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Scroll on the panel icon to cycle profiles")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                opacity: 0.55
                horizontalAlignment: Text.AlignHCenter
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
