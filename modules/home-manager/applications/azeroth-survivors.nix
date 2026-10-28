{ inputs, ... }:
{
  imports = [ inputs.azeroth-survivors.homeManagerModules.default ];
  programs.azeroth-survivors.enable = true;
}
