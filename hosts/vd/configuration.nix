{ pkgs, inputs, username, ... }:

{
  imports = [
    # System configuration
    ./hardware-configuration.nix

    # Home manager
    inputs.home-manager.nixosModules.default

    # Core system modules
    ./../../modules/nixos/core/audio.nix
    ./../../modules/nixos/core/boot.nix
    ./../../modules/nixos/core/locale.nix
    ./../../modules/nixos/core/networking.nix
    ./../../modules/nixos/core/security.nix
    ./../../modules/nixos/core/shell.nix
    ./../../modules/nixos/core/time.nix

    # Drivers
    ./../../modules/nixos/drivers/nvidia.nix

    # Display
    ./../../modules/nixos/display/default.nix

    # Services
    ./../../modules/nixos/services/default.nix
  ];

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
    permittedInsecurePackages = [ "electron-27.3.11" ];
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  environment.systemPackages = [ ];

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
      regreet = { enable = false; };
    };

    # Graphics should be enabled by default in 
    # /modules/nixos/display/graphics.nix

    # ----- Bar -----
    display.waybar.enable = true;

    # Docker 
    services.docker = {
      enable = true;
      rootless = true;
      devtools = true;
      nvidia = true;

      portainer.enable = true;
    };

    # Filesystem
    services.filesystemExtraServices.enable = true;

    # SSHD
    services.sshd.enable = true;
  };

  # User
  users.users.fractal-tess = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "wireshark" ];
    password = "password";
    description = "default user";
    # packages = with pkgs; []
  };

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

  # programs.wireshark.enable = true;
  # programs.wireshark.dumpcap.enable = true;
  # programs.wireshark.package = pkgs.wireshark;

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

