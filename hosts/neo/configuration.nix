{ pkgs, inputs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    ../../modules/nixos/default.nix
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "libsoup-2.74.3" ];
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  environment.systemPackages = with pkgs; [ ];

  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  modules = {
    drivers.amd.enable = true;
    security.noSudoPassword = true;
    display = {
      hyprland = {
        enable = true;
        autoLogin = true;
      };
    };
    display.waybar.enable = true;
    services.virtualization = {
      docker = {
        enable = true;
        rootless = false;
        devtools = true;
      };
    };
    services.sshd.enable = true;
    services.automount.enable = true;
    services.samba.share = {
      enable = true;
      openFirewall = true;
      shares = [{
        name = "home";
        path = "/home/${username}";
        forceUser = username;
        forceGroup = "users";
      }
      {
        name = "blockade";
        path = "/mnt/blockade";
        forceUser = username;
        forceGroup = "users";
      }];
    };


    services.sops = {
      enable = true;
      ssh.enable = true;
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  services.dbus.enable = true;
  programs.light.enable = true;

  # Zram
  zramSwap.enable = true;
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

  # User
  users.users.${username} = {
    isNormalUser = true;
    extraGroups =
      [ "networkmanager" "wheel" "video" "fractal-tess" "wireshark" ];
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

  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
  ];

  environment.variables = {
    # Set GTK theme and cursor settings
    GTK_THEME = "Nordic"; # Dark bluish GTK theme
    XCURSOR_THEME = "Nordzy-cursors"; # Matching cursor theme
    XCURSOR_SIZE = "24"; # Default cursor size

    # Silence direnv logging output
    DIRENV_LOG_FORMAT = "";

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
