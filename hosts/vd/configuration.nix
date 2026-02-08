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

  # DO NOT CHANGE.
  system.stateVersion = "25.05";

  services.libinput.enable = true;
  hardware.opentabletdriver.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    glibc
    libxext
    libx11
    libxrender
    libxtst
    libuuid
  ];
  hardware.nvidia-container-toolkit.enable = true;
  hardware.graphics.enable32Bit = true;

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
      syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
      };
      sops = {
        enable = true;
        ssh.enable = true;
        z_ai.enable = true;
        minimax.enable = true;
        # linux_wallpaperengine.enable = true; # Disabled - using waypaper instead
      };

      # Virtualization
      # NOTE: Changed rootless to false for Dokploy/Swarm compatibility
      # Swarm mode is incompatible with rootless Docker
      virtualization = {
        docker = {
          enable = true;
          rootless = false; # Required for Dokploy/Swarm
          devtools = true;
          nvidia = true;
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
        "docker" # Added for non-rootless Docker access
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
