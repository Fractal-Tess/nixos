{ config, lib, pkgs, ... }:

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

    # Shell
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    environment.systemPackages = with pkgs; [ ];

    # Nix settings
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
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
  };
}
