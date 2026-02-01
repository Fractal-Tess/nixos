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

    # System-wide packages
    ./packages.nix
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
  boot.kernelParams = [
    "amd_pstate=active" # Use active mode for better power management on AMD CPUs
    "pcie_aspm=powersupersave" # Aggressive PCIe ASPM for power saving
    "processor.max_cstate=9" # Allow deeper CPU C-states
    "intel_idle.max_cstate=9" # Allow deeper idle states (works on AMD too)
    "nvme_core.default_ps_max_latency_us=5500" # NVMe aggressive power saving
  ];

  # Optimize I/O scheduler for better power efficiency
  services.udev.extraRules = ''
    # Use deadline scheduler for better power efficiency on SSDs/NVMe
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="deadline"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    # DDC support for external monitor brightness control
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  hardware.i2c.enable = true;

  # VMware virtualization support
  # Disabled due to build stuck issue (vmware-unpack-env-17.6.4-bwrap)
  # virtualisation.vmware.host.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Memory management - use zram + hardware swap partition
  zramSwap.enable = true;

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
      syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
      };
      sops = {
        enable = true;
        ssh.enable = true;
        z_ai.enable = true;
        minimax.enable = true;
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
    };
  };

  networking.firewall.allowedTCPPorts = [
    631
    8384
  ];

  #============================================================================
  # SYSTEM PACKAGES & PROGRAMS
  #============================================================================

  # Enable SANE for scanner support
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan # Driverless scanning
      hplip # HP scanner backend (includes libsane-hpaio)
    ];
  };

  # Brightness control
  programs.light.enable = true;

  # Wireshark configuration - enables packet capture for non-root users
  # This automatically sets up dumpcap with CAP_NET_RAW and CAP_NET_ADMIN capabilities
  programs.wireshark.enable = true;

  # Gaming configuration
  programs.steam = {
    enable = true;
    protontricks.enable = true; # Wine prefix management
    gamescopeSession.enable = true; # Better gaming performance

    # Enhanced compatibility
    extraCompatPackages = with pkgs; [
      #protonup
    ];

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
  # NETWORKING AND DNS CONFIGURATION
  #============================================================================

  # Custom hosts file entries for local DNS resolution
  networking.extraHosts = ''
    127.0.0.1 web.local
    ::1 web.local
  '';

  #============================================================================
  # SECURITY & CERTIFICATES
  #============================================================================

  # Custom CA certificates
  security.pki.certificateFiles = [ ../../config/certs/carrierx.crt ];

  # PAM integration for GNOME Keyring automatic unlock on login
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    dbus.enable = true;
    gvfs.enable = true;

    # GNOME Keyring - secure credential storage
    gnome.gnome-keyring.enable = true;

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
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "performance";

        # Energy performance policies
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "default";

        CPU_BOOST_ON_AC = 0;

        # CPU frequency limits (in kHz) - Aggressively limited for efficiency
        # Limiting max frequency to reduce heat and power consumption
        CPU_SCALING_MIN_FREQ_ON_AC = 2000000; # ~2GHz minimum for stability
        CPU_SCALING_MAX_FREQ_ON_AC = 3900000; # 3.9GHz max on AC for efficiency
        CPU_SCALING_MIN_FREQ_ON_BAT = 1400000; # ~1.4GHz minimum on battery
        CPU_SCALING_MAX_FREQ_ON_BAT = 3400000; # 3.4GHz max on battery for efficiency
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
        "lp" # Allow printer management
        "scanner" # Allow scanner usage
      ];
      packages = [ ];
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
