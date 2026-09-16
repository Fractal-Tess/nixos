{ lib, package }:
{
  enable = lib.mkEnableOption "Hello";
  package = lib.mkOption {
    type = lib.types.package;
    default = package;
    description = "Package to install. Select versions through the flake input or override this package.";
  };
}
