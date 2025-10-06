#!/usr/bin/env bash

# Simple wallpaper startup script for linux-wallpaperengine
# This script starts wallpaper engine on all detected screens using secrets

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SECRETS_DIR="${HOME}/.config/secrets/linux-wallpaperengine"
readonly LOG_PREFIX="[wallpaper]"

# Default values
readonly DEFAULT_SCALING_MODE="fill"
readonly VALID_SCALING_MODES=("fill" "fit" "stretch" "center" "tile")

# Global variables
declare -a screens=()
scaling_mode="${1:-${DEFAULT_SCALING_MODE}}"

# Function to map monitor to wallpaper ID
map_monitor_to_wallpaper_id() {
    local screen="$1"
    local secret_file="${SECRETS_DIR}/${screen}"

    if [[ -f "$secret_file" ]]; then
        local id
        id=$(cat "$secret_file" 2>/dev/null || true)
        if [[ -n "$id" && "$id" =~ ^[0-9]+$ ]]; then
            echo "$id"
            return 0
        fi
    fi

    local any_file="${SECRETS_DIR}/ANY"
    if [[ -f "$any_file" ]]; then
        local id
        id=$(cat "$any_file" 2>/dev/null || true)
        if [[ -n "$id" && "$id" =~ ^[0-9]+$ ]]; then
            echo "$id"
            return 0
        fi
    fi
    
    return 1
}

# Function to show help
show_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [SCALING_MODE]

Start linux-wallpaperengine on all detected screens using secrets.

ARGUMENTS:
    SCALING_MODE    Scaling mode for wallpapers (default: ${DEFAULT_SCALING_MODE})
                    Valid modes: ${VALID_SCALING_MODES[*]}

EXAMPLES:
    ${SCRIPT_NAME}                    # Use default scaling mode
    ${SCRIPT_NAME} fit                # Use 'fit' scaling mode
    ${SCRIPT_NAME} stretch            # Use 'stretch' scaling mode

SECRETS:
    Wallpaper IDs are read from: ${SECRETS_DIR}/
    - Create files named after monitor names (e.g., DP-1, HDMI-A-1)
    - Create 'ANY' file for fallback wallpaper ID
    - Each file should contain only a numeric wallpaper ID

EOF
}

# Function to validate scaling mode
validate_scaling_mode() {
    local mode="$1"
    for valid_mode in "${VALID_SCALING_MODES[@]}"; do
        if [[ "$mode" == "$valid_mode" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to log messages
log() {
    echo "${LOG_PREFIX} $*" >&2
}

# Function to log errors
log_error() {
    echo "${LOG_PREFIX} ERROR: $*" >&2
}

# Function to kill existing wallpaper processes
kill_existing_wallpapers() {
    local pids
    # Only match the actual linux-wallpaperengine binary, not this script
    pids=$(pgrep -x "linux-wallpaperengine" 2>/dev/null || true)
    
    if [[ -n "$pids" ]]; then
        log "Killing existing wallpaper processes: $pids"
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        
        # Wait a moment for graceful shutdown
        sleep 1
        
        # Force kill if still running
        pids=$(pgrep -x "linux-wallpaperengine" 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            log "Force killing remaining processes: $pids"
            echo "$pids" | xargs kill -KILL 2>/dev/null || true
        fi
    else
        log "No existing wallpaper processes found"
    fi
}

# Function to detect screens
detect_screens() {
    if command -v hyprctl &> /dev/null; then
        mapfile -t screens < <(hyprctl monitors | grep -E '^Monitor\s+' | awk '{print $2}')
    elif command -v xrandr &> /dev/null; then
        mapfile -t screens < <(xrandr --listactivemonitors | grep -E '^[0-9]+:' | awk '{print $4}')
    else
        log_error "No xrandr or hyprctl found"
        return 1
    fi
}


# Main function
main() {
    # Kill existing wallpaper processes first
    kill_existing_wallpapers
    
    # Validate scaling mode
    if ! validate_scaling_mode "$scaling_mode"; then
        log_error "Invalid scaling mode: '$scaling_mode'"
        log "Valid modes: ${VALID_SCALING_MODES[*]}"
        exit 1
    fi

    # Detect screens
    if ! detect_screens; then
        exit 1
    fi

    if [[ ${#screens[@]} -eq 0 ]]; then
        log_error "No screens detected, exiting."
        exit 1
    fi

    log "Starting wallpaper on screens: ${screens[*]}"

    local started_count=0
    for screen in "${screens[@]}"; do
        local wallpaper_id
        if wallpaper_id=$(map_monitor_to_wallpaper_id "$screen"); then
            log "Starting on $screen (ID: $wallpaper_id)"
            echo screen: $screen
            echo wallpaper_id: $wallpaper_id
            echo scaling_mode: $scaling_mode

            if nohup linux-wallpaperengine \
                --screen-root "$screen" \
                --bg "$wallpaper_id" \
                --scaling "$scaling_mode" \
                > /dev/null 2>&1 & then
                ((started_count++))
            else
                log_error "Failed to start wallpaper on $screen"
            fi
        else
            log_error "No wallpaper ID found for screen: $screen"
        fi
    done

    if [[ $started_count -gt 0 ]]; then
        log "Wallpaper engine started on $started_count screen(s)"
    else
        log_error "Failed to start wallpaper on any screen"
        exit 1
    fi
}

# Handle command line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            scaling_mode="$1"
            ;;
    esac
fi

# Run main function
main
