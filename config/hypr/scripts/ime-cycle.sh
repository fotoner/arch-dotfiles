#!/usr/bin/env bash
# 입력기 바꾸기 (A 영어, 한 한글, あ 일본어).
#   (인자 없음)            A → 한 → あ 차례로. 상단바·잠금 화면의 배지를 누를 때
#   next <세션> <n>        Ctrl+Space를 n번째 누름 (Ctrl을 누른 채로). 맥처럼 1번 = 직전에 쓰던 입력기,
#                          2번 = 그 전에 쓰던 입력기 … (누르는 동안에는 순서를 고정해 둔다)
#   commit <세션> <n>      Ctrl을 뗌. 고른 입력기가 '가장 최근'이 되고, 바꾸기 전 입력기가 그다음이 된다
#   hangul                 한/영 키: 영어면 한글로, 아니면(한글·일본어) 영어로
# 그래서 Ctrl+Space를 한 번씩 누르면 자주 쓰는 두 입력기를 오가고, 세 번째는 Ctrl을 누른 채 Space 두 번.
# Hyprland(hyprland.lua)가 세션 번호와 누른 횟수를 넘긴다. 최근 순서는 $XDG_RUNTIME_DIR/ime/mru (로그인마다 새로)
set -u
ALL=(keyboard-us hangul mozc)
dir="${XDG_RUNTIME_DIR:-/tmp}/ime"
mkdir -p "$dir"
exec 9>"$dir/lock"

switch_to() {
  fcitx5-remote -s "$1"
  pkill -USR1 -x bar-status # 상단바 배지를 바로 바꾼다 (기다리면 1초 안에 바뀜)
}

# 첫 인자를 맨 앞에 두고, 나머지 인자 순서대로, 빠진 입력기는 기본 순서로 뒤에 (중복·모르는 이름은 뺌)
ordered() {
  local m
  local -a out=()
  for m in "$@" "${ALL[@]}"; do
    [[ " ${ALL[*]} " == *" $m "* ]] || continue
    [[ " ${out[*]} " == *" $m "* ]] || out+=("$m")
  done
  echo "${out[@]}"
}

# 최근 순서: 지금 입력기를 맨 앞에, 그다음은 기록 순서대로.
# (한/영 키처럼 이 스크립트 밖에서 바꾼 경우에도 지금 입력기가 맨 앞이 되어 맞는다)
recent_order() {
  # shellcheck disable=SC2046
  ordered "$1" $(cat "$dir/mru" 2>/dev/null)
}

# state 파일: "<세션> <적용한 횟수> <이번 순서...>"
read_state() {
  state_session="" state_n=0 order=()
  local -a f=()
  [ -f "$dir/state" ] && read -r -a f < "$dir/state"
  state_session=${f[0]:-} state_n=${f[1]:-0} order=("${f[@]:2}")
}

# 앞선 누름이 아직 처리 중이면(프로세스가 거의 동시에 뜬 경우) 잠깐 기다린다. 최대 0.5초
wait_for() {
  local want_session=$1 want_n=$2 i
  for i in $(seq 25); do
    flock 9
    read_state
    [ "$state_session" = "$want_session" ] && [ "$state_n" -ge "$want_n" ] && return 0
    flock -u 9
    sleep 0.02
  done
  return 1
}

current=$(fcitx5-remote -n 2>/dev/null)
[ -n "$current" ] || exit 0

case "${1:-}" in
  next)
    session=${2:?} n=${3:?}
    if [ "$n" = 1 ]; then
      flock 9
      read -r -a order <<<"$(recent_order "$current")"
    else
      wait_for "$session" $((n - 1)) || exit 0
      [ "$state_n" -ge "$n" ] && exit 0 # 이미 처리함
    fi
    echo "$session $n ${order[*]}" > "$dir/state"
    switch_to "${order[$((n % ${#order[@]}))]}"
    ;;
  commit)
    session=${2:?} n=${3:?}
    wait_for "$session" "$n" || exit 0
    # 고른 것(지금 입력기)을 맨 앞에, 그다음은 이번 순서대로 → 바꾸기 전 입력기가 두 번째
    ordered "$(fcitx5-remote -n 2>/dev/null || echo "$current")" "${order[@]}" > "$dir/mru"
    rm -f "$dir/state"
    ;;
  hangul)
    flock 9
    if [ "$current" = keyboard-us ]; then target=hangul; else target=keyboard-us; fi
    switch_to "$target"
    # shellcheck disable=SC2046
    ordered "$target" "$current" $(cat "$dir/mru" 2>/dev/null) > "$dir/mru.new" && mv "$dir/mru.new" "$dir/mru"
    rm -f "$dir/state"
    ;;
  *)
    flock 9
    case "$current" in
      keyboard-us) target=hangul ;;
      hangul) target=mozc ;;
      *) target=keyboard-us ;;
    esac
    switch_to "$target"
    # shellcheck disable=SC2046
    ordered "$target" "$current" $(cat "$dir/mru" 2>/dev/null) > "$dir/mru.new" && mv "$dir/mru.new" "$dir/mru"
    rm -f "$dir/state"
    ;;
esac
