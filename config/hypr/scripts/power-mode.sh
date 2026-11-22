#!/usr/bin/env bash
# 상단바 전원 모드 아이콘 (Quickshell 전원 모드와 같은 값: 저전력 · 균형 · 빠른 균형 · 성능).
# 모드는 Quickshell(Power.qml)이 ~/.local/state/power-mode에 적고, 바뀌면 waybar에 신호 10을 보낸다. 클릭 = qs ipc call power cycle
mode=$(cat "$HOME/.local/state/power-mode" 2>/dev/null)
[ -n "$mode" ] || mode=$(powerprofilesctl get 2>/dev/null)
case "$mode" in
  power-saver) icon=$''; name="저전력";    note="지속 전력 10W" ;;
  fast)        icon=$''; name="빠른 균형"; note="지속 전력 15W" ;;
  performance) icon=$''; name="성능";      note="지속 전력 22W" ;;
  *)           icon=$''; name="균형";      note="지속 전력 12W"; mode=balanced ;;
esac
printf '{"text":"%s","class":"%s","tooltip":"전원 모드: %s (%s, 클릭해서 바꾸기)"}\n' "$icon" "$mode" "$name" "$note"
