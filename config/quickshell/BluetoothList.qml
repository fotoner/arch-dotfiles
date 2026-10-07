pragma ComponentBehavior: Bound
// 블루투스 기기 목록: 연결된 기기 먼저. 누르면 연결/해제, 처음 보는 기기는 페어링 후 연결.
// '새 기기 찾기'를 누르면 주변 기기도 보인다
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Card {
    id: list

    property var adapter: null
    readonly property bool on: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter ? Array.from(adapter.devices.values)
        .filter(d => d.paired || d.connected || (list.discovering && d.deviceName !== ""))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)) : []

    // 목록을 닫으면 찾기도 멈춘다
    readonly property bool active: visible && CC.open
    onActiveChanged: if (!active && discovering) adapter.discovering = false

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 16

    ColumnLayout {
        id: col
        x: 6
        y: 8
        width: parent.width - 12
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 4
            Layout.bottomMargin: 4

            Txt {
                Layout.fillWidth: true
                text: "블루투스 기기"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.subtext1
            }

            Txt {
                visible: list.on
                text: list.discovering ? "찾는 중… (멈추기)" : "새 기기 찾기"
                font.pixelSize: 11
                color: scanArea.containsMouse ? Theme.text : list.discovering ? Theme.mauve : Theme.subtext0

                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: list.adapter.discovering = !list.discovering
                }
            }
        }

        Txt {
            visible: !list.on || list.devices.length === 0
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            text: !list.on ? "블루투스가 꺼져 있어요" : list.discovering ? "주변 기기를 찾고 있어요" : "연결했던 기기가 없어요. '새 기기 찾기'를 눌러 주세요"
            font.pixelSize: 12
            color: Theme.overlay1
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }

        ListView {
            id: view
            visible: list.on
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 236)
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: list.devices

            delegate: Item {
                id: entry

                required property var modelData
                readonly property var dev: modelData
                readonly property bool busy: dev.pairing || dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting
                property bool connectAfterPair: false

                width: view.width
                height: 42

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: area.containsMouse ? Theme.fill : "transparent"
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (entry.busy)
                            return;
                        if (entry.dev.connected) {
                            entry.dev.disconnect();
                        } else if (entry.dev.paired) {
                            entry.dev.connect();
                        } else {
                            entry.connectAfterPair = true;
                            entry.dev.trusted = true;
                            entry.dev.pair();
                        }
                    }
                }

                Connections {
                    target: entry.dev
                    function onPairedChanged() {
                        if (entry.dev.paired && entry.connectAfterPair) {
                            entry.connectAfterPair = false;
                            entry.dev.connect();
                        }
                    }
                }

                RowLayout {
                    x: 6
                    width: parent.width - 12
                    height: parent.height
                    spacing: 10

                    Glyph {
                        Layout.preferredWidth: 18
                        text: Icons.device(entry.dev.icon)
                        color: entry.dev.connected ? Theme.mauve : Theme.text
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        Txt {
                            width: parent.width
                            text: entry.dev.name
                            font.weight: entry.dev.connected ? Font.DemiBold : Font.Normal
                        }

                        Txt {
                            width: parent.width
                            font.pixelSize: 11
                            color: entry.dev.connected ? Theme.mauve : Theme.overlay1
                            text: entry.dev.pairing ? "페어링 중…"
                                : entry.dev.state === BluetoothDeviceState.Connecting ? "연결 중…"
                                : entry.dev.state === BluetoothDeviceState.Disconnecting ? "연결 끊는 중…"
                                : entry.dev.connected ? "연결됨"
                                : entry.dev.paired ? "연결 안 됨" : "눌러서 페어링"
                        }
                    }

                    // 기기 배터리 (이어폰 등이 알려 줄 때만)
                    Row {
                        visible: entry.dev.batteryAvailable
                        spacing: 3

                        readonly property real level: entry.dev.battery > 1 ? entry.dev.battery / 100 : entry.dev.battery

                        Glyph {
                            text: Icons.battery(parent.level, false)
                            font.pixelSize: 13
                            color: parent.level <= 0.2 ? Theme.red : Theme.subtext0
                        }

                        Txt {
                            text: Math.round(parent.level * 100) + "%"
                            font.pixelSize: 11
                            font.features: { "tnum": 1 }
                            color: Theme.subtext0
                        }
                    }
                }
            }
        }

        LinkRow {
            text: "블루투스 설정…"
            onClicked: CC.closeAndRun("blueman-manager")
        }
    }
}
