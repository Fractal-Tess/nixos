{ pkgs, username, ... }:

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs.nix
    ../../modules/home-manager/theming.nix
  ];

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05"; # Don't change this
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

  # USER PACKAGES
  #============================================================================

  home.packages = with pkgs; [

    #--------------------------------------------------------------------------
    # SYSTEM UTILITIES
    #--------------------------------------------------------------------------

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
    xfce.thunar # Lightweight file manager
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

    # Process management and system info
    procs # Modern replacement for ps
    bottom # Cross-platform graphical process/system monitor
    htop # Interactive process viewer

    # Security and secrets
    sops # Secret management tool
    seahorse # GUI for GNOME Keyring

    #--------------------------------------------------------------------------
    # NETWORKING TOOLS
    #--------------------------------------------------------------------------

    # Network analysis and monitoring
    ngrok # Expose local servers to the internet
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
    claude-flow # Enterprise AI agent orchestration platform

    # Programming languages and runtimes
    nodejs_22 # JavaScript runtime
    pnpm # Fast, disk space efficient package manager
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain

    # Build tools
    gnumake # Build automation tool

    # Development utilities
    flyctl # Command-line tool for fly.io
    hyperfine # Command-line benchmarking tool
    tokei # Count code statistics by language
    entr # Run arbitrary commands when files change
    watchexec # Execute commands in response to file modifications
    grex # Generate regular expressions from test cases

    # Version control
    gh # GitHub CLI
    lazygit # Simple terminal UI for git

    # Security tools
    burpsuite # Web vulnerability scanner

    #--------------------------------------------------------------------------
    # LANGUAGE SERVERS & FORMATTERS
    #--------------------------------------------------------------------------

    # Web development
    prettierd # Code formatter daemon
    svelte-language-server # Svelte language server
    emmet-language-server # Emmet language server
    tailwindcss-language-server # Tailwind CSS language server
    typescript-language-server # TypeScript language server
    astro-language-server # Astro language server
    vscode-langservers-extracted # HTML/CSS/JSON language servers

    # DevOps
    docker-compose-language-service # Docker Compose language server
    dockerfile-language-server-nodejs # Dockerfile language server

    # Programming languages
    rust-analyzer # Rust language server
    lua-language-server # Lua language server
    stylua # Lua code formatter
    phpactor # PHP language server
    nixd # Nix language server
    nil # Alternative Nix language server
    nixpkgs-fmt # Nix code formatter
    nixfmt-classic # Alternative Nix formatter
    sqls # SQL language server
    gopls # Go language server

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
    ulauncher # Application launcher
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

    # System tools
    rpi-imager # Raspberry Pi Imaging Utility
    f3 # SD card checker

    #--------------------------------------------------------------------------
    # COMMUNICATION
    #--------------------------------------------------------------------------

    discord # Voice, video and text chat
    telegram-desktop # Messaging app
    viber # Instant messaging
    slack # Team collaboration platform
    thunderbird # Email client

    #--------------------------------------------------------------------------
    # OFFICE & PRODUCTIVITY
    #--------------------------------------------------------------------------

    libreoffice # Office suite
    obsidian # Knowledge base and note-taking
    bitwarden # Password manager

    #--------------------------------------------------------------------------
    # DEVELOPMENT ENVIRONMENTS
    #--------------------------------------------------------------------------

    code-cursor # VS Code fork with AI features
    zed-editor # High-performance code editor
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
    (lutris.override { extraPkgs = pkgs: [ ]; }) # Game manager

    #--------------------------------------------------------------------------
    # TERMINAL ENHANCEMENTS
    #--------------------------------------------------------------------------

    # System information and utilities
    nitch # Lightweight system information fetch
    fastfetch # Fast system information tool
    lolcat # Rainbow text output
    nh # Nix helper CLI
    zathura # Document viewer
    
    # Modern CLI replacements and enhancements
    bat # Modern cat replacement with syntax highlighting
    fd # Modern find replacement
    zoxide # Smarter cd command with frecency
    tldr # Simplified man pages
    duf # Modern df replacement with better output
    du-dust # Modern du replacement
    choose # Human-friendly alternative to cut and awk

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
