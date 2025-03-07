{ config, lib, inputs, pkgs, ... }:

with lib;

let cfg = config.modules;

in {
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

  options.modules = {
    gui = mkEnableOption "Enable graphical user interface";
    drivers = {
      nvidia = mkEnableOption "Enable Nvidia drivers";
      amd = mkEnableOption "Enable AMD drivers";
    };
  };

  config = {
    # Assert conflicting configs
    assertions = [{
      assertion = !(cfg.drivers.nvidia && cfg.drivers.amd);
      message = "Nvidia and AMD drivers cannot be enabled at the same time.";
    }];

    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    environment.systemPackages = [ ];

    # Nix settings
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    hardware.graphics = mkIf cfg.gui {
      enable = true;
      enable32Bit = true;
    };

    # Allowing unfree and insecure
    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-27.3.11" ];
    };

    # Enable CUPS to print documents.
    # Enable CUPS for printing
    services.printing = mkIf cfg.gui {
      enable = true;
      drivers = with pkgs; [
        lexmark-aex # Lexmark printer drivers
        postscript-lexmark # PostScript drivers for Lexmark printers
        gutenprint # Additional printer drivers
        foomatic-filters # Required for many printers
        ghostscript # PostScript interpreter
      ];
    };

    # DBUS
    services.dbus.enable = true;

    # Android Debug Bridge
    # modules.services.adb.enable = mkIf cfg.tools.dev.mobile true;
    services.gvfs.enable = true;

    environment.variables = {
      # Fixes viber not lanuching
      QT_QPA_PLATFORM = mkIf cfg.gui "xcb";

      # Drivers
      LIBVA_DRIVER_NAME = mkIf cfg.gui "radeonsi";
      VDPAU_DRIVER = mkIf cfg.gui "radeonsi";

      GTK_THEME = mkIf cfg.gui "Nordic";
      XCURSOR_THEME = mkIf cfg.gui "Nordzy-cursors";
      XCURSOR_SIZE = mkIf cfg.gui "24";

      # Silence direnv env loading output
      DIRENV_LOG_FORMAT = mkIf cfg.gui "";

      # If cursor becomes invisible
      # WLR_NO_HARDWARE_CURSORS = mkIf cfg.gui "1";

      # Hint to electron apps to use wayland
      NIXOS_OZONE_WL = mkIf cfg.gui "1";

      # Editor
      VISUAL = mkIf cfg.gui "nvim";
      SUDO_EDITOR = mkIf cfg.gui "nvim";
      EDITOR = mkIf cfg.gui "nvim";

      # Firefox
      MOZ_USE_WAYLAND = mkIf cfg.gui 1;
      MOZ_USE_XINPUT2 = mkIf cfg.gui 1;
    };

  };
}
