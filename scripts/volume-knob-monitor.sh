#!/usr/bin/env bash
# Volume Knob Monitor for KBP7075W Wireless Keyboard
# Uses libinput-debug-events to capture horizontal wheel events

# Check if libinput-debug-events is available
if ! command -v libinput-debug-events &> /dev/null; then
    echo "libinput-debug-events not found. Installing..."
    nix-shell -p libinput --run "echo 'libinput available'"
fi

# Device path for the wireless keyboard volume knob
DEVICE_NAME="KBP7075W Keyboard"

echo "Monitoring volume knob on $DEVICE_NAME"
echo "Press Ctrl+C to stop"
echo "Turn the volume knob to test..."

# Monitor for horizontal wheel events using libinput
# This will capture wheel events and convert them to volume changes
nix-shell -p libinput --run "libinput-debug-events" | while read -r line; do
    # Check for horizontal wheel events
    if echo "$line" | grep -q "$DEVICE_NAME.*wheel.*horizontal"; then
        # Extract the wheel value (positive = right, negative = left)
        if echo "$line" | grep -q "wheel.*hi-res"; then
            # High resolution wheel event
            if echo "$line" | grep -q "wheel.*horizontal.*-"; then
                echo "Volume knob turned left (decrease)"
                pactl set-sink-volume @DEFAULT_SINK@ -2%
                # Show notification
                current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1)
                notify-send "Volume" "🔉 $current_vol" -h "string:x-canonical-private-synchronous:volume-knob" -t 1000
            else
                echo "Volume knob turned right (increase)"
                pactl set-sink-volume @DEFAULT_SINK@ +2%
                # Show notification
                current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1)
                notify-send "Volume" "🔊 $current_vol" -h "string:x-canonical-private-synchronous:volume-knob" -t 1000
            fi
        fi
    fi
done