{ flake }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.programs.hello = import ./options.nix {
    inherit lib;
    package = flake.packages.${pkgs.stdenv.hostPlatform.system}.hello;
  };
  config = lib.mkIf config.programs.hello.enable {
    environment.systemPackages = [ config.programs.hello.package ];
  };
}
