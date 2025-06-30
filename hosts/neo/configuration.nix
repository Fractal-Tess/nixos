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
    ./../../modules/nixos/drivers/default.nix

    # Display
    ./../../modules/nixos/display/default.nix

    # Services
    ./../../modules/nixos/services/default.nix
  ];

  # hardware.nvidia.open = false;

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
    permittedInsecurePackages = [ "electron-27.3.11" ];
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  environment.systemPackages = [ ];

  modules = {
    # ----- Drivers -----
    drivers.amd.enable = true;

    # ----- Security -----
    security.noSudoPassword = true;

    # ----- Display -----
    display = {
      hyprland.enable = true;
      regreet.enable = true;
    };
    display.waybar.enable = true;

    # Docker 
    services.docker = {
      enable = true;
      rootless = true;
      devtools = true;
      portainer.enable = true;
    };

    # Filesystem
    services.filesystemExtraServices.enable = true;

    # SSHD
    services.sshd.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Light
  programs.light.enable = true;

  # Zram
  zramSwap.enable = true;
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

  # User
  users.users.fractal-tess = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "wireshark" ];
    password = "password";
    description = "default user";
    packages = with pkgs; [ ];
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

  # Printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [ ]; # Add printer drivers as needed
  };

  services.dbus.enable = true;
  services.gvfs.enable = true;

  environment.variables = {
    QT_QPA_PLATFORM = "xcb";
    GTK_THEME = "Nordic";
    XCURSOR_THEME = "Nordzy-cursors";
    XCURSOR_SIZE = "24";
    DIRENV_LOG_FORMAT = "";
    NIXOS_OZONE_WL = "1";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";
    MOZ_USE_WAYLAND = 1;
    MOZ_USE_XINPUT2 = 1;
  };

  # Samba service for home directory sharing
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "map to guest" = "never";
        "server string" = "NixOS Samba Server";
        security = "user";
        "passdb backend" = "tdbsam";
      };
    };
    shares = {
      home = {
        path = "/home/fractal-tess";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "smbuser";
        "force user" = "fractal-tess";
        "force group" = "users";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  users.users.smbuser = {
    isSystemUser = true;
    description = "Samba User";
    group = "smbuser";
    password = "smbpassword";
  };
  users.groups.smbuser = { };

  system.stateVersion = "24.05";
}

