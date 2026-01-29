{ ... }:

{
  windows = ''
    ##############################
    ### WINDOWS AND WORKSPACES ###
    ##############################

    # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

    windowrule = minsize 200 400, float, title:^(UnityEngine.*)
    windowrule = minsize 200 400, float, title:^(UnityEditor.*)
    windowrule = float, class:^(ghostty)$
    windowrule = float, class:^(dev.warp.Warp)$
    windowrule = float, title:^(File Operation Progress)$
    windowrule = workspace 1, class:^(discord)$
    windowrule = workspace 2, class:^(dev.zed.Zed)$
    windowrule = workspace 2, class:^(cursor)$
    windowrule = workspace 3, class:^(Vivaldi-stable)$
    windowrule = suppress_event maximize, class:.*
  '';
}
