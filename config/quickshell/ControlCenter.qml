// 제어 센터 패널: 화면 오른쪽 위에 뜬다. 바깥을 누르거나 Esc를 누르면 닫힌다
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: win

    readonly property int pad: 8 // 그림자 자리 겸 화면 가장자리 간격 (창 간격 gaps_out과 같게)

    readonly property var wifiDevice: Array.from(Networking.devices.values).find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDevice ? (Array.from(wifiDevice.networks.values).find(n => n.connected) ?? null) : null
    readonly property bool wiredUp: Array.from(Networking.devices.values).some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var btConnected: adapter ? Array.from(adapter.devices.values).filter(d => d.connected) : []
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? true
    property bool dnd: false
    property real brightness: 0

    function toggleBluetooth() {
        if (!adapter)
            return;
        if (adapter.state === BluetoothAdapterState.Blocked)
            CC.run("rfkill unblock bluetooth && sleep 1 && bluetoothctl power on");
        else
            adapter.enabled = !adapter.enabled;
    }

    // 균형 → 성능 → 저전력 → 균형
    function cycleProfile() {
        const p = PowerProfiles.profile;
        if (p === PowerProfile.Balanced)
            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
        else if (p === PowerProfile.Performance)
            PowerProfiles.profile = PowerProfile.PowerSaver;
        else
            PowerProfiles.profile = PowerProfile.Balanced;
    }

    visible: CC.open || card.opacity > 0
    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: 380 + 2 * pad
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    // 카드 바깥(투명한 부분)은 클릭이 아래 창으로 지나간다
    mask: Region { item: card }

    onVisibleChanged: if (visible) card.forceActiveFocus()

    HyprlandFocusGrab {
        windows: [win]
        active: CC.open
        onCleared: CC.open = false
    }

    PwObjectTracker {
        objects: [win.sink, win.source]
    }

    // 방해 금지 상태: swaync가 바뀔 때마다 JSON 한 줄씩 알려 준다. swaync가 늦게 뜨거나 재시작되면 다시 붙는다
    Process {
        id: dndWatch
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    win.dnd = JSON.parse(line).alt.startsWith("dnd");
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) dndRetry.start()
    }

    Timer {
        id: dndRetry
        interval: 3000
        onTriggered: dndWatch.running = true
    }

    // 화면 밝기: 열려 있을 때 읽고, 끄는 동안에는 80ms에 한 번만 바꾼다
    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5 && !brightApply.running)
                    win.brightness = Number(f[2]) / Number(f[4]);
            }
        }
    }

    Timer {
        running: CC.open
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!brightRead.running) brightRead.running = true
    }

    Timer {
        id: brightApply
        interval: 80
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(1, Math.round(win.brightness * 100)) + "%"])
    }

    Item {
        id: card

        x: win.pad
        y: win.pad
        width: 380
        height: Math.min(content.implicitHeight + 28, win.height - 2 * win.pad)
        opacity: CC.open ? 1 : 0
        focus: true
        Keys.onEscapePressed: CC.open = false

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        transform: Translate {
            y: CC.open ? 0 : -10
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 18
            offset.y: 4
            color: Qt.rgba(0, 0, 0, 0.35)
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 22
            color: Qt.alpha(Theme.base, 0.86)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 14
            contentHeight: content.implicitHeight
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 10

                // Wi-Fi · 블루투스 + 빠른 버튼 4개
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: tiles.rowSpacing

                        ConnRow {
                            title: "Wi-Fi"
                            icon: !Networking.wifiEnabled ? Icons.wifiOff : win.wifiNet ? Icons.wifi(win.wifiNet.signalStrength) : Icons.wifiNone
                            subtitle: !Networking.wifiEnabled ? "꺼짐"
                                : win.wifiNet ? win.wifiNet.name
                                : win.wiredUp ? "유선 연결됨" : "연결 안 됨"
                            active: Networking.wifiEnabled
                            expanded: CC.section === "wifi"
                            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                            onExpandRequested: CC.toggleSection("wifi")
                        }

                        ConnRow {
                            readonly property var first: win.btConnected[0] ?? null
                            title: "블루투스"
                            icon: !win.btOn ? Icons.bluetoothOff : first ? Icons.bluetoothConnected : Icons.bluetooth
                            subtitle: !win.btOn ? "꺼짐"
                                : !first ? "켜짐"
                                : first.name + (win.btConnected.length > 1 ? " 외 " + (win.btConnected.length - 1) + "대" : "")
                                  + (first.batteryAvailable ? " · " + Math.round(first.battery > 1 ? first.battery : first.battery * 100) + "%" : "")
                            active: win.btOn
                            expanded: CC.section === "bluetooth"
                            onToggled: win.toggleBluetooth()
                            onExpandRequested: CC.toggleSection("bluetooth")
                        }
                    }

                    GridLayout {
                        id: tiles
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        SmallTile {
                            icon: Icons.moon
                            label: "방해 금지"
                            active: win.dnd
                            onClicked: CC.run("swaync-client -d -sw")
                        }

                        SmallTile {
                            icon: win.micMuted ? Icons.micOff : Icons.mic
                            label: "마이크"
                            active: !win.micMuted
                            onClicked: if (win.source?.audio) win.source.audio.muted = !win.source.audio.muted
                        }

                        SmallTile {
                            readonly property int profile: PowerProfiles.profile
                            icon: profile === PowerProfile.PowerSaver ? Icons.leaf : profile === PowerProfile.Performance ? Icons.bolt : Icons.balance
                            label: profile === PowerProfile.PowerSaver ? "저전력" : profile === PowerProfile.Performance ? "성능" : "균형"
                            active: profile !== PowerProfile.Balanced
                            onClicked: win.cycleProfile()
                        }

                        SmallTile {
                            icon: Icons.camera
                            label: "스크린샷"
                            onClicked: CC.closeAndRun("~/.config/hypr/scripts/screenshot.sh area")
                        }
                    }
                }

                WifiList {
                    visible: CC.section === "wifi"
                    device: win.wifiDevice
                }

                BluetoothList {
                    visible: CC.section === "bluetooth"
                    adapter: win.adapter
                }

                // 화면 밝기와 소리
                Card {
                    Layout.fillWidth: true
                    implicitHeight: sliders.implicitHeight + 24

                    ColumnLayout {
                        id: sliders
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 8

                        Txt {
                            text: "디스플레이"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.subtext1
                        }

                        BigSlider {
                            icon: Icons.brightness
                            value: win.brightness
                            onMoved: v => {
                                win.brightness = v;
                                if (!brightApply.running)
                                    brightApply.start();
                            }
                        }

                        // '사운드' 줄을 누르면 출력 장치 목록
                        Item {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            implicitHeight: 18

                            Txt {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "사운드"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.subtext1
                            }

                            Txt {
                                anchors.right: soundChevron.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width - 70)
                                text: CC.sinkName(win.sink)
                                font.pixelSize: 11
                                color: soundArea.containsMouse ? Theme.text : Theme.overlay1
                            }

                            Glyph {
                                id: soundChevron
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{f0142}"
                                font.pixelSize: 13
                                color: Theme.overlay1
                                rotation: CC.section === "sound" ? 90 : 0
                                Behavior on rotation { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: soundArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CC.toggleSection("sound")
                            }
                        }

                        BigSlider {
                            readonly property bool muted: win.sink?.audio?.muted ?? false
                            icon: Icons.volume(value, muted)
                            value: win.sink?.audio?.volume ?? 0
                            dimmed: muted
                            onMoved: v => {
                                if (!win.sink?.audio)
                                    return;
                                win.sink.audio.muted = false;
                                win.sink.audio.volume = v;
                            }
                            onIconClicked: if (win.sink?.audio) win.sink.audio.muted = !muted
                        }

                        SinkList {
                            visible: CC.section === "sound"
                        }
                    }
                }

                MediaCard {}

                BatteryCard {}

                StatsCard {}

                // 알림 센터, 전원 메뉴
                RowLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: 5
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: Icons.bell
                        onClicked: CC.closeAndRun("swaync-client -op -sw")
                    }

                    IconButton {
                        icon: Icons.power
                        onClicked: CC.closeAndRun("nwg-bar")
                    }
                }
            }
        }
    }
}
