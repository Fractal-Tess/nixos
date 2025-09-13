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

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-27.3.11" "libsoup-2.74.3" ];
  };

  #============================================================================
  # HARDWARE CONFIGURATION
  #============================================================================

  # DDC support for external monitor brightness control
  # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/6
  boot.kernelModules = [ "i2c-dev" ];
  hardware.i2c.enable = true;

  # Wake-on-LAN support
  networking.interfaces.enp34s0.wakeOnLan.enable = true;

  #============================================================================
  # CUSTOM MODULES CONFIGURATION
  #============================================================================

  modules = {
    # Hardware drivers
    drivers.nvidia.enable = true;

    # Security
    security.noSudoPassword = true;

    # Display system
    display = {
      hyprland = {
        enable = true;
        autoLogin = true;
      };
      waybar.enable = true;
      regreet = {
        enable = false;
        symlinkBackgrounds = true;
      };
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
          rootless = true;
          devtools = true;
          nvidia = true;
          useNetbirdDNS = true;
        };
        # firecracker.enable = true;
        # kubernetes.enable = true;
      };

      # Samba configuration
      samba = {
        # Mount remote shares
        mount = {
          enable = true;
          shares = [
            {
              mountPoint = "/mnt/oracle";
              device = "//oracle.netbird.cloud/home";
              username = "smbuser";
              password = "smbpass";
            }
            {
              mountPoint = "/mnt/neo";
              device = "//neo.netbird.cloud/home";
              username = "fractal-tess";
              password = "smbpass";
            }
            {
              mountPoint = "/mnt/blockade";
              device = "//neo.netbird.cloud/blockade";
              username = "fractal-tess";
              password = "smbpass";
            }
            {
              mountPoint = "/mnt/kiwi";
              device = "//kiwi.netbird.cloud/kiwi";
              username = "fractal-tess";
              password = "smbpass";
            }
          ];
        };

        # Share local directories
        share = {
          enable = true;
          shares = [
            {
              name = "home";
              path = "/home/${username}";
              forceUser = username;
              forceGroup = "users";
            }
            {
              name = "vault";
              path = "/mnt/vault";
              forceUser = username;
              forceGroup = "users";
            }
            {
              name = "backup";
              path = "/mnt/backup";
              forceUser = username;
              forceGroup = "users";
            }
          ];
        };
      };
    };
  };

  #============================================================================
  # SYSTEM PACKAGES & PROGRAMS
  #============================================================================

  # Essential system packages
  environment.systemPackages = with pkgs; [
    crush # File compression utility
  ];

  # Gaming configuration
  programs.steam = {
    enable = true;
    protontricks.enable = true; # Wine prefix management
    gamescopeSession.enable = true; # Better gaming performance

    # Enhanced compatibility
    extraCompatPackages = with pkgs; [ protonup ];

    # Required libraries for Wine/Proton
    extraPackages = with pkgs; [
      # Basic dependencies
      keyutils
      libkrb5
      libpng
      libpulseaudio

      # Media support
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good

      # 32-bit libraries
      pkgsi686Linux.keyutils
      pkgsi686Linux.libkrb5
    ];
  };

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    dbus.enable = true;
    gvfs.enable = true;

    # Secrets management
    gnome.gnome-keyring.enable = true;

    # Printing support
    printing = {
      enable = true;
      drivers = [ ]; # Add printer drivers as needed
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
        [ "networkmanager" "video" "input" "seat" "wheel" "fractal-tess" ];
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
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
    font-awesome
    powerline-fonts
    powerline-symbols
  ];

  #============================================================================
  # ENVIRONMENT VARIABLES
  #============================================================================

  environment.variables = {
    # Default editor configuration
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";

    # Development tools
    DIRENV_LOG_FORMAT = ""; # Silence direnv logging
  };
}
