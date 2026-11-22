// 설정 한 줄: 왼쪽에 이름, 오른쪽에 조작 (안에 넣은 것이 이름 옆에 붙는다)
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: row

    property string title

    Layout.fillWidth: true
    spacing: 12

    Txt {
        Layout.preferredWidth: 64
        text: row.title
        font.pixelSize: 12
        color: Theme.subtext1
    }
}
