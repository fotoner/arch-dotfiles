pragma ComponentBehavior: Bound
// Wi-Fi 목록: 연결된 곳 먼저, 나머지는 신호 센 순서. 누르면 연결 (저장된 곳은 바로, 처음이면 암호를 묻는다)
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

Card {
    id: list

    property var device: null // Wi-Fi 장치
    property string askPsk: "" // 암호를 묻고 있는 네트워크 이름
    property string message: ""

    readonly property bool scanning: visible && CC.open && Networking.wifiEnabled
    readonly property var networks: device ? Array.from(device.networks.values)
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []

    onScanningChanged: if (device) device.scannerEnabled = scanning
    onDeviceChanged: if (device) device.scannerEnabled = scanning
    onVisibleChanged: { askPsk = ""; message = ""; }

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
                text: "Wi-Fi 네트워크"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.subtext1
            }
        }

        Txt {
            visible: !Networking.wifiEnabled || list.networks.length === 0
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            text: Networking.wifiEnabled ? "주변 네트워크를 찾고 있어요" : "Wi-Fi가 꺼져 있어요"
            font.pixelSize: 12
            color: Theme.overlay1
        }

        ListView {
            id: view
            visible: Networking.wifiEnabled
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 236)
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: list.networks

            delegate: Item {
                id: entry

                required property var modelData
                readonly property var net: modelData
                readonly property bool secured: net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Owe
                readonly property bool asking: list.askPsk === net.name

                function submit() {
                    if (psk.text.length < 8) {
                        list.message = "암호는 8자 이상이에요";
                        return;
                    }
                    list.message = "";
                    net.connectWithPsk(psk.text);
                    list.askPsk = "";
                }

                width: view.width
                height: asking ? 76 : 36
                onAskingChanged: asking ? psk.forceActiveFocus() : psk.clear()

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: rowArea.containsMouse && !entry.net.connected ? Theme.fill : "transparent"
                }

                MouseArea {
                    id: rowArea
                    width: parent.width
                    height: 36
                    hoverEnabled: true
                    cursorShape: entry.net.connected ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (entry.net.connected || entry.net.stateChanging)
                            return;
                        list.message = "";
                        if (entry.net.known || !entry.secured)
                            entry.net.connect();
                        else
                            list.askPsk = entry.asking ? "" : entry.net.name;
                    }
                }

                RowLayout {
                    x: 6
                    width: parent.width - 12
                    height: 36
                    spacing: 10

                    Glyph {
                        Layout.preferredWidth: 18
                        text: Icons.wifi(entry.net.signalStrength)
                        font.pixelSize: 15
                        color: entry.net.connected ? Theme.mauve : Theme.text
                    }

                    Txt {
                        Layout.fillWidth: true
                        text: entry.net.name
                        font.weight: entry.net.connected ? Font.DemiBold : Font.Normal
                    }

                    Glyph {
                        Layout.preferredWidth: 14
                        opacity: entry.secured ? 1 : 0
                        text: Icons.lock
                        font.pixelSize: 12
                        color: Theme.overlay1
                    }

                    Item {
                        id: rightCol
                        readonly property bool offerDisconnect: entry.net.connected && (rowArea.containsMouse || disconnectArea.containsMouse)
                        Layout.preferredWidth: 50
                        Layout.fillHeight: true

                        Txt {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !rightCol.offerDisconnect
                            text: entry.net.stateChanging ? "연결 중…" : Math.round(entry.net.signalStrength * 100) + "%"
                            font.pixelSize: 11
                            font.features: { "tnum": 1 }
                            color: entry.net.connected ? Theme.mauve : Theme.overlay1
                        }

                        Txt {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: rightCol.offerDisconnect
                            text: "연결 해제"
                            font.pixelSize: 11
                            color: disconnectArea.containsMouse ? Theme.red : Theme.subtext0
                        }

                        MouseArea {
                            id: disconnectArea
                            anchors.fill: parent
                            enabled: entry.net.connected
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: entry.net.disconnect()
                        }
                    }
                }

                // 처음 연결하는 암호 걸린 네트워크: 암호 칸
                RowLayout {
                    visible: entry.asking
                    x: 6
                    y: 40
                    width: parent.width - 12
                    height: 32
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.25)
                        border.width: 1
                        border.color: psk.activeFocus ? Theme.mauve : Theme.line

                        TextInput {
                            id: psk
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            clip: true
                            color: Theme.text
                            selectionColor: Theme.mauve
                            font.family: Theme.font
                            font.pixelSize: 12
                            onAccepted: entry.submit()
                            Keys.onEscapePressed: list.askPsk = ""
                        }

                        Txt {
                            anchors.fill: psk
                            visible: psk.text === ""
                            text: "암호"
                            font.pixelSize: 12
                            color: Theme.overlay0
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.fillHeight: true
                        radius: 8
                        color: Theme.mauve

                        Txt {
                            anchors.centerIn: parent
                            text: "연결"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.base
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: entry.submit()
                        }
                    }
                }

                Connections {
                    target: entry.net
                    function onConnectionFailed(reason) {
                        list.message = entry.net.name + " 연결 실패" + (reason === ConnectionFailReason.NoSecrets ? " (암호를 확인해 주세요)" : "");
                        if (entry.secured)
                            list.askPsk = entry.net.name;
                    }
                }
            }
        }

        Txt {
            visible: list.message !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 6
            text: list.message
            font.pixelSize: 11
            color: Theme.red
        }

        LinkRow {
            text: "네트워크 설정…"
            onClicked: CC.closeAndRun("~/.config/hypr/scripts/wifi-menu.sh")
        }
    }
}
