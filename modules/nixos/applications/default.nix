{ inputs, ... }:
{
  imports = [
    inputs.asterveil.nixosModules.default
    inputs.clip-sync.nixosModules.default
    inputs.shadoword.nixosModules.default
    inputs.scorch.nixosModules.default
    inputs.gitadel.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.chorus.nixosModules.default
    inputs.oh-my-pi-flake.nixosModules.default
    inputs.open-design-flake.nixosModules.default
    inputs.responsively-flake.nixosModules.default
  ];
}
