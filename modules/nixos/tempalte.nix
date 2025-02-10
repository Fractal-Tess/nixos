{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.template;

in {
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

  options.modules = {
    template = {
      desktop = mkEnableOption "Enable desktop mode";
      headless = mkEnableOption "Enable headless mode";
    };
    drivers = {
      nvidia = mkDefault false;
      amd = mkDefault false;
    };
    tools = {
      dev = {
        mobile = mkDefault false;
        games = mkDefault false;
      };
    };
  };

  config = {
    # Assert conflicting configs
    assertions = [
      {
        assertion = !(cfg.drivers.nvidia && cfg.drivers.amd);
        message = "Either Nvidia or AMD drivers must be enabled, but not both.";
      }
      {
        assertion = cfg.desktop != cfg.headless;
        message =
          "Either desktop mode or headless mode must be enabled, but not both.";
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
    services.printing.enable = mkIf cfg.desktop true;

    # DBUS
    services.dbus.enable = true;

    # Android Debug Bridge
    modules.services.adb.enable = mkIf cfg.tools.dev.mobile true;
  };
}
