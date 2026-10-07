// 동그란 아이콘 버튼 (미디어 조작, 아래쪽 버튼 줄)
import QtQuick

Rectangle {
    id: button

    property string icon
    property int iconSize: 16
    property color iconColor: Theme.text
    signal clicked

    implicitWidth: 30
    implicitHeight: 30
    radius: width / 2
    color: area.containsMouse ? Theme.fillHover : "transparent"
    opacity: enabled ? 1 : 0.35
    scale: area.pressed ? 0.9 : 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    Glyph {
        anchors.centerIn: parent
        text: button.icon
        font.pixelSize: button.iconSize
        color: button.iconColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
