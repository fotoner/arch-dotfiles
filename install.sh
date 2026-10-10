#!/usr/bin/env bash
# ThinkPad T14 Gen1 (Intel) Arch Linux: 첫 부팅 후 기본 설정 + Hyprland 데스크톱 설치.
# 사용법: ./install.sh   (일반 사용자로 실행. sudo를 붙이지 않는다)
# 여러 번 실행해도 안전하다. 이미 된 단계는 건너뛴다.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die()  { printf '\n\033[1;31m오류: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "root가 아니라 일반 사용자로 실행하세요: ./install.sh"
[ -f /etc/arch-release ] || die "Arch Linux에서만 실행할 수 있습니다."
command -v sudo >/dev/null || die "sudo가 없습니다."

step "관리자 권한 확인 (사용자 암호 입력)"
sudo -v
# 설치가 길어져도 sudo 암호를 다시 묻지 않게 유지한다.
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

step "1/8 인터넷 연결 확인"
ping -c 1 -W 3 archlinux.org >/dev/null 2>&1 \
  || die "인터넷에 연결되지 않았습니다. 먼저 연결하세요: sudo nmcli device wifi connect \"와이파이이름\" --ask"

step "2/8 pacman 설정(색상, 병렬 다운로드) 후 전체 업데이트"
sudo sed -i 's/^#Color/Color/; s/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo pacman -Syu --noconfirm

step "3/8 스냅샷(snapper) 설정"
sudo pacman -S --needed --noconfirm snapper snap-pac
if sudo test -f /etc/snapper/configs/root; then
  note "이미 설정되어 있어 건너뜁니다."
else
  # snapper가 만드는 .snapshots 서브볼륨 대신, 설치 때 만든 @snapshots를 쓰도록 바꿔 끼운다.
  if mountpoint -q /.snapshots; then sudo umount /.snapshots; fi
  if [ -d /.snapshots ]; then sudo rmdir /.snapshots; fi
  sudo snapper -c root create-config /
  sudo btrfs subvolume delete /.snapshots
  sudo mkdir /.snapshots
  sudo mount -a
  sudo chmod 750 /.snapshots
  sudo snapper -c root set-config TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
    TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0
fi
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

step "4/8 Hyprland와 데스크톱 구성 요소 설치"
PKGS=(
  # Hyprland 본체와 짝꿍들
  hyprland hyprlauncher hyprpolkitagent hyprlock hypridle
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland
  # 터미널, 상단 막대, 알림 센터, 파일 관리자
  kitty waybar swaync libnotify nautilus xdg-user-dirs
  # 제어 센터 (Wi-Fi·블루투스 기기, 빠른 버튼, 충전 한도, 사용량)
  quickshell
  # Spotify 공식 앱(설치·업데이트 도구, sp 명령), 영상 하드웨어 가속 확인 도구(vainfo)
  spotify-launcher libva-utils
  # 소리
  pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
  # 상단바 오디오 파형
  cava
  # 글꼴
  noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
  # 테마: 바탕화면, 아이콘
  hyprpaper papirus-icon-theme
  # 맥 느낌: 로그아웃 화면, 음량·밝기 팝업, 전원 메뉴, GTK3 앱 테마, 글꼴
  hyprshutdown swayosd nwg-bar adw-gtk-theme inter-font
  # 맥의 미리보기·Quick Look: 이미지 보기, PDF 보기, Nautilus에서 Space로 빠른 미리보기
  loupe papers sushi
  # 배터리 부족 알림, 스크린샷 편집기, 단축키 도움말 창, 폴더 바로 이동
  batsignal satty yad zoxide
  # 터미널 도구, zsh 플러그인 (mac-dotfiles에서 가져옴)
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions
  bat eza fd fzf jq tmux tree lazygit htop btop fastfetch git-lfs github-cli unzip
  # fastfetch 원형 프로필 사진 만들기
  ffmpeg
  # Neovim(LazyVim)과 짝꿍 (npm: LSP 설치용)
  neovim tree-sitter-cli shfmt stylua npm
  # 앱: 메신저, VPN
  discord tailscale
  # AUR 패키지 빌드 도구
  base-devel
  # 한글 입력
  fcitx5 fcitx5-hangul fcitx5-mozc fcitx5-configtool fcitx5-gtk fcitx5-qt
  # 네트워크, 블루투스
  network-manager-applet bluez bluez-utils blueman
  # 노트북 키(밝기, 미디어), 스크린샷, 클립보드
  brightnessctl playerctl grim slurp wl-clipboard
  # 전원 모드, 하드웨어 영상 가속, 패키지 캐시 정리, 점검 도구, zram 스왑
  power-profiles-daemon intel-media-driver pacman-contrib pciutils zram-generator
)
sudo pacman -S --needed --noconfirm "${PKGS[@]}"
if [ -d "$HOME/.oh-my-zsh" ]; then
  note "oh-my-zsh: 이미 설치되어 있어 건너뜁니다."
