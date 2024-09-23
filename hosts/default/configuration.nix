# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/sddm/default.nix
      ../../modules/nixos/auto-cpufreq/default.nix
    ];

  nix.settings = {
    # Flakes
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    warn-dirty = true;
  };
  #
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  # Mobile dev
  programs.adb.enable = true;
  # services.udev.packages = [
  #   pkgs.android-udev-rules
  # ];

  # Zram 
  zramSwap.enable = true;

  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/etc/profiles/per-user/fractal-tess/bin/light -U 10"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/etc/profiles/per-user/fractal-tess/bin/light -A 10"; }
    ];
  };

  # Set your time zonesudo
  time.timeZone = "Europe/Sofia";

  # Select internationalisation properties.
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

  # Setting default editor to neovim
  # environment.variables.EDITOR = "nvim";
  # environment.variables.VISUAL = "nvim";
  # environment.variables.SUDO_EDITOR = "nvim";

  # Needed for zsh
  environment.pathsToLink = [ "/share/zsh" ];
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  services.xserver.windowManager.leftwm.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };


  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Docker
  virtualisation.docker.enable = true;
  # Netbird
  services.netbird.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.fractal-tess = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "adbusers" ];
    password = "password";
    # packages = with pkgs; [];
    # description = "";
  };
  # Make users mutable - allows them to change their password with passwd
  users.mutableUsers = true;

  # Home-Manger
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users = {
      "fractal-tess" = import ./home.nix;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Direnv 
  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [ ];



  security.sudo.extraRules = [
    {
      users = [ "fractal-tess" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
        }
      ];
    }
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      # PasswordAuthentication = true;
      PasswordAuthentication = false;
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 9 22 3000 4173 5173 8000 8080 8081 9000 ];
  networking.firewall.allowedUDPPorts = [ 9 22 3000 4173 5173 8000 8080 8081 9000 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
