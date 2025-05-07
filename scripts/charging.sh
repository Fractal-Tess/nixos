
# Check if the battery exists
if [ ! -d "/sys/class/power_supply/BAT0" ]; then
    echo "No battery found"
    exit 1
fi

# Get battery status
status=$(cat /sys/class/power_supply/BAT0/status)
capacity=$(cat /sys/class/power_supply/BAT0/capacity)

# Display information
echo "Battery Status: $status"
echo "Battery Level: $capacity%"

# Check if charging
if [ "$status" = "Charging" ]; then
    echo "Laptop is currently charging"
elif [ "$status" = "Full" ]; then
    echo "Battery is fully charged"
elif [ "$status" = "Discharging" ]; then
    echo "Laptop is running on battery power"
else
    echo "Unknown battery state: $status"
fi
