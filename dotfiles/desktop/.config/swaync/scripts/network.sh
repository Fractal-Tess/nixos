#!/bin/sh

WIFI_STATE=$(nmcli radio wifi)
ETH_IFACE=$(nmcli device status | grep ethernet | awk '{print $1}')
ETH_STATE=$(nmcli device status | grep ethernet | awk '{print $3}')

if [ "$WIFI_STATE" = "enabled" ] || [ "$ETH_STATE" = "connected" ]; then
    nmcli radio wifi off
    [ -n "$ETH_IFACE" ] && nmcli device disconnect "$ETH_IFACE"
    notify-send "Network" "Turned off"
else
    nmcli radio wifi on
    [ -n "$ETH_IFACE" ] && nmcli device connect "$ETH_IFACE"
    notify-send "Network" "Turned on"
fi
