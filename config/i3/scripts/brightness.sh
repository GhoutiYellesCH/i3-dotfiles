#!/bin/bash

iDIR="$HOME/.config/dunst/icons/brightness"
notification_timeout=1000

# Get brightness (0-100)
get_backlight() {
	# Check if xrandr software brightness is in use (not 1.0)
	xr_val=$(xrandr --verbose 2>/dev/null | grep -m 1 -i brightness | awk '{printf "%.0f", $2 * 100}')
	if [ -n "$xr_val" ] && [ "$xr_val" -lt 100 ]; then
		echo "$xr_val"
		return
	fi

	# Hardware backlight reading
	if [ -s /sys/class/backlight/intel_backlight/brightness ] && [ -s /sys/class/backlight/intel_backlight/max_brightness ]; then
		curr=$(cat /sys/class/backlight/intel_backlight/brightness 2>/dev/null)
		max=$(cat /sys/class/backlight/intel_backlight/max_brightness 2>/dev/null)
		if [ -n "$curr" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
			echo $(( curr * 100 / max ))
			return
		fi
	fi

	echo "${xr_val:-100}"
}

# Get icon according to level
get_icon() {
	local val="$1"
	if [ -z "$val" ]; then
		val=$(get_backlight)
	fi
	if [ "$val" -le 20 ]; then
		icon="$iDIR/brightness-20.png"
	elif [ "$val" -le 40 ]; then
		icon="$iDIR/brightness-40.png"
	elif [ "$val" -le 60 ]; then
		icon="$iDIR/brightness-60.png"
	elif [ "$val" -le 80 ]; then
		icon="$iDIR/brightness-80.png"
	else
		icon="$iDIR/brightness-100.png"
	fi
}

# Notify user
notify_user() {
	local val="$1"
	get_icon "$val"
	notify-send -e -h string:x-canonical-private-synchronous:brightness_notif \
		-h int:value:"$val" \
		-u low \
		-i "$icon" \
		"Brightness : $val%"
}

# Change brightness
change_backlight() {
	direction="$1"
	if [ "$direction" = "up" ]; then
		bctl_arg="+5%"
	else
		bctl_arg="5%-"
	fi

	# Try hardware backlight via brightnessctl first
	if brightnessctl set "$bctl_arg" -n >/dev/null 2>&1; then
		curr=$(cat /sys/class/backlight/intel_backlight/brightness 2>/dev/null)
		max=$(cat /sys/class/backlight/intel_backlight/max_brightness 2>/dev/null)
		if [ -n "$curr" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
			current=$(( curr * 100 / max ))
		else
			current=$(brightnessctl -m | head -n 1 | cut -d, -f4 | tr -d '%')
		fi
	else
		# Fallback to xrandr software brightness if brightnessctl lacks permissions
		disp=$(xrandr --query | grep " connected" | head -n 1 | cut -d' ' -f1)
		curr_raw=$(xrandr --verbose | grep -m 1 -i brightness | awk '{print $2}')
		if [ -z "$curr_raw" ]; then curr_raw="1.0"; fi
		if [ "$direction" = "up" ]; then
			new_val=$(awk -v c="$curr_raw" 'BEGIN {val = c + 0.05; if (val > 1.0) val = 1.0; printf "%.2f", val}')
		else
			new_val=$(awk -v c="$curr_raw" 'BEGIN {val = c - 0.05; if (val < 0.05) val = 0.05; printf "%.2f", val}')
		fi
		xrandr --output "$disp" --brightness "$new_val"
		current=$(awk -v val="$new_val" 'BEGIN {printf "%.0f", val * 100}')
	fi

	notify_user "$current"
}

# Execute accordingly
case "$1" in
	"--get")
		get_backlight
		;;
	"up")
		change_backlight "up"
		;;
	"down")
		change_backlight "down"
		;;
	*)
		get_backlight
		;;
esac
