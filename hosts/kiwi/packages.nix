{ pkgs, ... }:

{
  #============================================================================
  # SYSTEM-WIDE PACKAGES
  #============================================================================

  environment.systemPackages = with pkgs; [

    #--------------------------------------------------------------------------
    # SYSTEM UTILITIES
    #--------------------------------------------------------------------------

    # Hardware monitoring and control
    lm_sensors # Hardware monitoring tools
    acpi # Advanced Configuration and Power Interface (for battery/AC power detection)
    btop # Resource monitor with CPU, memory, disk, network
    # nvtopPackages.nvidia # NVIDIA GPU monitoring (commented out due to CUDA download issues)
    ddcutil # Monitor control utility (DDC/CI)
    usbutils # USB device utilities
    mesa-demos # OpenGL and Mesa demo programs (includes glxinfo functionality)

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
    # seahorse # GUI for GNOME Keyring
    openssl # Cryptography toolkit
    infisical # Infisical CLI for secret management

    #--------------------------------------------------------------------------
    # NETWORKING TOOLS
    #--------------------------------------------------------------------------

    # Network analysis and monitoring
    ngrok # Expose local servers to the internet
    lsof # Tool to list open files and processes listening on ports
    nmap # Network discovery and security auditing
    netscanner # Network scanner
    wireshark # Network protocol analyzer
    netcat # Networking utility for reading/writing network connections
    iperf3 # Network performance measurement
    bandwhich # Terminal bandwidth utilization tool
    nload # Console application which monitors network traffic
    speedtest-cli # Command line interface for testing internet bandwidth

    # Network management
    networkmanagerapplet # Network manager system tray
    openvpn # Open-source VPN solution
    protonvpn-gui
    gpclient # Interactively authenticate to GlobalProtect VPNs that require SAML
    # globalprotect-openconnect

    wakeonlan # Wake devices using Wake-on-LAN

    # Network testing and analysis
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
    cursor-cli # Command-line interface for Cursor AI editor
    gemini-cli # CLI interface for google's gemini

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
    geekbench_6 # benchmarking tool
    tokei # Count code statistics by language
    entr # Run arbitrary commands when files change
    watchexec # Execute commands in response to file modifications
    grex # Generate regular expressions from test cases

    # Version control
    gh # GitHub CLI
    forgejo-cli # Forgejo CLI tool
    lazygit # Simple terminal UI for git

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
    # linux-wallpaperengine # Wallpaper engine for Linux
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
    chromium # Open source chrome base
    tor-browser # Anonymous web browser
    google-chrome # Google's web browser
    vivaldi # Feature-rich web browser
    vivaldi-ffmpeg-codecs # Video codecs for Vivaldi
    microsoft-edge # Microsoft's web browser

    # Terminals
    warp-terminal # Modern terminal with AI features

    # System tools
    # rpi-imager # Raspberry Pi Imaging Utility (commented out due to build failure)
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
    bitwarden-desktop # Password manager
    zathura # Document viewer

    #--------------------------------------------------------------------------
    # DEVELOPMENT ENVIRONMENTS
    #--------------------------------------------------------------------------

    code-cursor # VS Code fork with AI features
    zed-editor # Zed editor
    antigravity # Google's vscode fork
    vscode # Open soure editor
    responsively-app # Web development tool for responsive design
    dbgate # Database manager
    postman # API development environment
    filezilla # FTP client

    # Language servers
    svelte-language-server
    emmet-language-server
    tailwindcss-language-server
    typescript-language-server
    astro-language-server
    vscode-langservers-extracted
    package-version-server
    docker-compose-language-service
    dockerfile-language-server
    rust-analyzer
    lua-language-server
    phpactor
    nixd
    nil
    sqls
    gopls

    # Formatters
    stylua
    prettierd
    nixfmt # Nix code formatter

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

    # System information and utilities
    nitch # Lightweight system information fetch
    fastfetch # Fast system information tool
    lolcat # Rainbow text output
    nh # Nix helper CLI
    man-pages # C programming language man pages

    # Modern CLI replacements and enhancements
    file # Program that shows the type of files
    bat # Modern cat replacement with syntax highlighting
    fd # Modern find replacement
    # zoxide # Smarter cd command with frecency
    duf # Modern df replacement with better output
    dust # Modern du replacement

    #--------------------------------------------------------------------------
    # THEMING & CUSTOMIZATION
    #--------------------------------------------------------------------------

    nordic # Nordic theme
    font-manager # Font management tool
    cliphist # Clipboard history tool

    #--------------------------------------------------------------------------
    # PRINTING & SCANNING (from existing configuration.nix)
    #--------------------------------------------------------------------------

    # Printing utilities
    cups # CUPS printing system
    ghostscript # PostScript and PDF interpreter

    # Network printing
    gutenprint # High-quality printer drivers

    # Scanner support
    sane-frontends # Scanner utilities
    xsane # GUI scanner frontend

    # User printing utilities
    system-config-printer # GUI printer management
    simple-scan # Document scanning
    hplip # SANE backend for HP devices (includes libsane-hpaio)
    sane-airscan # Driverless scanning
  ];
}
