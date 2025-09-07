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
    permittedInsecurePackages = [ "libsoup-2.74.3" ];
  };

  #============================================================================
  # HARDWARE CONFIGURATION
  #============================================================================

  # Bluetooth configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

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
        enable = true;
        autoLogin = true;
      };
      waybar.enable = true;
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
  programs.light.enable = true;

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    dbus.enable = true;
    blueman.enable = true; # Bluetooth manager

    # TLP - Power management for laptops
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 75;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        # Optional helps save long term battery health
        START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
        STOP_CHARGE_THRESH_BAT0 = 60; # 60 and above it stops charging
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
  # FONTS
  #============================================================================

  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
  ];

  #============================================================================
  # ENVIRONMENT VARIABLES
  #============================================================================

  environment.variables = {
    # Theme configuration
    GTK_THEME = "Nordic"; # Dark bluish GTK theme
    XCURSOR_THEME = "Nordzy-cursors"; # Matching cursor theme
    XCURSOR_SIZE = "24"; # Default cursor size

    # Default editor configuration
    VISUAL = "nvim"; # Visual editor for GUI contexts
    SUDO_EDITOR = "nvim"; # Editor used by sudo -e
    EDITOR = "nvim"; # Default terminal editor

    # Wayland support
    NIXOS_OZONE_WL = "1"; # Enable Wayland in Electron/Ozone apps
    MOZ_USE_WAYLAND = "1"; # Enable Wayland support in Firefox
    MOZ_USE_XINPUT2 = "1"; # Enable XInput2 for better input handling

    # Development tools
    DIRENV_LOG_FORMAT = ""; # Silence direnv logging output
  };
}
