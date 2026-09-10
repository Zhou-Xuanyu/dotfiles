#!/bin/bash
# toogle_etrackpad.sh

if pgrep etrackpad >/dev/null; then
  pkill etrackpad
  hyprland_toggle_touchscreen --enabled 1
else
  etrackpad &
  hyprland_toggle_touchscreen --enabled 0
fi
