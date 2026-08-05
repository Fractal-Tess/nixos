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
    inputs.clip-sync.nixosModules.default
    # inputs.comfyui-nix.nixosModules.default # temporarily disabled — re-enable after caches are trusted

    # Custom NixOS modules
    ../../modules/nixos/default.nix

    # System-wide packages
    ./packages.nix
  ];

  #============================================================================
  # SYSTEM CONFIGURATION
  #============================================================================

  # DO NOT CHANGE.
  system.stateVersion = "25.05";

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

  # Add 32GB swap file (swap partition already defined in hardware-configuration.nix)
  swapDevices = [
    {
      device = "/swapfile";
      size = 32 * 1024; # 32GB in MB
    }
  ];

  #============================================================================
  # CUSTOM MODULES CONFIGURATION
  #============================================================================

  sops.secrets.shadoword_api_token = {
    sopsFile = ../../secrets/shadoword.json;
    format = "json";
    owner = "shadoword";
    group = "shadoword";
    mode = "0600";
  };

  sops.secrets.clip_sync_mesh_key = {
    sopsFile = ../../secrets/clip-sync.json;
    format = "json";
    owner = username;
    group = "users";
    mode = "0400";
  };

  sops.templates."shadoword-desktop.json" = {
    owner = username;
    group = "users";
    mode = "0600";
    path = "/home/${username}/.config/shadoword/desktop.json";
    content = builtins.toJSON {
      mode = "remote";
      preload_on_startup = false;
      recording = {
        transcription_mode = "streaming";
        streaming_pcm_format = "s16le";
        english_only = true;
      };
      output = {
        copy_to_clipboard = true;
        paste_method = "direct";
        paste_delay_ms = 120;
      };
      remote = {
        endpoint = "http://100.91.0.2:47813";
        api_token = config.sops.placeholder.shadoword_api_token;
      };
      hotkey = {
        shortcut = "f2";
        mode = "push_to_talk";
      };
      close_to_tray = true;
    };
  };

  services.clip-sync.enable = true;

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
      nessus.enable = false; # Disabled for storage cleanup
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
        hermes-agent.enable = true;
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
        host = "100.91.0.2";
        port = 4096;
        extraArgs = [ "--print-logs" ];
      };

      shadoword-api = {
        enable = true;
        package = inputs.shadoword.packages.${pkgs.system}.shadoword-api-cuda;
        listenAddress = "100.91.0.2";
        tokenFile = config.sops.secrets.shadoword_api_token.path;
        requestRecordingDir = "/var/lib/shadoword/requests";
      };

      # Shared self-hosted web search and scraping API
      firecrawl = {
        enable = true;
        listenAddress = "100.91.0.2";
        port = 38473;
        llm = {
          enable = true;
          model = "gpt-5.4-mini";
        };
        agent = {
          enable = true;
          maxConcurrentJobs = 4;
        };
        search.imageSearch.enable = true;
        pdfOcr.enable = true;
      };

      # Hermes Agent
      hermes-agent = {
        enable = true;
        baseUrl = "https://chatgpt.com/backend-api/codex";
        provider = "openai-codex";
        container.enable = false;
        model = "gpt-5.3-codex-spark";
        firecrawlApiUrl = "http://100.91.0.2:38473";
        camofoxUrl = "http://100.91.0.2:9377";
        web = {
          search_backend = "firecrawl";
          extract_backend = "firecrawl";
        };
        extraDependencyGroups = [
          "messaging"
          "firecrawl"
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/blockade 0755 fractal-tess fractal-tess -"
    "d /home/${username}/.config/shadoword 0700 ${username} users -"
  ];

  environment.systemPackages = [
    inputs.shadoword.packages.${pkgs.system}.shadoword-desktop-client
    pkgs.wtype
    pkgs.xdotool
  ];

  networking.firewall = {
    allowedTCPPorts = [
      631
      8384
    ];
    interfaces.wt0.allowedTCPPorts = [ 38473 ];
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

  #============================================================================
  # SYSTEM SERVICES
  #============================================================================

  # Core system services
  services = {
    dbus.enable = true;
    gvfs.enable = true;

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
  # COMFYUI
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

  # ComfyUI — temporarily disabled, re-enable after caches are trusted
  # services.comfyui = {
  #   enable = true;
  #   gpuSupport = "cuda";
  #   port = 8188;
  #   listenAddress = "127.0.0.1";
  #   dataDir = "/var/lib/comfyui";
  #   enableManager = true;
  #   extraArgs = [
  #     "--lowvram"
  #     "--extra-model-paths-config"
  #     (toString (pkgs.writeText "extra-model-paths.yaml" ''
  #       vault:
  #         base_path: /mnt/vault/ComfyUI/models
  #         checkpoints: checkpoints/
  #         clip: clip/
  #         clip_vision: clip_vision/
  #         configs: configs/
  #         controlnet: controlnet/
  #         diffusers: diffusers/
  #         diffusion_models: diffusion_models/
  #         embeddings: embeddings/
  #         gligen: gligen/
  #         hypernetworks: hypernetworks/
  #         loras: loras/
  #         photomaker: photomaker/
  #         style_models: style_models/
  #         text_encoders: text_encoders/
  #         unet: unet/
  #         upscale_models: upscale_models/
  #         vae: vae/
  #         vae_approx: vae_approx/
  #     ''))
  #   ];
  # };

  # Binary caches for ComfyUI and CUDA packages (avoids building from source)
  nix.settings = {
    extra-substituters = [
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
    trusted-substituters = [
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
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
