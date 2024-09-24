{ pkgs, inputs, config, user, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  # Overlays
  nixpkgs.overlays = [ inputs.polymc.overlay ]; ## Within configuration.nix

  # Insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11"
  ];

  security.polkit.enable = true;
  # Flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  programs.dconf.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "nodev";
  # boot.loader.grub.useOSProber = true;

  networking.hostName = "vd";

  # ---
  # Networking
  networking.networkmanager.enable = true;

  # Network proxy 
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  xdg.mime.defaultApplications = {
    # Media files for VLC
    "audio/mpeg" = "vlc.desktop";
    "video/mp4" = "vlc.desktop";
    "video/mpeg" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "video/x-msvideo" = "vlc.desktop";

    # Image files for Nomacs
    "image/jpeg" = "org.nomacs.ImageLounge.desktop";
    "image/png" = "org.nomacs.ImageLounge.desktop";
    "image/gif" = "org.nomacs.ImageLounge.desktop";
    "image/bmp" = "org.nomacs.ImageLounge.desktop";

    # SVG files for Inkscape
    "image/svg+xml" = "org.inkscape.Inkscape.desktop";
  };

  # ---
  # Mobile dev
  # programs.adb.enable = true;
  #   services.udev.packages = [
  #  pkgs.android-udev-rules
  # ];

  # ---
  # Zram 
  # zramSwap.enable = true;


  # ---
  # Timezone 
  time.timeZone = "Europe/Sofia";

  # Internationalisation
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


  # ---
  # User accounts
  users.users.fractal-tess = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "adbusers" ];
    password = "password";
    # packages = with pkgs; [];
    # description = "";
  };
  # Make users mutable - allows them to change their password with passwd
  users.mutableUsers = true;



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


  ## Things to rehost
  # Dozzle
  # Indecisive
  # Minio


  # Shell (zsh)
  environment.pathsToLink = [ "/share/zsh" ];
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # --- 
  # SSHD (SSH daemon service)
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7pnb7H32DEXK262OZw0bgBZswsTRDJON2uLyUYXfsS root@coolify"
  ];


  # Hyprland
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };


  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "google-chrome-stable.desktop";
    "x-scheme-handler/https" = "google-chrome-stable.desktop";
    "text/html" = "google-chrome-stable.desktop";
  };

  # Greetd
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "fractal-tess";
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --greeting 'Welcome to NixOS!' --asterisks --remember --remember-user-session --time -cmd ${pkgs.hyprland}/bin/Hyprland}";
        user = "fractal-tess";
      };
    };
  };

  # GPU Drivers  (Nvidia)
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # intel-media-driver # LIBVA_DRIVER_NAME=iHD
      # intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

  };

  # Communication between windows
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs;[
      xdg-desktop-portal-gtk
      #xdg-desktop-portal-hyprland
    ];
  };

  # ---
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

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio = {
    enable = false;
    daemon.config = {
      flat-volumes = "yes";
    };
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # ---
  # Virtualisation & containers
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  # ---
  # Nnetworking
  # VPN
  services.netbird.enable = true;

  # Firewall
  networking.firewall = {

    allowedTCPPorts = [ 9 22 4321 ];
    allowedUDPPorts = [ 9 22 4321 ];
    enable = true;
    extraCommands = ''
      iptables -I INPUT 1 -i docker0 -p tcp -d 172.17.0.1 -j ACCEPT
      iptables -I INPUT 2 -i docker0 -p udp -d 172.17.0.1 -j ACCEPT
    '';
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Dbus
  services.dbus.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
  ];

  #environment.systemPackages = with pkgs; [
  #   polymc
  # ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
