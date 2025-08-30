#!/usr/bin/env bash

# Brightness control script for waybar
# Supports getting current brightness, adjusting brightness, and turning screens off
# Works on both desktop (i2c/ddcutil) and laptop (brightness/light) systems

# Configuration
STEP=10  # Brightness adjustment step (percentage)
CACHE_FILE="/tmp/brightness-cache"  # Cache file to avoid slow i2c calls

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

# Function to initialize cache file if it doesn't exist
init_brightness_cache() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        local method=$(detect_brightness_method)
        local initial_brightness=50  # default fallback
        
        case "$method" in
            "brightnessctl")
                local current=$(brightnessctl get 2>/dev/null)
                local max=$(brightnessctl max 2>/dev/null)
                if [[ -n "$current" && -n "$max" && $max -gt 0 ]]; then
                    initial_brightness=$((current * 100 / max))
                fi
                ;;
            "light")
                local current=$(light -G 2>/dev/null | cut -d. -f1)
                if [[ -n "$current" && "$current" =~ ^[0-9]+$ ]]; then
                    initial_brightness=$current
                fi
                ;;
            "ddcutil")
                # Only query once on initialization to avoid lag
                local ddcutil_output=$(ddcutil getvcp 10 2>/dev/null)
                local current=$(echo "$ddcutil_output" | grep -oP 'current value =\s*\K\d+' | head -1)
                if [[ -n "$current" && "$current" =~ ^[0-9]+$ ]]; then
                    initial_brightness=$current
                fi
                ;;
        esac
        
        echo "$initial_brightness" > "$CACHE_FILE"
    fi
}

# Function to get current brightness percentage from cache
get_brightness() {
    init_brightness_cache
    
    if [[ -f "$CACHE_FILE" ]]; then
        local cached_value=$(cat "$CACHE_FILE" 2>/dev/null)
        if [[ "$cached_value" =~ ^[0-9]+$ ]] && (( cached_value >= 0 && cached_value <= 100 )); then
            echo "$cached_value"
            return
        fi
    fi
    
    # Fallback if cache is corrupted or missing
    echo "50"
}

# Function to set brightness percentage and update cache
set_brightness() {
    local value=$1
    local method=$(detect_brightness_method)

    # Ensure value is within bounds
    if (( value < 0 )); then value=0; fi
    if (( value > 100 )); then value=100; fi

    # Update cache first for immediate feedback
    echo "$value" > "$CACHE_FILE"

    # Set actual brightness in background to avoid lag
    case "$method" in
        "brightnessctl")
            brightnessctl set "${value}%" >/dev/null 2>&1 &
            ;;
        "light")
            light -S "$value" >/dev/null 2>&1 &
            ;;
        "ddcutil")
            # Set brightness on all detected monitors in background
            {
                local buses=$(ddcutil detect 2>/dev/null | grep 'I2C bus' | awk '{print $3}' | sed 's/.*-//g')
                for bus in $buses; do
                    ddcutil --bus "$bus" --sleep-multiplier .1 setvcp 10 "$value" 2>/dev/null
                done
            } &
            ;;
        *)
            # No brightness control method available
            ;;
    esac
}

# Function to turn screens off (using the same method as Meta+M in hyprland)
turn_screens_off() {
    # Use the existing screen-manager script which handles monitor control
    ~/nixos/scripts/screen-manager.sh off 2>/dev/null
}

# Function to output JSON for waybar (single line format like nvidia script)
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

    local tooltip="Brightness: ${brightness}%${method_text}\\rScroll: adjust brightness\\rClick: turn screens off"

    # Output single-line JSON for waybar (like nvidia script)
    printf '{"percentage": %d, "text": "☀ %d%%", "tooltip": "%s", "class": "brightness"}\n' "$brightness" "$brightness" "$tooltip"
}

# Function to display help message
show_help() {
    cat << EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

A cross-platform brightness control utility for desktop and laptop systems.
Supports ddcutil (i2c monitors), brightnessctl, and light backends.

COMMANDS:
    get                 Get current brightness percentage
    set <percentage>    Set brightness to specific percentage (0-100)
    up [step]          Increase brightness (default: ${STEP}%)
    down [step]        Decrease brightness (default: ${STEP}%)
    off                Turn screens off
    json               Output JSON format for waybar
    help, -h, --help   Show this help message

EXAMPLES:
    $(basename "$0") get              # Show current brightness
    $(basename "$0") set 75           # Set brightness to 75%
    $(basename "$0") up               # Increase brightness by ${STEP}%
    $(basename "$0") up 20            # Increase brightness by 20%
    $(basename "$0") down 5           # Decrease brightness by 5%
    $(basename "$0") off              # Turn screens off

BACKEND DETECTION:
    Automatically detects available brightness control method:
    - ddcutil: External monitors via i2c/DDC-CI
    - brightnessctl: Laptop backlight control
    - light: Alternative laptop backlight control

For waybar integration, use 'json' command or call without arguments.
EOF
}

# Main script logic
case "${1:-}" in
    "get")
        get_brightness
        exit 0
        ;;
    "set")
        if [[ -z "$2" ]]; then
            echo "Error: set command requires a percentage argument (0-100)" >&2
            exit 1
        fi
        if ! [[ "$2" =~ ^[0-9]+$ ]] || (( $2 < 0 || $2 > 100 )); then
            echo "Error: brightness percentage must be a number between 0-100" >&2
            exit 1
        fi
        set_brightness "$2"
        echo "Brightness set to $2%"
        exit 0
        ;;
    "up")
        current=$(get_brightness)
        step="${2:-$STEP}"
        if ! [[ "$step" =~ ^[0-9]+$ ]] || (( step < 1 || step > 100 )); then
            echo "Error: step must be a number between 1-100" >&2
            exit 1
        fi
        new_brightness=$((current + step))
        set_brightness $new_brightness
        echo "Brightness increased by ${step}% (${current}% → ${new_brightness}%)"
        exit 0
        ;;
    "down")
        current=$(get_brightness)
        step="${2:-$STEP}"
        if ! [[ "$step" =~ ^[0-9]+$ ]] || (( step < 1 || step > 100 )); then
            echo "Error: step must be a number between 1-100" >&2
            exit 1
        fi
        new_brightness=$((current - step))
        set_brightness $new_brightness
        echo "Brightness decreased by ${step}% (${current}% → ${new_brightness}%)"
        exit 0
        ;;
    "off")
        echo "Turning screens off..."
        turn_screens_off
        exit 0
        ;;
    "json")
        output_waybar_json 2>/dev/null
        exit 0
        ;;
    "help"|"-h"|"--help")
        show_help
        exit 0
        ;;
    "")
        # No arguments provided - show help
        show_help
        exit 0
        ;;
    *)
        echo "Error: Unknown command '$1'" >&2
        echo "Use '$(basename "$0") help' for usage information." >&2
        exit 1
        ;;
esac
