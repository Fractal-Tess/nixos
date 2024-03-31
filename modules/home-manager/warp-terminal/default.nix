{ pkgs, ... }: {
  home.packages = with pkgs; [ warp-terminal ];
  home.file.".config/test".source = {
    recursive = true;
    source = ./warp-terminal;
  };
}
