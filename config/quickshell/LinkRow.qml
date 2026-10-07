// 목록 맨 아래 '… 설정' 줄
import QtQuick
import QtQuick.Layouts

Item {
    id: link

    property string text
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: area.containsMouse ? Theme.fill : "transparent"
    }

    Txt {
        anchors.fill: parent
        anchors.leftMargin: 6
        text: link.text
        font.pixelSize: 12
        color: area.containsMouse ? Theme.text : Theme.subtext0
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: link.clicked()
    }
}
