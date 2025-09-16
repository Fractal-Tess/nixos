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
  system.stateVersion = "25.05";

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
    };

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true; # Allow broken packages for fingerprint drivers
    permittedInsecurePackages = [ "libsoup-2.74.3" ];
  };

  #============================================================================
  # HARDWARE CONFIGURATION
  #============================================================================

  # DDC support for external monitor brightness control
  # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/6
  boot.kernelModules = [ "i2c-dev" ];
  boot.kernelParams = [ ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  hardware.i2c.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Fingerprint authentication - disabled due to unsupported device ID 2808:c652
  # services.fprintd = {
  #   enable = true;
  # };

  # PAM configuration for fingerprint authentication
  # security.pam.services = {
  #   # Enable fingerprint auth for SDDM (main login)
  #   sddm.fprintAuth = true;
  #
  #   # CRITICAL WORKAROUND: Disable fprint for login service
  #   # This prevents Issue #171136 where GUI password auth breaks
  #   # login.fprintAuth = false;
  #
  #   # Enable fingerprint for other services
  #   sudo.fprintAuth = true; # sudo commands
  #   swaylock.fprintAuth = true; # Screen lock (if using)
  #   hyprlock.fprintAuth = true; # Hyprland lock (if using)
  # };
  #
  # # Ensure fprintd daemon starts properly
  # systemd.services.fprintd = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "simple";
  # };

  # Memory management
  zramSwap.enable = true;
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

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
      hyprland.enable = true;
      waybar.enable = true;
      sddm.enable = true;
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
        };
        firecracker.enable = false;
        kubernetes.enable = false;
      };

      # Samba configuration
      samba = {
        # Mount remote shares
        mount = {
          enable = true;
          shares = [
            {
              mountPoint = "/mnt/blockade";
              device = "//neo.netbird.cloud/blockade";
              username = "fractal-tess";
              password = "smbpass";
            }
            {
              mountPoint = "/mnt/oracle";
              device = "//oracle.netbird.cloud/home";
              username = "smbuser";
              password = "smbpass";
            }
            {
              mountPoint = "/mnt/vault";
              device = "//vd.netbird.cloud/vault";
              username = "fractal-tess";
              password = "smbpass";
            }
            {
              mountPoint = "/mnt/backup";
              device = "//vd.netbird.cloud/backup";
              username = "fractal-tess";
              password = "smbpass";
            }
          ];
        };

        # Share local directories
        share = {
          enable = true;
          shares = [{
            name = "home";
            path = "/home/${username}";
            forceUser = username;
            forceGroup = "users";
          }];
        };
      };
    };
  };

  #============================================================================
  # SYSTEM PACKAGES & PROGRAMS
  #============================================================================

  # Essential system packages
  environment.systemPackages = with pkgs; [ ];

  # Brightness control
  programs.light.enable = true;

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

    # Printing support
    printing = {
      enable = true;
      drivers = [ ]; # Add printer drivers as needed
    };

    # TLP - Power management for laptop
    tlp = {
      enable = true;
      settings = {
        CPU_DRIVER_OPMODE_ON_AC = "active";
        CPU_DRIVER_OPMODE_ON_BAT = "active";

        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # # Frequency limits (using available frequencies: 2.0GHz, 1.8GHz, 1.6GHz)
        # CPU_MAX_FREQ_ON_AC = 1800000; # Max performance on AC
        # CPU_MAX_FREQ_ON_BAT = 1800000; # Balanced performance on battery
        # CPU_MIN_FREQ_ON_AC = 1100000; # Don't go too low on AC
        # CPU_MIN_FREQ_ON_BAT = 1100000; # Conservative minimum

        # Performance scaling percentages
        # CPU_MIN_PERF_ON_AC = 0; # Higher baseline on AC
        # CPU_MAX_PERF_ON_AC = 100; # Full performance when needed
        # CPU_MIN_PERF_ON_BAT = 0; # Lower baseline on battery
        # CPU_MAX_PERF_ON_BAT = 80; # Cap performance on battery

        # CPU boost settings
        CPU_BOOST_ON_AC = 1; # Enable boost on AC
        CPU_BOOST_ON_BAT = 0; # Disable boost on battery for power saving
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

    # Qt applications backend
    QT_QPA_PLATFORM = "xcb";

    # GTK theme and cursor settings
    GTK_THEME = "Nordic"; # Dark bluish GTK theme
    XCURSOR_THEME = "Nordzy-cursors"; # Matching cursor theme
    XCURSOR_SIZE = "24"; # Default cursor size

    # Wayland support
    NIXOS_OZONE_WL = "1"; # Enable Wayland support in Electron/Ozone apps
    MOZ_USE_WAYLAND = 1; # Enable Wayland support in Firefox
    MOZ_USE_XINPUT2 = 1; # Enable XInput2 for better input handling
  };
}

