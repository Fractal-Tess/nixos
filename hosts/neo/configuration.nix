{
  inputs,
  username,
  pkgs,
  ...
}:

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    # Hardware configuration
    ./hardware-configuration.nix

    # External modules
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # Custom NixOS modules
    ../../modules/nixos/default.nix

    # System-wide packages
    ./packages.nix
  ];

  #============================================================================
  # SYSTEM CONFIGURATION
  #============================================================================
  boot.kernelParams = [ "amd_pstate=disable" ];

  # Release version - DO NOT CHANGE unless you know what you're doing
  system.stateVersion = "24.05";

  #============================================================================
  # NIX CONFIGURATION
  #============================================================================

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ ];
  };

  #============================================================================
  # HARDWARE CONFIGURATION
  #============================================================================

  # Memory management
  zramSwap.enable = true;
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024; # 16GB
    }
  ];

  # Laptop lid settings - ignore lid close when docked/external power
  services.logind.settings.Login = {
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitch = "ignore";
  };

  #============================================================================
  # CUSTOM MODULES CONFIGURATION
  #============================================================================

  modules = {
    # Hardware drivers
    drivers.amd.enable = true;

    # Security
    security.noSudoPassword = true;

    # Display system
    display = {
      hyprland.enable = false;
      waybar.enable = false;
    };

    # Services
    services = {
      sshd.enable = true;
      automount.enable = true;
      syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        overrideDevices = false;
        overrideFolders = false;
        settings = {
          devices = {
            "vd" = {
              id = "EMPKFGK-UVXVPWQ-U2XOBDT-GIBZPXG-CTFEFFC-AV3OFNI-ZOCPY3M-UHOSCQ6";
              addresses = [ "tcp://vd.netbird.cloud" ];
              untrusted = false;
            };
            "kiwi" = {
              id = "VBKYDOP-SIXFK2R-ON2TBRL-H2YDC2O-4U5LCC4-5HHRED2-LUVKEK6-CTX47Q4";
              addresses = [ "tcp://kiwi.netbird.cloud" ];
              untrusted = false;
            };
          };
          folders = {
            "opencode-config" = {
              path = "/home/fractal-tess/.config/opencode";
              id = "opencode-config";
              label = "opencode-config";
              devices = [
                "vd"
                "kiwi"
              ];
            };
          };
        };
      };
      sops = {
        enable = true;
        z_ai.enable = true;
        ssh.enable = true;
      };

      # Virtualization
      virtualization = {
        docker = {
          enable = true;
          rootless = false;
          devtools = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    631
    8384
  ];

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        START_CHARGE_THRESH_BAT0 = 60;
        STOP_CHARGE_THRESH_BAT0 = 65;

        CPU_BOOST_ON_AC = 1;
      };
    };
  };

  #============================================================================
  # USER CONFIGURATION
  #============================================================================

  users = {
    mutableUsers = true;

    users.${username} = {
      isNormalUser = true;
      description = "default user";
      password = "password";
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "fractal-tess"
        "wireshark"
        "docker"
      ];
      packages = [ ];
    };

    users.dokploy = {
      isNormalUser = true;
      description = "Dokploy service user";
      uid = 1001;
      home = "/home/dokploy";
      createHome = true;
      shell = pkgs.bash;
      extraGroups = [ "docker" ];
    };

    groups.${username} = {
      members = [ username ];
    };
  };

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };
    users."${username}" = import ./home.nix;
    backupFileExtension = "hm-bak";
  };

  #============================================================================
  # ENVIRONMENT VARIABLES
  #============================================================================

  environment.variables = {
    # Terminal type for maximum compatibility
    TERM = "xterm-256color";

    # Default editor configuration
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";

    # Development tools
    DIRENV_LOG_FORMAT = ""; # Silence direnv logging
  };
}
