{ config, pkgs, lib, createOciContainer, ... }:

let
  # Test container to see the structure
  testContainer = createOciContainer {
    name = "test";
    image = "alpine";
    tag = "latest";
    ports = [{
      host = 1234;
      container = 1234;
      protocol = "tcp";
      openfw = true;
    }];
  };

  # Debug: let's see what the structure actually looks like
  debug = {
    testContainer = testContainer;
    testContainerKeys = lib.attrNames testContainer;
    testContainerVirtualisation =
      testContainer.virtualisation or "no virtualisation";
    testContainerOciContainers =
      testContainer.virtualisation.oci-containers or "no oci-containers";
    testContainerContainers =
      testContainer.virtualisation.oci-containers.containers or "no containers";
  };

in {
  # Just return debug info
  _module.args.debug = debug;
}
