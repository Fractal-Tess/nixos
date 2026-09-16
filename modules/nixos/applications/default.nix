{ inputs, lib, ... }:
{
  imports = [
    inputs.asterveil.nixosModules.default
    inputs.clip-sync.nixosModules.default
    inputs.shadoword.nixosModules.default
    inputs.scorch.nixosModules.default
    inputs.gitadel.nixosModules.default
    inputs.oh-my-pi-flake.nixosModules.default
    inputs.open-design-flake.nixosModules.default
    inputs.responsively-flake.nixosModules.default
  ];

  programs.omp.enable = lib.mkDefault true;
  programs.scorch.enable = lib.mkDefault true;
  services.scorchd = {
    enable = lib.mkDefault true;
    address = lib.mkDefault "0.0.0.0";
  };
}