else
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
# 공식 저장소에 없는 앱은 AUR에서 받아 빌드한다 (둘 다 공식 배포 파일을 받아 묶기만 함)
aur_install() {
  local pkg="$1" dir="$HOME/.cache/aur/$1"
  if pacman -Q "$pkg" >/dev/null 2>&1; then
    note "$pkg: 이미 설치되어 있어 건너뜁니다."
    return
  fi
  rm -rf "$dir"
  git clone --depth=1 "https://aur.archlinux.org/$pkg.git" "$dir"
  (cd "$dir" && makepkg -si --noconfirm)
}
aur_install google-chrome   # 기본 브라우저
aur_install vicinae-bin     # Raycast 대체 실행기
aur_install apple_cursor    # 맥 커서
aur_install pwvucontrol     # 음량 창 (상단바 음량 아이콘)
# AI 사용량(CodexBar): GitHub 공식 배포 파일을 받아 체크섬을 확인한 뒤 사용자 폴더에 설치한다 (공식 안내와 같은 절차)
if [ -x "$HOME/.local/bin/codexbar-linux" ]; then
  note "CodexBar: 이미 설치되어 있어 건너뜁니다."
else
  (
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    cd "$work"
    version=$(curl -fsSL https://api.github.com/repos/steipete/CodexBar/releases/latest | jq -r .tag_name)
    base="https://github.com/steipete/CodexBar/releases/download/$version"
    cli="CodexBarCLI-$version-linux-x86_64.tar.gz"
    desktop="CodexBarDesktop-$version-linux-x86_64.tar.gz"
    for archive in "$cli" "$desktop"; do
      curl -fSL "$base/$archive" -o "$archive"
      curl -fSL "$base/$archive.sha256" -o "$archive.sha256"
      sha256sum -c "$archive.sha256"
    done
    mkdir -p "$HOME/.local/lib/codexbar-cli" "$HOME/.local/bin"
    tar -xzf "$cli" -C "$HOME/.local/lib/codexbar-cli"
    ln -sfn "$HOME/.local/lib/codexbar-cli/codexbar" "$HOME/.local/bin/codexbar"
    tar -xzf "$desktop"
    # Hyprland는 XDG 자동 실행을 읽지 않아서 끄고, hyprland.lua에서 실행한다
    python3 "${desktop%.tar.gz}/Integrations/Linux/install.py" --cli "$HOME/.local/bin/codexbar" --no-autostart
  )
fi

step "5/8 서비스 켜기 (블루투스, 전원 모드, 패키지 캐시 자동 정리, 시간 동기화, Tailscale, 펌웨어 확인, 방화벽, zram 스왑, 소리)"
sudo systemctl enable --now bluetooth.service power-profiles-daemon.service paccache.timer \
  systemd-timesyncd.service tailscaled.service fwupd-refresh.timer
sudo install -m 644 "$REPO_DIR/system/zram-generator.conf" /etc/systemd/zram-generator.conf
# 방화벽: 밖에서 먼저 들어오는 연결 막기 (Tailscale, 같은 Wi-Fi 기기 찾기는 허용). 원래 파일은 .bak으로 남긴다
[ -f /etc/nftables.conf ] && [ ! -f /etc/nftables.conf.bak ] && sudo cp /etc/nftables.conf /etc/nftables.conf.bak
sudo install -m 644 "$REPO_DIR/system/nftables.conf" /etc/nftables.conf
sudo systemctl enable nftables.service
sudo systemctl restart nftables.service
sudo systemctl daemon-reload
sudo systemctl start dev-zram0.swap
# 로그인한 뒤에 설치한 PipeWire는 다음 로그인까지 꺼져 있어 소리가 안 난다. 지금 바로 켠다
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service

step "6/8 배터리 충전 한도 켜기 (75% 아래에서 충전 시작, 80%에서 멈춤)"
# UPower가 펌웨어에 기록하고 상태를 저장해 재부팅해도 유지한다. 제어 센터(Super+A)에서 80% / 100%를 바꿀 수 있다.
# 예전 방식(부팅마다 80%로 되돌리는 tmpfiles 규칙)은 제어 센터 설정을 덮어쓰므로 지운다
sudo rm -f /etc/tmpfiles.d/battery-threshold.conf
BAT_DEV=$(upower -e | grep -m1 battery_BAT)
if [ -n "$BAT_DEV" ] && busctl get-property org.freedesktop.UPower "$BAT_DEV" org.freedesktop.UPower.Device ChargeThresholdSupported | grep -q true; then
  busctl call org.freedesktop.UPower "$BAT_DEV" org.freedesktop.UPower.Device EnableChargeThreshold b true \
    && note "충전 한도 켜짐: 지금 상한 $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null)%" \
    || note "충전 한도를 켜지 못했습니다. 로그인한 화면의 터미널에서 다시 실행해 주세요."
else
  note "이 기기는 충전 한도를 지원하지 않아 건너뜁니다."
fi

step "7/8 설정 파일 복사 (기존 파일이 다르면 .bak-$STAMP 로 백업)"
copy_with_backup() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ "$(sha256sum < "$src")" != "$(sha256sum < "$dst")" ]; then
    cp -a "$dst" "$dst.bak-$STAMP"
    note "백업: $dst.bak-$STAMP"
  fi
  cp "$src" "$dst"
  note "설치: $dst"
}
place()      { copy_with_backup "$REPO_DIR/config/$1" "$HOME/.config/$1"; }
place_home() { copy_with_backup "$REPO_DIR/home/$1" "$HOME/$1"; }
place hypr/hyprland.lua
place hypr/hypridle.conf
place hypr/hyprlock.conf
place hypr/hyprpaper.conf
place hypr/hyprtoolkit.conf
place hypr/wallpaper.png
place waybar/config.jsonc
place waybar/style.css
place waybar/mocha.css
place kitty/kitty.conf
place kitty/current-theme.conf
place swaync/config.json
place swaync/style.css
place hypr/scripts/screenshot.sh
place hypr/scripts/keyhints.sh
place hypr/scripts/smart-paste.sh
place hypr/scripts/wifi-menu.sh
place hypr/scripts/ime-status.sh
place hypr/scripts/ime-cycle.sh
place hypr/scripts/media-focus.sh
place hypr/scripts/media-status.sh
place hypr/scripts/audio-wave.sh
place hypr/scripts/weather.sh
place hypr/scripts/idle-inhibit.sh
place hypr/scripts/startup-layout.sh
place hypr/scripts/big-clock.sh
place chrome-flags.conf
place spotify-launcher.conf
chmod +x "$HOME/.config/hypr/scripts/"*.sh
place swayosd/style.css
(cd "$REPO_DIR/config" && find quickshell -type f) | while read -r f; do place "$f"; done
place nwg-bar/bar.json
place nwg-bar/style.css
place fontconfig/fonts.conf
place fastfetch/config.jsonc
place fastfetch/face.sh
chmod +x "$HOME/.config/fastfetch/face.sh"
place gtk-4.0/gtk.css
place gtk-3.0/gtk.css
place wireplumber/wireplumber.conf.d/51-hide-hdmi.conf
place vicinae/settings.json
place fcitx5/profile
place fcitx5/config
place fcitx5/conf/classicui.conf
(cd "$REPO_DIR/home" && find .local/share/fcitx5 -type f) | while read -r f; do place_home "$f"; done
(cd "$REPO_DIR/home" && find .local/share/icons -type f) | while read -r f; do place_home "$f"; done
place git/config
place git/ignore
place gh/config.yml
(cd "$REPO_DIR/config" && find nvim -type f) | while read -r f; do place "$f"; done
place_home .zshrc
place_home .dircolors
# Claude Code 상태줄 (fotoner/claude-statusline에서 bash 5.2+ 버그를 고친 본). settings.json에는 statusLine만 넣는다
place_home .claude/statusline-command.sh
chmod +x "$HOME/.claude/statusline-command.sh"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
[ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline-command.sh", "refreshInterval": 3}' \
  "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
xdg-user-dirs-update
# 앱 다크 모드, GTK3 앱 테마(adw-gtk3), 맥 커서, 아이콘 테마
gsettings set org.gnome.desktop.interface color-scheme prefer-dark \
  && gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark \
  && gsettings set org.gnome.desktop.interface cursor-theme macOS \
  && gsettings set org.gnome.desktop.interface accent-color purple \
  && gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark \
  || note "다크 모드 설정 실패. Hyprland에서 install.sh를 다시 실행하세요."
xdg-settings set default-web-browser google-chrome.desktop || note "기본 브라우저 설정 실패"
# 이미지는 Loupe, PDF 같은 문서는 Papers로 연다 (앱이 여는 형식 전부)
for app in org.gnome.Loupe org.gnome.Papers; do
  xdg-mime default "$app.desktop" $(grep '^MimeType=' "/usr/share/applications/$app.desktop" | cut -d= -f2 | tr ';' ' ') \
    || note "$app 기본 앱 설정 실패"
done

step "8/8 점검"
if git config --global user.email >/dev/null; then
  note "git 이메일: 설정됨"
else
  note "git 이메일이 없습니다. 커밋하기 전에: git config --global user.email \"you@example.com\""
fi
if tailscale status >/dev/null 2>&1; then
  note "Tailscale: 연결됨"
else
  note "Tailscale: 로그인 전입니다. 연결하려면: sudo tailscale up"
fi
if swapon --show 2>/dev/null | grep zram >/dev/null; then note "zram 스왑: 정상"; else note "zram 스왑: 안 보임 (재부팅 후 다시 확인)"; fi
if [ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo '?')" = 0 ]; then
  note "터보 부스트: 켜짐"
else
  note "터보 부스트: 꺼져 있음. BIOS 설정을 기본값으로 되돌려 보세요."
fi
if lspci | grep -i nvidia >/dev/null; then
  note "NVIDIA GPU(MX330)가 있습니다. NVIDIA 설정이 따로 필요합니다."
else
  note "NVIDIA GPU 없음 (내장 Intel 그래픽만 사용)"
fi

printf '\n\033[1;32m완료.\033[0m\n'
cat <<'EOF'
    1) 이제 Hyprland를 실행해 보세요 (sudo 없이):  start-hyprland
    2) 잘 뜨면, 로그인할 때 자동으로 켜지게:        ./enable-autostart.sh
    단축키와 문제 해결은 README.md를 보세요.
EOF
