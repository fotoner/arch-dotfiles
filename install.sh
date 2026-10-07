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
  # 터미널, 상단 막대, 알림, 파일 관리자
  kitty waybar mako libnotify nautilus xdg-user-dirs
  # 소리
  pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
  # 글꼴
  noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
  # 테마: 바탕화면, 아이콘
  hyprpaper papirus-icon-theme
  # 터미널 도구, zsh 플러그인 (mac-dotfiles에서 가져옴)
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions
  bat eza fd fzf jq tmux tree lazygit htop git-lfs unzip
  # Neovim(LazyVim)과 짝꿍
  neovim tree-sitter-cli shfmt stylua
  # 한글 입력
  fcitx5 fcitx5-hangul fcitx5-configtool fcitx5-gtk fcitx5-qt
  # 네트워크, 블루투스
  network-manager-applet bluez bluez-utils blueman
  # 노트북 키(밝기, 미디어), 스크린샷, 클립보드
  brightnessctl playerctl grim slurp wl-clipboard
  # 전원 모드, 하드웨어 영상 가속, 패키지 캐시 정리, 점검 도구
  power-profiles-daemon intel-media-driver pacman-contrib pciutils
)
sudo pacman -S --needed --noconfirm "${PKGS[@]}"
if [ -d "$HOME/.oh-my-zsh" ]; then
  note "oh-my-zsh: 이미 설치되어 있어 건너뜁니다."
else
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

step "5/8 서비스 켜기 (블루투스, 전원 모드, 패키지 캐시 자동 정리)"
sudo systemctl enable --now bluetooth.service power-profiles-daemon.service paccache.timer

step "6/8 배터리 충전 상한 75~80%"
BAT=/sys/class/power_supply/BAT0
if [ -e "$BAT/charge_control_end_threshold" ]; then
  sudo install -m 644 "$REPO_DIR/system/battery-threshold.conf" /etc/tmpfiles.d/battery-threshold.conf
  sudo systemd-tmpfiles --create /etc/tmpfiles.d/battery-threshold.conf \
    || note "지금 바로 적용하지 못했습니다. 재부팅하면 적용됩니다."
  note "현재 충전 상한: $(cat "$BAT/charge_control_end_threshold")%"
else
  note "이 기기는 충전 상한 설정을 지원하지 않아 건너뜁니다."
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
place mako/config
place fcitx5/profile
place git/config
place git/ignore
(cd "$REPO_DIR/config" && find nvim -type f) | while read -r f; do place "$f"; done
place_home .zshrc
place_home .dircolors
xdg-user-dirs-update
# 앱 다크 모드와 아이콘 테마 (Catppuccin Mocha와 어울리게)
gsettings set org.gnome.desktop.interface color-scheme prefer-dark \
  && gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark \
  && gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark \
  || note "다크 모드 설정 실패. Hyprland에서 install.sh를 다시 실행하세요."

step "8/8 점검"
if git config --global user.email >/dev/null; then
  note "git 이메일: 설정됨"
else
  note "git 이메일이 없습니다. 커밋하기 전에: git config --global user.email \"you@example.com\""
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
