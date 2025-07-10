{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.disk-utils;
in {
  options.modules.services.disk-utils.enable = mkEnableOption "Disk utilities";

  # Configure disk utilities if enabled
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unzip # Extract .zip archives
      p7zip # File archiver with high compression ratio
      fd # Simple, fast alternative to 'find'
      dust # More intuitive version of du (disk usage)
      dysk # Disk usage reporting tool
    ];
  };
}
