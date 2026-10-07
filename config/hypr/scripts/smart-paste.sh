#!/usr/bin/env bash
# 터미널에서 Alt+V(맥의 Cmd+V). 클립보드에 글자 없이 이미지만 있으면 Ctrl+V(Claude Code가 이미지를 받는 키)를,
# 그 밖에는 터미널의 글자 붙여넣기(Ctrl+Shift+V)를 보낸다
types=$(wl-paste --list-types 2>/dev/null)
if grep -q '^image/' <<<"$types" && ! grep -qE '^(text/plain|UTF8_STRING|STRING|TEXT)' <<<"$types"; then
  mods="CTRL"
else
  mods="CTRL + SHIFT"
fi
if [ "${1:-}" = "--dry-run" ]; then
  echo "$mods"
  exit 0
fi
hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"$mods\", key = \"V\" })" >/dev/null
