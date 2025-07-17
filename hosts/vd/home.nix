{ pkgs, username, lib, osConfig, ... }:

with lib;
let cfg = osConfig;
in {
  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs.nix
    ../../modules/home-manager/theming.nix
  ];

  # Home Manager
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Home manager version - don't change this
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Has to exist so other home manager modules can mkMerge
  home.packages = with pkgs; [
    # === SYSTEM UTILITIES ===
    usbutils # USB device utilities
    lm_sensors # Hardware monitoring tools
    btop # Resource monitor with CPU, memory, disk, network
    trash-cli # Command line interface to FreeDesktop.org trash
    ddcutil # Monitor control utility (DDC/CI)
    sops # Secret management tool
    nvtopPackages.nvidia
    xfce.thunar

    # === SEARCH TOOLS ===
    fzf # Command-line fuzzy finder
    ripgrep # Fast search tool (grep alternative)
    sd # Intuitive find & replace CLI

    # === PROCESS MANAGEMENT ===
    procs # Modern replacement for ps

    # === NETWORKING TOOLS ===
    ngrok # Expose local servers to the internet
    nmap # Network discovery and security auditing
    networkmanagerapplet # Network manager system tray
    openvpn # Open-source VPN solution
    wakeonlan # Wake devices using Wake-on-LAN
    hping # Command-line TCP/IP packet assembler/analyzer
    oha # HTTP load generator

    # === DEVELOPMENT TOOLS ===
    # AI Assistants
    aider-chat # AI pair programming in the terminal
    claude-code # AI code assistant

    # Languages & Runtimes
    nodejs_22 # JavaScript runtime
    pnpm # Fast, disk space efficient package manager
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain

    # Build Tools
    gnumake # Build automation tool

    # Development Utilities
    flyctl # Command-line tool for fly.io
    jq # Command-line JSON processor
    hyperfine # Command-line benchmarking tool

    # Version Control
    gh # GitHub CLI
    lazygit # Simple terminal UI for git

    # Security Tools
    burpsuite # Web vulnerability scanner

    # === LANGUAGE SERVERS ===
    # Web Development
    prettierd # Code formatter daemon for web technologies
    svelte-language-server # Language server for Svelte
    emmet-language-server # Language server for Emmet
    tailwindcss-language-server # Language server for Tailwind CSS
    typescript-language-server # Language server for TypeScript
    astro-language-server # Language server for Astro
    vscode-langservers-extracted # HTML/CSS/JSON language servers

    # DevOps
    docker-compose-language-service # Language server for Docker Compose
    dockerfile-language-server-nodejs # Language server for Dockerfiles

    # Programming Languages
    rust-analyzer # Language server for Rust
    lua-language-server # Language server for Lua
    stylua # Lua code formatter
    nginx-language-server # Language server for Nginx
    phpactor # Language server for PHP
    nixd # Language server for Nix
    nixpkgs-fmt # Nix code formatter
    nixfmt-classic # Alternative Nix formatter
    sqls # Language server for SQL
    gopls # Language server for Go

    # === MULTIMEDIA TOOLS ===
    ffmpeg-full # Complete multimedia solution
    cava # Console-based audio visualizer

    # === SYSTEM MONITORING ===
    stress # Workload generator for system testing
    tokei # Count code statistics by language

    # === WAYLAND UTILITIES ===
    swww # Efficient animated wallpaper daemon for Wayland
    waypaper # Wallpaper manager for Wayland
    wl-clipboard # Command-line clipboard utilities for Wayland
    grim # Screenshot utility for Wayland
    slurp # Region selector for Wayland
    hyprpicker # Color picker for Hyprland
    # (flameshot.override { enableWlrSupport = true; })

    # === TERMINAL ENHANCEMENTS ===
    nitch # Lightweight system information fetch
    lolcat # Rainbow text output
    nh # Nix helper CLI
    zathura # Document viewer

    # === GUI APPLICATIONS ===
    # Launchers & System Tools
    ulauncher # Application launcherr
    wofi # Wayland native application launcher
    swaynotificationcenter # Notification daemon for Wayland
    rpi-imager # Raspberry Pi Imaging Utility
    f3 # Sd card checker

    # Web Browsers
    firefox # Open-source web browser
    google-chrome # Google's web browser
    # chromium # Chromium web browser
    microsoft-edge # Microsoft's web browser
    tor-browser # Privacy-focused browser

    # File Management
    pcmanfm # Lightweight file manager
    mate.engrampa # Archive manager

    # Media Players
    vlc # Versatile media player
    mpv # Minimalist video player
    kooha # Screen recorder for Wayland
    nomacs # Image viewer
    obs-studio # Streaming and recording software

    # Terminals
    warp-terminal # Modern terminal with AI features

    # === COMMUNICATION ===
    discord # Voice, video and text chat
    telegram-desktop # Messaging app
    bitwarden # Password manager
    viber-appimage # Voice and messaging app
    slack # Team collaboration platform
    thunderbird # Email client

    # === OFFICE & PRODUCTIVITY ===
    libreoffice # Office suite
    obsidian # Knowledge base and note-taking
    kdePackages.kdenlive # Video editor

    # === DEVELOPMENT ENVIRONMENTS ===
    code-cursor # VS Code fork with AI features
    zed-editor # High-performance code editor
    responsively-app # Web development tool for responsive design
    dbgate # Database manager
    postman # API development environment
    filezilla # FTP client

    # === GAMING ===
    # steam # Gaming platform
    # (steam.override {
    #   extraPkgs = pkgs: [ openldap ];
    #   # nativeOnly = true;
    # }).run
    # # steam-run # Steam runtime
    polymc # Minecraft launcher
    bottles # Wine wrapper
    heroic # Game launcher
    mangohud # FPS counter
    protonup-qt # Proton wrapper
    # wineWowPackages.stable # Windows compatibility layer
    (lutris.override { extraPkgs = pkgs: [ ]; }) # Game manager

    # === THEMING & CUSTOMIZATION ===
    nordic # Nordic theme
    font-manager # Font management tool
    cliphist # Clipboard history tool

    # === COMMENTED OUT ===
    blender
    # kicad
    audacity
    gimp
    inkscape

    qbittorrent # BitTorrent client
  ];

}
