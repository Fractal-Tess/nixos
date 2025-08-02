# Script to show detailed session information
# Useful for debugging session management

echo "=== All Sessions ==="
loginctl list-sessions

echo -e "\n=== Active Graphical Session ==="
ACTIVE_SESSION=$(loginctl list-sessions --no-legend | grep "seat0" | awk '{print $1}')

if [ -n "$ACTIVE_SESSION" ]; then
    echo "Active graphical session ID: $ACTIVE_SESSION"
    echo -e "\n=== Session Details ==="
    loginctl show-session "$ACTIVE_SESSION"
else
    echo "No active graphical session found"
fi

echo -e "\n=== Current User Sessions ==="
loginctl show-user "$USER" 
