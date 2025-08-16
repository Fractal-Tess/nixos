# oci-container-functions.nix
{ lib, pkgs, ... }:

with lib;

let
  # Helper: Create port bindings
  mkPortBinds = bindings:
    map (binding:
      if isString binding then
        binding
      else
        "${toString binding.host}:${toString binding.container}") bindings;

  # Helper: Create bind mounts  
  mkBindMounts = mounts:
    map (mount:
      if isString mount then
        mount
      else
        "${mount.host}:${mount.container}${
          optionalString (mount ? options) ":${mount.options}"
        }") mounts;

in {
  inherit mkPortBinds mkBindMounts;

  # Main function: Create OCI container
  createOciContainer = { name, image, tag ? "latest", ports ? [ ], volumes ? [ ]
    , environment ? { }, cmd ? [ ], ... }: {
      virtualisation.oci-containers.containers.${name} = {
        image = "${image}:${tag}";
        ports = mkPortBinds ports;
        volumes = mkBindMounts volumes;
        environment = environment;
      };
    };
}
