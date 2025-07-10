{ ... }: {
  imports = [
    # Core system modules
    ./core/audio.nix
    ./core/boot.nix
    ./core/locale.nix
    ./core/networking.nix
    ./core/security.nix
    ./core/shell.nix
    ./core/time.nix

    # Drivers
    ./drivers/default.nix

    # Display
    ./display/default.nix

    # Programs
    ./programs/default.nix

    # Services
    ./services/default.nix
  ];
}
