// 시스템 사용량: CPU, 메모리, 디스크(/), CPU 온도. 패널이 열려 있을 때만 2초마다 읽는다
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Card {
    id: card

    property real cpu: 0
    property var lastCpu: null
    property real mem: 0
    property real memUsed: 0
    property real memTotal: 0
    property real disk: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property real temp: 0

    function gb(bytes) {
        return (bytes / 1073741824).toFixed(bytes >= 107374182400 ? 0 : 1);
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 24

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (card.lastCpu && total > card.lastCpu.total)
                card.cpu = 1 - (idle - card.lastCpu.idle) / (total - card.lastCpu.total);
            card.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const kb = key => Number((t.match(new RegExp("^" + key + ":\\s+(\\d+)", "m")) ?? [0, 0])[1]) * 1024;
            card.memTotal = kb("MemTotal");
            card.memUsed = card.memTotal - kb("MemAvailable");
            card.mem = card.memTotal > 0 ? card.memUsed / card.memTotal : 0;
        }
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = (text.trim().split("\n")[1] ?? "").trim().split(/\s+/).map(Number);
                if (v.length === 2 && v[1] > 0) {
                    card.diskUsed = v[0];
                    card.diskTotal = v[1];
                    card.disk = v[0] / v[1];
                }
            }
        }
    }

    // CPU 온도 파일 찾기: coretemp(인텔)/k10temp(AMD) 센서, 없으면 x86_pkg_temp
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in coretemp|k10temp|zenpower) echo $h/temp1_input; exit;; esac; done; for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && echo $z/temp && exit; done"]
        stdout: StdioCollector {
            onStreamFinished: tempFile.path = text.trim()
        }
    }

    FileView {
        id: tempFile
        onLoaded: card.temp = parseInt(text()) / 1000
    }

    Timer {
        running: CC.open
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (tempFile.path !== "")
                tempFile.reload();
            if (!df.running)
                df.running = true;
        }
    }

    ColumnLayout {
        id: col
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 6

        Txt {
            text: "시스템"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.subtext1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Gauge {
                value: card.cpu
                color: Theme.blue
                text: Math.round(card.cpu * 100) + "%"
                label: "CPU"
                detail: " "
            }

            Item {
                Layout.fillWidth: true
            }

            Gauge {
                value: card.mem
                color: Theme.mauve
                text: Math.round(card.mem * 100) + "%"
                label: "메모리"
                detail: card.gb(card.memUsed) + " / " + card.gb(card.memTotal) + "G"
            }

            Item {
                Layout.fillWidth: true
            }

            Gauge {
                value: card.disk
                color: Theme.teal
                text: Math.round(card.disk * 100) + "%"
                label: "디스크"
                detail: card.gb(card.diskUsed) + " / " + card.gb(card.diskTotal) + "G"
            }

            Item {
                Layout.fillWidth: true
            }

            Gauge {
                value: card.temp / 100
                color: card.temp >= 85 ? Theme.red : card.temp >= 70 ? Theme.peach : Theme.yellow
                text: Math.round(card.temp) + "°"
                label: "온도"
                detail: " "
            }
        }
    }
}
