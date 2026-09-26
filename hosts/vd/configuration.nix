{
  config,
  pkgs,
  inputs,
  username,
  lib,
  ...
}:
{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    # Hardware configuration
    ./hardware-configuration.nix

    # External modules
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # Custom NixOS modules
    ../../modules/nixos/default.nix
    ./applications.nix

    # System-wide packages
    ./packages.nix
  ];

  #============================================================================
  # SYSTEM CONFIGURATION
  #============================================================================

  # DO NOT CHANGE.
  system.stateVersion = "25.05";

  # Enable GlobalProtect-compatible VPN connections through NetworkManager.
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  services.libinput.enable = true;
  hardware.opentabletdriver.enable = true;

  programs.fuse.userAllowOther = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    glibc
    libxext
    libx11
    libxrender
    libxtst
    libuuid
  ];
  hardware.nvidia-container-toolkit.enable = true;
  hardware.graphics.enable32Bit = true;

  #============================================================================
  # NIX CONFIGURATION
  #============================================================================

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    cudaCapabilities = [ "8.6" ];
    allowInsecurePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "electron"
        "libsoup"
        "ventoy"
      ];
    permittedInsecurePackages = [
      "electron-27.3.11"
      "libsoup-2.74.3"
      "ventoy-1.1.07"
      "ventoy-1.1.10"
    ];
  };

  #============================================================================
  # HARDWARE CONFIGURATION
  #============================================================================

  # DDC support for external monitor brightness control
  # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/6
  boot.kernelModules = [ "i2c-dev" ];
  hardware.i2c.enable = true;

  # Wake-on-LAN support
  networking.interfaces.enp34s0.wakeOnLan.enable = true;

  #============================================================================
  # MEMORY MANAGEMENT
  #============================================================================

  # Enable zram for compressed RAM swapping
  zramSwap.enable = true;

  # Add 16GB swap file (swap partition already defined in hardware-configuration.nix)
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024; # 16GB in MB
    }
  ];

  #============================================================================
  # CUSTOM MODULES CONFIGURATION
  #============================================================================

  # virtualisation.libvirtd = {
  #   enable = true;
  #   qemu = {
  #     package = pkgs.qemu_kvm;
  #     runAsRoot = true;
  #     swtpm.enable = true;
  #   };
  # };
  virtualisation.vmware.host.enable = true;

  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
  # virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.guest.dragAndDrop = true;

  modules = {
    # Hardware drivers
    drivers.nvidia.enable = true;

    # Security
    security.noSudoPassword = true;

    # Display system
    display = {
      hyprland.enable = true;
      waybar.enable = true;
      sddm.enable = true;
      autologin.enable = true;
    };

    # Services
    services = {
      sshd.enable = true;
      automount.enable = true;
      syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        overrideDevices = false;
        overrideFolders = false;
        guiUser = "vgfractal";
        guiPasswordFile = "/home/fractal-tess/.config/secrets/syncthing/pass";
        settings = {
          devices = {
            "neo" = {
              id = "S2Y37JJ-ENKW65X-NTY3XIS-OEYF4PG-VACBQUK-N3CZVCF-MEK5QH3-PTNJUAR";
              addresses = [ "tcp://neo.netbird.cloud" ];
              untrusted = false;
            };
            "kiwi" = {
              id = "VBKYDOP-SIXFK2R-ON2TBRL-H2YDC2O-4U5LCC4-5HHRED2-LUVKEK6-CTX47Q4";
              addresses = [ "tcp://kiwi.netbird.cloud" ];
              untrusted = false;
            };
          };
          folders = {
            "omp-settings" = {
              path = "/home/fractal-tess/.omp/agent";
              id = "omp-settings";
              label = "OMP Settings";
              devices = [
                "neo"
                "kiwi"
              ];
              ignorePatterns = [
                "!/config.yml"
                "*"
              ];
            };
            "opencode-config" = {
              path = "/home/fractal-tess/.config/opencode";
              id = "opencode-config";
              label = "opencode-config";
              devices = [
                "neo"
                "kiwi"
              ];
            };
            "obsidian-vault" = {
              path = "/home/fractal-tess/dev/obsidian";
              id = "obsidian-vault";
              label = "Obsidian Vault";
              devices = [
                "neo"
                "kiwi"
              ];
            };
            "vivaldi-default" = {
              path = "/home/fractal-tess/.config/vivaldi/Default/Sessions";
              id = "vivaldi-default";
              label = "Vivaldi Default Sessions";
              devices = [
                "neo"
                "kiwi"
              ];
            };
            "vivaldi-profile1" = {
              path = "/home/fractal-tess/.config/vivaldi/Profile 1/Sessions";
              id = "vivaldi-profile1";
              label = "Vivaldi Profile 1 Sessions";
              devices = [
                "neo"
                "kiwi"
              ];
            };
          };
        };
      };
      sops = {
        enable = true;
        ssh.enable = true;
        z_ai.enable = true;
        minimax.enable = true;
        syncthing.enable = true;
        reactbits.enable = true;
        # linux_wallpaperengine.enable = true; # Disabled - using waypaper instead
      };

      # Virtualization
      # NOTE: Changed rootless to false for Dokploy/Swarm compatibility
      # Swarm mode is incompatible with rootless Docker
      virtualization = {
        docker = {
          enable = true;
          rootless = false; # Required for Dokploy/Swarm
          devtools = true;
          nvidia = true;
        };
        # kubernetes.enable = true; # Disabled; K3s and Kubernetes tools uninstalled
      };

      # Remote Desktop (Sunshine host + Moonlight client)
      # Provides low-latency remote desktop/game streaming over Wayland
      remote-desktop = {
        enable = true;
        sunshine = {
          enable = true;
          autoStart = true;
          capSysAdmin = true; # Required for Wayland/KMS capture
          openFirewall = true;
          avahi = true;
        };
        moonlight = true; # Install Moonlight client
      };

      # Kimi Web UI service
      kimi-web = {
        enable = true;
        port = 5494;
        allowedOrigins = [
          "http://vd.netbird.cloud:5494"
          "http://localhost:5494"
          "http://127.0.0.1:5494"
        ];
        workDir = "/home/fractal-tess";
        openFirewall = true;
      };

      # OpenCode Remote Server
      opencode-server = {
        enable = true;
        # Share the opencode-flake build with programs.opencode. The default is
        # pkgs.opencode, which would put a second, older opencode in PATH.
        package = config.programs.opencode.package;
        host = "100.91.0.2";
        port = 4096;
        extraArgs = [ "--print-logs" ];
      };

      # NetBird-accessible OpenAI-compatible proxy and management dashboard
      cliproxyapi = {
        enable = true;
        listenAddress = "100.91.0.2";
        publicHostname = "vd.netbird.cloud";
      };

    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/blockade 0755 fractal-tess fractal-tess -"
  ];

  environment.systemPackages = [
    pkgs.wtype
    pkgs.xdotool
  ];

  networking.firewall = {
    allowedTCPPorts = [
      631
      8384
    ];
  };

  #============================================================================
  # SYSTEM PACKAGES & PROGRAMS
  #============================================================================

  # Gaming configuration
  programs.steam = {
    enable = true;
    protontricks.enable = true; # Wine prefix management
    gamescopeSession.enable = true; # Better gaming performance

    # Enhanced compatibility
    extraCompatPackages = with pkgs; [ protonup-ng ];
  };

  #============================================================================
  # SECURITY & CERTIFICATES
  #============================================================================

  # Custom CA certificates
  security.pki.certificateFiles = [ ../../config/certs/carrierx.crt ];

  # Unlock the login keyring through SDDM so desktop apps can store credentials.
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    dbus.enable = true;
    gvfs.enable = true;

    # Secret Service provider used by Delta and other desktop applications.
    gnome.gnome-keyring.enable = true;

    # Printing support
    printing = {
      enable = true;
      drivers = [ ]; # Add printer drivers as needed
    };

    # Bluetooth GUI services
    blueman.enable = true;

  };

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  #============================================================================
  # USER CONFIGURATION
  #============================================================================

  users = {
    mutableUsers = true;

    users.${username} = {
      isNormalUser = true;
      description = "default user";
      password = "password";
      extraGroups = [
        "networkmanager"
        "video"
        "input"
        "seat"
        "wheel"
        "fractal-tess"
        "dialout"
        "docker" # Added for non-rootless Docker access
      ];
      packages = [ ];
    };

    groups.${username} = {
      members = [ username ];
    };
  };

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };
    users."${username}" = import ./home.nix;
    backupFileExtension = "hm-bak";
  };

  #============================================================================
  # FONTS
  #============================================================================

  fonts.packages = with pkgs; [
    adwaita-fonts
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
    cascadia-code
    font-awesome
    powerline-fonts
    powerline-symbols
  ];

  #============================================================================
  # LOCAL AI SERVICES
  #============================================================================

  # Ollama LLM service with CUDA
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    environmentVariables = {
      OLLAMA_NUM_PARALLEL = "4";
      OLLAMA_MAX_QUEUE = "128";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_KEEP_ALIVE = "10m";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };

  # Open WebUI for Ollama
  services.open-webui = {
    enable = false; # Disabled for storage cleanup
    port = 9090;
    host = "0.0.0.0";
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
    };
  };

  # Community binary cache
  nix.settings = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
  };

  #============================================================================
  # ENVIRONMENT VARIABLES
  #============================================================================

  environment.variables = {
    # Default editor configuration
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";

    # Development tools
    DIRENV_LOG_FORMAT = ""; # Silence direnv logging
  };
}
