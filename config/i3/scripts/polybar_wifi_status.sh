#!/usr/bin/env bash

# Fast polybar status for Wi-Fi
active=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes:" | cut -d: -f2- | head -n1)

if [ -n "$active" ]; then
    if [ ${#active} -gt 14 ]; then
        echo "${active:0:11}..."
    else
        echo "$active"
    fi
else
    wifi_status=$(nmcli -t -f WIFI general 2>/dev/null)
    if [ "$wifi_status" = "disabled" ]; then
        echo "Off"
    else
        echo "Disconnected"
    fi
fi
