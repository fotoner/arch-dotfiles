#!/usr/bin/env bash
# fastfetch 로고용 원형 프로필 사진을 만든다: ~/.face(잠금 화면 사진)를 동그랗게 자르고,
# 바깥에 창 테두리와 같은 보라 → 파랑 그라데이션 링을 두른다 (링과 사진 사이는 투명한 틈).
# 결과는 ~/.cache/fastfetch/face.png. ~/.face가 바뀌었을 때만 다시 만든다. ~/.face가 없으면 지우고 1로 끝난다
# (fastfetch는 그림이 없으면 기본 Arch 로고를 보여 준다)
src="$HOME/.face"
out="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch/face.png"
SIZE=288 # 결과 크기(px). 가장자리 계산은 이 크기 기준
RING=7   # 링 두께
GAP=7    # 링과 사진 사이 틈

if [ ! -s "$src" ]; then
  rm -f "$out"
  exit 1
fi
[ "$out" -nt "$src" ] && exit 0
mkdir -p "$(dirname "$out")"

# d = 픽셀 중심에서 원 중심까지 거리, R = 바깥 반지름. clip(...)으로 가장자리를 1px 부드럽게
d="hypot(X+0.5-W/2,Y+0.5-H/2)"
R="(W/2-0.5)"
ring="clip($R-$d+0.5,0,1)*clip($d-($R-$RING)+0.5,0,1)"
photo="clip(($R-$RING-$GAP)-$d+0.5,0,1)"
t="((X+Y)/(W+H))" # 왼쪽 위 보라(#cba6f7) → 오른쪽 아래 파랑(#89b4fa)
ffmpeg -loglevel error -y -i "$src" -vf "scale=$SIZE:$SIZE:force_original_aspect_ratio=increase,crop=$SIZE:$SIZE,format=rgba,geq=\
r='$photo*r(X,Y)+$ring*(203+(137-203)*$t)':\
g='$photo*g(X,Y)+$ring*(166+(180-166)*$t)':\
b='$photo*b(X,Y)+$ring*(247+(250-247)*$t)':\
a='255*($photo+$ring)'" -frames:v 1 "$out.tmp.png" && mv "$out.tmp.png" "$out"
