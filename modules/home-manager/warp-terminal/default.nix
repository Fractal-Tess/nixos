{ pkgs, ... }: {
  home.packages = with pkgs; [ warp-terminal ];
  home.file.".config/warp-terminal" = {
    source = ./warp-terminal;
    recursive = true;
  };

}
