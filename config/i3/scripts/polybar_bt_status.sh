#!/usr/bin/env bash

# Fast polybar status for Bluetooth
powered=$(bluetoothctl show 2>/dev/null | grep -i "Powered: yes")

if [ -z "$powered" ]; then
    echo "Off"
else
    connected=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d" " -f3-)
    if [ -n "$connected" ]; then
        if [ ${#connected} -gt 14 ]; then
            echo "${connected:0:11}..."
        else
            echo "$connected"
        fi
    else
        echo "On"
    fi
fi
