#!/usr/bin/env bash
# Wi-Fi 목록 창 (상단바 Wi-Fi 아이콘 클릭). nmtui의 색을 터미널의 Catppuccin 색(default = 터미널 배경)에 맞춘다
export NEWT_COLORS='
root=white,default
window=white,default
border=blue,default
shadow=default,default
title=blue,default
roottext=white,default
helpline=white,default
label=white,default
textbox=white,default
acttextbox=black,blue
listbox=white,default
actlistbox=black,blue
sellistbox=black,blue
actsellistbox=black,blue
entry=white,default
disentry=gray,default
checkbox=white,default
actcheckbox=black,blue
button=black,blue
actbutton=black,cyan
compactbutton=white,default
emptyscale=,default
fullscale=,blue
'
exec kitty -o confirm_os_window_close=0 --class nmtui -e nmtui-connect
