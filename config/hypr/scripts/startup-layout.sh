#!/usr/bin/env bash
# 로그인 첫 화면 (Hyprland가 처음 켜질 때 한 번, hyprland.lua의 hyprland.start에서 실행):
#   왼쪽 위 fastfetch, 왼쪽 아래 큰 시계, 오른쪽 터미널 (포커스)
# dwindle 레이아웃이 지금 고른 창을 나눠 새 창을 넣는 것을 이용한다:
#   1) fastfetch → 화면 전체   2) 터미널 → 오른쪽 절반
#   3) fastfetch를 고르고 '아래로 나누기'를 정한 뒤 시계 → 왼쪽 아래   4) 터미널로 포커스
# 세 창 모두 보통 kitty 창이다 (Alt+V 붙여넣기 등 터미널 단축키가 그대로 먹도록 class를 바꾸지 않는다)

kitty_windows() {
  hyprctl clients -j | jq -r '.[] | select(.class == "kitty") | .address' | sort
}

# kitty 창을 하나 띄우고, 새로 생긴 창 주소를 출력한다 (최대 10초 기다림)
spawn() {
  local before addr
  before=$(kitty_windows)
  kitty "$@" >/dev/null 2>&1 &
  disown
  for _ in $(seq 100); do
    addr=$(comm -13 <(echo "$before") <(kitty_windows) | head -n1)
    if [[ -n $addr ]]; then
      echo "$addr"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

focus() {
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$1\" })" >/dev/null
}

# fastfetch 로고: ~/.face를 원형으로 잘라 둔다 (사진이 바뀌었을 때만 다시 만든다)
fetch=$(spawn zsh -c '~/.config/fastfetch/face.sh; fastfetch; exec zsh') || exit 1
term=$(spawn) || exit 1

focus "$fetch"
hyprctl dispatch 'hl.dsp.layout("preselect d")' >/dev/null
clock=$(spawn ~/.config/hypr/scripts/big-clock.sh) || exit 1

# 왼쪽 열은 fastfetch 60%, 시계 40% (dwindle 비율 1 = 반반, 위쪽 창 몫 = 비율 ÷ 2)
focus "$clock"
hyprctl dispatch 'hl.dsp.layout("splitratio 1.2 exact")' >/dev/null

focus "$term"
