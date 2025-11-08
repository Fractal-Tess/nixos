#!/bin/bash

# Script to help set up a gaming keyboard via Bluetooth
# This script provides an interactive setup process for Bluetooth keyboards

echo "🎮 Gaming Keyboard Bluetooth Setup"
echo "=================================="
echo ""

# Check if Bluetooth service is running
if ! systemctl is-active --quiet bluetooth; then
    echo "❌ Bluetooth service is not running."
    echo "🔧 Starting Bluetooth service..."
    sudo systemctl start bluetooth
    sudo systemctl enable bluetooth
fi

echo "✅ Bluetooth service is running"
echo ""

# Scan for devices
echo "🔍 Scanning for Bluetooth devices..."
echo "📝 Make sure your keyboard is in pairing mode (usually Bluetooth mode + pairing button)"
echo ""

# Start scanning
sudo bluetoothctl scan on &
SCAN_PID=$!

# Wait for devices to be discovered
sleep 10

# Stop scanning
sudo bluetoothctl scan off
kill $SCAN_PID 2>/dev/null

echo ""
echo "📋 Available Bluetooth devices:"
echo ""

# List discovered devices
sudo bluetoothctl devices | while read line; do
    echo "  $line"
done

echo ""
echo "🔧 Pairing Instructions:"
echo "1. Find your keyboard in the list above"
echo "2. Copy the MAC address (e.g., XX:XX:XX:XX:XX:XX)"
echo "3. Run: bluetoothctl connect XX:XX:XX:XX:XX:XX"
echo "4. If prompted for a PIN, enter the code shown on your keyboard"
echo ""
echo "💡 Quick Commands:"
echo "  - List devices: bluetoothctl devices"
echo "  - Connect: bluetoothctl connect <MAC_ADDRESS>"
echo "  - Disconnect: bluetoothctl disconnect <MAC_ADDRESS>"
echo "  - Remove device: bluetoothctl remove <MAC_ADDRESS>"
echo "  - Trust device: bluetoothctl trust <MAC_ADDRESS>"
echo ""
echo "📱 GUI Options:"
echo "  - Use 'blueman' for graphical Bluetooth management"
echo "  - Use 'bluetuith' for terminal-based Bluetooth management"
echo ""
echo "🎯 After connecting:"
echo "1. Test your volume knob in Bluetooth mode"
echo "2. Run 'wev' in terminal to see keyboard events"
echo "3. If volume knob works, you're all set!"
echo ""
echo "🔄 If it still doesn't work, try these troubleshooting steps:"
echo "1. Restart Bluetooth service: sudo systemctl restart bluetooth"
echo "2. Remove and re-pair the device"
echo "3. Check if keyboard supports HID profiles in Bluetooth mode"
echo "4. Some keyboards need specific firmware updates for full Bluetooth functionality"