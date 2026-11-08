#!/usr/bin/env bash

MODE_FILE="$HOME/.config/i3/.mode"
mode="dark"
[ -f "$MODE_FILE" ] && mode=$(cat "$MODE_FILE")

if [ "$mode" = "light" ]; then
    echo "Light"
else
    echo "Dark"
fi
