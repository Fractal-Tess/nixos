{ config, lib, username, ... }:

with lib;

let cfg = config.modules.services.sops;
in {
  # Define the enable option for SOPS secrets management
  options.modules.services.sops.enable =
    mkEnableOption "SOPS secrets management";

  # Configure SOPS only if enabled
  config = mkIf cfg.enable {
    # SOPS configuration for this host
    sops.defaultSopsFile =
      ../../../../secrets/secrets.yaml; # Path to the main secrets file
    sops.defaultSopsFormat = "yaml"; # Format of the secrets file
    sops.age.keyFile =
      "/home/${username}/.config/sops/age/keys.txt"; # Path to the age key file

    # Declare secrets to be managed by sops
    sops.secrets = {
      example_key = {
        owner = username;
        path = "/var/lib/${username}/secrets";
      };
      hello = {
        owner = username;
        path = "/home/${username}/.secretv2.zsh";
      };

      # SSH authorized_keys
      ssh_authorized_keys = {
        owner = username;
        sopsFile = ../../../../secrets/ssh_authorized_keys.yaml;
        format = "yaml";
        path = "/home/${username}/.ssh/authorized_keys";
      };

      ssh_config = {
        owner = username;
        sopsFile = ../../../../secrets/ssh_config.yaml;
        format = "yaml";
        path = "/home/${username}/.ssh/config";
      };
    };
  };
}
