{ pkgs, inputs, username, ... }:

{
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

  # I2C support for brightness control on external monitors
  hardware.i2c.enable = true;

  # Wake-on-LAN support
  networking.interfaces.enp34s0.wakeOnLan.enable = true;

  # Nix settings
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
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-27.3.11" "libsoup-2.74.3" ];
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  environment.systemPackages = with pkgs; [ crush dysk ];
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
  };

  # User
  users.users.${username} = {
    isNormalUser = true;
    extraGroups =
      [ "networkmanager" "video" "input" "seat" "wheel" "fractal-tess" ];
    password = "password";
    description = "default user";
    packages = [ ];
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
    drivers = [ ]; # Add printer drivers as needed
  };

  services.dbus.enable = true;
  services.gvfs.enable = true;

  environment.variables = {
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
