// 키캡 모양 글자 (단축키 시트). 아래쪽 어두운 띠로 눌리는 키처럼 보이게 한다
import QtQuick

Item {
    id: cap

    property string text

    implicitWidth: Math.max(24, label.implicitWidth + 14)
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 2
        radius: 6
        color: Theme.surface0
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        Txt {
            id: label
            anchors.centerIn: parent
            text: cap.text
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Theme.text
        }
    }
}
