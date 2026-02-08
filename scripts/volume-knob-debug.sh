#!/bin/bash

# Script to capture keyboard events for debugging volume knob issues
# This script will help identify the exact key codes your gaming keyboard sends

echo "🎮 Gaming Keyboard Volume Knob Debug Tool"
echo "=========================================="
echo ""
echo "This script will help identify what events your volume knob generates."
echo "Turn your volume knob or press volume keys when prompted."
echo ""

# Check if we have the required tools
if ! command -v wev &> /dev/null; then
    echo "❌ 'wev' (Wayland event viewer) is not installed."
    echo "Installing wev..."
    if command -v nix &> /dev/null; then
        nix shell nixpkgs#wev --command wev
    else
        echo "Please install wev manually or run: nix shell nixpkgs#wev --command wev"
        exit 1
    fi
fi

echo "📋 Starting event capture..."
echo "📋 Press Ctrl+C to stop capturing"
echo "📋 Turn your volume knob or press volume keys now"
echo ""

# Start capturing keyboard events
wev --type keyboard

echo ""
echo "✅ Event capture stopped."
echo "📝 Look for the keycodes that correspond to your volume knob."
echo "📝 Common volume knob events might be:"
echo "   - Scroll events (276/277)"
echo "   - XF86AudioRaiseVolume/XF86AudioLowerVolume"
echo "   - Custom keycodes specific to your keyboard"
echo ""
echo "🔧 Once you identify the correct keycodes, we can update your Hyprland config."