{ ... }:

{
  windows = ''
    ##############################
    ### WINDOWS AND WORKSPACES ###
    ##############################

    # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

    windowrule = match:title ^(UnityEngine.*), min_size 200 400, float on
    windowrule = match:title ^(UnityEditor.*), min_size 200 400, float on
    windowrule = match:class ^(ghostty)$, float on
    windowrule = match:class ^(dev.warp.Warp)$, float on
    windowrule = match:title ^(File Operation Progress)$, float on
    windowrule = match:class ^(discord)$, workspace 1
    windowrule = match:class ^(dev.zed.Zed)$, workspace 2
    windowrule = match:class ^(cursor)$, workspace 2
    windowrule = match:class ^(Vivaldi-stable)$, workspace 3
    windowrule = match:class .*, suppress_event maximize
  '';
}
