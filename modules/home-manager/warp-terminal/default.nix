{ pkgs, ... }: {
  home.packages = with pkgs; [ warp-terminal ];
  home.file.".config/warp-terminal" = {
    recursive = true;
    source = ./warp-terminal;
  };
}
