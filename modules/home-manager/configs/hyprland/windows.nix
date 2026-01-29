{ ... }:

{
  windows = ''
    ##############################
    ### WINDOWS AND WORKSPACES ###
    ##############################

    # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

    windowrule = min_size 200 400, float, match:title ^(UnityEngine.*)
    windowrule = min_size 200 400, float, match:title ^(UnityEditor.*)
    windowrule = float, match:class ^(ghostty)$
    windowrule = float, match:class ^(dev.warp.Warp)$
    windowrule = float, match:title ^(File Operation Progress)$
    windowrule = workspace 1, match:class ^(discord)$
    windowrule = workspace 2, match:class ^(dev.zed.Zed)$
    windowrule = workspace 2, match:class ^(cursor)$
    windowrule = workspace 3, match:class ^(Vivaldi-stable)$
    windowrule = suppress_event maximize, match:class .*
  '';
}
