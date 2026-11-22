pragma ComponentBehavior: Bound
// 디스플레이 설정 창: 지금 보고 있는 화면 가운데에 뜬다. 바깥을 누르거나 Esc를 누르면 닫힌다.
// 열기: 제어 센터 → 디스플레이 → 디스플레이 설정…, Vicinae "디스플레이 설정", qs ipc call display open
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property int shadowRoom: 28
    readonly property var mon: DS.current
    readonly property bool arranging: DS.monitors.filter(m => m.enabled && !m.mirror).length > 1
    property string screenName: ""
    property bool resOpen: false

    screen: Quickshell.screens.find(s => s.name === screenName) ?? Quickshell.screens[0] ?? null
    visible: DS.open || card.opacity > 0
    implicitWidth: card.width + shadowRoom * 2
    implicitHeight: card.height + shadowRoom * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-display"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: card }

    Connections {
        target: DS
        function onOpenChanged() {
            if (DS.open) {
                win.screenName = Hyprland.focusedMonitor?.name ?? "";
                win.resOpen = false;
                card.forceActiveFocus();
            }
        }
        function onSelectedChanged() {
            win.resOpen = false;
        }
    }

    // 확인 팝업이 떠 있는 동안에는 그 팝업을 눌러도 창이 닫히지 않게 잡지 않는다
    HyprlandFocusGrab {
        windows: [win]
        active: DS.open && !DS.pending
        onCleared: DS.open = false
    }

    Item {
        id: card

        x: win.shadowRoom
        y: win.shadowRoom
        width: 560
        height: content.implicitHeight + 40
        opacity: DS.open ? 1 : 0
        focus: true
        Keys.onEscapePressed: DS.open = false

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: DS.open ? 1 : 0.97
            yScale: DS.open ? 1 : 0.97
            Behavior on xScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 22
            offset.y: 6
            color: Qt.rgba(0, 0, 0, 0.4)
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 22
            color: Qt.alpha(Theme.base, 0.9)

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.07)
            }
        }

        ColumnLayout {
            id: content

            x: 20
            y: 20
            width: parent.width - 40
            spacing: 14

            // 제목
            RowLayout {
                Layout.fillWidth: true

                Txt {
                    Layout.fillWidth: true
                    text: "디스플레이"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                IconButton {
                    icon: Icons.close
                    iconSize: 15
                    iconColor: Theme.subtext0
                    onClicked: DS.open = false
                }
            }

            // 화면 구성 (모니터가 둘 이상일 때)
            DisplayModes {
                visible: DS.monitors.length > 1
                tileHeight: 68
            }

            // 배치
            Card {
                Layout.fillWidth: true
                implicitHeight: DS.monitors.length > 1 ? 236 : 0
                visible: DS.monitors.length > 1

                DisplayArrange {
                    id: arrange
                    anchors.fill: parent
                    anchors.bottomMargin: 26
                    visible: win.arranging
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    visible: win.arranging
                    text: "화면을 끌어서 실제 위치에 맞추세요 · 누르면 아래에서 설정"
                    font.pixelSize: 11
                    color: Theme.overlay1
                }

                // 미러링이나 화면 하나만 켜져 있을 때는 배치할 게 없다
                Column {
                    anchors.centerIn: parent
                    visible: !win.arranging
                    spacing: 8

                    Glyph {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: DS.topology === "mirror" ? Icons.mirror : DS.topology === "internal" ? Icons.laptop : Icons.monitor
                        font.pixelSize: 30
                        color: Theme.overlay1
                    }

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: DS.topology === "mirror" ? "미러링 중: 모든 화면에 같은 내용이 보입니다"
                            : DS.topology === "internal" ? "외부 모니터가 꺼져 있습니다"
                            : "외부 모니터만 켜져 있습니다"
                        font.pixelSize: 12
                        color: Theme.subtext0
                    }
                }
            }

            // 모니터 고르기 (배치 그림이 없을 때만. 있으면 그림을 눌러 고른다)
            Segmented {
                visible: DS.monitors.length > 1 && !win.arranging
                enabled: !DS.pending
                options: DS.monitors.filter(m => m.enabled).map(m => ({ label: m.label, value: m.name }))
                current: DS.selected
                onPicked: v => DS.selected = v
            }

            // 고른 모니터 설정
            Card {
                Layout.fillWidth: true
                implicitHeight: detail.implicitHeight + 28
                visible: win.mon !== null

                ColumnLayout {
                    id: detail

                    x: 16
                    y: 14
                    width: parent.width - 32
                    spacing: 12
                    enabled: !DS.pending
                    opacity: enabled ? 1 : 0.5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Glyph {
                            text: win.mon?.internal ? Icons.laptop : Icons.monitor
                            font.pixelSize: 22
                            color: Theme.mauve
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Txt {
                                Layout.fillWidth: true
                                text: win.mon?.label ?? ""
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Txt {
                                Layout.fillWidth: true
                                text: !win.mon ? ""
                                    : win.mon.name + " · " + win.mon.w + " × " + win.mon.h + " · " + DisplayFormat.hz(win.mon.refresh)
                                      + (win.mon.mirror ? " · " + (DS.monitors.find(m => m.name === win.mon.mirror)?.label ?? win.mon.mirror) + " 미러링" : "")
                                font.pixelSize: 11
                                color: Theme.overlay1
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.line
                    }

                    // 해상도: 누르면 목록을 펼친다
                    SettingRow {
                        title: "해상도"

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            readonly property bool many: (win.mon ? DS.resolutions(win.mon).length : 0) > 1

                            Rectangle {
                                anchors.fill: parent
                                radius: 9
                                color: resArea.containsMouse && parent.many ? Theme.fillHover : Theme.fill
                                border.width: 1
                                border.color: Theme.line
                            }

                            Txt {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.mon ? DisplayFormat.res(win.mon.w, win.mon.h, win.mon) : ""
                                font.pixelSize: 12
                            }

                            Glyph {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.many
                                text: Icons.chevron
                                font.pixelSize: 14
                                color: Theme.overlay1
                                rotation: win.resOpen ? 90 : 0
                                Behavior on rotation { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: resArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: parent.many ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: if (parent.many) win.resOpen = !win.resOpen
                            }
                        }
                    }

                    // 해상도 목록
                    Flickable {
                        Layout.fillWidth: true
                        Layout.leftMargin: 76
                        implicitHeight: Math.min(resList.implicitHeight, 6 * 30)
                        visible: win.resOpen && win.mon !== null
                        contentHeight: resList.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: resList
                            width: parent.width

                            Repeater {
                                model: win.mon ? DS.resolutions(win.mon) : []

                                delegate: Item {
                                    id: resItem

                                    required property var modelData
                                    required property int index
                                    readonly property bool on: win.mon && modelData.w === win.mon.w && modelData.h === win.mon.h

                                    width: resList.width
                                    height: 30

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 9
                                        color: itemArea.containsMouse ? Theme.fill : "transparent"
                                    }

                                    Txt {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: DisplayFormat.res(resItem.modelData.w, resItem.modelData.h, win.mon)
                                        font.pixelSize: 12
                                        font.weight: resItem.on ? Font.DemiBold : Font.Normal
                                        color: resItem.on ? Theme.mauve : Theme.text
                                    }

                                    Glyph {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: resItem.on
                                        text: Icons.check
                                        font.pixelSize: 14
                                        color: Theme.mauve
                                    }

                                    MouseArea {
                                        id: itemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            win.resOpen = false;
                                            if (!resItem.on)
                                                DS.setResolution(win.mon.name, resItem.modelData.w, resItem.modelData.h);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SettingRow {
                        title: "주사율"

                        Segmented {
                            options: !win.mon ? [] : win.mon.modes.filter(x => x.w === win.mon.w && x.h === win.mon.h)
                                .map(x => ({ label: DisplayFormat.hz(x.r), value: x.str }))
                            current: win.mon?.mode
                            onPicked: v => DS.setRefresh(win.mon.name, win.mon.modes.find(x => x.str === v))
                        }
                    }

                    SettingRow {
                        title: "배율"

                        Segmented {
                            options: !win.mon ? [] : DS.scalesFor(win.mon).map(s => ({ label: Math.round(s * 100) + "%", value: s }))
                            current: win.mon?.scale
                            onPicked: v => DS.change(win.mon.name, { scale: v })
                        }
                    }

                    SettingRow {
                        title: "회전"

                        Segmented {
                            options: [{ label: "기본", value: 0 }, { label: "90°", value: 1 }, { label: "180°", value: 2 }, { label: "270°", value: 3 }]
                            current: win.mon?.transform
                            onPicked: v => DS.change(win.mon.name, { transform: v })
                        }
                    }
                }
            }

            Txt {
                Layout.fillWidth: true
                Layout.topMargin: -4
                horizontalAlignment: Text.AlignHCenter
                text: "모니터마다 설정을 기억합니다 · 외부만/노트북만은 다시 꽂거나 재시작하면 풀립니다"
                font.pixelSize: 11
                color: Theme.overlay0
                wrapMode: Text.WordWrap
            }
        }
    }
}
