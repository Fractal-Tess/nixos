#!/usr/bin/env python3
"""
Volume Knob Monitor for KBP7075W Wireless Keyboard
Monitors the horizontal wheel (REL_HWHEEL) events and converts them to volume changes.
"""

import os
import sys
import fcntl
import struct
import subprocess
import time
from typing import Optional

# Input event constants
EV_REL = 0x02
REL_HWHEEL = 0x06
REL_HWHEEL_HI_RES = 0x0c

# Device path - update if needed
DEVICE_PATH = "/dev/input/event259"

def get_current_volume() -> int:
    """Get current volume percentage using pactl."""
    try:
        result = subprocess.run(
            ["pactl", "get-sink-volume", "@DEFAULT_SINK@"],
            capture_output=True,
            text=True,
            check=True
        )
        # Parse volume from pactl output
        # Format: Volume: front-left: 65536 / 100% / 0.00 dB, front-right: 65536 / 100% / 0.00 dB
        for line in result.stdout.split(', '):
            if '%' in line:
                volume_str = line.split('/')[1].strip().replace('%', '')
                return int(volume_str)
    except (subprocess.CalledProcessError, ValueError, IndexError):
        pass
    return 50  # Default to 50% if we can't get current volume

def set_volume(delta: int) -> None:
    """Set volume by a relative amount."""
    try:
        # Calculate new volume
        current = get_current_volume()
        new_volume = max(0, min(100, current + delta))

        # Set new volume
        subprocess.run([
            "pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{new_volume}%"
        ], check=True)

        # Show notification
        volume_icon = "🔊" if new_volume > 0 else "🔇"
        subprocess.run([
            "notify-send", "Volume", f"{volume_icon} {new_volume}%",
            "-h", "string:x-canonical-private-synchronous:volume-knob",
            "-t", "1000"
        ])

    except subprocess.CalledProcessError as e:
        print(f"Error setting volume: {e}")

def toggle_mute() -> None:
    """Toggle mute state."""
    try:
        subprocess.run([
            "pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"
        ], check=True)

        # Check mute status and notify
        result = subprocess.run(
            ["pactl", "get-sink-mute", "@DEFAULT_SINK@"],
            capture_output=True,
            text=True,
            check=True
        )
        is_muted = "Mute: yes" in result.stdout
        status = "🔇 Muted" if is_muted else "🔊 Unmuted"
        subprocess.run([
            "notify-send", "Audio", status,
            "-h", "string:x-canonical-private-synchronous:audio-status"
        ])
    except subprocess.CalledProcessError as e:
        print(f"Error toggling mute: {e}")

def read_input_events(device_path: str) -> None:
    """Read input events from the specified device."""
    try:
        # Open the device
        with open(device_path, 'rb') as device:
            # Make the file non-blocking
            fd = device.fileno()
            flags = fcntl.fcntl(fd, fcntl.F_GETFL)
            fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

            print(f"Monitoring volume knob on {device_path}")
            print("Press Ctrl+C to stop")

            # Event structure - try different formats for compatibility
            # Format: 'long long, long, unsigned short, unsigned short, int' for 64-bit
            event_format = 'llHHI'
            event_size = struct.calcsize(event_format)

            while True:
                try:
                    # Read event
                    event_data = device.read(event_size)
                    if event_data is None or len(event_data) != event_size:
                        time.sleep(0.01)
                        continue

                    # Unpack event
                    try:
                        (tv_sec, tv_usec, type_, code, value) = struct.unpack(event_format, event_data)
                    except struct.error as e:
                        print(f"Error unpacking event: {e}, data length: {len(event_data) if event_data else 'None'}")
                        # Try alternative format if needed
                        if event_format == 'llHHI':
                            try:
                                event_format_alt = 'llHHi'
                                (tv_sec, tv_usec, type_, code, value) = struct.unpack(event_format_alt, event_data)
                            except struct.error:
                                continue

                    # Handle horizontal wheel events
                    if type_ == EV_REL and code in (REL_HWHEEL, REL_HWHEEL_HI_RES):
                        if value != 0:
                            # Normalize the wheel value
                            if code == REL_HWHEEL_HI_RES:
                                # High resolution events need to be divided
                                wheel_delta = value // 120
                            else:
                                wheel_delta = value

                            if wheel_delta > 0:
                                print(f"Volume knob turned right (+{wheel_delta})")
                                set_volume(2 * wheel_delta)  # Adjust sensitivity
                            elif wheel_delta < 0:
                                print(f"Volume knob turned left ({wheel_delta})")
                                set_volume(2 * wheel_delta)  # Adjust sensitivity

                            # Small delay to prevent rapid volume changes
                            time.sleep(0.05)

                except BlockingIOError:
                    # No data available, sleep briefly
                    time.sleep(0.01)
                    continue
                except KeyboardInterrupt:
                    print("\nStopping volume knob monitor...")
                    break
                except Exception as e:
                    print(f"Error reading event: {e}")
                    time.sleep(0.1)

    except PermissionError:
        print(f"Permission denied accessing {device_path}")
        print("Try running with sudo or add your user to the input group:")
        print("sudo usermod -a -G input $USER")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Device {device_path} not found")
        print("Available input devices:")
        subprocess.run(["ls", "-la", "/dev/input/by-id/"])
        sys.exit(1)

def main():
    """Main function."""
    # Check if device exists
    if not os.path.exists(DEVICE_PATH):
        print(f"Error: Device {DEVICE_PATH} not found!")
        print("Please check that your wireless keyboard is connected and update DEVICE_PATH")
        sys.exit(1)

    # Try to read events
    read_input_events(DEVICE_PATH)

if __name__ == "__main__":
    main()