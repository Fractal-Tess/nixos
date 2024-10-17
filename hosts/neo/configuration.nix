{ pkgs, inputs, username, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default

      ../../modules/nixos/audio/default.nix
      ../../modules/nixos/boot/default.nix
      ../../modules/nixos/networking/default.nix
      ../../modules/nixos/display/all.nix
      ../../modules/nixos/programs/all.nix
      ../../modules/nixos/services/all.nix
    ];

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # Flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };


  # Packages and overlays
  nixpkgs.overlays = [ inputs.polymc.overlay ]; ## Within configuration.nix

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11"
  ];

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    # https://claude.ai/chat/c4669859-f224-409d-bed1-516fd26758e8
    amdvlk
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  # Enable audio -----------------------------------------------------------
  modules.audio.enable = true;

  # Enable networking ------------------------------------------------------
  modules.networking = {
    enable = true;
    firewall = {
      allowedPorts = [ 9 22 4321 3000 ];
    };
    vpn.netbird.enable = true;
  };

  # Window Manager & compositor --------------------------------------------
  modules.display.hyprland = {
    enable = true;
    greetd.enable = true;
    greetd.autoLogin = true;
    videoDrivers = [ "amdgpu" ];
    openGL = {
      enable = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
      extraPackages32 = with pkgs;[
        driversi686Linux.amdvlk
      ];

    };
  };
  modules.display.waybar.enable = true;

  # Boot -------------------------------------------------------------------
  modules.boot.useCustomConfig = true;




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
  };
  # auto-cpufreq
  modules.services.auto_cpu.enable = false;


  # Programs ---------------------------------------------------------------
  ## Enable direnv
  modules.programs.direnv.enable = true;

  ## Enable Yazi
  modules.programs.yazi.enable = true;

  ## Zsh
  modules.programs.zsh.enable = true;

  # Extra ------------------------------------------------------------------
  zramSwap.enable = true;
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];


  # Users  -----------------------------------------------------------------
  ## User accounts
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
    extraSpecialArgs = {
      inherit inputs username;
    };
    users."${username}" = import ./home.nix;
    backupFileExtension = "hm-bak";
  };

  # Fonts
  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
  ];


  # Security
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          # Removes the need for a password when using sudo
          command = "ALL";
          options = [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
        }
      ];
    }
  ];

  security.polkit.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  # Timezone 
  time.timeZone = "Europe/Sofia";

  ## Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  ## Extra locale settings
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


