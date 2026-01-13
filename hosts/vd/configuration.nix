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

  # DO NOT CHANGE.
  system.stateVersion = "25.05";
  services.libinput.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    glibc
    libxext
    libx11
    libxrender
    libxtst
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
      options = "--delete-older-than 7d";
    };

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-27.3.11"
      "libsoup-2.74.3"
      "ventoy-1.1.07"
      "ventoy-1.1.10"
    ];
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
  # virtualisation.libvirtd = {
  #   enable = true;
  #   qemu = {
  #     package = pkgs.qemu_kvm;
  #     runAsRoot = true;
  #     swtpm.enable = true;
  #   };
  # };
  virtualisation.vmware.host.enable = true;

  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
  # virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.guest.dragAndDrop = true;

  modules = {
    # Hardware drivers
    drivers.nvidia.enable = true;

    # Security
    security.noSudoPassword = true;

    # Display system
    display = {
      hyprland.enable = true;
      waybar.enable = true;
      sddm.enable = true;
      autologin.enable = true;
    };

    # Services
    services = {
      sshd.enable = true;
      automount.enable = true;
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
          nvidia = true;
        };
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
    brightnessctl # Brightness control for laptops
    bluez # Bluetooth stack
    bluez-tools # Bluetooth command line tools
    bluetuith # TUI Bluetooth manager
    pavucontrol # Audio control (for Bluetooth audio devices)

    # Volume knob monitoring dependencies
    evtest # Input device event monitoring
    libnotify # For notify-send command
    pulseaudio # For pactl command
  ];

  # Brightness control
  programs.light.enable = true;

  # Gaming configuration
  programs.steam = {
    enable = true;
    protontricks.enable = true; # Wine prefix management
    gamescopeSession.enable = true; # Better gaming performance

    # Enhanced compatibility
    extraCompatPackages = with pkgs; [ protonup-ng ];
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

    # Printing support
    printing = {
      enable = true;
      drivers = [ ]; # Add printer drivers as needed
    };

    # Bluetooth GUI services
    blueman.enable = true;
  };

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
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
        "video"
        "input"
        "seat"
        "wheel"
        "fractal-tess"
        "dialout"
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
    cascadia-code
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
