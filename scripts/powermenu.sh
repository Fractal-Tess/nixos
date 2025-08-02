# Pkill wofi 
pkill wofi

# Define the options
entries="⇠ Logout\n⏾ Suspend\n⭮ Reboot\n⏻ Shutdown"

# Use wofi to display the menu and get user selection
selected=$(echo -e "$entries" | wofi --width 250 --height 210 -p 'Power Menu:' --dmenu --cache-file /dev/null | awk '{print tolower($2)}')

# Perform action based on selection
case "$selected" in
    logout)
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch exit
        else
            loginctl terminate-user "$USER"
        fi
        ;;
    suspend)
        systemctl suspend
        ;;
    reboot)
        systemctl reboot
        ;;
    shutdown)
        systemctl poweroff
        ;;
esac
