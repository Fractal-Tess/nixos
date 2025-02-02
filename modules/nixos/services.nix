{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services;
in {
  options.modules.services = {
    enable = mkEnableOption "Services";

    adb = { enable = mkEnableOption "Android Debug Bridge"; };

    auto_cpu = {
      enable = mkEnableOption "Auto CPU frequency";
      charger = {
        governor = mkOption {
          type = types.string;
          default = "performance";
          description = "CPU governor to use when the laptop is plugged in";
        };

        turbo = mkOption {
          type = types.string;
          default = "always";
          description = "Turbo boost mode to use when the laptop is plugged in";
        };
      };

      battery = {
        governor = mkOption {
          type = types.string;
          default = "balanced";
          description = "CPU governor to use when the laptop is on battery";
        };

        turbo = mkOption {
          type = types.string;
          default = "auto";
          description = "Turbo boost mode to use when the laptop is on battery";
        };
      };
    };

    docker = {
      enable = mkEnableOption "Docker";
      rootless = mkEnableOption "Rootless Docker";
      nvidia = mkEnableOption "Nvidia support";
      devtools = mkEnableOption "Devtools";
      kubernetes = {
        enable = mkEnableOption "Kubernetes support";
        minikube = mkEnableOption "Minikube - Local Kubernetes cluster";
        kubectl = mkEnableOption "kubectl - Kubernetes command-line tool";
      };
    };

    filesystemExtraServices = {
      enable = mkEnableOption "Filesystem utilities";
    };

    sshd = {
      enable = mkEnableOption "SSH daemon";
      ports = mkOption {
        type = types.listOf types.int;
        default = [ 22 ];
        description = "Ports to listen on.";
      };

      settings = {
        PermitRootLogin = mkOption {
          type = types.str;
          default = "prohibit-password";
          description = "Permit root login.";
        };
        PasswordAuthentication = mkOption {
          type = types.bool;
          default = false;
          description = "Permit password authentication.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # ADB Configuration
    programs.adb.enable = mkIf cfg.adb.enable true;
    services.udev.packages = with pkgs;
      (optionals cfg.adb.enable [ android-udev-rules ]);

    # Auto-CPU Configuration
    services.auto-cpufreq = mkIf cfg.auto_cpu.enable {
      enable = true;
      settings = {
        charger = {
          governor = cfg.auto_cpu.charger.governor;
          turbo = cfg.auto_cpu.charger.turbo;
        };
        battery = {
          governor = cfg.auto_cpu.battery.governor;
          turbo = cfg.auto_cpu.battery.turbo;
        };
      };
    };

    # Docker Configuration
    users.extraGroups.docker.members = mkIf cfg.docker.enable [ username ];
    hardware.nvidia-container-toolkit.enable = cfg.docker.nvidia;
    virtualisation.docker = mkIf cfg.docker.enable {
      package = (pkgs.docker.override (args: { buildxSupport = true; }));
      enable = true;
      rootless = mkIf cfg.docker.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    environment.systemPackages = with pkgs;
      (optionals (cfg.docker.enable && cfg.docker.devtools) [
        dive
        docker-compose
        buildkit
        lazydocker
      ]) ++ (optionals cfg.docker.kubernetes.enable ([ kubernetes-helm ]
      ++ (optionals cfg.docker.kubernetes.kubectl [ kubectl ])
      ++ (optionals cfg.docker.kubernetes.minikube [ minikube ])));

    # Enable required services for Minikube
    virtualisation.virtualbox.host.enable =
      mkIf (cfg.docker.kubernetes.enable && cfg.docker.kubernetes.minikube)
        true;

    # All services configuration
    services = {
      # Filesystem Services Configuration
      udisks2.enable = mkIf cfg.filesystemExtraServices.enable true;
      devmon.enable = mkIf cfg.filesystemExtraServices.enable true;
      gvfs.enable = mkIf cfg.filesystemExtraServices.enable true;

      # SSH Configuration
      openssh = mkIf cfg.sshd.enable {
        enable = true;
        ports = cfg.sshd.ports;
        settings = {
          PermitRootLogin = cfg.sshd.settings.PermitRootLogin;
          PasswordAuthentication = cfg.sshd.settings.PasswordAuthentication;
        };
      };
    };
  };
}
