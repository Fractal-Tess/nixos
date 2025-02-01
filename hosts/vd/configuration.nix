{ pkgs, inputs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default

    ../../modules/nixos/core/audio.nix
    ../../modules/nixos/core/boot.nix
    ../../modules/nixos/core/networking.nix

    ../../modules/nixos/drivers/nvidia.nix

    ../../modules/nixos/display/all.nix
    ../../modules/nixos/programs/all.nix
    ../../modules/nixos/services/all.nix
  ];

  # Flakes 
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Nixpkgs config
  nixpkgs.config = {
    # Allow unfree packages
    allowUnfree = true;
  };

  # Packages
  environment.systemPackages = with pkgs; [
    tor-browser
    telegram-desktop
    firefox
    nixfmt
  ];

  # --------------------- CORE --------------------------

  # Audio
  modules.audio.enable = true;

  # Boot
  modules.boot = { useCustomConfig = true; };

  # Networking  
  modules.networking = {
    firewall = {
      # 9 - magic packet Wake-on-LAN
      # 22 - SSH
      allowedPorts = [ 9 22 ];
    };

    # VPN
    vpn.netbird.enable = true;
  };

  # Enable nvidia  ---------------------------------------------------------
  modules.hardware.nvidia.enable = true;

  # Window Manager & compositor --------------------------------------------
  modules.display.hyprland = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    greetd.enable = true;
    greetd.autoLogin = true;
  };
  modules.display.waybar.enable = true;

  # Services ---------------------------------------------------------------
  ## Enable CUPS to print documents.
  services.printing.enable = true;

  ## Dbus
  services.dbus.enable = true;

  ## Enable the OpenSSH daemon.
  modules.services.sshd.enable = true;

  ## Add additional filesystme services
  modules.services.filesystemExtraServices.enable = true;

  ## Andorid Debug Bridge
  modules.services.adb.enable = true;

  ## Docker 
  modules.services.docker = {
    enable = true;
    rootless = true;
    nvidia = true;
  };

  # Programs ---------------------------------------------------------------
  ## Enable direnv
  modules.programs.direnv.enable = true;

  ## Enable Yazi
  modules.programs.yazi.enable = true;

  ## Zsh
  modules.programs.zsh.enable = true;

  # ------------------- User accounts -------------------
  users.users.fractal-tess = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "docker" ];
    password = "password";
    description = "default user";
    # packages = with pkgs; []
  };

  ## Make users mutable 
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

  # Security
  security.sudo.extraRules = [{
    users = [ username ];
    commands = [{
      # Removes the need for a password when using sudo
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # security.polkit.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # --------------------- Timezone --------------------------
  time.timeZone = "Europe/Sofia";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

