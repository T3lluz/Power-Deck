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
        property int watts: -1
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

            PC3.Label {
                visible: pill.watts >= 0
                text: i18n("%1 W", pill.watts)
                color: Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
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
    property int cpuWatts: -1
    property int gpuWatts: -1

    property int chargeLimit: 100
    property bool chargeSliderPressed: false

    property string batteryState: "unknown"
    property int batteryPercent: -1
    property int batteryMinutes: -1
    property int batteryWatts: -1
    property bool onAC: false
    property bool acKnown: false

    property string gfxMode: "none"
    property string gfxPendingMode: "none"
    property string gfxPendingAction: "none"
    property var gfxSupported: []
    // dGPU hardware state: "off" (not on the bus), "asleep" (D3, ~0 W)
    // or "active" (D0, drawing power)
    property string gfxDgpu: "off"
    // how mode changes apply: "reboot" (always_reboot) or "logout"
    property string gfxPolicy: "reboot"
    // mode awaiting user confirmation in the overlay dialog
    property string gfxTarget: ""
    // last mode actually submitted, for the success notification
    property string gfxTargetApplied: ""
    // true while a mode switch is in flight: the pending state is shown
    // optimistically and polls must not overwrite it with stale data
    property bool gfxSwitching: false
    // whether the user asked to log out / reboot as soon as the switch
    // command succeeds
    property bool gfxActNow: false
    // true while undoing a queued (not yet applied) mode switch
    property bool gfxCancelling: false

    // gfx-ctl stages the mode and it is committed to supergfxd's config
    // at shutdown, applied when the daemon starts at the next boot —
    // every change is a reboot
    function gfxActionFor(mode) {
        return gfxPolicy === "reboot" ? "reboot" : "logout"
    }

    function gfxPerformAction(action) {
        if (action === "reboot") {
            execDataSource.connectSource("systemctl reboot")
        } else {
            // KDE logout without confirmation; loginctl as a fallback
            execDataSource.connectSource(
                "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout"
                + " || loginctl terminate-session ''")
        }
    }

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
    readonly property string batteryScriptPath: binDir + "/battery-ctl"
    readonly property string gfxScriptPath: binDir + "/gfx-ctl"
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

    // Coerce an unknown/loading profile to a valid glyph kind so the vector
    // icon always has something to draw.
    function glyphKind(profile) {
        return profiles.indexOf(profile) !== -1 ? profile : "balanced"
    }

    function dataFor(profile) {
        return profileData[profile] || {
            label: i18n("…"),
            name: i18n("Unknown"),
            desc: i18n("Reading profile…"),
            icon: Qt.resolvedUrl("../images/balanced.svg"),
            accent: Theme.red
        }
    }

    function formatMinutes(m) {
        if (m < 0) return ""
        var h = Math.floor(m / 60)
        var mm = m % 60
        return h > 0 ? i18n("%1h %2m", h, mm) : i18n("%1m", mm)
    }

    function gfxLabel(mode) {
        if (mode === "Integrated") return i18n("Integrated")
        if (mode === "Hybrid") return i18n("Hybrid")
        if (mode === "AsusMuxDgpu") return i18n("dGPU (MUX)")
        return mode
    }

    function notify(summary, body) {
        if (!Plasmoid.configuration.showNotifications) return
        // notify-send is near-universal on Plasma systems; quietly do
        // nothing when missing. Single quotes are stripped from the
        // controlled strings to keep shell quoting trivially safe.
        var s = String(summary).replace(/'/g, "")
        var b = String(body || "").replace(/'/g, "")
        execDataSource.connectSource(
            "command -v notify-send >/dev/null && notify-send -a 'Power Deck'"
            + " -i preferences-system-power-management -t 3500 '" + s + "' '" + b + "'")
    }

    // Widget icon follows the active profile, using the same per-profile
    // glyph SVGs as the panel (system tray, widget list, tooltip, alt-tab).
    Plasmoid.icon: dataFor(currentProfile).icon
    Plasmoid.status: PlasmaCore.Types.PassiveStatus

    toolTipMainText: i18n("Power Deck — %1", dataFor(currentProfile).name)
    toolTipSubText: {
        var line1 = i18n("CPU %1 · GPU %2 · %3 Hz",
            cpuTemp >= 0 ? i18n("%1°C", cpuTemp) : i18n("—"),
            gpuTemp >= 0 ? i18n("%1°C", gpuTemp) : i18n("—"),
            refreshCurrentHz)
        if (batteryPercent < 0) return line1
        var line2
        if (batteryState === "charging") {
            line2 = batteryMinutes >= 0
                ? i18n("Battery %1% — charging, %2 to full", batteryPercent, formatMinutes(batteryMinutes))
                : i18n("Battery %1% — charging", batteryPercent)
        } else if (batteryState === "discharging") {
            line2 = batteryMinutes >= 0
                ? i18n("Battery %1% — %2 remaining", batteryPercent, formatMinutes(batteryMinutes))
                : i18n("Battery %1% — on battery", batteryPercent)
            if (batteryWatts >= 0) line2 += i18n(" · drawing %1 W", batteryWatts)
        } else {
            line2 = onAC ? i18n("Battery %1% — plugged in", batteryPercent)
                         : i18n("Battery %1%", batteryPercent)
        }
        return line1 + "\n" + line2
    }

    switchWidth: Kirigami.Units.gridUnit * 19
    switchHeight: fullRepresentationItem && fullRepresentationItem.implicitHeight > 0
        ? fullRepresentationItem.implicitHeight
        : Kirigami.Units.gridUnit * 12

    Plasma5Support.DataSource {
        id: execDataSource
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            // Mode switches need explicit success/failure feedback, unlike
            // the fire-and-forget status polls below.
            if (sourceName.indexOf("gfx-ctl set") !== -1) {
                if (data["exit code"] === 0) {
                    if (root.gfxCancelling) {
                        root.gfxCancelling = false
                        root.gfxSwitching = false
                        root.notify(i18n("GPU mode switch cancelled"),
                            i18n("Staying on %1", root.gfxLabel(root.gfxMode)))
                    } else {
                        // the script prints the action required to apply
                        var action = (data["stdout"] || "").trim()
                        if (action === "logout" || action === "reboot" || action === "none") {
                            root.gfxPendingAction = action
                        }
                        if (root.gfxActNow && root.gfxPendingAction !== "none") {
                            root.gfxPerformAction(root.gfxPendingAction)
                        } else {
                            root.gfxSwitching = false
                            root.notify(i18n("GPU mode queued: %1", root.gfxLabel(root.gfxTargetApplied)),
                                i18n("Applies at the next reboot"))
                        }
                    }
                } else {
                    // roll back the optimistic pending state; the status
                    // poll below restores whatever is really configured
                    root.gfxCancelling = false
                    root.gfxSwitching = false
                    root.gfxPendingMode = "none"
                    root.gfxPendingAction = "none"
                    root.notify(i18n("GPU mode switch failed"),
                        i18n("Could not write the supergfxd config"))
                }
                connectSource(root.gfxScriptPath + " status")
                disconnectSource(sourceName)
                return
            }
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
                    if (tparts.length >= 4) {
                        var cw = parseInt(tparts[2])
                        var gw = parseInt(tparts[3])
                        root.cpuWatts = isNaN(cw) ? -1 : cw
                        root.gpuWatts = isNaN(gw) ? -1 : gw
                    }
                } else if (sourceName.indexOf("battery-ctl") !== -1) {
                    var bparts = output.split(" ")
                    if (bparts.length >= 4) {
                        root.batteryState = bparts[0]
                        var bp = parseInt(bparts[1])
                        var bm = parseInt(bparts[2])
                        root.batteryPercent = isNaN(bp) ? -1 : bp
                        root.batteryMinutes = isNaN(bm) ? -1 : bm
                        var bw = bparts.length >= 5 ? parseInt(bparts[4]) : NaN
                        root.batteryWatts = isNaN(bw) ? -1 : bw
                        var nowAC = (bparts[3] === "1")
                        if (root.acKnown && nowAC !== root.onAC) {
                            // re-apply AC-dependent settings right away as a
                            // backstop for the udev watcher service
                            execDataSource.connectSource(root.refreshScriptPath + " sync")
                            execDataSource.connectSource(root.animeScriptPath + " sync")
                            if (nowAC) {
                                root.notify(i18n("Plugged in"),
                                    root.batteryPercent >= 0
                                        ? i18n("Battery at %1%", root.batteryPercent) : "")
                            } else {
                                var left = root.formatMinutes(root.batteryMinutes)
                                root.notify(i18n("On battery"),
                                    root.batteryPercent >= 0
                                        ? (left.length > 0
                                            ? i18n("Battery at %1% — about %2 remaining", root.batteryPercent, left)
                                            : i18n("Battery at %1%", root.batteryPercent))
                                        : "")
                            }
                        }
                        root.onAC = nowAC
                        root.acKnown = true
                    }
                } else if (sourceName.indexOf("gfx-ctl") !== -1) {
                    if (sourceName.indexOf("status") !== -1) {
                        var gparts = output.split(" ")
                        if (gparts.length >= 4) {
                            root.gfxMode = gparts[0]
                            // a poll launched before the switch may still
                            // report "no pending mode" — don't let it erase
                            // the optimistic state shown to the user
                            if (!root.gfxSwitching) {
                                root.gfxPendingMode = gparts[1]
                                root.gfxPendingAction = gparts[2]
                            }
                            // "none" with a live mode means the daemon query
                            // failed AND the cache was lost — keep the last
                            // known list instead of hiding the section
                            if (gparts[3] !== "none") {
                                root.gfxSupported = gparts[3].split(",")
                            } else if (gparts[0] === "none") {
                                root.gfxSupported = []
                            }
                            if (gparts.length >= 5 && (gparts[4] === "reboot" || gparts[4] === "logout")) {
                                root.gfxPolicy = gparts[4]
                            }
                            if (gparts.length >= 6) {
                                root.gfxDgpu = gparts[5]
                            }
                        }
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
        notify(i18n("Power profile: %1", dataFor(profile).name),
            dataFor(profile).desc)
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

    function chargeOneshot() {
        execDataSource.connectSource(chargeScriptPath + " oneshot")
        notify(i18n("One-shot full charge"),
            i18n("Charging to 100% once — the %1% limit returns afterwards", chargeLimit))
    }

    function applyGfxMode(mode, actNow) {
        gfxTarget = ""
        gfxTargetApplied = mode
        gfxActNow = actNow
        // reflect the pending state immediately instead of waiting for
        // the next status poll
        gfxSwitching = true
        gfxPendingMode = mode
        gfxPendingAction = gfxActionFor(mode)
        execDataSource.connectSource(gfxScriptPath + " set " + mode)
    }

    // undo a queued switch by writing the live mode back into the config
    function cancelGfxPending() {
        gfxCancelling = true
        gfxSwitching = true
        gfxPendingMode = "none"
        gfxPendingAction = "none"
        execDataSource.connectSource(gfxScriptPath + " set " + gfxMode)
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
        execDataSource.connectSource(batteryScriptPath + " status")
        execDataSource.connectSource(gfxScriptPath + " status")
    }

    Timer {
        id: switchReset
        interval: 4000
        repeat: false
        onTriggered: { isSwitching = false }
    }

    compactRepresentation: Item {
        id: compactRoot
        implicitWidth: compactRow.implicitWidth + Kirigami.Units.largeSpacing * 2
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

                // 0 = icon, 1 = icon + profile, 2 = icon + battery,
                // 3 = icon + profile + battery
                readonly property int mode: Plasmoid.configuration.compactMode
                readonly property bool showProfile: mode === 1 || mode === 3
                readonly property bool showBattery: (mode === 2 || mode === 3)
                    && root.batteryPercent >= 0

                // Native vector glyph painted directly in the profile accent,
                // so the panel icon stays crisp and follows the active theme
                // (full color normally, grayscale in monochrome) instead of
                // being flattened to a single panel tint.
                ProfileGlyph {
                    readonly property int iconSize: Math.round(
                        Math.min(compactRoot.height, Kirigami.Units.gridUnit * 2) * 0.92)
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    Layout.alignment: Qt.AlignVCenter
                    kind: glyphKind(currentProfile)
                    glyphColor: dataFor(currentProfile).accent
                    glyphSize: iconSize
                    active: true
                }

                PC3.Label {
                    visible: compactRow.showProfile
                    text: dataFor(currentProfile).label
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    horizontalAlignment: Text.AlignLeft
                }

                PC3.Label {
                    visible: compactRow.showBattery
                    text: i18n("%1%", root.batteryPercent)
                    // green while charging/plugged, red when low on battery
                    color: root.onAC ? Theme.green
                        : (root.batteryPercent <= 20 ? Theme.redBright : Kirigami.Theme.textColor)
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    Behavior on color { ColorAnimation { duration: Theme.durMed } }
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

                ProfileGlyph {
                    id: headerBadge
                    kind: glyphKind(currentProfile)
                    glyphColor: dataFor(currentProfile).accent
                    glyphSize: Math.round(Kirigami.Units.gridUnit * 2.1)
                    active: true
                    Layout.preferredWidth: glyphSize
                    Layout.preferredHeight: glyphSize
                    Layout.alignment: Qt.AlignVCenter
                    onKindChanged: play()
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("POWER DECK")
                        color: Theme.muted
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

                // live battery readout
                Rectangle {
                    visible: root.batteryPercent >= 0
                    readonly property color batColor: root.batteryState === "charging" ? Theme.green
                        : (root.batteryState === "discharging" && root.batteryPercent <= 20) ? Theme.red
                        : root.onAC ? Theme.green
                        : Theme.teal
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.3)
                    Layout.preferredWidth: batLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                    radius: height / 2
                    color: Theme.alpha(batColor, 0.12)
                    border.width: 1
                    border.color: Theme.alpha(batColor, 0.35)
                    Behavior on border.color { ColorAnimation { duration: Theme.durMed } }

                    PC3.Label {
                        id: batLabel
                        anchors.centerIn: parent
                        text: {
                            var t = i18n("%1%", root.batteryPercent)
                            var left = root.formatMinutes(root.batteryMinutes)
                            if (root.batteryState === "discharging" && left.length > 0)
                                return t + " · " + left
                            if (root.batteryState === "charging")
                                return left.length > 0 ? t + " ↑ " + left : t + " ↑"
                            return t
                        }
                        color: parent.batColor
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }

                // live refresh-rate readout
                Rectangle {
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.3)
                    Layout.preferredWidth: hzLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                    radius: height / 2
                    color: Theme.alpha(Theme.accent, 0.12)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.35)

                    PC3.Label {
                        id: hzLabel
                        anchors.centerIn: parent
                        text: i18n("%1 Hz", root.refreshCurrentHz)
                        color: Theme.accentBright
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
                    watts: root.cpuWatts
                }

                TempPill {
                    sensorLabel: i18n("GPU")
                    temp: root.gpuTemp
                    watts: root.gpuWatts
                }

                // total system drain straight from the battery, the only
                // number that truly covers CPU + GPU + everything else
                Rectangle {
                    id: drawPill
                    visible: root.batteryState === "discharging" && root.batteryWatts >= 0
                    readonly property color drainColor: root.batteryWatts >= 35 ? Theme.red
                        : root.batteryWatts >= 20 ? Theme.amber
                        : Theme.green
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.4)
                    radius: height / 2
                    color: Theme.alpha(drainColor, 0.10)
                    border.width: 1
                    border.color: Theme.alpha(drainColor, 0.3)
                    Behavior on border.color { ColorAnimation { duration: Theme.durSlow } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing

                        PC3.Label {
                            text: i18n("DRAW")
                            color: Kirigami.Theme.disabledTextColor
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        }

                        PC3.Label {
                            text: i18n("%1 W", root.batteryWatts)
                            color: drawPill.drainColor
                            font.weight: Font.Bold
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        }
                    }
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
                        profileKind: root.glyphKind(modelData)
                        accentColor: dataFor(modelData).accent
                        burstEffect: dataFor(modelData).burst || "pulse"
                        isActive: currentProfile === modelData
                        onClicked: setProfile(modelData)
                    }
                }
            }

            // ================= graphics =================
            SectionCard {
                visible: root.gfxSupported.length > 0

                SectionHeader {
                    title: i18n("GRAPHICS")
                    iconSource: Qt.resolvedUrl("../images/gpu.svg")
                    glyphColor: Theme.iconGraphics
                    active: true

                    PC3.Label {
                        visible: root.gfxPendingMode !== "none" || root.gfxPendingAction !== "none"
                        text: {
                            var act = root.gfxPendingAction === "reboot" ? i18n("reboot") : i18n("logout")
                            return root.gfxPendingMode !== "none"
                                ? i18n("%1 after %2", root.gfxLabel(root.gfxPendingMode), act)
                                : i18n("Apply with %1", act)
                        }
                        color: Theme.amber
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }

                    // which GPU devices are live right now: green/teal when
                    // only the iGPU draws power, amber when the dGPU is awake
                    Rectangle {
                        readonly property color tagColor: root.gfxDgpu === "active" ? Theme.amber : Theme.teal
                        readonly property string tagText: {
                            if (root.gfxMode === "AsusMuxDgpu") return i18n("dGPU drives display")
                            if (root.gfxDgpu === "off") return i18n("iGPU only")
                            if (root.gfxDgpu === "active") return i18n("iGPU + dGPU on")
                            return i18n("iGPU + dGPU asleep")
                        }
                        implicitWidth: tagLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        implicitHeight: tagLabel.implicitHeight + Kirigami.Units.smallSpacing
                        radius: height / 2
                        color: Theme.alpha(tagColor, 0.14)
                        border.width: 1
                        border.color: Theme.alpha(tagColor, 0.45)

                        PC3.Label {
                            id: tagLabel
                            anchors.centerIn: parent
                            text: parent.tagText
                            color: parent.tagColor
                            font.weight: Font.DemiBold
                            font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.92)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: root.gfxSupported

                        AnimeChip {
                            required property string modelData
                            // mode that becomes active after the reboot
                            readonly property bool isPending: root.gfxPendingMode !== "none"
                                && root.gfxPendingMode === modelData
                            label: root.gfxLabel(modelData)
                            // accent = active now, pulsing amber = after reboot
                            accentColor: isPending ? Theme.amber : Theme.accent
                            pulsing: isPending
                            isActive: isPending || root.gfxMode === modelData
                            onClicked: {
                                if (modelData === root.gfxPendingMode) {
                                    return
                                }
                                if (modelData === root.gfxMode) {
                                    // clicking the live mode while a switch is
                                    // queued un-queues it
                                    if (root.gfxPendingMode !== "none") {
                                        root.cancelGfxPending()
                                    }
                                    return
                                }
                                root.gfxTarget = modelData
                            }
                        }
                    }
                }

                // one-click apply with an arm step so a stray click is harmless
                AnimeChip {
                    id: applyChip
                    property bool armed: false
                    readonly property bool needsReboot: root.gfxPendingAction === "reboot"
                    visible: root.gfxPendingMode !== "none" || root.gfxPendingAction !== "none"
                    label: armed
                        ? (needsReboot ? i18n("Click again to reboot") : i18n("Click again to log out"))
                        : (needsReboot ? i18n("Reboot now to apply") : i18n("Log out now to apply"))
                    accentColor: armed ? Theme.red : Theme.amber
                    isActive: armed
                    pulsing: armed
                    onClicked: {
                        if (armed) {
                            root.gfxPerformAction(root.gfxPendingAction)
                        } else {
                            armed = true
                            applyArmTimer.restart()
                        }
                    }

                    Timer {
                        id: applyArmTimer
                        interval: 4000
                        onTriggered: applyChip.armed = false
                    }
                }
            }

            // ================= AniMe Matrix =================
            SectionCard {
                SectionHeader {
                    title: i18n("ANIME MATRIX")
                    animeGlyph: true
                    animeAnimate: root.animeOn
                    glyphColor: Theme.iconAnime
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
                    glyphColor: Theme.iconKbd
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
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.highlightColor: Theme.accent
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
                        accentColor: Theme.accent
                        glyphColor: root.fnLockOn ? Theme.iconFn : Theme.iconHeader
                        badgeSize: Math.round(Kirigami.Units.gridUnit * 1.45)
                        active: root.fnLockOn
                        bare: true
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
                    glyphColor: Theme.iconRefresh
                    active: true

                    PC3.Label {
                        text: i18n("%1 Hz", root.refreshCurrentHz)
                        color: Theme.accentBright
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
                    glyphColor: Theme.iconCharge
                    active: true

                    PC3.Label {
                        text: root.chargeLimit >= 100
                            ? i18n("Full")
                            : i18n("%1%", root.chargeLimit)
                        color: root.chargeLimit >= 100 ? Theme.accentBright : Theme.green
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
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.highlightColor: Theme.accent
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

                AnimeChip {
                    visible: root.chargeLimit < 100
                    label: i18n("Charge to 100% once")
                    accentColor: Theme.amber
                    onClicked: chargeOneshot()
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

        // ============ GPU mode confirmation overlay ============
        Rectangle {
            anchors.fill: parent
            z: 100
            visible: root.gfxTarget !== ""
            color: Theme.alpha(Kirigami.Theme.backgroundColor, 0.85)

            // swallow clicks so the popup behind stays inert
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {}
                onWheel: function(wheel) { wheel.accepted = true }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.largeSpacing * 2
                height: confirmColumn.implicitHeight + Kirigami.Units.largeSpacing * 4
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.4)

                ColumnLayout {
                    id: confirmColumn
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing * 2
                    spacing: Kirigami.Units.smallSpacing * 2

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("SWITCH GPU MODE")
                        color: Theme.muted
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2.2
                    }

                    // logout-type switches must end the session while
                    // supergfxd waits, so "later" is only safe for MUX
                    readonly property bool needsReboot:
                        root.gfxTarget !== "" && root.gfxActionFor(root.gfxTarget) === "reboot"

                    PC3.Label {
                        Layout.fillWidth: true
                        text: i18n("Switch graphics to %1?", root.gfxLabel(root.gfxTarget))
                        color: Kirigami.Theme.textColor
                        font.weight: Font.Bold
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.1)
                        wrapMode: Text.WordWrap
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: confirmColumn.needsReboot
                            ? i18n("The new mode takes effect after the next reboot. Until then you can un-queue it by clicking the current mode.")
                            : i18n("Your session will close and the new mode is active when you log back in. Save your work first — nothing changes if you cancel.")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        wrapMode: Text.WordWrap
                    }

                    AnimeChip {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        label: confirmColumn.needsReboot
                            ? i18n("Switch + Reboot now")
                            : i18n("Switch + Log out now")
                        accentColor: Theme.red
                        isActive: true
                        onClicked: root.applyGfxMode(root.gfxTarget, true)
                    }

                    AnimeChip {
                        Layout.fillWidth: true
                        visible: confirmColumn.needsReboot
                        label: i18n("Switch, reboot later")
                        accentColor: Theme.amber
                        isActive: true
                        onClicked: root.applyGfxMode(root.gfxTarget, false)
                    }

                    AnimeChip {
                        Layout.fillWidth: true
                        label: i18n("Cancel")
                        onClicked: root.gfxTarget = ""
                    }
                }
            }
        }
    }

    // Keep the shared Theme palette in sync with the widget config so the
    // monochrome toggle applies live across every component.
    Binding {
        target: Theme
        property: "monochrome"
        value: Plasmoid.configuration.monochrome
    }

    Binding {
        target: Theme
        property: "accentChoice"
        value: Plasmoid.configuration.monoAccent
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
