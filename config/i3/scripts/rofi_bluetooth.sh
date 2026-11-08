#!/usr/bin/env bash

# Rofi Bluetooth Manager with Pywal Theme
THEME="$HOME/.config/rofi/themes/rofi-network.rasi"
notify_icon="bluetooth"

# Check if bluetooth is powered on
powered=$(bluetoothctl show 2>/dev/null | grep -i "Powered: yes")

if [ -z "$powered" ]; then
    chosen=$(printf "󰂯  Turn Bluetooth On\nCancel" | rofi -dmenu -i -p "󰂲 Bluetooth is Off" -theme "$THEME")
    if [ "$chosen" = "󰂯  Turn Bluetooth On" ]; then
        rfkill unblock bluetooth 2>/dev/null
        bluetoothctl power on >/dev/null 2>&1
        notify-send "Bluetooth" "Bluetooth turned On" -i "$notify_icon"
    fi
    exit 0
fi

options=()
options+=("󰂲  Turn Bluetooth Off")
options+=("󰑐  Scan for Nearby Devices")

# Get paired devices
paired_raw=$(bluetoothctl devices Paired 2>/dev/null)
declare -A paired_map

if [ -n "$paired_raw" ]; then
    while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)
        [ -z "$mac" ] && continue
        paired_map["$mac"]=1
        
        # Check connection status
        is_conn=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Connected: yes")
        if [ -n "$is_conn" ]; then
            options+=("󰄬  󰂱  $name  (Connected)  |  $mac")
        else
            options+=("   󰂯  $name  (Paired)  |  $mac")
        fi
    done <<< "$paired_raw"
fi

# Get available (unpaired) devices
all_devices=$(bluetoothctl devices 2>/dev/null)
if [ -n "$all_devices" ]; then
    while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)
        [ -z "$mac" ] && continue
        # Only add if not already in paired map
        if [ -z "${paired_map[$mac]}" ]; then
            options+=("   󰂰  $name  |  $mac")
        fi
    done <<< "$all_devices"
fi

# Run Rofi menu
chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu -i -p "󰂯 Bluetooth" -theme "$THEME")

[ -z "$chosen" ] && exit 0

# Handle control options
if [ "$chosen" = "󰂲  Turn Bluetooth Off" ]; then
    bluetoothctl power off >/dev/null 2>&1
    notify-send "Bluetooth" "Bluetooth turned Off" -i "bluetooth-disabled"
    exit 0
elif [ "$chosen" = "󰑐  Scan for Nearby Devices" ]; then
    notify-send "Bluetooth" "Scanning for nearby devices (5s)..." -i "$notify_icon"
    bluetoothctl --timeout 5 scan on >/dev/null 2>&1
    exec "$0"
fi

# Extract MAC address from chosen line
mac=$(echo "$chosen" | awk -F'|' '{print $NF}' | tr -d ' ')
name=$(echo "$chosen" | sed -E "s/^[ *󰄬]+[^ ]+[[:space:]]+//; s/[[:space:]]+\(.*//; s/[[:space:]]+\|.*//")

[ -z "$mac" ] && exit 0

# Check current state of selected device
is_conn=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Connected: yes")
is_paired=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Paired: yes")

if [ -n "$is_conn" ]; then
    action=$(printf "󱚵  Disconnect\n󰅖  Unpair / Remove\nCancel" | rofi -dmenu -i -p "$name" -theme "$THEME")
    if [ "$action" = "󱚵  Disconnect" ]; then
        notify-send "Bluetooth" "Disconnecting from $name..." -i "$notify_icon"
        bluetoothctl disconnect "$mac" >/dev/null 2>&1
        notify-send "Bluetooth" "Disconnected from $name" -i "$notify_icon"
    elif [ "$action" = "󰅖  Unpair / Remove" ]; then
        bluetoothctl remove "$mac" >/dev/null 2>&1
        notify-send "Bluetooth" "Removed $name" -i "$notify_icon"
    fi
elif [ -n "$is_paired" ]; then
    action=$(printf "󰂱  Connect\n󰅖  Unpair / Remove\nCancel" | rofi -dmenu -i -p "$name" -theme "$THEME")
    if [ "$action" = "󰂱  Connect" ]; then
        notify-send "Bluetooth" "Connecting to $name..." -i "$notify_icon"
        if bluetoothctl connect "$mac" 2>&1 | grep -q "Successful"; then
            notify-send "Bluetooth" "Connected to $name" -i "$notify_icon"
        else
            notify-send "Bluetooth" "Connection attempted with $name" -i "$notify_icon"
        fi
    elif [ "$action" = "󰅖  Unpair / Remove" ]; then
        bluetoothctl remove "$mac" >/dev/null 2>&1
        notify-send "Bluetooth" "Removed $name" -i "$notify_icon"
    fi
else
    action=$(printf "󰂱  Pair & Connect\nCancel" | rofi -dmenu -i -p "Pair with $name?" -theme "$THEME")
    if [ "$action" = "󰂱  Pair & Connect" ]; then
        notify-send "Bluetooth" "Pairing with $name ($mac)..." -i "$notify_icon"
        bluetoothctl pair "$mac" >/dev/null 2>&1
        bluetoothctl trust "$mac" >/dev/null 2>&1
        bluetoothctl connect "$mac" >/dev/null 2>&1
        notify-send "Bluetooth" "Paired and connected to $name" -i "$notify_icon"
    fi
fi
