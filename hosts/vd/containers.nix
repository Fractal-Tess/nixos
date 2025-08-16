# configuration.nix
{ config, pkgs, lib, ... }:

let
  ociLib = import ./oci-container.nix { inherit lib pkgs; };

  # Simple nginx container
in ociLib.createOciContainer {
  name = "nginx";
  image = "nginx";

  ports = ociLib.mkPortBinds [ "8080:80" ];

  volumes = ociLib.mkBindMounts [ ];
}
