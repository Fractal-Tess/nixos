#!/usr/bin/env bash

# Dynamic workspace switching script
# Swaps workspaces only between active/enabled monitors
# Excludes disabled monitors (like laptop display when docked)

# Get list of active monitors (exclude disabled ones)
get_active_monitors() {
    hyprctl monitors -j | jq -r '.[] | select(.disabled != true) | .name' | head -2
}

# Get the two main active monitors for workspace swapping
get_main_monitors() {
    local active_monitors=($(get_active_monitors))

    # If we have at least 2 active monitors, use the first two
    if [[ ${#active_monitors[@]} -ge 2 ]]; then
        echo "${active_monitors[0]} ${active_monitors[1]}"
        return 0
    elif [[ ${#active_monitors[@]} -eq 1 ]]; then
        # Only one active monitor, notify user
        echo "${active_monitors[0]}"
        return 1
    else
        # No active monitors found
        return 2
    fi
}

# Main function to swap active workspaces
swap_active_workspaces() {
    local monitors=($(get_main_monitors))
    local exit_code=$?

    case $exit_code in
        0)
            # Two or more active monitors - swap workspaces
            local monitor1="${monitors[0]}"
            local monitor2="${monitors[1]}"

            echo "Swapping workspaces between monitor $monitor1 and monitor $monitor2"
            hyprctl dispatch swapactiveworkspaces "$monitor1" "$monitor2"

            # Send notification
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Workspace Switch" "Swapped workspaces between monitors $monitor1 ↔ $monitor2" -t 2000
            fi
            ;;
        1)
            # Only one active monitor
            echo "Only one active monitor found (${monitors[0]}). Cannot swap workspaces."
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Workspace Switch" "Only one active monitor - cannot swap" -t 3000
            fi
            ;;
        2)
            # No active monitors
            echo "No active monitors found."
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Workspace Switch" "No active monitors found" -t 3000
            fi
            ;;
    esac
}

# Show current monitor configuration
show_status() {
    echo "=== Active Monitor Configuration ==="
    hyprctl monitors -j | jq -r '.[] | "\(.id): \(.name) (\(.width)x\(.height)) - Disabled: \(.disabled)"'

    local active_monitors=($(get_active_monitors))
    echo ""
    echo "Active monitor names: ${active_monitors[*]}"
    echo "Total active monitors: ${#active_monitors[@]}"
}

# Help function
show_help() {
    echo "Dynamic Workspace Switcher"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  swap      Swap workspaces between main active monitors (default)"
    echo "  status    Show current monitor configuration"
    echo "  help      Show this help message"
    echo ""
    echo "This script automatically detects active monitors and excludes"
    echo "disabled displays (like laptop screen when docked)."
}

# Main script logic
case "${1:-swap}" in
    "swap"|"")
        swap_active_workspaces
        ;;
    "status")
        show_status
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac