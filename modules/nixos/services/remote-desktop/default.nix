#============================================================================
# REMOTE DESKTOP MODULE
#============================================================================
# Provides remote desktop access using Sunshine (host) and Moonlight client.
# Optimized for Wayland compositors (Hyprland).
#
# Usage:
#   modules.services.remote-desktop = {
#     enable = true;
#     sunshine = {
#       enable = true;
#       autoStart = true;
#     };
#     moonlight = true;  # Install Moonlight client
#   };
#============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.remote-desktop;
in
{
  #============================================================================
  # OPTIONS
  #============================================================================

  options.modules.services.remote-desktop = {
    enable = mkEnableOption "remote desktop services (Sunshine + Moonlight)";

    sunshine = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sunshine game streaming server (host).";
      };

      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically start Sunshine on graphical session login.";
      };

      capSysAdmin = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Grant CAP_SYS_ADMIN capability to Sunshine.
          Required for Wayland/KMS screen capture.
          Not needed for X11/Xorg.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall ports for Sunshine (47984-47990).";
      };

      avahi = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Avahi/mDNS for automatic service discovery.";
      };
    };

    moonlight = mkOption {
      type = types.bool;
      default = true;
      description = "Install Moonlight client for connecting to remote hosts.";
    };

    rustdesk = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable RustDesk client for alternative remote desktop.";
      };

      server = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable RustDesk self-hosted server (hbbs + hbbr).";
        };

        openFirewall = mkOption {
          type = types.bool;
          default = true;
          description = "Open firewall ports for RustDesk server.";
        };

        relayHosts = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            List of relay server hosts for the signal server.
            Required even if relay is disabled (use loopback IP if not using relay).
          '';
        };
      };
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================

  config = mkIf cfg.enable (mkMerge [
    #--------------------------------------------------------------------------
    # SUNSHINE HOST CONFIGURATION
    #--------------------------------------------------------------------------
    (mkIf cfg.sunshine.enable {
      # Enable Sunshine service
      services.sunshine = {
        enable = true;
        autoStart = cfg.sunshine.autoStart;
        capSysAdmin = cfg.sunshine.capSysAdmin;
        openFirewall = cfg.sunshine.openFirewall;
      };

      # Kernel module for input emulation (virtual mouse/keyboard/gamepad)
      boot.kernelModules = [ "uinput" ];

      # Udev rules for uinput device - REQUIRED for input to work
      services.udev.extraRules = ''
        # Sunshine uinput access
        KERNEL=="uinput", MODE="0660", GROUP="input", SYMLINK+="uinput", TAG+="uaccess"
      '';

      # Avahi/mDNS for service discovery (optional but recommended)
      services.avahi = mkIf cfg.sunshine.avahi {
        enable = mkDefault true;
        publish = {
          enable = mkDefault true;
          userServices = mkDefault true;
        };
      };

      # NOTE: User must be in 'input' group - add this in host configuration:
      # users.users.<username>.extraGroups = [ "input" ];
    })

    #--------------------------------------------------------------------------
    # MOONLIGHT CLIENT
    #--------------------------------------------------------------------------
    (mkIf cfg.moonlight {
      environment.systemPackages = with pkgs; [
        moonlight-qt
      ];
    })

    #--------------------------------------------------------------------------
    # RUSTDESK CLIENT
    #--------------------------------------------------------------------------
    (mkIf cfg.rustdesk.enable {
      environment.systemPackages = with pkgs; [
        rustdesk-flutter # Use flutter version (newer), not deprecated 'rustdesk'
      ];
    })

    #--------------------------------------------------------------------------
    # RUSTDESK SERVER (Self-hosted)
    #--------------------------------------------------------------------------
    (mkIf cfg.rustdesk.server.enable {
      services.rustdesk-server = {
        enable = true;
        openFirewall = cfg.rustdesk.server.openFirewall;
        signal.relayHosts = cfg.rustdesk.server.relayHosts;
      };
    })
  ]);
}
