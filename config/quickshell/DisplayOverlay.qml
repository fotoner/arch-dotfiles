pragma ComponentBehavior: Bound
// 화면마다 뜨는 것 두 가지
// 1) 설정 창이 열려 있으면 각 화면 왼쪽 위에 그 화면 이름표 (어느 네모가 어느 화면인지 알 수 있게). 누르면 그 화면을 고른다
// 2) 해상도 등을 바꾼 뒤 "유지할까요?" 확인 창. 15초 안에 안 누르면 되돌린다 (화면이 안 나와도 원래대로 돌아오게)
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: scope

        required property var modelData
        readonly property var mon: DS.monitors.find(m => m.name === modelData.name) ?? null

        PanelWindow {
            id: badge

            screen: scope.modelData
            visible: DS.open && scope.mon !== null && !scope.mon.mirror
            anchors {
                top: true
                left: true
            }
            margins {
                top: 12
                left: 12
            }
            implicitWidth: pill.width
            implicitHeight: pill.height
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.namespace: "quickshell-display-badge"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                id: pill

                readonly property bool chosen: DS.selected === scope.modelData.name

                width: row.implicitWidth + 28
                height: 36
                radius: 18
                color: chosen ? Theme.mauve : Qt.alpha(Theme.base, 0.9)
                border.width: 1
                border.color: chosen ? "transparent" : Qt.rgba(1, 1, 1, 0.08)

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8

                    Glyph {
                        text: scope.mon?.internal ? Icons.laptop : Icons.monitor
                        font.pixelSize: 16
                        color: pill.chosen ? Theme.base : Theme.mauve
                    }

                    Txt {
                        text: scope.mon?.label ?? ""
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: pill.chosen ? Theme.base : Theme.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DS.selected = scope.modelData.name
                }
            }
        }

        PanelWindow {
            id: confirm

            readonly property int shadowRoom: 28

            screen: scope.modelData
            visible: DS.pending !== null
            implicitWidth: box.width + shadowRoom * 2
            implicitHeight: box.height + shadowRoom * 2
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-display-confirm"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            mask: Region { item: box }

            onVisibleChanged: if (visible) box.forceActiveFocus()

            Item {
                id: box

                x: confirm.shadowRoom
                y: confirm.shadowRoom
                width: 360
                height: col.implicitHeight + 40
                focus: true
                Keys.onReturnPressed: DS.keep()
                Keys.onEnterPressed: DS.keep()
                Keys.onEscapePressed: DS.revert()

                RectangularShadow {
                    anchors.fill: boxBg
                    radius: boxBg.radius
                    blur: 22
                    offset.y: 6
                    color: Qt.rgba(0, 0, 0, 0.45)
                }

                Rectangle {
                    id: boxBg
                    anchors.fill: parent
                    radius: 20
                    color: Qt.alpha(Theme.base, 0.94)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                }

                ColumnLayout {
                    id: col

                    x: 20
                    y: 20
                    width: parent.width - 40
                    spacing: 6

                    Txt {
                        Layout.fillWidth: true
                        text: "이 디스플레이 설정을 유지할까요?"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Txt {
                        Layout.fillWidth: true
                        text: DS.countdown + "초 뒤에 이전 설정으로 돌아갑니다."
                        font.pixelSize: 12
                        color: Theme.subtext0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                        }

                        DialogButton {
                            text: "되돌리기"
                            onClicked: DS.revert()
                        }

                        DialogButton {
                            text: "유지"
                            primary: true
                            onClicked: DS.keep()
                        }
                    }
                }
            }
        }
    }
}
