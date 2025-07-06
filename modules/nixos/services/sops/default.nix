{ ... }:

{
  # SOPS configuration for this host
  sops.defaultSopsFile =
    ../../../../secrets/secrets.yaml; # Path to the main secrets file
  sops.defaultSopsFormat = "yaml"; # Format of the secrets file
  sops.age.keyFile =
    "/home/fractal-tess/.config/sops/age/keys.txt"; # Path to the age key file

  # Declare secrets to be managed by sops
  sops.secrets = {
    example_key = {
      owner = "fractal-tess";
      path = "/var/lib/fractal-tess/secrets";
    };
    hello = {
      owner = "fractal-tess";
      path = "/var/lib/fractal-tess/hello";
    };
  };
}
