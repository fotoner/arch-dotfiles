-- arch-dotfiles: Hyprland 0.56.2 기본 예시 설정(example/hyprland.lua)에서 출발해 '-- 한글 주석' 부분만 바꿨습니다.
-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- 디스플레이 설정 창(제어 센터 → 디스플레이 → 디스플레이 설정…)이 저장한 모니터별 해상도·위치·배율·회전·미러링.
-- 이 컴퓨터에만 있는 파일(~/.config/hypr/monitors.lua)이라 저장소에는 없다
pcall(require, "monitors")


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "hyprlauncher"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- hl.on("hyprland.start", function () 
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)


hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent") -- 관리자 암호 창
    hl.exec_cmd("fcitx5 -d --disable=notificationitem")   -- 한글 입력기 (트레이 아이콘 대신 상단바에 한/A 표시)
    hl.exec_cmd("waybar")                                 -- 상단 막대
    hl.exec_cmd("hyprpaper")                              -- 바탕화면
    hl.exec_cmd("systemctl --user start swayosd-server")  -- 음량·밝기 팝업 (PipeWire가 재시작되면 같이 재시작, ~/.config/systemd/user)
    hl.exec_cmd("swaync")                                 -- 알림 센터 (Super+N, 시계 클릭)
    hl.exec_cmd("qs")                                     -- 제어 센터 (Super+A, 상단바 제어 센터 아이콘), ~/.config/quickshell
    hl.exec_cmd("batsignal -b -w 20 -c 10")               -- 배터리 20%·10%에서 알림
    hl.exec_cmd("hypridle")                               -- 자동 잠금/화면 끄기
    hl.exec_cmd("vicinae server")                         -- Raycast 대체 실행기 (Alt+Space)
    hl.exec_cmd("~/.local/bin/codexbar-linux --background") -- AI 사용량 (상단바 트레이)
    hl.exec_cmd("~/.config/hypr/scripts/startup-layout.sh") -- 첫 화면: 왼쪽 위 fastfetch, 왼쪽 아래 시계, 오른쪽 터미널
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "macOS") -- 맥 커서 (apple_cursor)

-- fcitx5: Wayland 앱은 text-input 프로토콜을 쓰고, Xwayland/Qt 앱용으로만 지정
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- 처음 켤 때 뜨는 Hyprland 기부 요청 팝업을 끈다 (업데이트 소식 팝업은 그대로: no_update_news)
hl.config({
    ecosystem = {
        no_donation_nag = true,
    },
})

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 8, -- 화면 가장자리·상단바와 창 사이 여백

        border_size = 2,

        -- 창 테두리 색: Catppuccin Mocha (보라 → 하늘색)
        col = {
            active_border   = { colors = {"rgba(cba6f7ee)", "rgba(89b4faee)"}, angle = 45 },
            inactive_border = "rgba(45475aaa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true, -- 맥처럼 창 테두리를 끌어서 크기 조절

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee11111b, -- 그림자 색: Catppuccin Mocha crust
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
-- 워크스페이스 전환: 맥 Spaces처럼 옆으로 밀기
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        -- 바탕화면은 hyprpaper가 그린다. hyprpaper가 없을 때는 기본 그림 대신 Catppuccin 배경색만
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        background_color        = 0xff1e1e2e,
        -- 앱이 앞으로 와 달라고 하면 그 창으로 간다 (터미널에서 링크를 누르면 다른 워크스페이스의 브라우저로 바로 이동)
        focus_on_activate       = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.8, -- 터치패드 스크롤 속도 (기본 1.0, 작을수록 느림)
            clickfinger_behavior = true, -- 맥처럼 두 손가락으로 누르면 오른쪽 클릭, 세 손가락은 가운데 클릭 (모서리 위치와 상관없이)
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
-- 로그아웃: 바로 끝내지 않고 확인 창을 띄운다 (실수로 눌러도 안전). 맥의 Cmd+Shift+Q는 아래 Alt + Shift + Q
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call session logout"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- 지금 창을 그 방향의 창과 자리 바꾸기
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))

