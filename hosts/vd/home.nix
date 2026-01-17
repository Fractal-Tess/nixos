{ pkgs, username, ... }:

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs
    ../../modules/home-manager/theming.nix
  ];

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05"; # Don't change this
    sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

  # USER PACKAGES
  #============================================================================

  home.packages = with pkgs; [

    #--------------------------------------------------------------------------
    # SYSTEM UTILITIES
    #--------------------------------------------------------------------------

    # USB and boot tools
    ventoy # Bootable USB creation tool

    # Hardware monitoring and control
    lm_sensors # Hardware monitoring tools
    btop # Resource monitor with CPU, memory, disk, network
    nvtopPackages.nvidia # NVIDIA GPU monitoring
    ddcutil # Monitor control utility (DDC/CI)
    usbutils # USB device utilities

    # File system tools
    gparted # Partition editor
    parted # Command-line partition tool
    bleachbit # System cleaner
    trash-cli # FreeDesktop.org trash interface
    dysk # Modern disk usage utility with visual tree representation
    tree # Directory tree display utility
    eza # Modern replacement for ls with color and Git integration

    # File managers
    thunar # Lightweight file manager
    pcmanfm # Alternative lightweight file manager

    # Archive management
    mate.engrampa # Archive manager
    p7zip # 7-Zip implementation
    unzip # Extract compressed files in a ZIP archive
    zip # Create and extract ZIP archives

    # Search and text processing
    fzf # Command-line fuzzy finder
    ripgrep # Fast search tool (grep alternative)
    sd # Intuitive find & replace CLI
    jq # Command-line JSON processor
    yq # YAML/XML processor (jq for YAML)
    gron # Make JSON greppable
    fx # Command-line JSON processing tool
    calc # Command-line calculator

    # Process management and system info
    procs # Modern replacement for ps
    bottom # Cross-platform graphical process/system monitor
    htop # Interactive process viewer

    # Security and secrets
    sops # Secret management tool
    seahorse # GUI for GNOME Keyring
    openssl # Cryptography toolkit
    infisical # Infisical CLI for secret management

    #--------------------------------------------------------------------------
    # NETWORKING TOOLS
    #--------------------------------------------------------------------------

    # Network analysis and monitoring
    ngrok # Expose local servers to the internet
    lsof # Tool to list open files
    nmap # Network discovery and security auditing
    wireshark # Network protocol analyzer
    netcat # Networking utility for reading/writing network connections
    iperf3 # Network performance measurement
    bandwhich # Terminal bandwidth utilization tool
    nload # Console application which monitors network traffic
    speedtest-cli # Command line interface for testing internet bandwidth

    # Network management
    networkmanagerapplet # Network manager system tray
    openvpn # Open-source VPN solution
    gpclient # Interactively authenticate to GlobalProtect VPNs that require SAML
    wakeonlan # Wake devices using Wake-on-LAN

    # Network testing and analysis
    hping # TCP/IP packet assembler/analyzer
    oha # HTTP load generator
    mtr # Network diagnostic tool combining ping and traceroute
    dig # DNS lookup tool
    whois # Whois client for domain/IP information

    #--------------------------------------------------------------------------
    # DEVELOPMENT TOOLS
    #--------------------------------------------------------------------------

    # AI assistants
    aider-chat # AI pair programming in the terminal
    claude-code # AI code assistant
    opencode
    amp-cli
    appimage-run
    cursor-cli # Command-line interface for Cursor AI editor

    # Programming languages and runtimes
    nodejs_22 # JavaScript runtime
    pnpm # Fast, disk space efficient package manager
    bun # Fast, modern, all-in-one JavaScript runtime
    python3 # Python programming language
    uv # Python package installer and resolver
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain
    sqlite # SQLite database engine

    # Build tools
    gnumake # Build automation tool

    # Development utilities
    # flyctl # Command-line tool for fly.io
    hyperfine # Command-line benchmarking tool
    tokei # Count code statistics by language
    entr # Run arbitrary commands when files change
    watchexec # Execute commands in response to file modifications
    grex # Generate regular expressions from test cases

    # Version control
    gh # GitHub CLI
    forgejo-cli # Forgejo CLI tool
    lazygit # Simple terminal UI for git
    graphite-cli # CLI for creating stacked git changes

    # Security tools
    # burpsuite # Web vulnerability scanner

    #--------------------------------------------------------------------------
    # LANGUAGE SERVERS & FORMATTERS
    #--------------------------------------------------------------------------

    # Language servers
    svelte-language-server # Svelte language server
    emmet-language-server # Emmet language server
    tailwindcss-language-server # Tailwind CSS language server
    typescript-language-server # TypeScript language server
    astro-language-server # Astro language server
    vscode-langservers-extracted # HTML/CSS/JSON language servers
    package-version-server # NPM package version server
    docker-compose-language-service # Docker Compose language server
    dockerfile-language-server # Dockerfile language server
    rust-analyzer # Rust language server
    lua-language-server # Lua language server
    phpactor # PHP language server
    nixd # Nix language server
    nil # Alternative Nix language server
    sqls # SQL language server
    gopls # Go language server

    # Formatters
    stylua # Lua code formatter
    nixpkgs-fmt # Nix code formatter
    nixfmt # Nix code formatter
    prettierd # Code formatter daemon

    #--------------------------------------------------------------------------
    # MULTIMEDIA TOOLS
    #--------------------------------------------------------------------------

    # Audio/Video processing
    ffmpeg-full # Complete multimedia solution
    cava # Console-based audio visualizer

    # Media players
    vlc # Versatile media player
    mpv # Minimalist video player

    # Image viewers and editors
    nomacs # Image viewer
    gimp # GNU Image Manipulation Program
    inkscape # Vector graphics editor

    # Video editing and streaming
    kdePackages.kdenlive # Video editor
    obs-studio # Streaming and recording software
    kooha # Screen recorder for Wayland
    blender # 3D modeling and animation

    # Audio editing
    audacity # Audio editor and recorder

    #--------------------------------------------------------------------------
    # WAYLAND/HYPRLAND UTILITIES
    #--------------------------------------------------------------------------

    swww # Animated wallpaper daemon for Wayland
    waypaper # Wallpaper manager for Wayland
    linux-wallpaperengine # Wallpaper engine for Linux
    wl-clipboard # Clipboard utilities for Wayland
    grim # Screenshot utility for Wayland
    slurp # Region selector for Wayland
    hyprpicker # Color picker for Hyprland
    swaynotificationcenter # Notification daemon for Wayland
    gource # Version control visualization

    #--------------------------------------------------------------------------
    # GUI APPLICATIONS
    #--------------------------------------------------------------------------

    # Application launchers
    wofi # Wayland native application launcher

    # Web browsers
    firefox # Open-source web browser
    google-chrome # Google's web browser
    vivaldi # Feature-rich web browser
    vivaldi-ffmpeg-codecs # Video codecs for Vivaldi
    microsoft-edge # Microsoft's web browser
    tor-browser # Privacy-focused browser

    # Terminals
    warp-terminal # Modern terminal with AI features
    waveterm # Wave terminal for seamless workflows

    # System tools
    # rpi-imager # Raspberry Pi Imaging Utility (temporarily disabled due to build issues)
    f3 # SD card checker

    #--------------------------------------------------------------------------
    # COMMUNICATION
    #--------------------------------------------------------------------------

    discord # Voice, video and text chat
    telegram-desktop # Messaging app
    viber # Instant messaging
    slack # Team collaboration platform (temporarily disabled due to download failure)
    thunderbird # Email client

    #--------------------------------------------------------------------------
    # BLUETOOTH UTILITIES
    #--------------------------------------------------------------------------

    blueman # Bluetooth GUI manager
    carla # Audio plugin host (useful for Bluetooth audio testing)

    #--------------------------------------------------------------------------
    # OFFICE & PRODUCTIVITY
    #--------------------------------------------------------------------------

    libreoffice # Office suite
    obsidian # Knowledge base and note-taking
    bitwarden-desktop # Password manager

    #--------------------------------------------------------------------------
    # DEVELOPMENT ENVIRONMENTS
    #--------------------------------------------------------------------------

    code-cursor # VS Code fork with AI features
    zed-editor # Zed editor
    antigravity
    responsively-app # Web development tool for responsive design
    dbgate # Database manager
    postman # API development environment
    filezilla # FTP client

    #--------------------------------------------------------------------------
    # GAMING
    #--------------------------------------------------------------------------

    polymc # Minecraft launcher
    bottles # Wine wrapper
    heroic # Game launcher
    mangohud # FPS counter overlay
    protonup-qt # Proton version manager
    # (lutris.override { extraPkgs = pkgs: [ ]; }) # Game manager

    #--------------------------------------------------------------------------
    # TERMINAL ENHANCEMENTS
    #--------------------------------------------------------------------------

    # Terminal multiplexers
    zellij # Terminal multiplexer with layouts and session management

    # System information and utilities
    nitch # Lightweight system information fetch
    fastfetch # Fast system information tool
    lolcat # Rainbow text output
    nh # Nix helper CLI
    zathura # Document viewer
    man-pages

    # Modern CLI replacements and enhancements
    bat # Modern cat replacement with syntax highlighting
    fd # Modern find replacement
    zoxide # Smarter cd command with frecency
    tldr # Simplified man pages
    duf # Modern df replacement with better output
    dust # Modern du replacement

    #--------------------------------------------------------------------------
    # THEMING & CUSTOMIZATION
    #--------------------------------------------------------------------------

    nordic # Nordic theme
    font-manager # Font management tool
    cliphist # Clipboard history tool

    #--------------------------------------------------------------------------
    # MISCELLANEOUS
    #--------------------------------------------------------------------------

    qbittorrent # BitTorrent client
    stress # System stress testing tool

    #--------------------------------------------------------------------------
    # COMMENTED OUT / DISABLED
    #--------------------------------------------------------------------------

    # Steam gaming platform - configured at system level
    # steam
    # (steam.override {
    #   extraPkgs = pkgs: [ openldap ];
    #   nativeOnly = true;
    # }).run
    # steam-run

    # Alternative browsers
    # chromium

    # Development tools
    # kicad              # PCB design tool

    # Windows compatibility
    # wineWowPackages.stable

    # Screenshot tools (using grim/slurp instead)
    # (flameshot.override { enableWlrSupport = true; })

    # Nginx language server - temporarily disabled
    # nginx-language-server
  ];
}
