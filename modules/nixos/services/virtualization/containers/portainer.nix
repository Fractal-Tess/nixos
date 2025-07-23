{ config, lib, ... }:

with lib;
let cfg = config.modules.services.virtualization.containers.portainer;
in {
  options.modules.services.virtualization.containers.portainer = {
    enable = mkEnableOption "Enable Portainer";
  };

  config = mkIf cfg.enable {
    # Create system user for Portainer
    users.users.portainer = {
      isSystemUser = true;
      group = "docker";
      description = "Portainer service user";
    };

    # Create persistent volume directory
    systemd.tmpfiles.rules = [ "d /var/lib/portainer 0750 portainer docker -" ];

    # Define the Portainer service
    virtualisation.oci-containers.containers.portainer = {
      autoStart = true;
      image = "portainer/portainer-ce:latest";
      ports = [
        "8000:8000" # Agents
        "9000:9000" # HTTP Web UI
        "9443:9443" # HTTPS Web UI
      ];
      volumes = [
        "/run/user/1000/docker.sock:/var/run/docker.sock"
        "/var/lib/portainer:/data"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
      };
      extraOptions = [ ];
    };
  };
}
