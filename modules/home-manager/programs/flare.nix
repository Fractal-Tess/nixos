{ pkgs, inputs, ... }:

{
  home.packages = [ inputs.flare.packages.x86_64-linux.default ];

  # Set the webkit environment variable for flare
  home.sessionVariables.WEBKIT_DISABLE_DMABUF_RENDERER = "1";

  systemd.user.services.flare = {
    Unit = {
      Description = "Flare launcher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${inputs.flare.packages.x86_64-linux.default}/bin/flare";
      Restart = "on-failure";
      Environment = "WEBKIT_DISABLE_DMABUF_RENDERER=1";
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
