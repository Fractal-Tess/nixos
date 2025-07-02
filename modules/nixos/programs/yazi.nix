{ pkgs, ... }: {
  programs.yazi = {
    enable = true;
    plugins = { "compress.yazi" = ./compress.yazi; };
    settings = {
      keymap = {
        manager = {
          prepend_keymap = [
            {
              on = [ "c" "a" "a" ];
              run = "plugin compress";
              desc = "Archive selected files";
            }
            {
              on = [ "c" "a" "p" ];
              run = "plugin compress -p";
              desc = "Archive selected files (password)";
            }
            {
              on = [ "c" "a" "h" ];
              run = "plugin compress -ph";
              desc = "Archive selected files (password+header)";
            }
            {
              on = [ "c" "a" "l" ];
              run = "plugin compress -l";
              desc = "Archive selected files (compression level)";
            }
            {
              on = [ "c" "a" "u" ];
              run = "plugin compress -phl";
              desc = "Archive selected files (password+header+level)";
            }
          ];
        };
      };
    };
  };
}
