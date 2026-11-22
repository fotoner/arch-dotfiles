// 확인 창 단추. primary면 보라색으로 채운다
import QtQuick

Rectangle {
    id: button

    property string text
    property bool primary: false
    signal clicked

    implicitWidth: Math.max(84, label.implicitWidth + 32)
    implicitHeight: 32
    radius: 10
    color: primary ? (area.containsMouse ? Qt.lighter(Theme.mauve, 1.08) : Theme.mauve) : area.containsMouse ? Theme.fillHover : Theme.fill
    border.width: 1
    border.color: primary ? "transparent" : Theme.line
    scale: area.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    Txt {
        id: label
        anchors.centerIn: parent
        text: button.text
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: button.primary ? Theme.base : Theme.text
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
