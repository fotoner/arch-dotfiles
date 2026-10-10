// 정사각형 빠른 버튼 (방해 금지, 마이크, 전원 모드, 잠자기 방지). 글자 없이 아이콘만 가운데, 켜져 있으면 보라색으로 채운다.
// 아이콘이 칸 정중앙이라 왼쪽 Wi-Fi·블루투스 동그라미와 같은 높이에 온다
import QtQuick

Rectangle {
    id: tile

    property string icon
    property string label // 화면에는 안 보이고 접근성 이름으로만
    property bool active: false
    signal clicked

    implicitWidth: 66
    implicitHeight: 66
    radius: 16
    color: active ? Theme.mauve : area.containsMouse ? Theme.fillHover : Theme.fill
    border.width: 1
    border.color: active ? "transparent" : Theme.line
    scale: area.pressed ? 0.95 : 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    Accessible.name: label

    Glyph {
        anchors.centerIn: parent
        text: tile.icon
        font.pixelSize: 20
        color: tile.active ? Theme.base : Theme.text
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
