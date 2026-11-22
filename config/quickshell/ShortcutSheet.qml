pragma ComponentBehavior: Bound
// 단축키 시트: 지금 보고 있는 화면 가운데에 종류별 카드로 띄운다. 바로 입력하면 찾고, Esc나 바깥을 누르면 닫힌다.
// 열기: Super+H, 제어 센터 아래 키보드 단추, Vicinae "단축키", qs ipc call keys toggle
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property int shadowRoom: 28
    readonly property int columns: 3
    property string query: ""
    property string screenName: ""

    // 찾는 말이 들어간 줄만 남기고, 줄이 없는 카드는 뺀다
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (!q)
            return Shortcuts.groups;
        return Shortcuts.groups.map(g => ({
            title: g.title,
            icon: g.icon,
            items: g.title.toLowerCase().includes(q) ? g.items : g.items.filter(it => (it.desc + " " + it.keys).toLowerCase().includes(q))
        })).filter(g => g.items.length > 0);
    }

    // 카드를 높이가 고르게 세 줄로 나눈다 (가장 짧은 줄에 다음 카드를 넣는다)
    readonly property var lanes: {
        const lanes = [];
        const heights = [];
        for (let i = 0; i < columns; i++) {
            lanes.push([]);
            heights.push(0);
        }
        for (const g of shown) {
            const i = heights.indexOf(Math.min(...heights));
            lanes[i].push(g);
            heights[i] += g.items.length + 2;
        }
        return lanes;
    }

    function parts(keys) {
        const out = [];
        keys.split(" / ").forEach((alt, i) => {
            if (i > 0)
                out.push({ sep: "/" });
            alt.split(" → ").forEach((step, j) => {
                if (j > 0)
                    out.push({ sep: "→" });
                step.split("+").forEach(k => out.push({ key: k.trim() }));
            });
        });
        return out;
    }

    screen: Quickshell.screens.find(s => s.name === screenName) ?? Quickshell.screens[0] ?? null
    visible: Shortcuts.open || card.opacity > 0
    implicitWidth: card.width + shadowRoom * 2
    implicitHeight: card.height + shadowRoom * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-shortcuts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Shortcuts.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: card }

    Connections {
        target: Shortcuts
        function onOpenChanged() {
            if (Shortcuts.open) {
                win.screenName = Hyprland.focusedMonitor?.name ?? "";
                win.query = "";
                search.text = "";
                search.forceActiveFocus();
            }
        }
    }

    HyprlandFocusGrab {
        windows: [win]
        active: Shortcuts.open
        onCleared: Shortcuts.open = false
    }

    Item {
        id: card

        x: win.shadowRoom
        y: win.shadowRoom
        width: 1060
        height: Math.min(content.implicitHeight + 44, (win.screen?.height ?? 1080) - 120)
        opacity: Shortcuts.open ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: Shortcuts.open ? 1 : 0.97
            yScale: Shortcuts.open ? 1 : 0.97
            Behavior on xScale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        }

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 24
            offset.y: 6
            color: Qt.rgba(0, 0, 0, 0.4)
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 24
            color: Qt.alpha(Theme.base, 0.9)

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.07)
            }
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 22
            contentHeight: content.implicitHeight
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content

                width: parent.width
                spacing: 16

                // 제목, 찾기, 닫기
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Txt {
                        text: "단축키"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Txt {
                        Layout.fillWidth: true
                        text: "Alt는 맥의 ⌘ 자리 · Super(윈도우 키)는 창 관리"
                        font.pixelSize: 12
                        color: Theme.overlay1
                    }

                    Rectangle {
                        Layout.preferredWidth: 260
                        implicitHeight: 34
                        radius: 11
                        color: Theme.fill
                        border.width: 1
                        border.color: search.activeFocus ? Qt.alpha(Theme.mauve, 0.6) : Theme.line

                        Glyph {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{f0349}"
                            font.pixelSize: 15
                            color: Theme.overlay1
                        }

                        TextInput {
                            id: search

                            anchors.left: searchIcon.right
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: Theme.text
                            selectionColor: Qt.alpha(Theme.mauve, 0.4)
                            clip: true
                            onTextChanged: win.query = text
                            Keys.onEscapePressed: {
                                if (text)
                                    text = "";
                                else
                                    Shortcuts.open = false;
                            }

                            Txt {
                                anchors.fill: parent
                                visible: !search.text
                                text: "찾기 (예: 복사, 스크린샷, 창)"
                                font.pixelSize: 13
                                color: Theme.overlay0
                            }
                        }
                    }

                    IconButton {
                        icon: Icons.close
                        iconSize: 15
                        iconColor: Theme.subtext0
                        onClicked: Shortcuts.open = false
                    }
                }

                // 카드 세 줄
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: win.lanes

                        delegate: ColumnLayout {
                            id: lane

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            spacing: 12

                            Repeater {
                                model: lane.modelData

                                delegate: Card {
                                    id: group

                                    required property var modelData

                                    Layout.fillWidth: true
                                    implicitHeight: rows.implicitHeight + 26

                                    ColumnLayout {
                                        id: rows

                                        x: 14
                                        y: 13
                                        width: parent.width - 28
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.bottomMargin: 6
                                            spacing: 8

                                            Glyph {
                                                text: group.modelData.icon
                                                font.pixelSize: 15
                                                color: Theme.mauve
                                            }

                                            Txt {
                                                Layout.fillWidth: true
                                                text: group.modelData.title
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                color: Theme.subtext1
                                            }
                                        }

                                        Repeater {
                                            model: group.modelData.items

                                            delegate: RowLayout {
                                                id: entry

                                                required property var modelData

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 30
                                                spacing: 10

                                                Txt {
                                                    Layout.fillWidth: true
                                                    text: entry.modelData.desc
                                                    font.pixelSize: 12
                                                }

                                                Row {
                                                    spacing: 3

                                                    Repeater {
                                                        model: win.parts(entry.modelData.keys)

                                                        delegate: Item {
                                                            id: part

                                                            required property var modelData

                                                            width: part.modelData.sep ? sepText.implicitWidth + 4 : cap.width
                                                            height: 24

                                                            Txt {
                                                                id: sepText
                                                                anchors.centerIn: parent
                                                                visible: !!part.modelData.sep
                                                                text: part.modelData.sep ?? ""
                                                                font.pixelSize: 11
                                                                color: Theme.overlay0
                                                            }

                                                            Keycap {
                                                                id: cap
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                visible: !part.modelData.sep
                                                                text: part.modelData.key ?? ""
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Txt {
                    Layout.fillWidth: true
                    visible: win.shown.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: "\"" + win.query + "\"에 맞는 단축키가 없습니다"
                    font.pixelSize: 13
                    color: Theme.overlay1
                }
            }
        }
    }
}
