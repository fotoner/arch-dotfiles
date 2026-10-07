# arch-dotfiles

ThinkPad T14 Gen1 (Intel)에 Arch Linux 기본 설치를 마친 뒤, 스크립트 하나로 기본 설정과 [Hyprland](https://hypr.land) 데스크톱을 깔아 주는 저장소입니다.

전제 조건: LUKS2 + btrfs 서브볼륨(`@`, `@home`, `@log`, `@pkg`, `@snapshots`), systemd-boot로 설치했고 첫 부팅과 사용자 로그인까지 된 상태.

## 빠른 시작

일반 사용자로 로그인한 텍스트 화면에서 실행합니다.

```sh
sudo nmcli device wifi connect "와이파이이름" --ask   # 인터넷이 안 될 때만
sudo pacman -S --needed git
git clone https://github.com/fotoner/arch-dotfiles.git
cd arch-dotfiles
./install.sh            # sudo를 붙이지 않는다. 중간에 사용자 암호를 한 번 묻는다
start-hyprland          # Hyprland 실행
./enable-autostart.sh   # 잘 뜨면: 다음부터 로그인하면 자동으로 켜진다
```

`install.sh`는 여러 번 실행해도 안전합니다. 이미 된 단계는 건너뜁니다.

## install.sh가 하는 일

1. 인터넷 연결 확인
2. pacman 색상·병렬 다운로드를 켜고 전체 업데이트
3. snapper + snap-pac 스냅샷 설정 (시간별 5개, 일별 7개 보존). 이미 설정돼 있으면 건너뜀
4. Hyprland, Waybar, 한글 입력기(fcitx5), 글꼴, 테마(바탕화면·아이콘), 소리, 블루투스, 터미널 도구, Neovim, Discord, Tailscale, 맥 느낌 도구(음량·밝기 팝업, 전원 메뉴, 로그아웃 화면) 등 설치. oh-my-zsh 내려받기, Google Chrome·Vicinae·맥 커서(AUR) 빌드·설치, CodexBar(AI 사용량) 설치
5. 블루투스, 전원 모드(power-profiles-daemon), 패키지 캐시 자동 정리, 시간 동기화, Tailscale 켜기. zram 스왑(RAM의 절반, 최대 8GB) 설정. 소리(PipeWire)를 재로그인 없이 바로 켜기
6. 배터리 충전 상한 75~80%
7. `config/` 아래 설정 파일을 `~/.config/`로 복사. 내용이 다른 기존 파일은 `.bak-날짜시각`으로 백업. Claude Code 상태줄 설치, 앱 다크 모드 켜기, 기본 브라우저를 Chrome으로
8. git 이메일, Tailscale 로그인, zram 스왑, 터보 부스트, NVIDIA GPU 유무 점검

## 단축키

SUPER는 Windows 키입니다.

| 단축키 | 동작 | 맥과 비교 |
|---|---|---|
| SUPER + Q | 터미널(kitty) 열기 | 맥의 Cmd+Q(종료)는 아래 Alt + Q |
| SUPER + C | 창 닫기 | Cmd+W |
| SUPER + R | 앱 검색 실행 | Spotlight |
| SUPER + E | 파일 관리자(Nautilus) | Finder |
| SUPER + L | 화면 잠금 | Ctrl+Cmd+Q |
| SUPER + Esc | 전원 메뉴: 화면 잠금·로그아웃·잠자기·재시동·시스템 종료 (알림 센터의 전원 버튼도 같음) | 메뉴의 전원 항목 |
| SUPER + N | 알림 센터: 빠른 버튼(Wi-Fi·블루투스·마이크·스크린샷·전원), 음량·밝기, 재생 중인 음악, 알림 목록, 방해 금지 (상단바 오른쪽 끝 시계를 눌러도 열림, 시계 오른쪽 클릭 = 방해 금지). 읽지 않은 알림이 있으면 시계 옆에 빨간 점, 방해 금지 중이면 달 | 알림 센터 + 제어 센터 |
| SUPER + H | 단축키 도움말 창 | |
| 음량·밝기 키 | 화면에 팝업으로 표시 | 같음 |
| 상단바 음량 아이콘 | 클릭: 음량 창(출력 장치·앱별 음량), 오른쪽 클릭: 음소거, 휠: 음량 | 메뉴바 소리 메뉴 |
| SUPER + 1~0 | 워크스페이스 이동 | Spaces 이동 |
| SUPER + Shift + 1~0 | 창을 그 워크스페이스로 보내기 | |
| SUPER + V | 창 띄우기/타일로 되돌리기 | |
| SUPER + 마우스 끌기 | 왼쪽: 창 이동, 오른쪽: 크기 조절 | |
| 세 손가락 좌우 쓸기 | 워크스페이스 전환 | 같음 |
| Print | 영역 스크린샷을 클립보드로 | Cmd+Shift+Ctrl+4 |
| Shift + Print | 전체 화면을 `~/Pictures`에 저장 | Cmd+Shift+3 |
| SUPER + M | 앱을 정리하고 로그아웃 (hyprshutdown) | 로그아웃 |

입력기는 영어, 한글, 일본어(Mozc, 로마자 입력) 세 개입니다. **Ctrl+Space**를 누를 때마다 A → 한 → あ 순서로 바뀌고(한/영 키가 있으면 그 키는 영어 ↔ 한글), 지금 상태는 상단바의 "A" / "한" / "あ" 배지로 보입니다. 배지를 누르면 영어와 마지막 입력기 사이를 오갑니다. 한글이 목록에 없으면 SUPER+R → "Fcitx 5 Configuration"에서 "Only Show Current Language"를 끄고 Hangul을 추가하세요.

상단바의 커피잔 아이콘을 누르면 잠자기 방지(화면이 꺼지지 않음)가 켜집니다. 배터리가 20%, 10%가 되면 알림이 뜨고, 유튜브 화면 속 화면(PiP)은 오른쪽 아래에 떠서 모든 워크스페이스에 보입니다.

자동으로 일어나는 일: 2분 30초 뒤 화면 어둡게, 5분 뒤 잠금, 5분 30초 뒤 화면 끔, 30분 뒤 절전. 덮개를 닫으면 잠근 뒤 절전합니다 (`config/hypr/hypridle.conf`).

### 맥식 단축키 (Alt = Cmd)

스페이스바 바로 옆 **Alt**가 맥의 Cmd 자리라서, Alt를 Cmd처럼 쓰게 했습니다. Ctrl은 맥의 control 자리 그대로라 터미널에서 Ctrl+C는 맥처럼 실행 중단입니다.

| 단축키 | 동작 | 터미널(kitty)에서 |
|---|---|---|
| Alt + C | 복사 | 같음 (Ctrl+Shift+C로 보냄) |
| Alt + V | 붙여넣기 | 같음 (Ctrl+Shift+V로 보냄. 클립보드에 이미지만 있으면 Ctrl+V를 보내 Claude Code에 이미지가 붙음) |
| Alt + X | 잘라내기 | Alt + X 그대로 |
| Alt + A | 전체 선택 | Alt + A 그대로 |
| Alt + Z | 실행 취소 | Alt + Z 그대로 |
| Alt + Shift + Z | 다시 실행 | Alt + Shift + Z 그대로 |
| Alt + S | 저장 | Alt + S 그대로 |
| Alt + F | 찾기 | Alt + F 그대로 (셸에서 단어 단위 이동) |
| Alt + T | 새 탭 | 같음 |
| Alt + W | 탭 닫기 | 같음 |
| Alt + N | 새 창 | 같음 |
| Alt + Q | 창 닫기 (맥처럼 앱 전체 종료는 아님) | 같음 |
| Alt + Space | Vicinae: 앱 검색·계산기·클립보드 기록·이모지 등 (Raycast) | 같음 |
| Alt + Shift + 3 | 스크린샷: 전체 화면을 `~/Pictures/Screenshots`에 저장 + 클립보드 복사 | 같음 |
| Alt + Shift + 4 | 스크린샷: 영역을 골라 편집기(satty)로. Enter = 저장 + 복사 | 같음 (찍은 뒤 마크업) |
| Alt + Tab | 지금 워크스페이스의 다음 창 (Shift를 더하면 이전 창) | 같음 |

"그대로"는 Alt 조합을 터미널에 그대로 넘긴다는 뜻이라 셸의 Alt 단축키도 계속 쓸 수 있습니다. 다른 터미널을 쓰면 `config/hypr/hyprland.lua`의 `terminalClasses`에 그 창의 class(`hyprctl clients`로 확인)를 추가하세요.

## 테마

[Catppuccin](https://github.com/catppuccin/catppuccin) Mocha 색으로 맞췄습니다. 앱은 다크 모드(GTK3 앱은 `adw-gtk3-dark`), 아이콘은 Papirus-Dark, 커서는 맥 커서(`macOS`)입니다. 창 테두리를 끌어 크기를 바꿀 수 있고, 워크스페이스는 맥 Spaces처럼 옆으로 밀리며 바뀝니다.

| 부분 | 색이 들어 있는 곳 |
|---|---|
| 바탕화면 | `config/hypr/wallpaper.png` (다른 그림은 `~/.config/hypr/hyprpaper.conf`의 `path`를 바꾸기. 저작권이 있는 그림은 저장소에 올리지 말고 `~/Pictures/Wallpapers`에 두기) |
| 창 테두리·그림자 | `config/hypr/hyprland.lua`의 `col`, `shadow` |
| 상단 막대 | `config/waybar/mocha.css` (모양은 `style.css`) |
| 터미널 | `config/kitty/current-theme.conf` (`kitty +kitten themes`로 골라도 됨) |
| 잠금 화면 | `config/hypr/hyprlock.conf`: 맥처럼 위에 날짜와 큰 시계, 가운데 사용자와 암호 입력, 오른쪽 아래 배터리 |
| 음량·밝기 팝업 | `config/swayosd/style.css` |
| 전원 메뉴 | `config/nwg-bar/style.css` (항목은 `bar.json`) |
| 알림 센터 | `config/swaync/style.css` (기본 스타일을 불러와 색 변수만 바꿈), 구성은 `config.json` |
| 앱 검색 창 | `config/hypr/hyprtoolkit.conf` |
| Vicinae | `config/vicinae/settings.json`의 `theme` |
| 입력기 후보 창·전환 팝업 | `home/.local/share/fcitx5/themes/catppuccin-mocha-mauve` ([catppuccin/fcitx5](https://github.com/catppuccin/fcitx5), MIT, 둥근 모서리 켬), 고르는 곳은 `config/fcitx5/conf/classicui.conf` |

## 터미널 환경

[mac-dotfiles](https://github.com/fotoner/mac-dotfiles)의 셸·git·Neovim 설정을 Arch 경로로 옮겼습니다. Homebrew와 macOS 전용 설정은 뺐습니다.

- **zsh**: oh-my-zsh(`amuse` 테마, `git` 플러그인), 입력 중 자동완성 제안, 명령어 색칠, Catppuccin 색 `ls` (`home/.zshrc`, `home/.dircolors`)
- **git**: 이름과 전역 gitignore는 저장소에 있고, 이메일은 저장소에 올리지 않도록 `~/.gitconfig`에 직접 넣습니다.
  ```sh
  git config --global user.email "you@example.com"
  gh auth setup-git   # gh로 GitHub에 로그인한 뒤 git push 인증 연결
  ```
- **터미널 도구**: `bat eza fd fzf jq tmux tree lazygit htop btop fastfetch git-lfs`, `zoxide`(`z 폴더이름일부`로 바로 이동), GitHub CLI(`gh`, 설정은 `config/gh/config.yml`. 로그인 정보는 저장소에 없음)
- **Claude Code 상태줄**: [fotoner/claude-statusline](https://github.com/fotoner/claude-statusline)의 스크립트에서 bash 5.2+ 버그(`~`가 홈 경로 전체로 바뀜)를 고친 본 (`home/.claude/statusline-command.sh`). `install.sh`가 `~/.claude/settings.json`에 `statusLine`만 추가하고 다른 설정은 건드리지 않습니다.
- **Neovim**: LazyVim. 처음 `nvim`을 켜면 플러그인을 내려받습니다. 색은 Catppuccin Mocha (`config/nvim/lua/plugins/colorscheme.lua`)

## 꼬였을 때

- 화면이 멈추거나 Hyprland가 안 뜨면 **Ctrl+Alt+F2**로 다른 텍스트 화면에 로그인해서 고칩니다.
- 화면 위에 빨간 막대가 뜨면 설정 파일 오류입니다. `hyprctl configerrors`로 내용을 봅니다.
- 패키지 설치 때문에 망가졌으면 snap-pac이 남긴 스냅샷으로 되돌립니다.
  ```sh
  sudo snapper -c root list                # 설치 전(pre)·후(post) 번호 확인
  sudo snapper -c root undochange 12..13   # 예: 12번~13번 사이 변경 되돌리기
  ```
- 자동 실행을 끄려면 `~/.zprofile`에서 `# arch-dotfiles:`로 시작하는 블록을 지웁니다.

## 파일 구성

| 파일 | 설치 위치 | 내용 |
|---|---|---|
| `config/hypr/hyprland.lua` | `~/.config/hypr/` | Hyprland 0.56 공식 예시 설정에서 한글 주석 부분만 바꿈: 자동 실행, 한글 입력 환경 변수, 맥식 스크롤 방향, 잠금·스크린샷 단축키, 맥식 Alt(=Cmd) 단축키, 파일 관리자 |
| `config/hypr/hypridle.conf` | `~/.config/hypr/` | 자동 잠금·화면 끄기·절전 |
| `config/hypr/hyprlock.conf` | `~/.config/hypr/` | 잠금 화면 |
| `config/hypr/hyprpaper.conf`, `wallpaper.png` | `~/.config/hypr/` | 바탕화면 |
| `config/hypr/hyprtoolkit.conf` | `~/.config/hypr/` | 앱 검색 창(hyprlauncher) 등 Hypr 앱 색 |
| `config/waybar/config.jsonc` | `~/.config/waybar/` | 상단 막대: 왼쪽 워크스페이스, 오른쪽 트레이·잠자기 방지·전원 모드·음량·배터리·A/한/あ 입력기 배지·Wi-Fi(누르면 Wi-Fi 목록)·시계(알림 빨간 점) |
| `config/waybar/style.css`, `mocha.css` | `~/.config/waybar/` | 상단 막대 모양과 색 |
| `config/kitty/kitty.conf`, `current-theme.conf` | `~/.config/kitty/` | 터미널 글꼴·여백·색 |
| `config/swaync/config.json`, `style.css` | `~/.config/swaync/` | 알림 센터 |
| `config/hypr/scripts/screenshot.sh`, `keyhints.sh` | `~/.config/hypr/scripts/` | 맥식 스크린샷, 단축키 도움말 창 |
| `config/hypr/scripts/quick-toggle.sh` | `~/.config/hypr/scripts/` | 알림 센터 빠른 버튼(Wi-Fi·블루투스·마이크): 실제 상태를 보고 바꾼 뒤 팝업으로 알림 |
| `config/hypr/scripts/ime-status.sh` | `~/.config/hypr/scripts/` | 상단바 입력기 배지 A / 한 / あ (fcitx5 트레이 아이콘 대신) |
| `config/hypr/scripts/wifi-menu.sh` | `~/.config/hypr/scripts/` | 상단바 Wi-Fi 아이콘을 누르면 뜨는 Wi-Fi 목록 창(nmtui, Catppuccin 색) |
| `config/hypr/scripts/smart-paste.sh` | `~/.config/hypr/scripts/` | 터미널에서 Alt+V: 클립보드에 이미지만 있으면 Ctrl+V(Claude Code 이미지 붙여넣기), 아니면 글자 붙여넣기 |
| `config/swayosd/style.css` | `~/.config/swayosd/` | 음량·밝기 팝업 |
| `config/nwg-bar/bar.json`, `style.css` | `~/.config/nwg-bar/` | 전원 메뉴 |
| `config/fontconfig/fonts.conf` | `~/.config/fontconfig/` | 웹페이지의 맥 전용 글꼴 이름(`-apple-system` 등)을 Inter로 |
| `config/fcitx5/conf/classicui.conf`, `home/.local/share/fcitx5/themes/` | `~/.config/fcitx5/conf/`, `~/.local/share/fcitx5/themes/` | 입력기 후보 창 테마 |
| `config/fcitx5/profile`, `config` | `~/.config/fcitx5/` | 입력기 목록(영어, 한글, 일본어)과 전환 키(Ctrl+Space로 차례로) |
| `config/git/config`, `ignore` | `~/.config/git/` | git 이름, LFS, 전역 gitignore |
| `config/gh/config.yml` | `~/.config/gh/` | GitHub CLI 설정 (`gh co` = PR 체크아웃) |
| `config/nvim/` | `~/.config/nvim/` | Neovim(LazyVim) 설정 |
| `config/vicinae/settings.json` | `~/.config/vicinae/` | Raycast 대체 실행기 Vicinae: 테마, 모서리 |
| `home/.zshrc`, `home/.dircolors` | `~/` | zsh 설정, `ls` 색 |
| `home/.claude/statusline-command.sh` | `~/.claude/` | Claude Code 상태줄 |
| `system/battery-threshold.conf` | `/etc/tmpfiles.d/` | 배터리 충전 상한 |
| `system/zram-generator.conf` | `/etc/systemd/` | zram 스왑 크기와 압축 방식 |

## 참고

- Hyprland 0.56부터 설정 파일이 `hyprland.conf`가 아니라 Lua(`hyprland.lua`)입니다. 인터넷의 예전 `bind = ...` 형식 예시는 그대로 쓸 수 없습니다.
- [Hyprland Master tutorial](https://wiki.hypr.land/Getting-Started/Master-Tutorial/) · [Must-have](https://wiki.hypr.land/Useful-Utilities/Must-have/) · [hypridle](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/) · [hyprlock](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/)
- [ArchWiki: Lenovo ThinkPad T14/T14s (Intel) Gen 1](https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14/T14s_(Intel)_Gen_1) · [ArchWiki: Fcitx5](https://wiki.archlinux.org/title/Fcitx5) · [ArchWiki: Snapper](https://wiki.archlinux.org/title/Snapper)
- Google Chrome, [Vicinae](https://vicinae.com), 맥 커서, 음량 창(pwvucontrol)은 공식 저장소에 없어서 `install.sh`가 AUR의 `google-chrome`, `vicinae-bin`, `apple_cursor`, `pwvucontrol`을 받아 빌드합니다. pwvucontrol은 Rust로 소스를 빌드해서 몇 분 걸립니다. AUR은 누구나 올릴 수 있으니 바뀐 PKGBUILD가 걱정되면 `~/.cache/aur/<패키지>/PKGBUILD`를 먼저 읽어 보세요. 업데이트는 `pacman -Syu`로 되지 않으니 같은 폴더에서 `git pull && makepkg -si`를 실행합니다.
- Tailscale은 `install.sh`가 서비스만 켭니다. 처음 한 번 `sudo tailscale up`으로 로그인하세요. 연결되면 `/etc/resolv.conf`를 Tailscale이 직접 관리합니다(MagicDNS).
- Vicinae의 "활성 창에 붙여넣기"와 스니펫 기능은 키보드 입력을 감시하는 도우미가 필요해서, 설치할 때 그 도우미에 권한(`cap_dac_override`)을 줍니다. 필요 없으면 `settings.json`에 `"input_server": { "enabled": false }`를 넣으세요.
- 리눅스에는 무릎 위 감지(lap mode)가 없어서 "performance" 전원 모드에서는 75°C를 넘을 수 있습니다. 무릎 위에서는 balanced 이하로 두세요.
- [CodexBar](https://github.com/steipete/CodexBar)(AI 사용량, 상단바 트레이)는 `install.sh`가 GitHub 공식 배포 파일을 받아 체크섬을 확인한 뒤 `~/.local`에 설치합니다. 업데이트도 같은 방법이라, 새 버전을 쓰려면 `~/.local/bin/codexbar-linux`를 지우고 `install.sh`를 다시 실행하세요. 보여줄 서비스(Claude, Codex 등)는 트레이 아이콘 → Settings → Providers에서 고릅니다.
