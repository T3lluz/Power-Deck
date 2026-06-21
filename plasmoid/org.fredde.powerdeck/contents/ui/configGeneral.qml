import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property int cfg_compactMode
    property alias cfg_showNotifications: notifyCheck.checked
    property alias cfg_monochrome: monoCheck.checked
    property int cfg_monoAccent

    // Mirrors Theme.monoAccents — kept here so the config page has no
    // dependency on the running widget's singleton.
    readonly property var accentOptions: [
        { name: i18n("White"),  color: "#e6e9ef" },
        { name: i18n("Green"),  color: "#34d399" },
        { name: i18n("Teal"),   color: "#2dd4bf" },
        { name: i18n("Orange"), color: "#fb923c" },
        { name: i18n("Red"),    color: "#f2596a" },
        { name: i18n("Blue"),   color: "#56b6f0" },
        { name: i18n("Purple"), color: "#a78bfa" }
    ]

    Kirigami.FormLayout {
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Panel display:")
            model: [
                i18n("Icon only"),
                i18n("Icon + profile"),
                i18n("Icon + battery"),
                i18n("Icon + profile + battery")
            ]
            currentIndex: root.cfg_compactMode
            onActivated: function(index) { root.cfg_compactMode = index }
        }

        QQC2.CheckBox {
            id: notifyCheck
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Notify on profile and power changes")
        }

        QQC2.CheckBox {
            id: monoCheck
            Kirigami.FormData.label: i18n("Theme:")
            text: i18n("Monochrome (grayscale) palette")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Accent color:")
            enabled: monoCheck.checked
            opacity: enabled ? 1.0 : 0.5
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: root.accentOptions

                delegate: Rectangle {
                    required property int index
                    required property var modelData

                    readonly property bool selected: root.cfg_monoAccent === index

                    implicitWidth: Kirigami.Units.gridUnit * 1.6
                    implicitHeight: Kirigami.Units.gridUnit * 1.6
                    radius: width / 2
                    color: modelData.color
                    border.width: selected ? 3 : 1
                    border.color: selected
                        ? Kirigami.Theme.textColor
                        : Qt.rgba(Kirigami.Theme.textColor.r,
                                  Kirigami.Theme.textColor.g,
                                  Kirigami.Theme.textColor.b, 0.35)

                    QQC2.ToolTip.visible: hover.hovered
                    QQC2.ToolTip.text: modelData.name

                    // a check mark on the chosen swatch
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.55
                        height: width
                        source: "checkmark"
                        visible: parent.selected
                        color: index === 0 ? "#222428" : "#ffffff"
                        isMask: true
                    }

                    HoverHandler { id: hover }

                    TapHandler {
                        onTapped: root.cfg_monoAccent = index
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            visible: monoCheck.checked
            text: i18n("Pick White for a fully neutral monochrome look, or a hue to tint the active controls, profile icon and panel glyph.")
            color: Kirigami.Theme.disabledTextColor
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
        }
    }
}
