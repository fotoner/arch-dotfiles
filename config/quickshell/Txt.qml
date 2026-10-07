// 기본 글자 (Inter, 한글은 fontconfig가 Noto Sans CJK로 채운다)
import QtQuick

Text {
    font.family: Theme.font
    font.pixelSize: 13
    color: Theme.text
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
