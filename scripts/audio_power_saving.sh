#!/bin/bash

BAT_STATUS_FILE="/sys/class/power_supply/BAT0/status"
PSAVE_FILE="/sys/module/snd_hda_intel/parameters/power_save"
PSAVE_CTRL_FILE="/sys/module/snd_hda_intel/parameters/power_save_controller"

# If any required file is missing, bail silently
[ -r "$BAT_STATUS_FILE" ] || exit 0
[ -w "$PSAVE_FILE" ] || exit 0
[ -w "$PSAVE_CTRL_FILE" ] || exit 0

status=$(cat "$BAT_STATUS_FILE")

if [ "$status" = "Discharging" ]; then
  # On battery → enable audio power saving
  echo 10 >"$PSAVE_FILE"
  echo Y >"$PSAVE_CTRL_FILE"
else
  # Charging or Full → disable audio power saving (avoid ticking)
  echo 0 >"$PSAVE_FILE"
  echo N >"$PSAVE_CTRL_FILE"
fi
