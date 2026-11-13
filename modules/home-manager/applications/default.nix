{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.asterveil.homeManagerModules.default
    inputs.clip-sync.homeManagerModules.default
    inputs.shadoword.homeManagerModules.default
    inputs.scorch.homeManagerModules.default
    inputs.open-design-flake.homeManagerModules.default
    inputs.responsively-flake.homeManagerModules.default
  ];

  config = lib.mkIf config.services.clip-sync.enable {
    services.clip-sync.package =
      inputs.clip-sync.packages.${pkgs.stdenv.hostPlatform.system}.clip-sync.overrideAttrs
        (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
          # Keep encrypted history backed by SQLCipher when using system libraries.
          buildInputs = (old.buildInputs or [ ]) ++ [
            pkgs.openssl
            pkgs.sqlcipher
          ];
        });
  };
}
