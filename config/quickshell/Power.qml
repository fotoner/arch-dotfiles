pragma Singleton
// 전원 모드 네 가지: 저전력 · 균형 · 빠른 균형 · 성능
// 저전력·균형은 power-profiles-daemon(PPD) 그대로 (펌웨어 전력 상한 10W · 12W).
// 성능은 PPD 성능 모드인데 펌웨어 상한 28W에서는 이 노트북이 20초 만에 99°C가 되고 팬·코일 소음이 커서 MSR PL1을 22W로 낮춘다.
// 빠른 균형은 PPD 성능 모드(팬·펌웨어 상한 28W) 위에서 CPU 성향(EPP)을 balance_performance로,
// 오래 유지하는 전력 상한(MSR PL1)을 15W(인텔 기본 설계 전력)로 낮춘 것. 이 노트북은 18W에서 이미 97°C라 15W로 잡았다.
// 펌웨어는 모드를 바꿀 때 MMIO 상한만 바꾸고 MSR 상한은 그대로 둔다. 그래서 주기적으로 확인하지 않고,
// PPD가 모드를 바꿨을 때(EPP를 다시 씀)와 전원이 바뀌었을 때만 다시 맞춘다.
// 쓰기 권한과 펌웨어 기본 상한(/run/power-mode/pl1-default)은 부팅 때 /usr/local/bin/power-mode-setup이 준비한다
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: pm

    readonly property int fastWatts: 15
    readonly property int performanceWatts: 22
    property string mode: "balanced"
    property bool ready: false
    property string pl1Default: "51000000"

    readonly property var order: ["balanced", "fast", "performance", "power-saver"] // 제어 센터 버튼을 누를 때 순서
    readonly property var names: ({ "power-saver": "저전력", "balanced": "균형", "fast": "빠른 균형", "performance": "성능" })
    readonly property var notes: ({
        "power-saver": "지속 10W · 조용하고 배터리 오래 감",
        "balanced": "지속 12W · 평소 작업",
        "fast": "지속 15W · 긴 작업이 균형보다 빠름",
        "performance": "지속 22W · 가장 빠름, 팬이 많이 돎"
    })
    readonly property var icons: ({ "power-saver": Icons.leaf, "balanced": Icons.balance, "fast": Icons.gauge, "performance": Icons.bolt })
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/power-mode"

    function profileOf(m) {
        return m === "power-saver" ? PowerProfile.PowerSaver : m === "balanced" ? PowerProfile.Balanced : PowerProfile.Performance;
    }

    function modeOfProfile(p) {
        return p === PowerProfile.PowerSaver ? "power-saver" : p === PowerProfile.Balanced ? "balanced" : "performance";
    }

    function set(m) {
        if (!(m in names))
            return;
        mode = m;
        save();
        if (PowerProfiles.profile !== profileOf(m))
            PowerProfiles.profile = profileOf(m); // 바뀌면 아래 onProfileChanged에서 tune()
        else
            tune();
    }

    function cycle() {
        set(order[(order.indexOf(mode) + 1) % order.length]);
    }

    // PPD가 EPP를 다 쓴 뒤에 덮어쓰도록 조금 기다렸다가 적용한다
    function tune() {
        tuneTimer.restart();
    }

    function save() {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"${1%/*}\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", stateFile, mode]);
        Quickshell.execDetached(["pkill", "-RTMIN+10", "-x", "waybar"]); // 상단바 아이콘 새로 그리기
    }

    Timer {
        id: tuneTimer
        interval: 400
        onTriggered: {
            const fast = pm.mode === "fast";
            // 빠른 균형과 성능은 PPD에서 같은 성능이라 둘 사이를 오가면 PPD가 EPP를 다시 쓰지 않는다. 그래서 둘 다 직접 쓴다.
            // 저전력·균형은 PPD가 모드를 바꾸며 EPP를 쓰므로 그대로 둔다 (균형은 배터리일 때 PPD가 더 아끼는 값으로 바꾼다)
            const epp = fast ? "balance_performance" : pm.mode === "performance" ? "performance" : "";
            writer.command = ["sh", "-c",
                "[ -n \"$2\" ] && for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do echo \"$2\" > \"$f\"; done; " +
                "echo \"$1\" > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw",
                "sh", fast ? String(pm.fastWatts * 1000000) : pm.mode === "performance" ? String(pm.performanceWatts * 1000000) : pm.pl1Default, epp];
            writer.running = true;
        }
    }

    Process {
        id: writer
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("전원 모드 적용 실패 (power-mode-setup.service 확인):", text.trim())
        }
    }

    FileView {
        path: "/run/power-mode/pl1-default"
        printErrors: false
        onLoaded: if (/^\d+$/.test(text().trim())) pm.pl1Default = text().trim()
    }

    // 시작할 때 저장해 둔 모드를 다시 건다 (없으면 PPD의 지금 모드).
    // 막 켜졌을 때는 PPD 정보가 아직 안 와서 성능 모드를 요청할 수 없으므로, 정보가 온 뒤(hasPerformanceProfile)에 건다
    property string savedMode: ""
    property bool savedRead: false
    readonly property bool ppdReady: PowerProfiles.hasPerformanceProfile || ppdWait.expired

    function start() {
        if (ready || !savedRead || !ppdReady)
            return;
        ready = true;
        set(savedMode in names ? savedMode : modeOfProfile(PowerProfiles.profile));
    }

    onSavedReadChanged: start()
    onPpdReadyChanged: start()

    // 성능 모드가 없는 기기에서도 시작은 하도록 5초 뒤에는 그냥 진행한다
    Timer {
        id: ppdWait
        property bool expired: false
        running: true
        interval: 5000
        onTriggered: expired = true
    }

    FileView {
        path: pm.stateFile
        printErrors: false
        onLoaded: {
            pm.savedMode = text().trim();
            pm.savedRead = true;
        }
        onLoadFailed: pm.savedRead = true
    }

    // 다른 곳(powerprofilesctl 등)에서 PPD 모드를 바꾸면 그 모드를 따르고, 같은 모드여도 EPP를 PPD가 다시 썼으니 다시 맞춘다
    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            if (!pm.ready)
                return;
            if (PowerProfiles.profile !== pm.profileOf(pm.mode)) {
                pm.mode = pm.modeOfProfile(PowerProfiles.profile);
                pm.save();
            }
            pm.tune();
        }
    }

    // 전원 연결·해제 때 PPD가 EPP를 바꿀 수 있어서 다시 맞춘다
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (pm.ready)
                pm.tune();
        }
    }
}
