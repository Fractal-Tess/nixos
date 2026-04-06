{ pkgs, inputs, ... }:
let
  pwndbg-pkg = inputs.pwndbg.packages.${pkgs.system}.default;
  burpsuite-pkgs = import inputs.nixpkgs-burpsuite {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in
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
    btop-rocm # Resource monitor with CPU, memory, disk, network and AMD GPU support
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
    tumbler # Thumbnail service for Thunar
    pcmanfm # Alternative lightweight file manager
    nextcloud-client # Nextcloud sync client
    yazi # Terminal file manager with image preview

    # Archive management
    engrampa # Archive manager
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
    proton-vpn
    gpclient # Interactively authenticate to GlobalProtect VPNs that require SAML
    # globalprotect-openconnect

    wakeonlan # Wake devices using Wake-on-LAN

    # Network testing and analysis
    oha # HTTP load generator
    mtr # Network diagnostic tool combining ping and traceroute
    dig # DNS lookup tool
    whois # Whois client for domain/IP information

    #--------------------------------------------------------------------------
    # PENTESTING & SECURITY TOOLS
    #--------------------------------------------------------------------------

    # Network Analysis & Scanning
    masscan # Fast port scanner
    tcpdump # Network packet analyzer
    socat # Multipurpose relay for bidirectional data transfer
    hping # Active network security tool
    bind.dnsutils # DNS utilities (dig, nslookup, etc.)

    # Web Application Testing
    burpsuite-pkgs.burpsuite # Web vulnerability scanner
    gobuster # Directory/file & DNS busting tool
    dirb # Web content scanner
    ffuf # Fast web fuzzer
    wfuzz # Web application fuzzer
    sqlmap # Automatic SQL injection tool
    nikto # Web server scanner

    # Password Attacks & Cracking
    john # John the Ripper password cracker
    wordlists # Common wordlists for security testing
    seclists # Collection of security testing lists
    hashcat # Advanced password recovery
    hydra # Network logon cracker
    crunch # Wordlist generator

    # Wireless Testing
    aircrack-ng # WiFi security auditing tools
    kismet # Wireless network detector and sniffer

    # Forensics & Data Recovery
    sleuthkit # Digital forensics tools
    binwalk # Firmware analysis tool
    foremost # File recovery tool
    exif # EXIF data reader
    exiftool # Read/write meta information

    # Steganography Tools
    stegsolve # Steganography analysis tool
    zsteg # PNG/BMP steganography detector
    steghide # Steganography tool for hiding data
    outguess # Steganographic tool

    # Exploitation Frameworks
    metasploit # Penetration testing framework

    # Reverse Engineering & Binary Analysis
    ghidra # Software reverse engineering framework
    (cutter.withPlugins (ps: with ps; [ rz-ghidra ])) # RE platform with Ghidra decompiler
    radare2 # Reverse engineering framework
    rizin # UNIX-like reverse engineering framework
    pwndbg-pkg # GDB plugin for exploit development
    binutils-unwrapped # Binary tools (objdump, readelf, etc.)
    xxd # Hex dump utility
    ltrace # Library call tracer
    strace # System call tracer
    ropgadget # ROP gadget finder
    hexedit # Hex editor

    # Cryptography Tools
    gnupg # GNU Privacy Guard
    hashdeep # Hash computation tool

    # Vulnerability Assessment
    nuclei # Vulnerability scanner
    nuclei-templates # Templates for nuclei scanner

    #--------------------------------------------------------------------------
    # ELECTRONICS DESIGN TOOLS
    #--------------------------------------------------------------------------

    kicad # Electronics design automation (EDA) for PCB design

    #--------------------------------------------------------------------------
    # MATLAB
    #--------------------------------------------------------------------------

    matlab # MATLAB (requires manual installation first via matlab-shell)

    #--------------------------------------------------------------------------
    # DEVELOPMENT TOOLS
    #--------------------------------------------------------------------------

    # AI assistants
    opencode # AI coding assistant
    claude-code # Claude Code CLI
    codex # OpenAI Codex CLI
    t3code # T3 Code desktop app
    aider-chat # AI pair programming in the terminal
    amp-cli
    cursor-cli # Command-line interface for Cursor AI editor
    gemini-cli # CLI interface for google's gemini

    # Testing/Automation
    playwright-driver.browsers # Playwright browsers for e2e testing and agent-browser

    # Programming languages and runtimes
    nodejs_22 # JavaScript runtime
    pnpm # Fast, disk space efficient package manager
    bun # Fast, modern, all-in-one JavaScript runtime
    python3 # Python programming language
    uv # Python package installer and resolver
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain
    sqlite # SQLite database engine
    rustc # Rust compiler
    cargo # Rust package manager

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
    glab # GitLab CLI
    tea # Gitea CLI tool
    lazygit # Simple terminal UI for git
    gitkraken # Git GUI tool
    git-fame # Git repository statistics by contributor

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

    awww # Animated wallpaper daemon for Wayland
    matugen # Material You color palette generator from wallpaper
    waypaper # Wallpaper manager for Wayland
    # linux-wallpaperengine # Wallpaper engine for Linux
    wl-clipboard # Clipboard utilities for Wayland
    grim # Screenshot utility for Wayland (required by satty)
    slurp # Region selector for Wayland (required by satty)
    satty # Screenshot annotation tool for Wayland
    hyprpicker # Color picker for Hyprland
    wtype # Text input simulation for Wayland (required for Handy app)
    libayatana-appindicator # System tray support for apps (required for Handy)
    handy # Speech-to-text application (offline)
    sox # Dependency of claude code voice
    swaynotificationcenter # Notification daemon for Wayland
    libnotify # notify-send command for desktop notifications
    brightnessctl # Brightness control for displays and keyboards
    # gource # Version control visualization (temporarily disabled - build failure)

    #--------------------------------------------------------------------------
    # GUI APPLICATIONS
    #--------------------------------------------------------------------------

    # Application launchers
    rofi # Launcher used by the Hyprland desktop config
    rofi-calc # Calculator mode for rofi launcher
    # Web browsers
    firefox # Open-source web browser
    chromium # Open source chrome base
    tor-browser # Anonymous web browser
    google-chrome # Google's web browser
    vivaldi # Feature-rich web browser
    vivaldi-ffmpeg-codecs # Video codecs for Vivaldi
    # microsoft-edge # Microsoft's web browser (temporarily disabled - version unavailable)

    # Terminals
    kitty # Fast GPU-accelerated terminal emulator
    warp-terminal # Modern terminal with AI features

    # System tools
    # rpi-imager # Raspberry Pi Imaging Utility (commented out due to build failure)
    f3 # SD card checker

    #--------------------------------------------------------------------------
    # COMMUNICATION
    #--------------------------------------------------------------------------

    discord # Voice, video and text chat
    telegram-desktop # Messaging app
    # viber # Instant messaging (download unavailable)
    slack # Team collaboration platform
    thunderbird # Email client

    #--------------------------------------------------------------------------
    # OFFICE & PRODUCTIVITY
    #--------------------------------------------------------------------------

    libreoffice # Office suite
    obsidian # Knowledge base and note-taking
    # bitwarden-desktop # Password manager -- broken: electron-39 patch failure (upstream nixpkgs bug)
    zathura # Document viewer

    #--------------------------------------------------------------------------
    # DEVELOPMENT ENVIRONMENTS
    #--------------------------------------------------------------------------

    code-cursor # VS Code fork with AI features
    zed-editor # Zed editor
    antigravity # Google's vscode fork
    vscode # Open soure editor
    responsively-app # Web development tool for responsive design
    tradingview # Trading platform desktop app
    tws # Interactive Brokers Trader Workstation
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
    bash-language-server
    yaml-language-server
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
    # heroic # Game launcher -- broken: electron-39 patch failure (upstream nixpkgs bug)
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
