import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Rounded-square icon badge that lights up in its accent color when active.
Rectangle {
    id: root

    property url iconSource
    property color accentColor: Theme.red
    property int badgeSize: Math.round(Kirigami.Units.gridUnit * 1.75)
    property bool active: false

    implicitWidth: badgeSize
    implicitHeight: badgeSize
    Layout.preferredWidth: badgeSize
    Layout.preferredHeight: badgeSize
    Layout.alignment: Qt.AlignVCenter

    radius: Math.round(badgeSize * 0.3)
    color: Theme.alpha(accentColor, active ? 0.26 : 0.1)
    border.width: 1
    border.color: Theme.alpha(accentColor, active ? 0.55 : 0.18)

    Behavior on color {
        ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
    }

    Image {
        anchors.centerIn: parent
        width: Math.round(root.badgeSize * 0.62)
        height: width
        source: root.iconSource
        sourceSize.width: width * 2
        sourceSize.height: width * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.active ? 1 : 0.65
        Behavior on opacity {
            NumberAnimation { duration: Theme.durMed }
        }
    }
}
