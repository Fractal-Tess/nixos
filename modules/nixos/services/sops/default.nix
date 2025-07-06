{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.sops;
in {
  options.modules.services.sops = {
    enable = mkEnableOption "Enable sops secret management";
    age = mkOption {
      type = types.bool;
      default = true;
      description = "Enable age as the backend for sops";
    };
  };

  config = mkIf cfg.enable {
    # Enable sops-nix module
    environment.systemPackages = [ pkgs.sops ];
    sops = {
      enable = true;
      defaultSopsFile = null; # User can override
      age = mkIf cfg.age {
        enable = true;
        # The user should provide their age key(s) in /var/lib/sops/age/keys.txt or via home-manager
      };
    };
  };
}
