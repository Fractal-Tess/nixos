{ lib }:

let
  # Test the firewall port extraction logic
  extractFirewallPorts = containers:
    let
      # Extract all ports with openfw = true from container configurations
      allPorts = lib.concatMap (container:
        lib.optionals (container ? ports)
        (lib.filter (port: port.openfw or false) container.ports))
        (lib.attrValues containers);

      # Separate TCP and UDP ports
      tcpPorts = lib.unique (lib.map (port: port.host)
        (lib.filter (port: port.protocol == "tcp") allPorts));
      udpPorts = lib.unique (lib.map (port: port.host)
        (lib.filter (port: port.protocol == "udp") allPorts));
    in {
      tcp = tcpPorts;
      udp = udpPorts;
    };

  # Test containers with various port configurations
  testContainers = {
    test1 = {
      ports = [{
        host = 7878;
        protocol = "tcp";
        openfw = true;
      }];
    };
    test2 = {
      ports = [
        {
          host = 8096;
          protocol = "tcp";
          openfw = true;
        }
        {
          host = 7359;
          protocol = "udp";
          openfw = true;
        }
      ];
    };
    test3 = {
      ports = [{
        host = 9000;
        protocol = "tcp";
        openfw = false;
      } # This should NOT be included
        ];
    };
    test4 = {
      # Container without ports should be handled gracefully
    };
  };

  result = extractFirewallPorts testContainers;

in {
  inherit result;
  # Expected: tcp = [7878, 8096], udp = [7359]
}
