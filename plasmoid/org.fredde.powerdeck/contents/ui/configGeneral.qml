import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property int cfg_compactMode
    property alias cfg_showNotifications: notifyCheck.checked
    property alias cfg_monochrome: monoCheck.checked

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
    }
}
