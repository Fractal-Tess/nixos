{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops;
in
{

  imports = [
    ./ssh.nix
    ./z-ai.nix
    ./minimax.nix
    ./syncthing.nix
  ];

  options.modules.services.sops = {
    enable = mkEnableOption "SOPS secrets management";
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../../secrets/secrets.yaml;
      age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    };
  };

}
