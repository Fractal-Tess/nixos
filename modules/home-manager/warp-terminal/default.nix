{ pkgs, ... }: {
  home.packages = with pkgs; [ warp-terminal ];
  home.file.".config/test" = {
    source = ./warp-terminal;
    recursive = true;
  };

}
