#!/usr/bin/env bash
# Simple test to check if volume knob is detected

echo "Testing volume knob detection..."
echo "Turn the volume knob on your keyboard now."
echo "Press Ctrl+C to stop testing."

# Test 1: Check with evtest if available
if command -v evtest &> /dev/null; then
    echo "=== Testing with evtest ==="
    echo "Monitoring /dev/input/event259 (KBP7075W Keyboard)"
    echo "Look for REL_HWHEEL events when you turn the knob."
    echo ""
    timeout 30s evtest /dev/input/event259 2>/dev/null | grep -E "(REL_HWHEEL|VOLUME|HWHEEL)" || echo "No evtest events detected in 30 seconds."
else
    echo "evtest not available, installing temporarily..."
    nix-shell -p evtest --run "timeout 30s evtest /dev/input/event259 2>/dev/null | grep -E '(REL_HWHEEL|VOLUME|HWHEEL)'" || echo "No evtest events detected in 30 seconds."
fi

echo ""
echo "=== Test 2: Check with wev ==="
echo "Starting wev for 15 seconds. Turn the volume knob now."
echo "Look for any keyboard events with unusual key codes."
timeout 15s wev 2>/dev/null | grep -E "(keyboard|key)" | tail -10 || echo "No wev keyboard events detected."

echo ""
echo "=== Test 3: Direct device monitoring ==="
echo "Monitoring raw events for 15 seconds..."
timeout 15s sudo hexdump -C /dev/input/event259 2>/dev/null | head -20 || echo "No raw events detected."

echo ""
echo "=== Summary ==="
echo "If you see any events above when turning the volume knob, the device is working."
echo "If not, there might be a connection issue or the volume knob uses a different device."