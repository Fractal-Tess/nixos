{ pkgs, inputs, username, ... }:

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
  boot.kernelModules = [ "i2c-dev" ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

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
    extraGroups = [ "networkmanager" "wheel" "video" "fractal-tess" ];
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
    # Force Qt applications to use X11 backend instead of Wayland
    QT_QPA_PLATFORM = "xcb";

    # Set AMD GPU video acceleration drivers
    # LIBVA_DRIVER_NAME = "radeonsi";  # VA-API driver for AMD GPUs
    # VDPAU_DRIVER = "radeonsi";       # VDPAU driver for AMD GPUs

    # Set GTK theme and cursor settings
    GTK_THEME = "Nordic"; # Dark bluish GTK theme
    XCURSOR_THEME = "Nordzy-cursors"; # Matching cursor theme
    XCURSOR_SIZE = "24"; # Default cursor size

    # Silence direnv logging output
    DIRENV_LOG_FORMAT = "";

    # Uncomment to force software cursor if hardware cursor doesn't work
    # WLR_NO_HARDWARE_CURSORS = "1";

    # Enable Wayland support in Electron/Ozone apps
    NIXOS_OZONE_WL = "1";

    # Set default editors
    VISUAL = "nvim"; # Visual editor for GUI contexts
    SUDO_EDITOR = "nvim"; # Editor used by sudo -e
    EDITOR = "nvim"; # Default terminal editor

    # Firefox Wayland settings
    MOZ_USE_WAYLAND = 1; # Enable Wayland support in Firefox
    MOZ_USE_XINPUT2 = 1; # Enable XInput2 for better input handling
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}

