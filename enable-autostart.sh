#!/usr/bin/env bash
# 첫 번째 텍스트 화면(tty1)에서 로그인하면 Hyprland가 바로 켜지게 한다.
# 꼬였을 때는 Ctrl+Alt+F2로 다른 화면에 로그인해서 아래 블록을 지우면 된다.
set -euo pipefail

case "$(basename "${SHELL:-bash}")" in
  zsh) PROFILE="$HOME/.zprofile" ;;
  *)   PROFILE="$HOME/.bash_profile" ;;
esac
MARK="# arch-dotfiles: tty1 로그인 시 Hyprland 자동 실행"

if grep -qF "$MARK" "$PROFILE" 2>/dev/null; then
  echo "이미 설정되어 있습니다: $PROFILE"
  exit 0
fi

cat >> "$PROFILE" <<EOF

$MARK
if [ -z "\$WAYLAND_DISPLAY" ] && [ "\$(tty)" = /dev/tty1 ]; then
  exec start-hyprland
fi
EOF
echo "설정했습니다: $PROFILE (다음 로그인부터 적용)"
