#!/bin/sh

# ---- ENV (required for dwm keybinds) ----
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

# ---- DMENU POSITION (red square) ----
X=1100
Y=40
W=420
L=8

export DMENU="/usr/bin/dmenu -i -x $X -y $Y -w $W -l $L"
export NOTIFY="/usr/bin/notify-send"

