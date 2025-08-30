#!/usr/bin/env bash

# Brightness control script for waybar
# Supports getting current brightness, adjusting brightness, and turning screens off
# Works on both desktop (i2c/ddcutil) and laptop (brightness/light) systems

# Configuration
STEP=10  # Brightness adjustment step (percentage)

# Detect system type and available tools
detect_brightness_method() {
    # Check for laptop brightness controls first
    if command -v brightnessctl >/dev/null 2>&1 && [[ -d /sys/class/backlight ]]; then
        echo "brightnessctl"
    elif command -v light >/dev/null 2>&1 && [[ -d /sys/class/backlight ]]; then
        echo "light"  
    elif command -v ddcutil >/dev/null 2>&1; then
        # Check if ddcutil can detect any monitors
        if ddcutil detect >/dev/null 2>&1; then
            echo "ddcutil"
        else
            echo "none"
        fi
    else
        echo "none"
    fi
}

# Function to get current brightness percentage
get_brightness() {
    local method=$(detect_brightness_method)
    local brightness=50  # fallback value
    
    case "$method" in
        "brightnessctl")
            brightness=$(brightnessctl get)
            local max=$(brightnessctl max)
            brightness=$((brightness * 100 / max))
            ;;
        "light")
            brightness=$(light -G | cut -d. -f1)
            ;;
        "ddcutil")
            # Get brightness from the primary external monitor
            brightness=$(ddcutil getvcp 10 2>/dev/null | grep -oP 'current value = \K\d+' | head -1)
            if [[ -z "$brightness" ]]; then
                brightness=50
            fi
            ;;
        *)
            brightness=50  # fallback if no method available
            ;;
    esac
    
    echo "$brightness"
}

# Function to set brightness percentage
set_brightness() {
    local value=$1
    local method=$(detect_brightness_method)
    
    # Ensure value is within bounds
    if (( value < 0 )); then value=0; fi
    if (( value > 100 )); then value=100; fi
    
    case "$method" in
        "brightnessctl")
            brightnessctl set "${value}%" >/dev/null 2>&1
            ;;
        "light")
            light -S "$value" >/dev/null 2>&1
            ;;
        "ddcutil")
            # Set brightness on all detected monitors using the same method as brightness.sh
            for bus in $(ddcutil detect 2>/dev/null | grep 'I2C bus' | awk '{print $3}' | sed 's/.*-//g'); do
                ddcutil --bus "$bus" --sleep-multiplier .1 setvcp 10 "$value" 2>/dev/null
            done
            ;;
        *)
            # No brightness control available
            ;;
    esac
}

# Function to turn screens off (using the same method as Meta+M in hyprland)
turn_screens_off() {
    # Use the existing screen-manager script which handles monitor control
    ~/nixos/scripts/screen-manager.sh off 2>/dev/null
}

# Function to output JSON for waybar
output_waybar_json() {
    local brightness=$(get_brightness)
    local method=$(detect_brightness_method)
    local method_text=""
    
    case "$method" in
        "brightnessctl") method_text=" (brightnessctl)" ;;
        "light") method_text=" (light)" ;;
        "ddcutil") method_text=" (ddcutil)" ;;
        "none") method_text=" (no control)" ;;
    esac
    
    local tooltip="Brightness: ${brightness}%${method_text}\nScroll: adjust brightness\nClick: turn screens off"
    
    # Create JSON output for waybar
    cat << EOF
{
    "text": "☀ ${brightness}%",
    "tooltip": "$tooltip",
    "class": "brightness",
    "percentage": $brightness
}
EOF
}

# Main script logic
case "${1:-}" in
    "up")
        current=$(get_brightness)
        new_brightness=$((current + STEP))
        set_brightness $new_brightness
        ;;
    "down")
        current=$(get_brightness)
        new_brightness=$((current - STEP))
        set_brightness $new_brightness
        ;;
    "off")
        turn_screens_off
        ;;
    "get")
        get_brightness
        ;;
    *)
        # Default: output JSON for waybar
        output_waybar_json
        ;;
esac