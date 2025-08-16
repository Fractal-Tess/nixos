# oci-container-functions.nix
# This module provides helper functions for creating and configuring OCI containers
# in NixOS using the virtualisation.oci-containers module.
{ lib, pkgs, ... }:

with lib;

let
  # Helper: Create port bindings for container networking with protocol and firewall support
  # 
  # This function converts port specifications into the format expected by
  # virtualisation.oci-containers.containers.[name].ports and optionally
  # generates firewall rules for the specified ports.
  #
  # Parameters:
  #   bindings: List of port bindings, each must be an attribute set:
  #     - { host = 8080; container = 80; protocol = "tcp"; openfw = true; }
  #     - { host = 8080; container = 80; protocol = "udp"; openfw = false; }
  #
  # Returns:
  #   Attribute set with:
  #     ports: List of port binding strings in "hostPort:containerPort" format
  #     firewallPorts: List of host ports that should be opened in the firewall
  #     firewallProtocols: List of protocols for firewall rules
  #
  # Examples:
  #   mkPortBinds [
  #     { host = 8080; container = 80; protocol = "tcp"; openfw = true; }
  #     { host = 9000; container = 9000; protocol = "udp"; openfw = false; }
  #   ]
  mkPortBinds = bindings:
    let
      # Process each binding and extract ports, firewall ports, and protocols
      processed = map (binding: {
        port = "${toString binding.host}:${toString binding.container}";
        firewallPort = if binding.openfw or false then binding.host else null;
        protocol = binding.protocol or "tcp";
      }) bindings;

      # Extract just the port strings
      ports = map (item: item.port) processed;

      # Extract firewall ports (filter out nulls)
      firewallPorts =
        filter (port: port != null) (map (item: item.firewallPort) processed);

      # Extract protocols for firewall ports (only for ports that are opened)
      firewallProtocols = filter (protocol: protocol != null)
        (map (item: if item.firewallPort != null then item.protocol else null)
          processed);
    in { inherit ports firewallPorts firewallProtocols; };

  # Helper: Create bind mount specifications for container volumes
  #
  # This function converts volume mount specifications into the format expected by
  # virtualisation.oci-containers.containers.[name].volumes
  #
  # Parameters:
  #   mounts: List of volume mounts, each must be an attribute set:
  #     - { host = "/host/data"; container = "/data"; }
  #     - { host = "/host/config"; container = "/config"; options = "ro"; }
  #
  # Returns:
  #   List of volume mount strings in "hostPath:containerPath:options" format
  #
  # Examples:
  #   mkBindMounts [
  #     { host = "/host/data"; container = "/data"; }
  #     { host = "/host/config"; container = "/config"; options = "ro"; }
  #   ]
  mkBindMounts = mounts:
    map (mount:
      "${mount.host}:${mount.container}${
        optionalString (mount ? options) ":${mount.options}"
      }") mounts;

in {
  inherit mkPortBinds mkBindMounts;

  # Main function: Create OCI container configuration
  #
  # This function generates a complete container configuration that can be
  # directly merged into your NixOS configuration. It handles the common
  # container configuration patterns and provides sensible defaults.
  #
  # Parameters:
  #   name: String - The name of the container (used as the key in virtualisation.oci-containers.containers)
  #   image: String - The container image name (e.g., "nginx", "postgres")
  #   tag: String (optional, default: "latest") - The image tag to use
  #   ports: List (optional, default: []) - List of port bindings in the format:
  #     - { host = 3000; container = 3000; protocol = "tcp"; openfw = true; }
  #     - { host = 8080; container = 80; protocol = "tcp"; openfw = false; }
  #   volumes: List (optional, default: []) - List of volume mounts, use mkBindMounts for proper formatting
  #   environment: Attribute set (optional, default: {}) - Environment variables to pass to the container
  #   cmd: List (optional, default: []) - Command to run when the container starts
  #   extraOptions: List (optional, default: []) - Additional container options (e.g., --network, --device, --security-opt)
  #   autoStart: Boolean (optional, default: true) - Whether to automatically start the container
  #   ...: Additional attributes are passed through to the container configuration
  #
  # Returns:
  #   Attribute set with the structure:
  #   {
  #     virtualisation.oci-containers.containers.${name} = { ... };
  #     networking.firewall.allowedTCPPorts = [ ... ]; # If any TCP ports have openfw = true
  #     networking.firewall.allowedUDPPorts = [ ... ]; # If any UDP ports have openfw = true
  #   }
  #
  # Usage Example:
  #   ociLib.createOciContainer {
  #     name = "webapp";
  #     image = "myapp";
  #     tag = "v1.0.0";
  #     ports = [ 
  #       { host = 3000; container = 3000; protocol = "tcp"; openfw = true; }
  #       { host = 8080; container = 80; protocol = "tcp"; openfw = false; }
  #       { host = 9000; container = 9000; protocol = "udp"; openfw = true; }
  #     ];
  #     volumes = ociLib.mkBindMounts [ 
  #       { host = "/host/data"; container = "/app/data"; }
  #     ];
  #     environment = { NODE_ENV = "production"; };
  #     extraOptions = [
  #       "--network=host"
  #       "--security-opt=no-new-privileges:false"
  #       "--device=/dev/dri:/dev/dri"
  #     ];
  #   }
  createOciContainer = { name, image, tag ? "latest", ports ? [ ], volumes ? [ ]
    , environment ? { }, cmd ? [ ], extraOptions ? [ ], autoStart ? true, ... }:
    let
      portConfig = mkPortBinds ports;
      hasFirewallPorts = portConfig.firewallPorts != [ ];

      # Separate TCP and UDP ports for firewall configuration
      # Create pairs of ports and protocols, then filter by protocol
      portProtocolPairs =
        lib.zipLists portConfig.firewallPorts portConfig.firewallProtocols;

      # Filter TCP and UDP ports
      firewallTCPPorts = map (pair: pair.fst)
        (filter (pair: pair.snd == "tcp") portProtocolPairs);
      firewallUDPPorts = map (pair: pair.fst)
        (filter (pair: pair.snd == "udp") portProtocolPairs);
    in {
      virtualisation.oci-containers.containers.${name} = {
        image = "${image}:${tag}";
        ports = portConfig.ports;
        volumes = mkBindMounts volumes;
        environment = environment;
        extraOptions = extraOptions;
        autoStart = autoStart;
      };

      # Automatically open TCP firewall ports if any TCP ports have openfw = true
      networking.firewall.allowedTCPPorts =
        mkIf (firewallTCPPorts != [ ]) firewallTCPPorts;

      # Automatically open UDP firewall ports if any UDP ports have openfw = true
      networking.firewall.allowedUDPPorts =
        mkIf (firewallUDPPorts != [ ]) firewallUDPPorts;
    };
}
