{ pkgs, inputs, username, ... }:

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
  ];

  #============================================================================
  # SYSTEM CONFIGURATION
  #============================================================================

  # Release version - DO NOT CHANGE unless you know what you're doing
  system.stateVersion = "24.05";

  #============================================================================
  # NIX CONFIGURATION
  #============================================================================

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
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
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

  #============================================================================
  # POWER MANAGEMENT
  #============================================================================

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
      hyprland = {
        enable = false;
        autoLogin = true;
      };
      waybar.enable = false;
    };

    # Services
    services = {
      sshd.enable = true;
      automount.enable = true;
      sops = {
        enable = true;
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

      # Samba configuration
      samba.share = {
        enable = true;
        openFirewall = true;
        shares = [
          {
            name = "home";
            path = "/home/${username}";
            forceUser = username;
            forceGroup = "users";
          }
          {
            name = "blockade";
            path = "/mnt/blockade";
            forceUser = username;
            forceGroup = "users";
          }
        ];
      };
    };
  };

  #============================================================================
  # SYSTEM PACKAGES & PROGRAMS
  #============================================================================

  # Essential system packages (minimal for laptop)
  environment.systemPackages = with pkgs; [ ];

  # Brightness control
  # programs.light.enable = true;

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    # TLP - Aggressive power management for server use
    tlp = {
      enable = true;
      settings = {
        # CPU scaling - always use powersave
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # Energy performance policy - maximum power savings
        CPU_ENERGY_PERF_POLICY_ON_AC = "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # CPU performance limits - very conservative for server
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 30;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        # Aggressive power management
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";

        # USB power saving
        USB_AUTOSUSPEND = 1;

        # PCI Express power saving
        PCIE_ASPM_ON_AC = "powersupersave";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # Disk power management
        DISK_APM_LEVEL_ON_AC = "128";
        DISK_APM_LEVEL_ON_BAT = "1";

        # Network power saving
        WIFI_PWR_ON_AC = "on";
        WIFI_PWR_ON_BAT = "on";

        # Sound card power saving
        SOUND_POWER_SAVE_ON_AC = 1;
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # Battery thresholds for longevity
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 60;
      };
    };

    # Disable power-profiles-daemon as it conflicts with TLP
    power-profiles-daemon.enable = false;
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
      extraGroups =
        [ "networkmanager" "wheel" "video" "fractal-tess" "wireshark" ];
      packages = [ ];
    };

    groups.${username} = { members = [ username ]; };
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
    # Default editor configuration
    VISUAL = "nvim"; # Visual editor for GUI contexts
    SUDO_EDITOR = "nvim"; # Editor used by sudo -e
    EDITOR = "nvim"; # Default terminal editor

    # Development tools
    DIRENV_LOG_FORMAT = ""; # Silence direnv logging output
  };
}
