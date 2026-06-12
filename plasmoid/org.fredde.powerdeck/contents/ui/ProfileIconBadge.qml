import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property url iconSource
    property color accentColor: Kirigami.Theme.highlightColor
    property int badgeSize: Math.round(Kirigami.Units.gridUnit * 1.75)
    property bool active: false

    implicitWidth: badgeSize
    implicitHeight: badgeSize
    Layout.preferredWidth: badgeSize
    Layout.preferredHeight: badgeSize
    Layout.alignment: Qt.AlignVCenter

    radius: width / 2
    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, active ? 0.28 : 0.18)
    border.width: active ? 1 : 0
    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5)

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
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
    }
}