-- 모니터가 여럿일 때: SUPER + CTRL + SHIFT + 방향키 = 창을 그 방향 모니터로, SUPER + ALT + SHIFT + 방향키 = 지금 워크스페이스를 통째로
for key, dir in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
    hl.bind(mainMod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ monitor = dir }))
    hl.bind(mainMod .. " + ALT + SHIFT + " .. key,  hl.dsp.workspace.move({ monitor = dir }))
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
-- 음량·밝기 키: swayosd가 맥처럼 화면에 팝업을 띄운다. swayosd가 없거나 꺼져 있으면 팝업 없이 바로 바꾼다
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5 --max-volume 100 || wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5 || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),         { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),          { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness +5 || brightnessctl -e4 -n2 set 5%+"),                     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness -5 || brightnessctl -e4 -n2 set 5%-"),                     { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


-- 잠금 (맥의 Ctrl+Cmd+Q)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- 덮개 (맥 클램쉘 모드): 외부 모니터가 켜져 있을 때 덮개를 닫으면 노트북 화면만 끄고, 열면 닫기 전 화면 구성으로 되돌린다.
-- 외부 모니터가 없으면 아무것도 하지 않고 logind가 잠그고 절전한다 (모니터가 꽂혀 있으면 logind는 덮개를 무시한다)
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("qs ipc call display lid close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("qs ipc call display lid open"),  { locked = true })

-- 전원 메뉴 (화면 잠금·로그아웃·잠자기·재시동·시스템 종료). 알림 센터의 전원 버튼도 같은 메뉴
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("nwg-bar"))

-- 알림 센터 열고 닫기 (맥처럼 상단바 오른쪽 끝 시계를 눌러도 열린다. 시계 오른쪽 클릭 = 방해 금지), 단축키 도움말
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
-- 제어 센터: Wi-Fi·블루투스 기기, 빠른 버튼, 밝기·음량, 미디어, 배터리 충전 한도, 시스템 사용량
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs ipc call cc toggle"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("qs ipc call keys toggle")) -- 단축키 시트 (목록은 ~/.config/quickshell/Shortcuts.qml)

-- Ctrl+Space: 맥처럼 입력기 바꾸기. 한 번 = 직전에 쓰던 입력기로(자주 쓰는 두 개를 오감), Ctrl을 누른 채 Space를 더 누르면
-- 그 전에 쓰던 입력기로, Ctrl을 떼면 고른 입력기가 '가장 최근'이 된다 (~/.config/hypr/scripts/ime-cycle.sh next/commit).
-- fcitx5 대신 Hyprland가 키를 받아서 어느 앱에서도 공백이 들어가지 않는다.
-- locked: 잠금 화면에서도 동작해서 암호 칸에 공백이 들어가지 않고 좌하단 배지가 바뀐다
local imeCmd = "~/.config/hypr/scripts/ime-cycle.sh"
local imeSession, imePresses = 0, 0
hl.bind("CTRL + space", function()
    if imePresses == 0 then imeSession = imeSession + 1 end
    imePresses = imePresses + 1
    hl.dispatch(hl.dsp.exec_cmd(imeCmd .. " next " .. imeSession .. " " .. imePresses))
end, { locked = true })
for _, ctrl in ipairs({ "Control_L", "Control_R" }) do
    for _, mods in ipairs({ "CTRL", "CTRL + SHIFT" }) do
        hl.bind(mods .. " + " .. ctrl, function() -- Ctrl을 떼는 순간 (평소 Ctrl을 뗄 때는 아무것도 안 하고 앱도 그대로 받음)
            if imePresses == 0 then return end
            hl.dispatch(hl.dsp.exec_cmd(imeCmd .. " commit " .. imeSession .. " " .. imePresses))
            imePresses = 0
        end, { release = true, non_consuming = true, transparent = true, locked = true })
    end
end

-- Caps Lock을 누르면 켜짐/꺼짐 팝업 (키 자체는 그대로 동작)
hl.bind("Caps_Lock", hl.dsp.exec_cmd("swayosd-client --caps-lock"), { release = true, non_consuming = true })

-- 스크린샷: Print = 영역 선택 후 클립보드, SHIFT + Print = 전체 화면을 ~/Pictures에 저장
hl.bind("Print",         hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd('mkdir -p ~/Pictures && grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'))

-- 맥식 스크린샷 (Alt = Cmd): Alt+Shift+3 전체 화면, Alt+Shift+4 영역을 골라 편집기로. 파일은 ~/Pictures/Screenshots
hl.bind("ALT + SHIFT + 3", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind("ALT + SHIFT + 4", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area"))
-- 맥식 화면 녹화 (Alt+Shift+5): 녹화 도구 막대를 띄우고, 녹화 중이면 멈춘다. 파일은 ~/Videos/Screen Recordings
hl.bind("ALT + SHIFT + 5", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenrecord.sh toggle"))

-- 맥식 단축키: 스페이스바 옆 Alt를 맥의 Cmd처럼 쓴다 (ThinkPad의 Alt 자리가 맥의 Cmd 자리)
-- 리눅스 앱은 맥의 ⌘ 단축키를 Ctrl로 쓰므로, 일반 앱에는 Alt+키를 Ctrl+키로, Alt+Shift+키를 Ctrl+Shift+키로 바꿔 보낸다.
-- 그러면 T3 Code(⌘K 명령 팔레트, ⌘B 사이드바, ⌘J 터미널, ⌘1~9 스레드), 크롬(⌘L 주소창, ⌘R 새로고침, ⌘⇧T 닫은 탭),
-- Obsidian(⌘P, ⌘O), Discord(⌘K) 등이 맥에서처럼 된다. 맥의 ⌘⌥ 조합(T3 Code의 mod+alt)은 Ctrl+Alt+키를 그대로 누른다.
-- 터미널은 Ctrl+C가 '실행 중단'이라 복사·탭·창만 Ctrl+Shift 조합으로 보내고, 나머지는 Alt 조합을 그대로 넘겨
-- 셸의 Alt 단축키(Alt+F 단어 이동 등)를 살린다. 게임(Steam)에도 Alt 조합을 그대로 넘긴다.
-- 단축키를 바꾸면 단축키 시트(~/.config/quickshell/Shortcuts.qml)도 같이 고친다
local terminalClasses = { kitty = true } -- 다른 터미널을 쓰면 그 창의 class를 추가 (hyprctl clients로 확인)
local terminalCtrlShift = { C = true, T = true, W = true, N = true } -- 터미널에서 Ctrl+Shift로 보낼 키: 복사, 새 탭, 탭 닫기, 새 창
-- Alt+[ ]를 뒤로/앞으로(Alt+←→)로 보내는 앱 (맥 크롬·Finder의 ⌘[ ⌘])
local backForwardClasses = { ["google-chrome"] = true, ["chromium"] = true, ["org.gnome.Nautilus"] = true }
-- Alt+방향키를 그대로 넘기는 앱: 파일 관리자는 Alt+↑ 상위 폴더, Alt+↓ 열기, Alt+←→ 뒤로/앞으로 (Finder의 ⌘↑↓)
local arrowPassClasses = { ["org.gnome.Nautilus"] = true }

local function send(mods, key)
    hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key }))
end

-- Alt 조합을 바꾸지 않고 그대로 넘길 창: 터미널, 게임
local function passThrough(win)
    return terminalClasses[win.class] or win.class:match("^steam_app_") ~= nil or win.class == "gamescope"
end

-- Alt(+Shift)+키 → Ctrl(+Shift)+키. Q(창 닫기)와 V(붙여넣기)는 아래에 따로, Alt+Shift+3·4·5는 스크린샷·화면 녹화
local cmdKeys = {}
for c in ("ABCDEFGHIJKLMNOPRSTUWXYZ"):gmatch(".") do cmdKeys[#cmdKeys + 1] = c end
for _, k in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "bracketleft", "bracketright", "minus", "equal",
                     "comma", "period", "slash", "semicolon", "apostrophe", "backslash", "grave", "Return" }) do
    cmdKeys[#cmdKeys + 1] = k
end
local repeatKeys = { Z = true, minus = true, equal = true } -- 누르고 있으면 반복: 실행 취소, 축소·확대
local reserved = { ["ALT + SHIFT + 3"] = true, ["ALT + SHIFT + 4"] = true, ["ALT + SHIFT + 5"] = true } -- 스크린샷, 화면 녹화

for _, key in ipairs(cmdKeys) do
    for _, shift in ipairs({ false, true }) do
        local mods = shift and "ALT + SHIFT" or "ALT"
        local combo = mods .. " + " .. key
        if not reserved[combo] then
            hl.bind(combo, function()
                local win = hl.get_active_window()
                if not win then return end
                if passThrough(win) then
                    if terminalClasses[win.class] and not shift and terminalCtrlShift[key] then
                        send("CTRL + SHIFT", key)
                    else
                        send(mods, key)
                    end
                elseif not shift and backForwardClasses[win.class] and (key == "bracketleft" or key == "bracketright") then
                    send("ALT", key == "bracketleft" and "Left" or "Right")
                else
                    send(shift and "CTRL + SHIFT" or "CTRL", key)
                end
            end, { repeating = repeatKeys[key] or false })
        end
    end
end

-- 글자 편집: ⌘←→ 줄 처음·끝, ⌘↑↓ 문서 처음·끝 (Shift를 같이 누르면 거기까지 선택)
local textNav = {
    Left  = { "", "Home" },
    Right = { "", "End" },
    Up    = { "CTRL", "Home" },
    Down  = { "CTRL", "End" },
}
for key, to in pairs(textNav) do
    for _, shift in ipairs({ false, true }) do
        local mods = shift and "ALT + SHIFT" or "ALT"
        hl.bind(mods .. " + " .. key, function()
            local win = hl.get_active_window()
            if not win then return end
            if passThrough(win) or arrowPassClasses[win.class] then
                send(mods, key)
                return
            end
            local m = to[1]
            if shift then m = (m == "") and "SHIFT" or (m .. " + SHIFT") end
            send(m, to[2])
        end, { repeating = true })
    end
end

-- ⌘⌫: 줄 처음까지 지우기. 파일 관리자에서는 Finder처럼 휴지통으로
hl.bind("ALT + BackSpace", function()
    local win = hl.get_active_window()
    if not win then return end
    if passThrough(win) then
        send("ALT", "BackSpace")
    elseif win.class == "org.gnome.Nautilus" then
        send("", "Delete")
    else
        send("SHIFT", "Home")
        send("", "BackSpace")
    end
end)

-- 붙여넣기: 터미널에서는 클립보드에 이미지만 있으면 Ctrl+V(Claude Code 이미지 붙여넣기), 아니면 Ctrl+Shift+V
hl.bind("ALT + V", function()
    local win = hl.get_active_window()
    if not win then return end
    if terminalClasses[win.class] then
        hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/smart-paste.sh"))
    elseif passThrough(win) then
        send("ALT", "V")
    else
        send("CTRL", "V")
    end
end)

hl.bind("ALT + Q",     hl.dsp.window.close()) -- 맥의 Cmd+Q: 앱 전체 종료 대신 지금 창 닫기
hl.bind("ALT + SHIFT + Q", hl.dsp.exec_cmd("qs ipc call session logout")) -- 맥의 Cmd+Shift+Q: 확인 창을 띄운 뒤 로그아웃
hl.bind("ALT + space", hl.dsp.exec_cmd("vicinae toggle")) -- 맥의 Cmd+Space: Raycast 대신 Vicinae
hl.bind("ALT + SHIFT + V", hl.dsp.exec_cmd("vicinae cmd launch clipboard:history")) -- 클립보드 기록 (Raycast의 Clipboard History)
-- 맥의 Cmd+Tab: 빠르게 한 번 = 직전에 쓰던 앱으로, Alt를 누른 채 Tab = 앱 목록에서 고르기 (워크스페이스·모니터 상관없이).
-- 목록과 고르기는 Quickshell 앱 전환기(~/.config/quickshell/AppSwitcher.qml)가 한다
-- 전환 중에 Alt를 떼는 순간에만 넘어간다. 평소 Alt를 뗄 때(복사 등)는 아무것도 하지 않고, 앱도 Alt 떼기를 그대로 받는다(non_consuming)
local switching = false
hl.bind("ALT + Tab", function()
    switching = true
    hl.dispatch(hl.dsp.exec_cmd("qs ipc call switcher next"))
end)
hl.bind("ALT + SHIFT + Tab", function()
    switching = true
    hl.dispatch(hl.dsp.exec_cmd("qs ipc call switcher prev"))
end)
for _, alt in ipairs({ "Alt_L", "Alt_R" }) do
    for _, mods in ipairs({ "ALT", "ALT + SHIFT" }) do -- Shift+Tab으로 고르다 Shift를 누른 채 Alt를 먼저 떼도
        hl.bind(mods .. " + " .. alt, function()
            if not switching then return end
            switching = false
            hl.dispatch(hl.dsp.exec_cmd("qs ipc call switcher release"))
        end, { release = true, non_consuming = true, transparent = true })
    end
end


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- 상단 막대(Waybar) 뒤를 흐리게. 투명한 틈은 흐리지 않는다
hl.layer_rule({
    name         = "blur-waybar",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0.3,
})

-- Vicinae(Raycast 대체 실행기): 뒤를 흐리게, 열고 닫을 때 애니메이션 없이
hl.layer_rule({
    name         = "vicinae-blur",
    match        = { namespace = "vicinae" },
    blur         = true,
    ignore_alpha = 0,
})
hl.layer_rule({
    name    = "vicinae-no-animation",
    match   = { namespace = "vicinae" },
    no_anim = true,
})

-- CodexBar(AI 사용량): 맥 메뉴바 앱처럼 오른쪽 위에 띄운다
hl.window_rule({
    name  = "codexbar-popup",
    match = { class = "^com\\.steipete\\.CodexBar$" },
    float = true,
    size  = "560 700",
    move  = "monitor_w-570 36",
})

-- 음량·밝기 팝업(swayosd)과 전원 메뉴(nwg-bar, 이름공간 gtk-layer-shell) 뒤를 흐리게
hl.layer_rule({
    name         = "blur-osd-and-power-menu",
    match        = { namespace = "^(swayosd|gtk-layer-shell)$" },
    blur         = true,
    ignore_alpha = 0.3,
})

-- 화면 속 화면(PiP): 타일에 끼지 않고 오른쪽 아래 구석에 떠서 모든 워크스페이스에 보이게.
-- 창 제목은 브라우저 언어를 따른다 (한국어 Chrome은 "PIP 모드", 이 창은 class가 비어 있다)
hl.window_rule({
    name              = "pip",
    match             = { title = "^(Picture[- ]in[- ][Pp]icture|PIP 모드|화면 속 화면)$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = "480 270",
    move              = "monitor_w-495 monitor_h-285",
})

-- Nautilus 빠른 미리보기(Sushi, Space): 맥 Quick Look처럼 타일에 끼지 않고 화면 가운데에 띄운다
hl.window_rule({
    name   = "sushi-preview",
    match  = { class = "^org\\.gnome\\.NautilusPreviewer$" },
    float  = true,
    center = true,
})

-- 제어 센터(Quickshell) 뒤를 흐리게. 열고 닫는 애니메이션은 패널이 직접 하므로 Hyprland 애니메이션은 끈다.
-- ignore_alpha: 반투명 그림자 부분은 흐리지 않는다
hl.layer_rule({
    name         = "quickshell-control-center",
    match        = { namespace = "^quickshell-control-center$" },
    blur         = true,
    ignore_alpha = 0.5,
    no_anim      = true,
})

-- 디스플레이 설정 창, 유지 확인 창, 화면 이름표, 단축키 시트, 화면 녹화 막대, 앱 전환기, 로그아웃 확인 창(Quickshell)도 뒤를 흐리게
hl.layer_rule({
    name         = "quickshell-panels",
    match        = { namespace = "^quickshell-(display|shortcuts|record|switcher|session)" },
    blur         = true,
    ignore_alpha = 0.5,
    no_anim      = true,
})

-- 알림 센터와 알림(swaync) 뒤를 흐리게
hl.layer_rule({
    name         = "blur-swaync",
    match        = { namespace = "^swaync-(control-center|notification-window)$" },
    blur         = true,
    ignore_alpha = 0.3,
})

-- 스크린샷 편집기(satty)는 가운데에 띄운다
hl.window_rule({
    name   = "satty",
    match  = { class = "^com\\.gabm\\.satty$" },
    float  = true,
    size   = "1280 800",
    center = true,
})

-- Wi-Fi 목록 창(상단바 Wi-Fi 아이콘 클릭)은 가운데에 띄운다
hl.window_rule({
    name   = "nmtui",
    match  = { class = "^nmtui$" },
    float  = true,
    size   = "720 520",
    center = true,
})

-- 음량 상세 설정 창(pwvucontrol, 상단바 음량 아이콘 오른쪽 클릭)은 가운데에 넓게 띄운다
hl.window_rule({
    name   = "volume-settings",
    match  = { class = "^(com\\.saivert\\.)?pwvucontrol$" },
    float  = true,
    size   = "860 600",
    center = true,
})

-- 크로미움 계열 앱(크롬, T3 Code, Obsidian, Discord, Spotify, Bitwarden)은 Wayland에서 터치패드 스크롤을 크게 받아들여
-- 확확 내려간다. 그 창에서만 터치패드 스크롤 배율을 낮춘다 (다른 앱은 input.touchpad.scroll_factor 0.8 그대로)
hl.window_rule({
    name            = "chromium-touchpad-scroll",
    match           = { class = "(?i)^(google-chrome|chromium|com\\.t3tools\\.t3code|obsidian|discord|spotify|bitwarden)$" },
    scroll_touchpad = 0.45,
})

-- 이 컴퓨터에서만 쓰는 개인 설정(~/.config/hypr/personal.lua)이 있으면 읽는다. 저장소에는 없다 (예: 저작권 있는 커서)
pcall(require, "personal")
