{ config, lib, pkgs, ... }:

with lib;


let
  cfg = config.modules.programs;
  gui = cfg.gui;
  cli = cfg.cli;
in
{
  options.modules.programs = {
    enable = mkEnableOption "Programs";
    cli = {
      core = mkEnableOption "Core";
      devtools = mkEnableOption "Devtools";
      language-servers = mkEnableOption "Language Servers";
      extra = mkEnableOption "Extra";
    };
    gui = {
      core = mkEnableOption "Core";
      communication = mkEnableOption "Communication";
      browsers = mkEnableOption "Browsers";
      office = mkEnableOption "Office";
      devtools = mkEnableOption "Devtools";
      games = mkEnableOption "Games";
      fonts = mkEnableOption "Fonts";
      extra = mkEnableOption "Extra";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkMerge [
      # CLI ------
      (with pkgs;
      optionals cli.core [
        neovim # Text editor
        usbutils # USB utils
        lm_sensors # System sensors

        fzf # Fuzzy finder
        ripgrep # Rg
        sd # Sed alternative
        procs # ps replacement
        fd # Find replacement

        dust # Disk usage
        unzip # Unzip files
        p7zip # 7zip
        trash-cli # Trash files
        yazi # File manager

        btop # Top replacement

        ngrok # Tunneling
        nmap # Network scanner
        networkmanagerapplet # Network manager
        openvpn # VPN
        wakeonlan # Wake on lan util
        hping # Network ping  util
        oha # HTTP benchmark
      ])

      (with pkgs;
      optionals cli.devtools [
        aider-chat # AI code assistant
        claude-code # AI code assistant

        pnpm # Package manager

        # bun # JavaScript runtime
        # deno # JavaScript runtime
        nodejs_22 # JavaScript runtime

        # php # PHP runtime
        # phpPackages.composer # PHP package manager
        # laravel # PHP framework
        gcc # C compiler
        clang-tools # C compiler
        gnumake # GNU Make

        flyctl # Fly.io CLI


        jq # JSON processor
        hyperfine # Command benchmark
        gh # Github CLI
        lazygit # Git GUI
        burpsuite # Web pentesting
      ])

      (with pkgs;
      optionals cli.language-servers [
        prettierd # Format code
        svelte-language-server # Svelte language server
        emmet-language-server # Emmet language server
        tailwindcss-language-server # Tailwind CSS language server
        typescript-language-server # TypeScript language server
        astro-language-server # Astro language server
        docker-compose-language-service # Docker Compose language service
        dockerfile-language-server-nodejs # Dockerfile language server
        rust-analyzer # Rust language server
        lua-language-server # Lua language server
        stylua # Lua formatter
        nginx-language-server # Nginx language server
        phpactor # PHP language server
        nixd # Nix language server
        nixpkgs-fmt # Nix formatter
        nixfmt-classic # Nix formatter
        vscode-langservers-extracted # VSCode language servers
        sqls # SQL language server
        gopls # Go language server
        nixfmt-classic # Nix formatter
      ])

      (with pkgs;
      optionals cli.extra [
        ffmpeg-full # Video converter
        # nvtopPackages.nvidia

        stress # Cpu stress
        # geekbench # System benchmark
        # carbon-now-cli # Code to image

        tokei # Code stats

        # Wallpaper manager
        swww
        waypaper

        zathura # PDF viewer

        nh # Nix cleaner

        # Clipboard
        wl-clipboard # Clipboard for neovim

        # Screenshot
        grim # Wayland screenshotter
        slurp # Screen coordinates picker

        # Flex
        neofetch # System info
        nitch # System info
        lolcat # Colorful gradient stdin to stdout
        cava # Audio visualizer
      ])

      # GUI ------
      (with pkgs;
      optionals gui.core [
        # qbittorrent-enhanced # Torrent client
        ulauncher # Application launcher
        wofi # Used for cliphist

        firefox # Firefox
        google-chrome # Chrome
        microsoft-edge # Edge
        # safari # Safari

        hyprpicker # Color picker
        kooha # Screen recorder
        nomacs # Image viewer
        vlc # Media player
        mpv # Media player
        pcmanfm # File manager
        mate.engrampa # Archive manager
        nextcloud-client # Nextcloud client

        # Notifications 
        swaynotificationcenter

        # lxmenu-data
        # shared-mime-info

        # avidemux # Video editor

        obs-studio # Recording and streaming

        warp-terminal # Terminal emulator
      ])

      (with pkgs;
      optionals gui.communication [
        discord # Chat platform
        telegram-desktop # Chat platform
        bitwarden # Password manager
        viber # Chat platform
        slack # Chat platform
        thunderbird # Email client
      ])

      (with pkgs;
      optionals gui.office [
        libreoffice # Office suite
        obsidian # Note taking
        # logseq # Note taking
        kdePackages.kdenlive
      ])

      (with pkgs;
      optionals gui.devtools [
        code-cursor # Cursor
        zed-editor # Zed
        # gparted # Partition manager
        responsively-app # Responsive web development
        # tiled # Tile manager
        # unityhub # Unity launcher
        # gitkraken # Git GUI
        dbgate # DB client
        # dbeaver-bin # DB client
        postman # API testing
        # insomnia # API testing
        filezilla # FTP client
        wireshark # Network analyzer
      ])

      (with pkgs;
      optionals gui.games [
        steam # Gaming platform
        polymc # Minecraft launcher
        wineWowPackages.stable # support both 32-bit and 64-bit applications
        (lutris.override { extraPkgs = pkgs: [ ]; })
      ])

      (with pkgs;
      optionals gui.fonts [
        nordic # Theme
        font-manager # Font manager
        cliphist # Clipboard history
      ])

      (with pkgs;
      optionals gui.extra [
        # blender # 3D modeling
        # kicad # PCB design
        # audacity # Audio editor
        # gimp # Image editor
        # inkscape # Vector graphics
      ])
    ];
  };
}

