#!/usr/bin/env bash

# Audio sink switching script for waybar
# Usage:
#   audio-sink-switch.sh          - Toggle mute/unmute current sink (left-click)
#   audio-sink-switch.sh next     - Switch to next sink (right-click)

STATE_FILE="/tmp/audio_sink_state"

# Get current default sink ID (look specifically in Sinks section)
current=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep '\*' | grep -o '\*[[:space:]]*[0-9]\+' | grep -o '[0-9]\+')

# Get all available sink IDs (all sinks, not just Analog Stereo)
sinks=($(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '[0-9]+\.' | sed 's/.*[[:space:]]\([0-9]\+\)\. .*/\1/'))

# Debug output (uncomment to see what's found)
# echo "Current: $current"
# echo "Sinks: ${sinks[@]}"

# Check if current sink is muted
is_muted=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep '\*' | grep -q 'MUTED' && echo "true" || echo "false")

# If script is called with "next" argument, switch to next sink
if [ "$1" = "next" ]; then
    if [ ${#sinks[@]} -gt 1 ]; then
        # Save current sink as previous for potential future use
        echo "$current" > "$STATE_FILE"

        for i in "${!sinks[@]}"; do
            if [[ "${sinks[$i]}" == "$current" ]]; then
                next=$(( (i+1) % ${#sinks[@]} ))
                wpctl set-default ${sinks[$next]}
                echo "Switched to sink: ${sinks[$next]}"
                exit 0
            fi
        done
    else
        echo "Only one sink available"
        exit 1
    fi
fi

# Default operation: toggle mute/unmute current sink
if [ -n "$current" ]; then
    if [ "$is_muted" = "true" ]; then
        wpctl set-mute "$current" 0
        echo "Unmuted sink: $current"
    else
        wpctl set-mute "$current" 1
        echo "Muted sink: $current"
    fi
else
    echo "No active sink found"
    exit 1
fi