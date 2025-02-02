{ pkgs, inputs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default

    ../../modules/nixos/core/audio.nix
    ../../modules/nixos/core/boot.nix
    ../../modules/nixos/core/networking.nix

    ../../modules/nixos/display/all.nix
    ../../modules/nixos/services.nix
    ../../modules/nixos/programs.nix
  ];

  # Shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [ ];

  # Flakes 
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Nixpkgs config
  nixpkgs.config = {
    # Allow unfree packages
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-27.3.11" ];
  };

  # Bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot =
    true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true; # enables the Bluetooth manager

  # Light
  programs.light.enable = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --------------------- CORE --------------------------

  # Audio
  modules.audio.enable = true;

  # Boot
  modules.boot = { useCustomConfig = true; };

  # Networking  
  modules.networking = {
    firewall = {
      allowedPorts = [
        9 # Magic packet
        22 # SSH
      ];
    };

    # VPN
    vpn.netbird.enable = true;
  };

  # --------------------- Drivers -----------------------

  # --------------------- Display ------------------------

  # Window manager
  modules.display.hyprland = {
    enable = true;
    greetd.enable = true;
    greetd.autoLogin = false;
    videoDrivers = [ "amdgpu" ];
    openGL = {
      enable = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
        amdvlk
        # rocm-opencl-icd
        # rocm-opencl-runtime
      ];
      extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];

    };
  };

  # Bar
  modules.display.waybar.enable = true;

  # --------------------- Services ------------------------

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # DBUS
  services.dbus.enable = true;

  # Andorid Debug Bridge
  modules.services.adb.enable = true;

  # Docker 
  modules.services.docker = {
    enable = true;
    rootless = true;
  };

  # Filesystem
  modules.services.filesystemExtraServices.enable = true;

  # SSHD
  modules.services.sshd.enable = true;

  # Zram
  zramSwap.enable = true;
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

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
    extraGroups = [ "networkmanager" "wheel" "video" ]
      ++ (if config.modules.services.docker.enable then [ "docker" ] else [ ]);
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

  # Security
  security.sudo.extraRules = [{
    users = [ username ];
    commands = [{
      # Removes the need for a password when using sudo
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Timezone & locale
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

