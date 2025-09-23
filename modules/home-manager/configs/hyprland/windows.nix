{ ... }:

{
  windows = ''
    ##############################
    ### WINDOWS AND WORKSPACES ###
    ##############################

    # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

    windowrulev2 = minsize 200 400, float, title:^(UnityEngine.*)
    windowrulev2 = minsize 200 400, float, title:^(UnityEditor.*)
    windowrulev2 = float, class:^(kitty)$
    windowrulev2 = float, class:^(dev.warp.Warp)$
    windowrulev2 = float, title:^(File Operation Progress)$
    windowrulev2 = workspace 1, class:^(discord)$
    windowrulev2 = workspace 2, class:^(dev.zed.Zed)$
    windowrulev2 = workspace 2, class:^(cursor)$
    windowrulev2 = workspace 3, class:^(Vivaldi-stable)$

    windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.
  '';
}