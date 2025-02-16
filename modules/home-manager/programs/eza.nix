{ pkgs, ... }: {
  programs.eza = {
    enable = true;
    git = true;
    colors = "auto";
    enableZshIntegration = true;
    extraOptions = [ "--group-directories-first" "--header" ];
  };
}
