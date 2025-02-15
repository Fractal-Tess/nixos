{ config, lib, inputs, ... }:

with lib;

let cfg = config.modules;

in {
  options.modules = {
    template = {
      desktop = mkEnableOption "Enable desktop mode";
      headless = mkEnableOption "Enable headless mode";
    };
    drivers = {
      nvidia = mkEnableOption "Enable Nvidia drivers";
      amd = mkEnableOption "Enable AMD drivers";
    };
    tools = {
      dev = {
        mobile = mkEnableOption "Enable mobile development tools";
        games = mkEnableOption "Enable game development tools";
      };
    };
  };

  imports = [
    ./core/audio.nix
    ./core/boot.nix
    ./core/locale.nix
    ./core/networking.nix
    ./core/security.nix
    ./core/shell.nix
    ./core/time.nix

    ./drivers/nvidia.nix
    ./display/all.nix
    ./services.nix
    ./programs.nix

    ./services/index.nix
  ];

  config = {
    # Assert conflicting configs
    assertions = [
      {
        assertion = !(cfg.drivers.nvidia && cfg.drivers.amd);
        message = "Nvidia and AMD drivers cannot be enabled at the same time.";
      }
      {

        assertion = (cfg.template.desktop || cfg.template.headless)
          && !(cfg.template.desktop && cfg.template.headless);
        message =
          "Either desktop or headless mode must be enabled, but not both at the same time.";
      }
    ];

    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    environment.systemPackages = [ ];

    # Nix settings
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    hardware.graphics = mkIf cfg.template.desktop {
      enable = true;
      enable32Bit = true;
    };

    # Allowing unfree and insecure
    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-27.3.11" ];
    };

    # Enable CUPS to print documents.
    services.printing.enable = mkIf cfg.template.desktop true;

    # DBUS
    services.dbus.enable = true;

    # Android Debug Bridge
    modules.services.adb.enable = mkIf cfg.tools.dev.mobile true;

    environment.variables = {
      # Fixes viber not lanuching
      QT_QPA_PLATFORM = "xcb";

      # Drivers
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";

      GTK_THEME = "Nordic";
      XCURSOR_THEME = "Nordzy-cursors";
      XCURSOR_SIZE = "24";

      # Silence direnv env loading ouput
      DIRENV_LOG_FORMAT = "";

      # If cursor becomes invisible
      # WLR_NO_HARDWARE_CURSORS = "1";

      # Hint to electron apps to use wayland
      NIXOS_OZONE_WL = "1";

      # Editor
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
      EDITOR = "nvim";

      # Firefox
      MOZ_USE_WAYLAND = 1;
      MOZ_USE_XINPUT2 = 1;
    };

  };
}
