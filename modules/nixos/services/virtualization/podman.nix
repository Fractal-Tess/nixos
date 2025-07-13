{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services.virtualization.podman;
in {
  options.modules.services.virtualization.podman = {
    enable = mkEnableOption "Podman";
    rootless = mkEnableOption "Rootless Podman";
    nvidia = mkEnableOption "Nvidia support";
    devtools = mkEnableOption "Devtools";
    dockerCompat = mkEnableOption "Enable Docker-compatible socket for Podman";
  };

  # Configure the Podman service if enabled
  config = mkIf cfg.enable {
    # Add the user to the podman group
    users.extraGroups.podman.members = mkDefault [ username ];

    # Enable the Nvidia container toolkit if Nvidia support is enabled
    hardware.nvidia-container-toolkit.enable = cfg.nvidia;

    # Configure the Podman virtualisation
    virtualisation.podman = {
      enable = true;
      # Enable Docker-compatible socket if requested
      dockerCompat = cfg.dockerCompat;
      # Enable Nvidia support if enabled (CDI is used)
      enableNvidia = cfg.nvidia;
      # Add extra packages for Podman
      extraPackages = with pkgs;
        [ podman-compose ] ++ (mkIf cfg.devtools [ dive buildkit lazydocker ]);
    };
  };
}
