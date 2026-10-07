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
4. Hyprland, Waybar, 한글 입력기(fcitx5), 글꼴, 소리, 블루투스 등 설치
5. 블루투스, 전원 모드(power-profiles-daemon), 패키지 캐시 자동 정리 켜기
6. 배터리 충전 상한 75~80%
7. `config/` 아래 설정 파일을 `~/.config/`로 복사. 내용이 다른 기존 파일은 `.bak-날짜시각`으로 백업
8. zram 스왑, 터보 부스트, NVIDIA GPU 유무 점검

## 단축키

SUPER는 Windows 키입니다.

| 단축키 | 동작 | 맥과 비교 |
|---|---|---|
| SUPER + Q | 터미널(kitty) 열기 | 맥의 Cmd+Q(종료)와 다름 |
| SUPER + C | 창 닫기 | Cmd+W |
| SUPER + R | 앱 검색 실행 | Spotlight |
| SUPER + E | 파일 관리자(Nautilus) | Finder |
| SUPER + L | 화면 잠금 | Ctrl+Cmd+Q |
| SUPER + 1~0 | 워크스페이스 이동 | Spaces 이동 |
| SUPER + Shift + 1~0 | 창을 그 워크스페이스로 보내기 | |
| SUPER + V | 창 띄우기/타일로 되돌리기 | |
| SUPER + 마우스 끌기 | 왼쪽: 창 이동, 오른쪽: 크기 조절 | |
| 세 손가락 좌우 쓸기 | 워크스페이스 전환 | 같음 |
| Print | 영역 스크린샷을 클립보드로 | Cmd+Shift+Ctrl+4 |
| Shift + Print | 전체 화면을 `~/Pictures`에 저장 | Cmd+Shift+3 |
| SUPER + M | Hyprland 종료 | 로그아웃 |

한글 전환은 **Ctrl+Space**(키보드에 한/영 키가 있으면 그 키도)입니다. 한글이 목록에 없으면 SUPER+R → "Fcitx 5 Configuration"에서 "Only Show Current Language"를 끄고 Hangul을 추가하세요.

자동으로 일어나는 일: 2분 30초 뒤 화면 어둡게, 5분 뒤 잠금, 5분 30초 뒤 화면 끔, 30분 뒤 절전. 덮개를 닫으면 잠근 뒤 절전합니다 (`config/hypr/hypridle.conf`).

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
| `config/hypr/hyprland.lua` | `~/.config/hypr/` | Hyprland 0.56 공식 예시 설정에서 한글 주석 부분만 바꿈: 자동 실행, 한글 입력 환경 변수, 맥식 스크롤 방향, 잠금·스크린샷 단축키, 파일 관리자 |
| `config/hypr/hypridle.conf` | `~/.config/hypr/` | 자동 잠금·화면 끄기·절전 |
| `config/hypr/hyprlock.conf` | `~/.config/hypr/` | 잠금 화면 |
| `config/waybar/config.jsonc` | `~/.config/waybar/` | 상단 막대: 워크스페이스, 시계, 전원 모드, 음량, Wi-Fi, 배터리 |
| `config/fcitx5/profile` | `~/.config/fcitx5/` | 입력기 목록: 영어 + 한글 |
| `system/battery-threshold.conf` | `/etc/tmpfiles.d/` | 배터리 충전 상한 |

## 참고

- Hyprland 0.56부터 설정 파일이 `hyprland.conf`가 아니라 Lua(`hyprland.lua`)입니다. 인터넷의 예전 `bind = ...` 형식 예시는 그대로 쓸 수 없습니다.
- [Hyprland Master tutorial](https://wiki.hypr.land/Getting-Started/Master-Tutorial/) · [Must-have](https://wiki.hypr.land/Useful-Utilities/Must-have/) · [hypridle](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/) · [hyprlock](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/)
- [ArchWiki: Lenovo ThinkPad T14/T14s (Intel) Gen 1](https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14/T14s_(Intel)_Gen_1) · [ArchWiki: Fcitx5](https://wiki.archlinux.org/title/Fcitx5) · [ArchWiki: Snapper](https://wiki.archlinux.org/title/Snapper)
- 리눅스에는 무릎 위 감지(lap mode)가 없어서 "performance" 전원 모드에서는 75°C를 넘을 수 있습니다. 무릎 위에서는 balanced 이하로 두세요.
