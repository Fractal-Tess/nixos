{ ... }:

{
  keybindings = ''
    ####################
    ### KEYBINDINGSS ###
    ####################

    # See https://wiki.hyprland.org/Configuring/Keywords/
    $mainMod = SUPER # Sets "Windows" key as main modifier

    # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
    #
    # Managing windows
    bind = $mainMod, P, exec, $menu
    bind = $mainMod SHIFT, Q, killactive
    bind = $mainMod, Return, exec, $terminal
    bind = $mainMod, F, togglefloating
    bind = $mainMod SHIFT, F, fullscreen

    # Swap
    bind = $mainMod, W, swapactiveworkspaces, 0 1

    bind = $mainMod SHIFT, H, movewindow, l
    bind = $mainMod SHIFT, L, movewindow, r
    bind = $mainMod SHIFT, K, movewindow, u
    bind = $mainMod SHIFT, J, movewindow, d

    # Send to other monitor
    bind = $mainMod SHIFT, W, movewindow, mon:+1

    # Resize
    bind = $mainMod Alt, H, resizeactive, -60 0
    bind = $mainMod Alt, L, resizeactive, 60 0

    # Moving
    bind = $mainMod, LEFT, moveactive, -60 0
    bind = $mainMod, UP, moveactive, 0 -60
    bind = $mainMod, DOWN, moveactive, 0 60
    bind = $mainMod, RIGHT, moveactive, 60 0

    # Spawning
    bind = $mainMod, A, exec, $browser
    bind = $mainMod, C, exec, cursor
    bind = $mainMod, D, exec, discord
    bind = $mainMod, E, exec, $fileManager
    bind = $mainMod, V, exec, $editor
    bind = $mainMod, y, exec, $browser https://youtube.com
    bind = $mainMod, g, exec, $browser https://github.com
    bind = $mainMod, h, exec, ~/nixos/scripts/cliphistory.sh

    # Screenshot
    bind = $mainMod SHIFT, X, exec, ~/nixos/scripts/screenshot.sh

    # Color picker
    bind = $mainMod, Z, exec, hyprpicker

    # Wallpaper engine
    bind = $mainMod, B, exec, ~/nixos/scripts/linux-wallpaperengine/wallpaper.sh
    bind = $mainMod SHIFT, B, exec, ~/nixos/scripts/linux-wallpaperengine/wallpaper.sh fit

    # Lock screen
    bind = $mainMod, L, exec, hyprlock

    # Exiting wayland
    bind = $mainMod SHIFT, L, exit,

    # Switch workspaces with mainMod + [0-6]
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6

    # bind = $mainMod, 1, exec, hyprctl dispatch focusmonitor cursor && hyprctl dispatch workspace 1
    # bind = $mainMod, 2, exec, hyprctl dispatch focusmonitor cursor && hyprctl dispatch workspace 2
    # bind = $mainMod, 3, exec, hyprctl dispatch focusmonitor cursor && hyprctl dispatch workspace 3
    # bind = $mainMod, 4, exec, hyprctl dispatch focusmonitor cursor && hyprland dispatch workspace 4
    # bind = $mainMod, 5, exec, hyprctl dispatch focusmonitor cursor && hyprctl dispatch workspace 5
    #
    # Move active window to a workspace with mainMod + SHIFT + [0-6]
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6

    # Example special workspace (scratchpad)
    bind = $mainMod, S, togglespecialworkspace, magic
    bind = $mainMod SHIFT, S, movetoworkspace, special:magic

    # Scroll through existing workspaces with mainMod + scroll
    # bind = $mainMod, mouse_down, workspace, e+1
    # bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    # Power menu
    bind = $mainMod, ESCAPE, exec, ~/nixos/scripts/powermenu.sh

    # Restart Waybar
    bind = $mainMod SHIFT, R, exec, pkill waybar && waybar &
    # Toggle Waybar visibility
    bind = $mainMod SHIFT, T, exec, ~/nixos/scripts/waybar-toggle.sh

    # Volume Controls with correct keycodes and XF86Audio symbols
    # Volume Up (XF86AudioRaiseVolume - 123)
    bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%

    # Volume Down (XF86AudioLowerVolume - 122)
    bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%

    # Default mute toggle using standard mute key
    bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle && notify-send "Audio" "$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo '🔇 Muted' || echo '🔊 Unmuted')" -h string:x-canonical-private-synchronous:audio-status

    # Mic mute
    bind = , XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle && notify-send "Microphone" "$(pactl get-source-mute @DEFAULT_SOURCE@ | grep -q 'yes' && echo '🎤 Muted' || echo '🎤 Unmuted')" -h string:x-canonical-private-synchronous:mic-status

    # Brightness Controls using light
    # Brightness Up (XF86MonitorBrightnessUp - usually 232)
    bind = , XF86MonitorBrightnessUp, exec, light -A 5 && notify-send "Brightness: $(light -G | cut -d'.' -f1)%"

    # Brightness Down (XF86MonitorBrightnessDown - usually 233)
    bind = , XF86MonitorBrightnessDown, exec, light -U 5 && notify-send "Brightness: $(light -G | cut -d'.' -f1)%"

    # --- MEDIA KEYS ---
    # Play/Pause
    bind = , XF86AudioPlay, exec, playerctl play-pause
    # Next Track
    bind = , XF86AudioNext, exec, playerctl next
    # Previous Track
    bind = , XF86AudioPrev, exec, playerctl previous
    # Stop
    bind = , XF86AudioStop, exec, playerctl stop
    # Eject
    bind = , XF86Eject, exec, notify-send "Eject pressed"
    # Calculator
    bind = , XF86Calculator, exec, gnome-calculator
    # Home Page
    bind = , XF86HomePage, exec, $browser
    # Email
    bind = , XF86Mail, exec, notify-send "Mail key pressed"
    # Print Screen (Screenshot)
    bind = , Print, exec, ~/nixos/scripts/screenshot.sh
    # Screen Lock
    bind = , XF86ScreenSaver, exec, loginctl lock-session
    # Sleep
    bind = , XF86Sleep, exec, systemctl suspend
    # Touchpad Toggle
    bind = , XF86TouchpadToggle, exec, notify-send "Touchpad toggle pressed"
    # Touchpad On/Off
    bind = , XF86TouchpadOn, exec, notify-send "Touchpad enabled"
    bind = , XF86TouchpadOff, exec, notify-send "Touchpad disabled"
    # Display Toggle
    bind = , XF86Display, exec, notify-send "Display key pressed"

    # Monitor Controls
    bind = $mainMod, M, exec, ~/nixos/scripts/screen-manager.sh off && notify-send "Monitors" "🔴 Turned off" -h string:x-canonical-private-synchronous:monitor-status
    bind = $mainMod SHIFT, M, exec, ~/nixos/scripts/screen-manager.sh on && notify-send "Monitors" "🟢 Turned on" -h string:x-canonical-private-synchronous:monitor-status
    # Battery
    bind = , XF86Battery, exec, notify-send "Battery key pressed"
    # WWW Search
    bind = , XF86Search, exec, $browser https://www.google.com
  '';
}
