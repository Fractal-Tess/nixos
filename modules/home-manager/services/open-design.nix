{
  config,
  inputs,
  osConfig,
  ...
}:

let
  cfg = config.services.open-design;
  hostName = osConfig.networking.hostName;
  netbirdOrigin = "http://${hostName}.netbird.cloud:${toString cfg.webFrontend.port}";

in
{
  imports = [
    inputs.open-design.homeManagerModules.default
  ];

  services.open-design = {
    enable = true;
    autoStart = true;
    webFrontend = {
      enable = true;
      host = "0.0.0.0";
      allowedOrigins = [ netbirdOrigin ];
    };
  };
}
