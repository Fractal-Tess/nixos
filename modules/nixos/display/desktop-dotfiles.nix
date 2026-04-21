{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.display.hyprland;
  repoDir = "/home/${username}/nixos";
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.stow ];

    systemd.user.services.desktop-dotfiles-stow = {
      description = "Apply Stow-managed desktop dotfiles";
      wantedBy = [ "default.target" ];
      after = [ "graphical-session-pre.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      environment = {
        HOME = "/home/${username}";
        REPO_DIR = repoDir;
        HOSTNAME_VALUE = config.networking.hostName;
      };
      path = with pkgs; [
        bash
        coreutils
        python3
        stow
      ];
      script = ''
        ${repoDir}/scripts/system/dotfiles apply
      '';
    };
  };
}
