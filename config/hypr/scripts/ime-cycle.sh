#!/usr/bin/env bash
# 입력기를 A(영어) → 한(한글) → あ(일본어) 순서로 바꾼다. 상단바 배지와 잠금 화면 배지를 누를 때 쓴다
case "$(fcitx5-remote -n 2>/dev/null)" in
  keyboard-us) fcitx5-remote -s hangul ;;
  hangul) fcitx5-remote -s mozc ;;
  *) fcitx5-remote -s keyboard-us ;;
esac
