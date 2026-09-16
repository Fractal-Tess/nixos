{ inputs, ... }:
{
  imports = [
    inputs.asterveil.homeManagerModules.default
    inputs.clip-sync.homeManagerModules.default
    inputs.shadoword.homeManagerModules.default
    inputs.scorch.homeManagerModules.default
    inputs.oh-my-pi-flake.homeManagerModules.default
    inputs.open-design-flake.homeManagerModules.default
    inputs.responsively-flake.homeManagerModules.default
  ];
}
