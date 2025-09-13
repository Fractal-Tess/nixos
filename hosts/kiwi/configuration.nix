{ pkgs, inputs, username, ... }:

{
  imports = [
    # System configuration
    ./hardware-configuration.nix

    # Home manager
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # NixOS modules
    ../../modules/nixos/default.nix
  ];

  # DDC support
  # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/6
  boot.kernelModules = [ "i2c-dev" ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  hardware.i2c.enable = true;

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "libsoup-2.74.3" ];
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  environment.systemPackages = with pkgs; [ ];
  programs.steam = {
    enable = true;
    # Required for managing Wine prefixes
    protontricks.enable = true;
    # Recommended for better gaming performance
    gamescopeSession.enable = true;

    # Install Proton-GE for better compatibility
    extraCompatPackages = with pkgs; [ protonup ];

    # Additional libraries needed for Wine/Proton
    extraPackages = with pkgs; [
      # Basic dependencies
      keyutils
      libkrb5
      libpng
      libpulseaudio
      # Media support
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      # 32-bit libraries
      pkgsi686Linux.keyutils
      pkgsi686Linux.libkrb5
    ];
  };

  modules = {
    # ----- Drivers -----
    drivers.amd.enable = true;

    # ----- Security -----
    security.noSudoPassword = true;

    # ----- Display -----
    display = {
      # ----- Hyprland -----
      hyprland.enable = true;

      # ----- ReGreet -----
      regreet = {
        enable = true;
        symlinkBackgrounds = true;
      };
    };

    # ----- Bar -----
    display.waybar.enable = true;

    # ----- Virtualization -----
    services.virtualization = {
      docker = {
        enable = true;
        rootless = true;
        devtools = true;
      };
      firecracker.enable = false;
      kubernetes.enable = false;

      # --- Containers   ---
      # containers = {
      #   # Add container configurations here if needed
      # };
    };

    # ----- SSHD -----
    services.sshd.enable = true;

    # ----- Automount -----
    services.automount.enable = true;

    # ----- Samba shares -----
    services.samba.mount = {
      enable = true;
      shares = [
        {
          mountPoint = "/mnt/blockade";
          device = "//neo.netbird.cloud/blockade";
          username = "fractal-tess";
          password = "smbpass";
        }
        {
          mountPoint = "/mnt/oracle";
          device = "//oracle.netbird.cloud/home";
          username = "smbuser";
          password = "smbpass";
        }
        {
          mountPoint = "/mnt/vault";
          device = "//vd.netbird.cloud/vault";
          username = "fractal-tess";
          password = "smbpass";
        }
        {
          mountPoint = "/mnt/backup";
          device = "//vd.netbird.cloud/backup";
          username = "fractal-tess";
          password = "smbpass";
        }
      ];
    };

    # Samba share service
    services.samba.share = {
      enable = true;
      shares = [{
        name = "home";
        path = "/home/${username}";
        forceUser = username;
        forceGroup = "users";
      }];
    };

    # SOPS
    services.sops = {
      enable = true;
      ssh.enable = true;
    };
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

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
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

  # TLP - Balanced power management for laptop
  services.tlp = {
    enable = true;
    settings = {
      # CPU scaling governors
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy performance policy
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # CPU performance limits
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;

      # Power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # USB autosuspend
      USB_AUTOSUSPEND = 1;

      # PCI Express power management
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Sound card power saving
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # Battery thresholds to preserve battery health
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Disable power-profiles-daemon as it conflicts with TLP
  services.power-profiles-daemon.enable = false;

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
