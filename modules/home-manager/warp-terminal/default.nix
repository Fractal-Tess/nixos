{ pkgs, ... }: {
  home.packages = with pkgs; [ warp-terminal ];
  home.file.".config/warp-terminal/user_preferences.json".source = {
    source = ./warp-terminal/user_preferences.json;
  };
}
