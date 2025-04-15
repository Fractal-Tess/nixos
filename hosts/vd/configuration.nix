{ pkgs, inputs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/nixos/main.nix
  ];

  modules = {
    gui = true;

    # Drivers
    drivers.nvidia = true;

    #Security
    security.noSudoPassword = true;

    # Window manager
    display.hyprland = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      greetd.enable = true;
      greetd.autoLogin = true;
    };

    # Bar
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

  # --------------------- Programs --------------------------

  modules.programs = {
    enable = true;
    cli = {
      core = true;
      devtools = true;
      language-servers = true;
      extra = true;
    };
    gui = {
      core = true;
      communication = true;
      browsers = true;
      office = true;
      devtools = true;
      games = true;
      fonts = true;
      extra = true;
    };
  };

  # ------------------- User accounts -----------------------

  # User
  users.users.fractal-tess = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" ];
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

