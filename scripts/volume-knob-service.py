#!/usr/bin/env python3
"""
Volume Knob Service for KBP7075W Wireless Keyboard
A simple service to monitor the volume knob and control system volume.
"""

import asyncio
import subprocess
import os
import signal
import sys
from typing import Optional

class VolumeKnobService:
    def __init__(self):
        self.running = True
        self.last_volume_change = 0
        self.debounce_ms = 50  # Debounce volume changes

    async def get_current_volume(self) -> int:
        """Get current volume percentage."""
        try:
            result = await asyncio.create_subprocess_exec(
                'pactl', 'get-sink-volume', '@DEFAULT_SINK@',
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                output = stdout.decode()
                for line in output.split(', '):
                    if '%' in line:
                        volume_str = line.split('/')[1].strip().replace('%', '')
                        return int(volume_str)
        except Exception:
            pass
        return 50

    async def set_volume(self, delta: int) -> None:
        """Set volume by delta percentage."""
        try:
            current = await self.get_current_volume()
            new_volume = max(0, min(100, current + delta))

            # Set volume
            proc = await asyncio.create_subprocess_exec(
                'pactl', 'set-sink-volume', '@DEFAULT_SINK@', f'{new_volume}%'
            )
            await proc.communicate()

            # Show notification
            volume_icon = "🔊" if new_volume > 0 else "🔇"
            notify_proc = await asyncio.create_subprocess_exec(
                'notify-send', 'Volume', f'{volume_icon} {new_volume}%',
                '-h', 'string:x-canonical-private-synchronous:volume-knob',
                '-t', '1000'
            )
            await notify_proc.communicate()

        except Exception as e:
            print(f"Error setting volume: {e}")

    async def monitor_events(self):
        """Monitor input events using the 'wev' command."""
        print("Starting volume knob monitor...")
        print("Using wev to capture keyboard events...")

        # Start wev process to capture keyboard events
        proc = await asyncio.create_subprocess_exec(
            'wev',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        try:
            while self.running:
                line = await proc.stdout.readline()
                if not line:
                    break

                line_str = line.decode().strip()

                # Look for keyboard events that might be volume controls
                # Check for any unusual key codes that might be the volume knob
                if 'keyboard' in line_str and 'key' in line_str:
                    current_time = asyncio.get_event_loop().time() * 1000

                    # Debounce rapid events
                    if current_time - self.last_volume_change < self.debounce_ms:
                        continue

                    # Check for specific key codes that might be volume knob
                    # Some keyboards use unusual key codes for volume knobs
                    if any(code in line_str for code in ['165', '166', '167', '163', '164']):  # Media keys
                        if 'down' in line_str:
                            await self.set_volume(-3)
                            self.last_volume_change = current_time
                        elif 'up' in line_str:
                            await self.set_volume(3)
                            self.last_volume_change = current_time

        except Exception as e:
            print(f"Error monitoring events: {e}")
        finally:
            proc.terminate()
            await proc.wait()

    async def run_alternative_monitor(self):
        """Alternative monitor using input device directly."""
        print("Trying alternative input device monitoring...")

        device_path = "/dev/input/event259"
        if not os.path.exists(device_path):
            print(f"Device {device_path} not found")
            return

        try:
            # Use 'cat' to read raw events and decode them
            proc = await asyncio.create_subprocess_exec(
                'sudo', 'cat', device_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            # Simple binary reading
            while self.running:
                data = await proc.stdout.read(24)  # Standard input event size
                if not data:
                    break

                if len(data) == 24:
                    # Try to decode as input event
                    # struct input_event { timeval time; __u16 type; __u16 code; __s32 value; }
                    import struct
                    try:
                        # Try different struct formats
                        for fmt in ['llHHI', 'llHHi']:
                            try:
                                tv_sec, tv_usec, ev_type, ev_code, ev_value = struct.unpack(fmt, data)

                                # Check for horizontal wheel events
                                if ev_type == 2 and ev_code in [6, 12]:  # EV_REL, REL_HWHEEL variants
                                    if ev_value != 0:
                                        current_time = asyncio.get_event_loop().time() * 1000
                                        if current_time - self.last_volume_change >= self.debounce_ms:
                                            if ev_value > 0:
                                                await self.set_volume(2)
                                                print("Volume knob: increase")
                                            else:
                                                await self.set_volume(-2)
                                                print("Volume knob: decrease")
                                            self.last_volume_change = current_time
                                        break
                            except struct.error:
                                continue
                    except Exception:
                        continue

        except Exception as e:
            print(f"Alternative monitor error: {e}")

    async def run(self):
        """Main service loop."""
        # Set up signal handlers
        def signal_handler(signum, frame):
            print(f"\nReceived signal {signum}, shutting down...")
            self.running = False

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

        print("Volume Knob Service starting...")
        print("Press Ctrl+C to stop")

        # Try wev first, then fall back to direct device monitoring
        try:
            await asyncio.wait_for(self.monitor_events(), timeout=5.0)
        except asyncio.TimeoutError:
            print("wev monitoring timed out, trying alternative approach...")
            await self.run_alternative_monitor()
        except Exception as e:
            print(f"wev monitoring failed: {e}")
            print("Trying alternative approach...")
            await self.run_alternative_monitor()

def main():
    service = VolumeKnobService()

    try:
        asyncio.run(service.run())
    except KeyboardInterrupt:
        print("\nService stopped by user")
    except Exception as e:
        print(f"Service error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()