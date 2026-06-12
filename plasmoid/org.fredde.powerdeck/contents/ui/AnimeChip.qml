import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

Item {
    id: root

    property string label: ""
    property bool isActive: false
    property bool chipEnabled: true
    property color accentColor: "#c084fc"

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.7)
    opacity: chipEnabled ? 1.0 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.isActive
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
            : (mouse.containsMouse && root.chipEnabled
                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.035))
        border.width: 1
        border.color: root.isActive
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)
            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    PC3.Label {
        anchors.centerIn: parent
        text: root.label
        color: root.isActive ? root.accentColor : Kirigami.Theme.textColor
        font.weight: root.isActive ? Font.DemiBold : Font.Medium
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.chipEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.chipEnabled) root.clicked()
    }
}
