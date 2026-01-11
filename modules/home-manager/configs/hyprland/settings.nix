{ ... }:

{
  settings = ''
    # This is an example Hyprland config file.
    # Refer to the wiki for more information.
    # https://wiki.hyprland.org/Configuring/Configuring-Hyprland/

    # Please note not all available settings / options are set here.
    # For a full list, see the wiki

    # You can split this configuration into multiple files
    # Create your files separately and then link them to this file like this:
    # source = ~/.config/hypr/myColors.conf

    ###################
    ### MY PROGRAMS ###
    ###################

    # See https://wiki.hyprland.org/Configuring/Keywords/

    # Set programs that you use
    $terminal = ghostty
    $fileManager = thunar
    $menu = wofi --show drun
    $browser = vivaldi --remote-debugging-port=9222
    $editor = cursor

    general {
      gaps_in = 4
      gaps_out = 8

      border_size = 1

      # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
      col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
      col.inactive_border = rgba(595959aa)

      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = false

      layout = dwindle
    }

    # https://wiki.hyprland.org/Configuring/Variables/#decoration
    decoration {
      rounding = 10

      # Change transparency of focused and unfocused windows
      active_opacity = 1.0
      inactive_opacity = 1.0

      # drop_shadow = true
      # shadow_range = 4
      # shadow_render_power = 3
      # col.shadow = rgba(1a1a1aee)

      # https://wiki.hyprland.org/Configuring/Variables/#blur
      blur {
          enabled = true
          size = 3
          passes = 1

          vibrancy = 0.1696
      }
    }

    # https://wiki.hyprland.org/Configuring/Variables/#animations
    animations {
      enabled = true

      # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

      bezier = myBezier, 0.05, 0.9, 0.1, 1.05

      animation = windows, 1, 5, myBezier
      animation = windowsOut, 1, 5, default, popin 80%
      animation = border, 1, 8, default
      animation = borderangle, 1, 8, default
      animation = fade, 1, 5, default
      animation = workspaces, 1, 4, default
    }

    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    dwindle {
      pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = true # You probably want this
    }

    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    master {
      new_status = master
    }

    # https://wiki.hyprland.org/Configuring/Variables/#misc
    misc {
      disable_hyprland_logo = true # If true disables the random hyprland logo / anime girl background. :(
      on_focus_under_fullscreen = 2  # optional: controls behavior when spawning on fullscreen workspace
      enable_swallow = true                 # optional: window swallowing behavior
      mouse_move_focuses_monitor = true     # ensures proper focus behavior
      mouse_move_enables_dpms = true        # optional: prevents screen timeout issues
      force_default_wallpaper = 0           # reduces startup lag
    }
  '';
}