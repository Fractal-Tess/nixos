{
  config,
  inputs,
  lib,
  username,
  ...
}:

{
  imports = [
    inputs.asterveil.nixosModules.default
    inputs.shadoword.nixosModules.default
    inputs.scorch.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.chorus.nixosModules.default
    inputs.oh-my-pi-flake.nixosModules.default
    inputs.responsively-flake.nixosModules.default
    inputs.t3code-flake.nixosModules.default
  ];

  config = lib.mkMerge [
    # OMP
    {
      programs.omp.enable = lib.mkDefault true;
    }

    # Asterveil
    {
      programs.asterveil.enable = true;
    }

    # Responsively
    {
      programs.responsively.enable = true;
    }

    # T3 Code
    {
      programs.t3code.enable = true;
    }

    # Scorch
    {
      programs.scorch.enable = lib.mkDefault true;
      services.scorchd = {
        enable = lib.mkDefault true;
        address = lib.mkDefault "0.0.0.0";
      };
    }

    # Gitadel
    {
      programs.gitadel-cli = {
        enable = lib.mkDefault true;
        serverUrl = lib.mkDefault "http://neo.netbird.cloud:3030";
        tokenFile = config.sops.secrets.gitadel_api_token.path;
      };
      sops.secrets.gitadel_api_token = lib.mkIf config.modules.services.sops.enable {
        owner = username;
        group = "users";
        mode = "0600";
        sopsFile = ../../secrets/gitadel.json;
        format = "json";
      };
    }

    # Chorus
    {
      services.chorus = {
        enable = true;
        engines = [ "kokoro" ];
        devices = [
          "cpu"
          "cuda:0"
        ];
        host = "0.0.0.0";
        port = 8749;
        openFirewall = false;
        downloadMissing = true;
        preload = [ "kokoro/82m-v1.0" ];
      };
      # Keep access on the mesh rather than opening the port on every interface.
      networking.firewall.interfaces.wt0.allowedTCPPorts = [ 8000 ];
    }

    # ClipSync
    {
      home-manager.users.${username}.services.clip-sync.enable = true;
      sops.secrets.clip_sync_mesh_key = {
        sopsFile = ../../secrets/clip-sync.json;
        format = "json";
        owner = username;
        group = "users";
        mode = "0400";
      };
    }

    # Open Design
    {
      home-manager.users.${username}.services.open-design = {
        enable = true;
        autoStart = true;
        port = 7457;
        webFrontend = {
          enable = true;
          host = "0.0.0.0";
          port = 38471;
          allowedOrigins = [
            "http://vd.netbird.cloud:38471"
            "http://localhost:38471"
            "http://127.0.0.1:38471"
          ];
        };
        mcp = {
          enable = true;
          port = 38472;
        };
      };
    }

    # Shadoword
    {
      services.shadoword-api = {
        enable = true;
        variant = "cuda";
        listenAddress = "100.91.0.2";
        requestRecordingDir = "/var/lib/shadoword/requests";
        initTokenFile = config.sops.secrets.shadoword_admin_token.path;
      };
      home-manager.users.${username}.services.shadoword-desktop = {
        enable = true;
        environment = {
          PATH = "/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin";
          # Keep the NVIDIA/Hyprland WebKit workaround local to this host.
          GDK_BACKEND = "x11";
          WEBKIT_DISABLE_DMABUF_RENDERER = "1";
        };
      };
      # Read by systemd as root into the daemon's credential store, not by the user.
      sops.secrets.shadoword_admin_token = {
        sopsFile = ../../secrets/shadoword.json;
        format = "json";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      sops.secrets.shadoword_user_token = {
        sopsFile = ../../secrets/shadoword.json;
        format = "json";
        owner = username;
        group = "users";
        mode = "0400";
      };
      systemd.tmpfiles.rules = [
        "d /home/${username}/.config/shadoword 0700 ${username} users -"
      ];
      # Wait for the interface before binding its address; expose the port only there.
      systemd.services.shadoword-api.after = [ "netbird.service" ];
      networking.firewall.interfaces.wt0.allowedTCPPorts = [ 47813 ];
    }
  ];
}
