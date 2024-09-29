{ pkgs, ... }: {
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ ];
}
