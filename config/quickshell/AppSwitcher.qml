pragma ComponentBehavior: Bound
// 앱 전환기 (맥 ⌘Tab): Alt+Tab을 빠르게 한 번 누르면 바로 직전에 쓰던 앱으로, Alt를 누른 채 Tab을 누르면
// 화면 가운데에 최근에 쓴 순서대로 앱 아이콘이 뜨고 Tab(Shift+Tab, ←→)으로 고른 뒤 Alt를 떼면 그 앱으로 간다. Esc = 취소.
// 워크스페이스·모니터와 상관없이 앱 단위로 보여 준다 (같은 앱 창이 여럿이면 가장 최근 창으로).
// 고르는 동안에는 아무것도 바뀌지 않고, Alt를 떼는 순간에만 그 앱으로 넘어간다(커서도 그때 따라간다).
// 한 바퀴 돌아 지금 쓰던 앱을 고르면 아무것도 하지 않는다 (커서가 창 가운데로 튀지 않게).
// Hyprland가 Alt+Tab에서 qs ipc call switcher next|prev를, 전환 중에 Alt를 떼면 release를 부른다 (hyprland.lua)
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property int shadowRoom: 28
    property bool active: false // Alt를 누르고 고르는 중
    property bool shown: false // 목록이 화면에 보임 (빠르게 한 번 누를 때는 안 보이고 바로 넘어간다)
    property var apps: [] // [{ cls, name, icon, address, count }]

    // Quickshell은 앱 목록(.desktop)을 처음 물어볼 때 읽기 시작한다. 셸이 켜질 때 미리 물어봐 두지 않으면
    // 재시작 뒤 첫 Alt+Tab에서 목록이 비어 아이콘·이름을 창 class로 추측하게 된다
    Component.onCompleted: DesktopEntries.applications.values.length
    property int index: 0
    property int startDir: 1
    property bool released: false // 목록을 만들기 전에 이미 Alt를 뗐음 (빠르게 한 번)
    property string screenName: ""

    function next() {
        step(1);
    }

    function prev() {
        step(-1);
    }

    function step(dir) {
        if (!active) {
            active = true;
            released = false;
            startDir = dir;
            screenName = Hyprland.focusedMonitor?.name ?? "";
            reader.running = true;
            return;
        }
        if (apps.length > 0)
            index = (index + dir + apps.length) % apps.length;
        if (!shown)
            reveal();
    }

    function reveal() {
        shown = true;
        card.forceActiveFocus();
    }

    // Alt를 뗌: 목록이 아직 안 만들어졌으면 만들어지자마자 넘어간다
    function release() {
        if (!active)
            return;
        if (apps.length === 0 || reader.running)
            released = true;
        else
            commit();
    }

    function commit() {
        const target = apps[index];
        const same = index === 0; // 목록 첫 칸은 지금 쓰던 앱 (최근 순서)
        const wasShown = shown;
        reset();
        if (!target || same)
            return;
        // 목록이 떠 있었으면 키보드를 잡고 있던 목록 창이 닫히면서 Hyprland가 포커스를 원래 창으로 돌려준다.
        // 그게 끝난 뒤에 넘어가야 하므로 사라지는 애니메이션(0.11초)이 끝날 때까지 기다린다
        focusTimer.address = target.address;
        focusTimer.interval = wasShown ? 160 : 1;
        focusTimer.restart();
    }

    function reset() {
        active = false;
        shown = false;
        released = false;
        holdTimer.stop();
    }

    // 창 class에 맞는 앱 정보(.desktop): StartupWMClass나 파일 이름이 class와 같은 것, 없으면 Quickshell의 추측
    function entryFor(cls) {
        const lc = cls.toLowerCase();
        return DesktopEntries.applications.values.find(e => (e.startupClass || "").toLowerCase() === lc || e.id.toLowerCase() === lc)
            ?? DesktopEntries.heuristicLookup(cls);
    }

    // 최근에 쓴 창 순서(focusHistoryID)대로, 같은 앱은 처음 나온 것(가장 최근 창)만
    function build(text) {
        let list;
        try {
            list = JSON.parse(text);
        } catch (e) {
            return [];
        }
        list = list.filter(c => c.mapped && !c.hidden && c.focusHistoryID >= 0).sort((a, b) => a.focusHistoryID - b.focusHistoryID);
        const out = [];
        for (const c of list) {
            const found = out.find(a => a.cls === c.class);
            if (found) {
                found.count++;
                continue;
            }
            const entry = win.entryFor(c.class);
            out.push({
                cls: c.class,
                name: entry?.name || c.class,
                icon: Quickshell.iconPath(entry?.icon || c.class.toLowerCase(), "application-x-executable"),
                address: c.address,
                count: 1
            });
        }
        return out;
    }

    Process {
        id: reader
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                win.apps = win.build(text);
                if (win.apps.length === 0) {
                    win.reset();
                    return;
                }
                win.index = win.startDir > 0 ? Math.min(1, win.apps.length - 1) : win.apps.length - 1;
                if (win.released)
                    win.commit();
                else
                    holdTimer.restart();
            }
        }
    }

    Timer {
        id: focusTimer
        property string address
        onTriggered: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + address + "\" })"])
    }

    // 잠깐(0.12초) 안에 Alt를 떼지 않았으면 목록을 보여 준다. 빠르게 한 번이면 그 전에 release가 와서 바로 넘어간다
    Timer {
        id: holdTimer
        interval: 120
        onTriggered: if (win.active && !win.shown) win.reveal()
    }

    screen: Quickshell.screens.find(s => s.name === screenName) ?? Quickshell.screens[0] ?? null
    visible: shown || card.opacity > 0
    implicitWidth: card.width + shadowRoom * 2
    implicitHeight: card.height + shadowRoom * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: card }

    Item {
        id: card

        x: win.shadowRoom
        y: win.shadowRoom
        width: Math.max(row.implicitWidth, nameText.implicitWidth) + 36
        height: row.implicitHeight + nameText.implicitHeight + 44
        opacity: win.shown ? 1 : 0
        focus: true

        Behavior on opacity { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr || event.key === Qt.Key_Meta)
                win.commit();
        }
        Keys.onEscapePressed: win.reset()
        Keys.onReturnPressed: win.commit()
        Keys.onRightPressed: win.step(1)
        Keys.onLeftPressed: win.step(-1)

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 24
            offset.y: 6
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 26
            color: Qt.alpha(Theme.base, 0.88)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }

        Row {
            id: row

            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            spacing: 6

            Repeater {
                model: win.apps

                delegate: Rectangle {
                    id: tile

                    required property var modelData
                    required property int index
                    readonly property bool on: tile.index === win.index

                    width: 96
                    height: 96
                    radius: 20
                    color: on ? Qt.rgba(1, 1, 1, 0.14) : area.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                    border.width: on ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.12)

                    Image {
                        anchors.centerIn: parent
                        width: 68
                        height: 68
                        sourceSize.width: 136
                        sourceSize.height: 136
                        source: tile.modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    // 같은 앱 창이 여럿이면 오른쪽 아래에 개수
                    Rectangle {
                        visible: tile.modelData.count > 1
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        width: Math.max(18, countText.implicitWidth + 8)
                        height: 18
                        radius: 9
                        color: Theme.surface1

                        Txt {
                            id: countText
                            anchors.centerIn: parent
                            text: tile.modelData.count
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            win.index = tile.index;
                            win.commit();
                        }
                    }
                }
            }
        }

        Txt {
            id: nameText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: row.bottom
            anchors.topMargin: 10
            text: win.apps[win.index]?.name ?? ""
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }
}
