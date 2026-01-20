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
    btop # Resource monitor with CPU, memory, disk, network
    nvtopPackages.amd # AMD GPU monitoring
    ddcutil # Monitor control utility (DDC/CI)
    usbutils # USB device utilities

    # File system tools
    bleachbit # Disk space cleaner
    dust # Simple, quick, user-friendly disk usage analyzer
    dysk # Modern disk usage utility with visual tree representation
    tree # Directory tree display utility
    eza # Modern replacement for ls with color and Git integration
    trash-cli # FreeDesktop.org trash interface

    # Archive management
    p7zip # 7-Zip implementation
    unzip # Extract compressed files in a ZIP archive
    zip # Create and extract ZIP archives

    # Search and text processing
    fzf # Command-line fuzzy finder
    ripgrep # Fast search tool (grep alternative)
    sd # Intuitive find & replace CLI
    jq # Command-line JSON processor
    yq # YAML/XML processor (jq for YAML)
    fx # Command-line JSON processing tool
    calc # Command-line calculator

    # Process management and system info  
    procs # Modern replacement for ps
    htop # Interactive process viewer

    # Security and secrets
    sops # Secret management tool
    openssl # Cryptography toolkit
    infisical # Infisical CLI for secret management

    #--------------------------------------------------------------------------
    # NETWORKING TOOLS
    #--------------------------------------------------------------------------

    # Essential network tools
    ngrok # Expose local servers to the internet
    nmap # Network discovery and security auditing
    netcat # Networking utility for reading/writing network connections
    iperf3 # Network performance measurement
    bandwhich # Terminal bandwidth utilization tool
    speedtest-cli # Command line interface for testing internet bandwidth
    
    # Network management
    wakeonlan # Wake devices using Wake-on-LAN
    
    # Network testing and diagnostics
    hping # TCP/IP packet assembler/analyzer
    oha # HTTP load generator
    mtr # Network diagnostic tool combining ping and traceroute
    dig # DNS lookup tool

    #--------------------------------------------------------------------------
    # DEVELOPMENT TOOLS
    #--------------------------------------------------------------------------

    # AI assistants
    claude-code # AI code assistant
    opencode
    cursor-cli # Command-line interface for Cursor AI editor

    # Programming languages and runtimes
    nodejs_22 # JavaScript runtime
    bun # Fast, modern, all-in-one JavaScript runtime
    deno # JavaScript runtime
    python3 # Python programming language
    uv # Python package installer and resolver
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain
    sqlite # SQLite database engine

    # Build tools
    gnumake # Build automation tool

    # Development utilities
    gh # GitHub CLI  
    hyperfine # Command-line benchmarking tool
    tokei # Count code statistics by language
    entr # Run arbitrary commands when files change
    watchexec # Execute commands in response to file modifications

    # Version control
    forgejo-cli # Forgejo CLI tool
    lazygit # Simple terminal UI for git

    #--------------------------------------------------------------------------
    # LANGUAGE SERVERS & FORMATTERS
    #--------------------------------------------------------------------------

    # Language servers
    lua-language-server # Language server for Lua
    nixd # Language server for Nix
    svelte-language-server # Language server for Svelte
    emmet-language-server # Language server for Emmet
    tailwindcss-language-server # Language server for Tailwind CSS
    typescript-language-server # Language server for TypeScript
    astro-language-server # Language server for Astro
    vscode-langservers-extracted # HTML/CSS/JSON language servers

    # Code formatters
    stylua # Formatter for Lua
    nixpkgs-fmt # Nix code formatter
    prettier # Code formatter for web technologies
    prettierd # Code formatter daemon for web technologies

    #--------------------------------------------------------------------------
    # MULTIMEDIA TOOLS
    #--------------------------------------------------------------------------

    # Audio/Video processing
    ffmpeg-full # Complete multimedia solution

    #--------------------------------------------------------------------------
    # TERMINAL ENHANCEMENTS
    #--------------------------------------------------------------------------

    # System information and utilities
    nitch # Lightweight system information fetch
    fastfetch # Fast system information tool
    lolcat # Rainbow text output
    nh # Nix helper CLI
    stress # Workload generator for system testing
    
    # Modern CLI replacements and enhancements
    bat # Modern cat replacement with syntax highlighting
    fd # Modern find replacement
    zoxide # Smarter cd command with frecency
    tldr # Simplified man pages
    duf # Modern df replacement with better output
    choose # Human-friendly alternative to cut and awk

    #--------------------------------------------------------------------------
    # ADDITIONAL (from existing configuration.nix)
    #--------------------------------------------------------------------------

    rclone
    git
  ];
}
