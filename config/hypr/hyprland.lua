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
    hl.exec_cmd("swayosd-server")                         -- 음량·밝기 팝업
    hl.exec_cmd("swaync")                                 -- 알림 센터 (Super+N, 시계 클릭)
    hl.exec_cmd("qs")                                     -- 제어 센터 (Super+A, 상단바 제어 센터 아이콘), ~/.config/quickshell
    hl.exec_cmd("batsignal -b -w 20 -c 10")               -- 배터리 20%·10%에서 알림
    hl.exec_cmd("hypridle")                               -- 자동 잠금/화면 끄기
    hl.exec_cmd("vicinae server")                         -- Raycast 대체 실행기 (Alt+Space)
    hl.exec_cmd("~/.local/bin/codexbar-linux --background") -- AI 사용량 (상단바 트레이)
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
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
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

-- 전원 메뉴 (화면 잠금·로그아웃·잠자기·재시동·시스템 종료). 알림 센터의 전원 버튼도 같은 메뉴
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("nwg-bar"))

-- 알림 센터 열고 닫기 (맥처럼 상단바 오른쪽 끝 시계를 눌러도 열린다. 시계 오른쪽 클릭 = 방해 금지), 단축키 도움말
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
-- 제어 센터: Wi-Fi·블루투스 기기, 빠른 버튼, 밝기·음량, 미디어, 배터리 충전 한도, 시스템 사용량
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs ipc call cc toggle"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("~/.config/hypr/scripts/keyhints.sh"))

-- Ctrl+Space: 입력기 바꾸기 (A → 한 → あ). fcitx5 대신 Hyprland가 키를 받아서 어느 앱에서도 공백이 들어가지 않는다.
-- locked: 잠금 화면에서도 동작해서 암호 칸에 공백이 들어가지 않고 좌하단 배지가 바뀐다
hl.bind("CTRL + space", hl.dsp.exec_cmd("~/.config/hypr/scripts/ime-cycle.sh"), { locked = true })

-- Caps Lock을 누르면 켜짐/꺼짐 팝업 (키 자체는 그대로 동작)
hl.bind("Caps_Lock", hl.dsp.exec_cmd("swayosd-client --caps-lock"), { release = true, non_consuming = true })

-- 스크린샷: Print = 영역 선택 후 클립보드, SHIFT + Print = 전체 화면을 ~/Pictures에 저장
hl.bind("Print",         hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd('mkdir -p ~/Pictures && grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'))

-- 맥식 스크린샷 (Alt = Cmd): Alt+Shift+3 전체 화면, Alt+Shift+4 영역을 골라 편집기로. 파일은 ~/Pictures/Screenshots
hl.bind("ALT + SHIFT + 3", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind("ALT + SHIFT + 4", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area"))

-- 맥식 단축키: 스페이스바 옆 Alt를 맥의 Cmd처럼 쓴다 (ThinkPad의 Alt 자리가 맥의 Cmd 자리)
-- 일반 앱에는 Ctrl 조합을 보낸다. 터미널은 Ctrl+C가 '실행 중단'이라 복사·붙여넣기·탭·창은 Ctrl+Shift 조합으로 보내고,
-- 터미널에 맞는 기능이 없는 키는 Alt 조합을 그대로 넘겨 셸의 Alt 단축키(Alt+F 단어 이동 등)를 살린다
local terminalClasses = { kitty = true } -- 다른 터미널을 쓰면 그 창의 class를 추가 (hyprctl clients로 확인)

local function cmdBind(mods, key, appMods, termMods, opts)
    hl.bind(mods .. " + " .. key, function()
        local win = hl.get_active_window()
        if not win then return end
        local sendMods = appMods
        if terminalClasses[win.class] then sendMods = termMods or mods end
        hl.dispatch(hl.dsp.send_shortcut({ mods = sendMods, key = key }))
    end, opts)
end

cmdBind("ALT",         "C", "CTRL",         "CTRL + SHIFT")             -- 복사
-- 붙여넣기: 터미널에서는 클립보드에 이미지만 있으면 Ctrl+V(Claude Code 이미지 붙여넣기), 아니면 Ctrl+Shift+V
hl.bind("ALT + V", function()
    local win = hl.get_active_window()
    if not win then return end
    if terminalClasses[win.class] then
        hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/smart-paste.sh"))
    else
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "V" }))
    end
end)
cmdBind("ALT",         "X", "CTRL")                                     -- 잘라내기
cmdBind("ALT",         "A", "CTRL")                                     -- 전체 선택
cmdBind("ALT",         "Z", "CTRL",         nil, { repeating = true })  -- 실행 취소
cmdBind("ALT + SHIFT", "Z", "CTRL + SHIFT", nil, { repeating = true })  -- 다시 실행
cmdBind("ALT",         "S", "CTRL")                                     -- 저장
cmdBind("ALT",         "F", "CTRL")                                     -- 찾기
cmdBind("ALT",         "T", "CTRL",         "CTRL + SHIFT")             -- 새 탭
cmdBind("ALT",         "W", "CTRL",         "CTRL + SHIFT")             -- 탭 닫기
cmdBind("ALT",         "N", "CTRL",         "CTRL + SHIFT")             -- 새 창

hl.bind("ALT + Q",     hl.dsp.window.close()) -- 맥의 Cmd+Q: 앱 전체 종료 대신 지금 창 닫기
hl.bind("ALT + space", hl.dsp.exec_cmd("vicinae toggle")) -- 맥의 Cmd+Space: Raycast 대신 Vicinae
hl.bind("ALT + Tab", function()               -- 맥의 Cmd+Tab: 지금 워크스페이스의 다음 창으로
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)


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

-- 화면 속 화면(PiP): 타일에 끼지 않고 오른쪽 아래 구석에 떠서 모든 워크스페이스에 보이게
hl.window_rule({
    name              = "pip",
    match             = { title = "^(Picture[- ]in[- ][Pp]icture)$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = "480 270",
    move              = "monitor_w-495 monitor_h-285",
})

-- 단축키 도움말 창은 가운데에 띄운다
hl.window_rule({
    name   = "keyhints",
    match  = { class = "^yad$", title = "^단축키$" },
    float  = true,
    size   = "620 780",
    center = true,
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

-- 이 컴퓨터에서만 쓰는 개인 설정(~/.config/hypr/personal.lua)이 있으면 읽는다. 저장소에는 없다 (예: 저작권 있는 커서)
pcall(require, "personal")
