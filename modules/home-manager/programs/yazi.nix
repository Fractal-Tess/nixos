{ pkgs, ... }:

{
  #============================================================================
  # CONFIG
  #============================================================================

  programs.yazi = {
    enable = true;
    extraPackages = with pkgs; [
      file
      wl-clipboard
    ];

    keymap = {
      mgr.prepend_keymap = [
        {
          on = "y";
          run = [
            ''shell -- case "$(file -b --mime-type %h)" in image/*) wl-copy -t "$(file -b --mime-type %h)" < %h ;; *) wl-copy < %h ;; esac''
            "yank"
          ];
          desc = "Copy file content to system clipboard and yank";
        }
        {
          on = [
            "c"
            "z"
          ];
          run = "plugin zip";
          desc = "Zip hovered file/dir";
        }
      ];
    };
  };
}
