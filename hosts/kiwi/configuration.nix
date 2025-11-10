{
  pkgs,
  inputs,
  username,
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
  ];

  #============================================================================
  # SYSTEM CONFIGURATION
  #============================================================================

  # Release version - DO NOT CHANGE unless you know what you're doing
  system.stateVersion = "25.05";

  # Enable link dynamic
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # code-cursor # VS Code fork with AI features
  ];

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

  # VMware virtualization support
  virtualisation.vmware.host.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Memory management
  zramSwap.enable = true;
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024; # 16GB
    }
  ];

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
        z_ai.enable = true;
        linux_wallpaperengine.enable = true;
      };

      # Virtualization
      virtualization = {
        docker = {
          enable = true;
          rootless = true;
          devtools = true;
        };
      };

      # Samba configuration
      samba = {
        # Mount remote shares
        mount = {
          enable = false;
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
          shares = [
            {
              name = "home";
              path = "/home/${username}";
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
    # Printing utilities
    cups  # CUPS printing system
    ghostscript  # PostScript and PDF interpreter
    poppler_utils  # PDF utilities (pdftops, pdfinfo, etc.)

    # Network printing
    gutenprint  # High-quality printer drivers

    # Command-line printing tools (these are provided by cups)
    # lpr, lpstat, cancel, lpq are included with cups

    # Scanner support
    sane-frontends  # Scanner utilities
    xsane  # GUI scanner frontend
  ];

  # Enable SANE for scanner support
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan  # Driverless scanning
      hplip  # HP scanner backend (includes libsane-hpaio)
    ];
  };

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
  # SECURITY & CERTIFICATES
  #============================================================================

  # Custom CA certificates
  security.pki.certificateFiles = [ ../../config/certs/carrierx.crt ];

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    dbus.enable = true;
    gvfs.enable = true;

    # Printing support - CUPS configuration
    printing = {
      enable = true;

      # Start CUPS on boot
      startWhenNeeded = true;

      # Default paper size and language
      defaultShared = true;

      # Drivers for common printers
      drivers = with pkgs; [
        # Generic drivers
        cups-filters
        foomatic-filters
        gutenprint

        # HP printer drivers
        hplip

        # Brother printer drivers
        brlaser

        # Canon printer drivers
        cnijfilter2

        # Epson printer drivers
        epson-escpr

        # Samsung printer drivers
        splix

        # Lexmark printer drivers
        postscript-lexmark

        # PostScript printer support
        ghostscript
      ];

      # Additional CUPS settings
      extraConf = ''
        # Allow remote administration
        <Location /admin>
          Order allow,deny
          Allow localhost
          Allow @LOCAL
        </Location>

        # Log level for troubleshooting
        LogLevel info
      '';
    };

    # Enable Avahi for automatic printer discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;

      # Publish CUPS printers on the network
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
      };
    };

    # Systemd logind configuration for lid switch handling
    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend"; # Suspend when lid is closed
          HandleLidSwitchExternalPower = "suspend"; # Also suspend when on external power
          HandleLidSwitchDocked = "ignore"; # Don't suspend when docked
        };
      };
    };

    # TLP - Power management for laptop
    tlp = {
      enable = true;
      settings = {
        # CPU driver operation mode
        CPU_DRIVER_OPMODE_ON_AC = "active";
        CPU_DRIVER_OPMODE_ON_BAT = "active";

        # CPU scaling governors
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # Energy performance policies
        CPU_ENERGY_PERF_POLICY_ON_AC = "default";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "default";

        # CPU frequency limits (in kHz)
        # Limiting max frequency to reduce heat and power consumption
        # CPU_SCALING_MIN_FREQ_ON_AC = 0;
        CPU_SCALING_MAX_FREQ_ON_AC = 4100000; # 4.1GHz max on AC
        # CPU_SCALING_MIN_FREQ_ON_BAT = 0;
        CPU_SCALING_MAX_FREQ_ON_BAT = 3700000; # 3.7GHz max on battery

        # CPU boost settings
        CPU_BOOST_ON_AC = 1; # Allow boost on AC
        CPU_BOOST_ON_BAT = 1; # Allow boot on BAT
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
        "lp"  # Allow printer management
        "scanner"  # Allow scanner usage
      ];
      packages = with pkgs; [
        # Printing utilities
        system-config-printer  # GUI printer management
        simple-scan  # Document scanning
        hplip  # SANE backend for HP devices (includes libsane-hpaio)
        sane-airscan  # Driverless scanning
      ];
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
    # Used by the wallpaper script to determine which wallpaper script to use
    WALLPAPER_TYPE = "WAYPAPER";
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
