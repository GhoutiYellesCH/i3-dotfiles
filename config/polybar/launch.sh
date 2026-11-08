#!/usr/bin/env bash

# Add this script to your wm startup file.

THEME=square
DIR="$HOME/.config/polybar/$THEME"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch the bar
setsid -f polybar -q main -c "$DIR"/config.ini </dev/null >/dev/null 2>&1 &
