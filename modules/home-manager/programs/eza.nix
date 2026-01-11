{ pkgs, ... }:
{
  programs.eza = {
    enable = true;
    git = true;
    colors = "auto";
    enableFishIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
