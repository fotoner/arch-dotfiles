pragma ComponentBehavior: Bound
// 배터리: 잔량, 충전 상태, 남은 시간, 충전 한도(80%까지만 / 100% 완충).
// 충전 한도는 UPower가 ThinkPad 펌웨어에 기록한다 (비밀번호 필요 없음, 재부팅해도 유지)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Card {
    id: card

    readonly property var dev: UPower.displayDevice
    readonly property var battery: Array.from(UPower.devices.values).find(d => d.isLaptopBattery) ?? null
    readonly property string name: battery?.nativePath || "BAT0"
    readonly property real level: dev.percentage > 1 ? dev.percentage / 100 : dev.percentage
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property bool full: dev.state === UPowerDeviceState.FullyCharged
    readonly property bool plugged: !UPower.onBattery

    // 지금 펌웨어에 걸린 멈춤 값 (100이면 제한 없음)과, 제한을 켤 때 쓰는 값
    property int endNow: 100
    property int limitStart: 75
    property int limitEnd: 80
    readonly property bool limited: endNow < 100

    function hm(seconds) {
        const h = Math.floor(seconds / 3600), m = Math.round(seconds % 3600 / 60);
        return h > 0 ? h + "시간 " + m + "분" : m + "분";
    }

    function setLimit(on) {
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.UPower", "/org/freedesktop/UPower/devices/battery_" + name,
            "org.freedesktop.UPower.Device", "EnableChargeThreshold", "b", on ? "true" : "false"]);
        recheck.restart();
    }

    readonly property string status: {
        if (charging)
            return "충전 중" + (dev.timeToFull > 0 ? " · " + hm(dev.timeToFull) + " 후 " + (limited ? limitEnd + "%" : "완충") : "");
        if (full)
            return "완전히 충전됨";
        if (plugged)
            return limited && level * 100 >= limitStart - 1 ? "전원 연결됨 · 충전 한도라서 충전 안 함" : "전원 연결됨 · 충전 대기";
        return "배터리 사용 중" + (dev.timeToEmpty > 0 ? " · " + hm(dev.timeToEmpty) + " 남음" : "");
    }

    visible: battery !== null
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 24

    FileView {
        id: endFile
        path: "/sys/class/power_supply/" + card.name + "/charge_control_end_threshold"
        onLoaded: card.endNow = parseInt(text()) || 100
    }

    Process {
        running: true
        command: ["sh", "-c", "for p in ChargeStartThreshold ChargeEndThreshold; do busctl get-property org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_" + card.name + " org.freedesktop.UPower.Device $p; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").map(l => parseInt(l.split(" ")[1]));
                if (v[0] > 0) card.limitStart = v[0];
                if (v[1] > 0) card.limitEnd = v[1];
            }
        }
    }

    Timer {
        id: recheck
        interval: 700
        onTriggered: endFile.reload()
    }

    Timer {
        running: CC.open
        interval: 5000
        repeat: true
        onTriggered: endFile.reload()
    }

    ColumnLayout {
        id: col
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Glyph {
                Layout.alignment: Qt.AlignVCenter
                text: Icons.battery(card.level, card.charging)
                font.pixelSize: 18
                color: card.charging ? Theme.green : card.level <= 0.1 ? Theme.red : card.level <= 0.25 ? Theme.yellow : card.plugged ? Theme.teal : Theme.text
            }

            Txt {
                Layout.alignment: Qt.AlignBaseline
                text: Math.round(card.level * 100) + "%"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }

            Txt {
                Layout.alignment: Qt.AlignBaseline
                Layout.fillWidth: true
                text: card.status
                font.pixelSize: 11
                color: Theme.subtext0
            }

            Txt {
                Layout.alignment: Qt.AlignBaseline
                visible: card.dev.changeRate > 0.05
                text: card.dev.changeRate.toFixed(1) + "W"
                font.pixelSize: 11
                font.features: { "tnum": 1 }
                color: Theme.overlay1
            }
        }

        // 잔량 막대. 충전 한도를 켜 두면 멈추는 자리에 눈금
        Item {
            Layout.fillWidth: true
            implicitHeight: 6

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Rectangle {
                height: parent.height
                width: parent.width * Math.min(1, card.level)
                radius: 3
                color: card.charging ? Theme.green : card.level <= 0.1 ? Theme.red : card.level <= 0.25 ? Theme.yellow : card.plugged ? Theme.teal : Theme.subtext1
                Behavior on width { NumberAnimation { duration: 400 } }
            }

            Rectangle {
                visible: card.limited
                x: parent.width * card.endNow / 100 - 1
                y: -2
                width: 2
                height: parent.height + 4
                radius: 1
                color: Theme.text
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Column {
                Layout.fillWidth: true
                spacing: 1

                Txt {
                    width: parent.width
                    text: "충전 한도"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Txt {
                    width: parent.width
                    text: card.limited ? card.limitStart + "% 아래로 내려가면 충전, " + card.endNow + "%에서 멈춤" : "100%까지 충전 (외출 전에 완충할 때)"
                    font.pixelSize: 10
                    color: Theme.overlay1
                }
            }

            // [80%] [100%] 고르기
            Rectangle {
                implicitWidth: seg.implicitWidth + 4
                implicitHeight: 28
                radius: 14
                color: Qt.rgba(0, 0, 0, 0.25)

                Row {
                    id: seg
                    anchors.centerIn: parent

                    Repeater {
                        model: [{ label: card.limitEnd + "%", limit: true }, { label: "100%", limit: false }]

                        delegate: Rectangle {
                            id: option

                            required property var modelData
                            readonly property bool selected: card.limited === modelData.limit

                            width: 52
                            height: 24
                            radius: 12
                            color: selected ? Theme.mauve : optionArea.containsMouse ? Theme.fill : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Txt {
                                anchors.centerIn: parent
                                text: option.modelData.label
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: option.selected ? Theme.base : Theme.subtext0
                            }

                            MouseArea {
                                id: optionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!option.selected) card.setLimit(option.modelData.limit)
                            }
                        }
                    }
                }
            }
        }
    }
}
