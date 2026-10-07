#!/usr/bin/env bash
# 맥식 스크린샷. 파일은 ~/Pictures/Screenshots에 저장하고 클립보드에도 복사한다
#   full (Alt+Shift+3): 전체 화면을 바로 저장
#   area (Alt+Shift+4): 영역을 고른 뒤 편집기(satty)로 연다. Enter = 저장 + 복사, Esc = 닫기
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/스크린샷 $(date '+%Y-%m-%d %H.%M.%S').png"

case "${1:-}" in
  full)
    grim "$file"
    wl-copy < "$file"
    notify-send -a "스크린샷" -i "$file" "스크린샷" "저장하고 클립보드에 복사했어요"
    ;;
  area)
    region=$(slurp) || exit 0 # 영역을 고르다 Esc를 누르면 아무것도 하지 않는다
    grim -g "$region" - | satty --filename - --output-filename "$file" \
      --copy-command wl-copy --early-exit --actions-on-enter save-to-clipboard,save-to-file
    ;;
  *)
    echo "사용법: $0 full|area" >&2
    exit 1
    ;;
esac
