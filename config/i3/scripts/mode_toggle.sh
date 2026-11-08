#!/usr/bin/env bash

# System Dark / Light Mode Selector and Toggle
MODE_FILE="$HOME/.config/i3/.mode"
THEME="$HOME/.config/rofi/themes/rofi-network.rasi"

current_mode="dark"
[ -f "$MODE_FILE" ] && current_mode=$(cat "$MODE_FILE")

set_mode() {
    new_mode="$1"
    echo "$new_mode" > "$MODE_FILE"
    notify-send "Appearance" "Switching to $new_mode mode..." -i style
    "$HOME/.config/i3/scripts/Colors.sh" >/dev/null 2>&1
    notify-send "Appearance" "Active system mode: $new_mode" -i style
}

# Instant toggle mode
if [ "$1" = "--toggle" ]; then
    if [ "$current_mode" = "light" ]; then
        set_mode "dark"
    else
        set_mode "light"
    fi
    exit 0
fi

# Explicit mode setting
if [ "$1" = "dark" ] || [ "$1" = "light" ]; then
    set_mode "$1"
    exit 0
fi

# Rofi interactive picker
options=()
if [ "$current_mode" = "dark" ]; then
    options+=("󰄬  󰖔  Dark Mode")
    options+=("   󰖙  Light Mode")
else
    options+=("   󰖔  Dark Mode")
    options+=("󰄬  󰖙  Light Mode")
fi
options+=("   󰑐  Toggle Mode")

chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu -i -p "󰃟 Theme Mode" -theme "$THEME")

[ -z "$chosen" ] && exit 0

if [[ "$chosen" =~ "Dark Mode" ]]; then
    set_mode "dark"
elif [[ "$chosen" =~ "Light Mode" ]]; then
    set_mode "light"
elif [[ "$chosen" =~ "Toggle Mode" ]]; then
    if [ "$current_mode" = "light" ]; then
        set_mode "dark"
    else
        set_mode "light"
    fi
fi
