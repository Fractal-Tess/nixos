#!/usr/bin/env bash
# Real-time volume knob monitor for KBP7075W
# Monitors both key events and wheel events

echo "Starting volume knob monitor..."
echo "Device: KBP7075W Keyboard (/dev/input/event259)"
echo "Turn the volume knob to test. Press Ctrl+C to stop."
echo ""

# Function to change volume and show notification
change_volume() {
    local delta=$1
    local direction=$2

    # Apply volume change
    pactl set-sink-volume @DEFAULT_SINK@ "${delta}%"

    # Get current volume for notification
    local current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
    local icon="🔊"

    if [ "$current_vol" -eq 0 ]; then
        icon="🔇"
    elif [ "$current_vol" -lt 30 ]; then
        icon="🔈"
    elif [ "$current_vol" -lt 70 ]; then
        icon="🔉"
    fi

    # Show notification
    notify-send "Volume" "$icon $current_vol%" \
        -h "string:x-canonical-private-synchronous:volume-knob" \
        -t 1000

    echo "Volume $direction: $current_vol%"
}

# Monitor the device for events
monitor_events() {
    local device="/dev/input/event259"

    # Check if device exists
    if [ ! -e "$device" ]; then
        echo "Error: Device $device not found!"
        echo "Available devices:"
        ls -la /dev/input/by-id/ | grep -i keyboard
        exit 1
    fi

    echo "Monitoring events on $device..."

    # Use evtest to monitor events
    nix-shell -p evtest --run "evtest $device" 2>/dev/null | while read -r line; do
        # Check for volume key events
        if echo "$line" | grep -q "KEY_VOLUMEUP.*value 1"; then
            echo "Volume Up key pressed"
            change_volume "+5" "up"
        elif echo "$line" | grep -q "KEY_VOLUMEDOWN.*value 1"; then
            echo "Volume Down key pressed"
            change_volume "-5" "down"
        fi

        # Check for horizontal wheel events
        if echo "$line" | grep -q "REL_HWHEEL.*value -1"; then
            echo "Volume wheel turned left"
            change_volume "-2" "down"
        elif echo "$line" | grep -q "REL_HWHEEL.*value 1"; then
            echo "Volume wheel turned right"
            change_volume "+2" "up"
        fi

        # Check for high-resolution wheel events
        if echo "$line" | grep -q "REL_HWHEEL_HI_RES.*value -"; then
            # Extract the value and normalize
            local value=$(echo "$line" | grep -o "value -[0-9]*" | grep -o "[0-9]*")
            if [ -n "$value" ] && [ "$value" -gt 0 ]; then
                echo "Volume wheel high-res turned left ($value)"
                change_volume "-1" "down"
            fi
        elif echo "$line" | grep -q "REL_HWHEEL_HI_RES.*value "; then
            local value=$(echo "$line" | grep -o "value [0-9]*" | grep -o "[0-9]*")
            if [ -n "$value" ] && [ "$value" -gt 0 ]; then
                echo "Volume wheel high-res turned right ($value)"
                change_volume "+1" "up"
            fi
        fi
    done
}

# Start monitoring
monitor_events