#!/usr/bin/env bash

# Rofi Wi-Fi Manager with Pywal Theme
THEME="$HOME/.config/rofi/themes/rofi-network.rasi"

# Ensure notification icon fallback
notify_icon="network-wireless"

# Check if Wi-Fi is enabled
wifi_status=$(nmcli -t -f WIFI general 2>/dev/null)

if [ "$wifi_status" = "disabled" ]; then
    chosen=$(printf "󰖩  Turn Wi-Fi On\nCancel" | rofi -dmenu -i -p "󰤮 Wi-Fi is Off" -theme "$THEME")
    if [ "$chosen" = "󰖩  Turn Wi-Fi On" ]; then
        nmcli radio wifi on
        notify-send "Wi-Fi" "Wi-Fi turned On" -i "$notify_icon"
    fi
    exit 0
fi

# Get active Wi-Fi connection
active_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes:" | cut -d: -f2- | head -n1)

# Scan available networks and format entries
options=()

if [ -n "$active_ssid" ]; then
    options+=("󱚵  Disconnect from $active_ssid")
fi
options+=("󰑐  Rescan Networks")
options+=("󰖪  Turn Wi-Fi Off")

# Scan Wi-Fi networks (sort by signal strength, deduplicate SSIDs)
mapfile -t wifi_lines < <(nmcli -t -f "IN-USE,SSID,SIGNAL,SECURITY" device wifi list 2>/dev/null | awk -F: '
    $2 != "" {
        ssid = $2
        signal = $3
        in_use = $1
        sec = $4
        if (!(ssid in seen) || signal > max_sig[ssid]) {
            seen[ssid] = 1
            max_sig[ssid] = signal
            in_use_map[ssid] = in_use
            sec_map[ssid] = sec
        }
    }
    END {
        for (ssid in seen) {
            printf "%s:%s:%s:%s\n", in_use_map[ssid], ssid, max_sig[ssid], sec_map[ssid]
        }
    }
' | sort -t: -k1,1r -k3,3nr)

for entry in "${wifi_lines[@]}"; do
    IFS=: read -r in_use ssid signal security <<< "$entry"
    [ -z "$ssid" ] && continue

    # Signal icon
    if [ "$signal" -ge 75 ]; then
        sig_icon="󰤨"
    elif [ "$signal" -ge 50 ]; then
        sig_icon="󰤥"
    elif [ "$signal" -ge 25 ]; then
        sig_icon="󰤢"
    else
        sig_icon="󰤟"
    fi

    # Security icon
    if [ "$security" != "--" ] && [ -n "$security" ]; then
        sec_str="󰌾 $security"
    else
        sec_str="󰌿 Open"
    fi

    # Mark active
    if [ "$in_use" = "*" ]; then
        status_prefix="󰄬"
    else
        status_prefix=" "
    fi

    options+=("$status_prefix  $sig_icon  $ssid  |  $sec_str  |  $signal%")
done

# Run Rofi menu
chosen=$(printf "%s\n" "${options[@]}" | rofi -dmenu -i -p "󰤨 Wi-Fi" -theme "$THEME")

# Exit if cancelled
[ -z "$chosen" ] && exit 0

# Handle control options
if [ "$chosen" = "󰑐  Rescan Networks" ]; then
    notify-send "Wi-Fi" "Scanning for networks..." -i "$notify_icon"
    nmcli device wifi rescan 2>/dev/null
    sleep 1
    exec "$0"
elif [ "$chosen" = "󰖪  Turn Wi-Fi Off" ]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Wi-Fi turned Off" -i "network-wireless-offline"
    exit 0
elif [[ "$chosen" =~ ^󱚵[[:space:]]+Disconnect ]]; then
    nmcli device disconnect wlp2s0 2>/dev/null || nmcli connection down id "$active_ssid" 2>/dev/null
    notify-send "Wi-Fi" "Disconnected from $active_ssid" -i "network-wireless-disconnected"
    exit 0
fi

# Extract selected SSID
selected_ssid=$(echo "$chosen" | sed -E "s/^[ *󰄬]+[^ ]+[[:space:]]+//; s/[[:space:]]+\|.*//")

[ -z "$selected_ssid" ] && exit 0

# If user chose the currently connected network
if [ "$selected_ssid" = "$active_ssid" ]; then
    action=$(printf "󱚵  Disconnect\n󰑐  Reconnect\nCancel" | rofi -dmenu -i -p "Already connected" -theme "$THEME")
    if [ "$action" = "󱚵  Disconnect" ]; then
        nmcli connection down id "$active_ssid"
        notify-send "Wi-Fi" "Disconnected from $active_ssid" -i "network-wireless-disconnected"
    elif [ "$action" = "󰑐  Reconnect" ]; then
        nmcli connection up id "$active_ssid"
        notify-send "Wi-Fi" "Reconnected to $active_ssid" -i "$notify_icon"
    fi
    exit 0
fi

# Check if connection is already saved/known
is_saved=$(nmcli -g NAME connection show 2>/dev/null | grep -Fx "$selected_ssid")

if [ -n "$is_saved" ]; then
    notify-send "Wi-Fi" "Connecting to saved network '$selected_ssid'..." -i "$notify_icon"
    if nmcli connection up id "$selected_ssid" 2>/dev/null; then
        notify-send "Wi-Fi" "Connected to '$selected_ssid'" -i "$notify_icon"
        exit 0
    fi
    # If connection up failed, prompt for password below
fi

# Determine if password is required
needs_password=true
if [[ "$chosen" =~ \|\ *󰌿\ Open\ *\| ]]; then
    needs_password=false
fi

if [ "$needs_password" = true ]; then
    wifi_password=$(rofi -dmenu -password -p "Password for $selected_ssid" -theme "$THEME")
    [ -z "$wifi_password" ] && exit 0
    
    notify-send "Wi-Fi" "Connecting to '$selected_ssid'..." -i "$notify_icon"
    conn_output=$(nmcli device wifi connect "$selected_ssid" password "$wifi_password" 2>&1)
    status=$?
else
    notify-send "Wi-Fi" "Connecting to '$selected_ssid'..." -i "$notify_icon"
    conn_output=$(nmcli device wifi connect "$selected_ssid" 2>&1)
    status=$?
fi

if [ $status -eq 0 ]; then
    notify-send "Wi-Fi" "Successfully connected to '$selected_ssid'" -i "$notify_icon"
else
    notify-send "Wi-Fi" "Failed to connect: $conn_output" -u critical -i "network-wireless-offline"
fi
