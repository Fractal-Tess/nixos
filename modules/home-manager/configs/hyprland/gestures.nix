{ ... }:

{
  gestures = ''
    #############
    ### INPUT ###
    #############

    # https://wiki.hyprland.org/Configuring/Variables/#input
    input {
      kb_layout = us,bg
      kb_options =  grp:alt_shift_toggle
      kb_variant =,phonetic

      follow_mouse = 1

      sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

      touchpad {
          natural_scroll = false
      }
    }

    # https://wiki.hyprland.org/Configuring/Variables/#gestures
    # Gesture syntax: gesture = fingers, direction, action, options

    # Workspace navigation
    gesture = 3, left, workspace, +1
    gesture = 3, right, workspace, -1

    # Window management
    gesture = 3, up, fullscreen
    gesture = 3, down, close
    gesture = 4, up, float
    gesture = 4, down, move
    gesture = 4, left, resize
    gesture = 4, right, resize

    # Special workspace
    gesture = 3, up, mod: SUPER, special, magic

    # Example per-device config
    # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
    device {
      name = epic-mouse-v1
      sensitivity = -0.5
    }
  '';
}