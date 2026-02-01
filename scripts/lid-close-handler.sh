#!/usr/bin/env bash

# Script to handle laptop lid close events
# - Always disable eDP-1 when lid is closed
# - Lock system with hyprlock if no external monitors are connected
# - Suspend system if no external monitors are connected (after locking)
# - Always re-enable eDP-1 when lid is opened

# Laptop monitor identifier (usually eDP-1, but check with hyprctl monitors)
LAPTOP_MONITOR="eDP-1"

# Check if any external monitors are connected
# Count monitors excluding the laptop display (eDP-1)
EXTERNAL_MONITORS=$(hyprctl monitors | grep -E "^Monitor [^e]" | wc -l)

# Check if laptop monitor is currently enabled
LAPTOP_MONITOR_ENABLED=$(hyprctl monitors | grep -A 5 "$LAPTOP_MONITOR" | grep -q "disabled" && echo "false" || echo "true")

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /tmp/lid-close-handler.log
}

log_message "Lid handler triggered. External monitors: $EXTERNAL_MONITORS, Laptop monitor enabled: $LAPTOP_MONITOR_ENABLED"

case "$1" in
    "close")
        log_message "Processing lid close event"

        # Always disable laptop monitor when lid is closed
        if [[ "$LAPTOP_MONITOR_ENABLED" == "true" ]]; then
            log_message "Disabling laptop monitor: $LAPTOP_MONITOR"
            hyprctl keyword monitor "$LAPTOP_MONITOR, disable"
            notify-send "Lid Closed" "Laptop screen disabled" -t 3000
        fi

        # Lock and suspend system if no external monitors are connected
        if [[ "$EXTERNAL_MONITORS" -eq 0 ]]; then
            log_message "No external monitors detected - locking system with hyprlock"
            # Give a brief moment for the screen to disable before locking
            sleep 0.5

            # Lock the system first
            log_message "Executing hyprlock"
            (hyprlock &) &
            HYPRLOCK_PID=$!

            # Give hyprlock time to start, then suspend
            sleep 2
            log_message "Suspending system to preserve battery"

            # Try to suspend with proper method (requires sudo/polkit)
            if command -v loginctl >/dev/null 2>&1; then
                # Use loginctl for user-initiated suspend
                loginctl suspend
            elif sudo -n true 2>/dev/null; then
                # Use sudo if no password required
                sudo systemctl suspend
            else
                # Fallback: try polkit agent or notify user
                log_message "Cannot suspend - insufficient privileges"
                notify-send "Suspend Failed" "Cannot suspend - insufficient privileges" -t 5000
            fi

            # When system resumes, hyprlock should still be running
            # Clean up the background hyprlock process if it's still running
            if kill -0 $HYPRLOCK_PID 2>/dev/null; then
                wait $HYPRLOCK_PID
            fi
        else
            log_message "$EXTERNAL_MONITORS external monitor(s) detected - system remains unlocked"
        fi
        ;;

    "open")
        log_message "Processing lid open event"

        # Always re-enable laptop monitor when lid is opened
        log_message "Enabling laptop monitor: $LAPTOP_MONITOR"
        hyprctl keyword monitor "$LAPTOP_MONITOR, preferred, auto, 1"
        # Reload to ensure proper monitor configuration
        hyprctl reload
        notify-send "Lid Opened" "Laptop screen enabled" -t 3000

        # Check if we're resuming from suspend (external monitor count might have changed)
        UPDATED_EXTERNAL_MONITORS=$(hyprctl monitors | grep -c "Monitor\|Display Port\|HDMI" || echo "0")
        log_message "Lid opened with $UPDATED_EXTERNAL_MONITORS external monitor(s) detected"
        ;;

    *)
        echo "Usage: $0 {close|open}"
        echo "  close - Handle lid close event (disable laptop screen, lock + suspend if no external monitors)"
        echo "  open  - Handle lid open event (re-enable laptop screen)"
        exit 1
        ;;
esac