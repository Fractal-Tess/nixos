{ pkgs, inputs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/sddm/default.nix
      ../../modules/nixos/auto-cpufreq/default.nix
      ./modules/audio.nix
      ./modules/boot.nix
      ./modules/display-protocol.nix
      ./modules/misc.nix
      ./modules/networking.nix
      ./modules/packages.nix
      ./modules/time-and-locale.nix
    ];

  nix.settings = {
    # Flakes
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };


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
    backupFileExtension = "hm-backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users = {
      "fractal-tess" = import ./home.nix;
    };
  };



  security.sudo.extraRules = [
    {
      users = [ "fractal-tess" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];



  system.stateVersion = "23.11";
}
