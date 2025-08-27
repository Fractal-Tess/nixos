{ pkgs, inputs, lib, username, config, ... }:

let backupDirs = [ "/mnt/backup/backup" "/mnt/vault/backup" ];

in {
  imports = [
    # System configuration
    ./hardware-configuration.nix

    # Home manager
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # NixOS modules
    ../../modules/nixos/default.nix

    # Containers
    ./containers.nix
  ];

  # DDC support
  # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/6
  boot = {
    kernelModules = [ "i2c-dev" ] ++ (if config.modules.drivers.nvidia.enable then [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ] else []);
    kernelParams = if config.modules.drivers.nvidia.enable then [ "nvidia-drm.modeset=1" ] else [];
  };

  # I2C support for brightness control on external monitors
  hardware.i2c.enable = true;

  # Wake-on-LAN support
  networking.interfaces.enp34s0.wakeOnLan.enable = true;

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-27.3.11" "libsoup-2.74.3" ];

  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  environment.systemPackages = with pkgs; [ crush ];
  programs.steam = {
    enable = true;
    # Required for managing Wine prefixes
    protontricks.enable = true;
    # Recommended for better gaming performance
    gamescopeSession.enable = true;

    # Install Proton-GE for better compatibility
    extraCompatPackages = with pkgs; [ protonup ];

    # Additional libraries needed for Wine/Proton
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

  modules = {
    # ----- Drivers -----
    drivers.nvidia.enable = true;

    # ----- Security -----
    security.noSudoPassword = true;

    # ----- Display -----
    display = {
      # ----- Hyprland -----
      hyprland.enable = true;

      # ----- ReGreet -----
      regreet = {
        enable = false;
        symlinkBackgrounds = true;
      };
    };

    # ----- Bar -----
    display.waybar.enable = true;

    # ----- Virtualization -----
    services.virtualization = {
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

    # ----- SSHD -----
    services.sshd.enable = true;

    # ----- Automount -----
    services.automount.enable = true;

    # ----- Samba shares -----
    services.samba.mount = {
      enable = true;
      shares = [
        # {
        #   mountPoint = "/mnt/blockade";
        #   device = "//rp.netbird.cloud/blockade";
        #   username = "smbuser";
        #   password = "smbpass";
        # }
        # {
        #   mountPoint = "/mnt/greystone";
        #   device = "//rp.netbird.cloud/greystone";
        #   username = "smbuser";
        #   password = "smbpass";
        # }
        {
          mountPoint = "/mnt/oracle";
          device = "//oracle.netbird.cloud/home";
          username = "smbuser";
          password = "smbpass";
        }
        # {
        #   mountPoint = "/mnt/neo";
        #   device = "//neo.netbird.cloud/home";
        #   username = "fractal-tess";
        #   password = "smbpass";
        # }
      ];
    };

    # Samba share service
    services.samba.share = {
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

    # SOPS
    services.sops = {
      enable = true;
      ssh.enable = true;
    };

    # ----- Disk Utils ----- TODO:
    services.disk-utils.enable = true;
  };

  # User
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "video" "input" "seat" "wheel" "fractal-tess" ];
    password = "password";
    description = "default user";
    packages = with pkgs; [ ];
  };

  users.groups.${username} = { members = [ username ]; };

  # Make users mutable
  users.mutableUsers = true;

  # Home-Manger
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };
    users."${username}" = import ./home.nix;
    backupFileExtension = "hm-bak";
  };

  # Fonts
  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
  ];

  # Printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [ ]; # Add printer drivers as needed
  };

  services.dbus.enable = true;
  services.gvfs.enable = true;

  environment.variables = {
       # Session and display configuration
       XDG_SESSION_TYPE = "wayland";

       # NVIDIA-specific variables (when enabled)
     } // (lib.mkIf config.modules.drivers.nvidia.enable {
       LIBVA_DRIVER_NAME = "nvidia";
       GBM_BACKEND = "nvidia-drm";
       __GLX_VENDOR_LIBRARY_NAME = "nvidia";
       WLR_NO_HARDWARE_CURSORS = "1";
     }) // (lib.mkIf config.modules.drivers.amd.enable {
       # AMD GPU video acceleration drivers
       LIBVA_DRIVER_NAME = "radeonsi";
       VDPAU_DRIVER = "radeonsi";
     }) // {
       # Application-specific Wayland support
       NIXOS_OZONE_WL = "1";           # Electron/Chromium apps
       MOZ_ENABLE_WAYLAND = "1";       # Firefox Wayland support
       MOZ_USE_XINPUT2 = "1";          # Better Firefox input handling

       # Qt and GTK configuration
       QT_QPA_PLATFORM = "wayland;xcb"; # Try Wayland first, fallback to X11
       GTK_THEME = "Nordic";           # Dark bluish GTK theme

       # Cursor configuration
       XCURSOR_THEME = "Nordzy-cursors";
       XCURSOR_SIZE = "24";

       # Editor configuration
       VISUAL = "nvim";
       SUDO_EDITOR = "nvim";
       EDITOR = "nvim";

       # Silence direnv logging
       DIRENV_LOG_FORMAT = "";
     };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
